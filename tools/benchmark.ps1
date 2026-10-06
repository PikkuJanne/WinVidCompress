# Developer-only benchmark. Retains owned media/diagnostics in ignored .test-results.
[CmdletBinding()]
param(
    [string]$FFmpeg='ffmpeg.exe',
    [string]$FFprobe='ffprobe.exe',
    [ValidateRange(2,10)][int]$Repeats=3,
    [ValidateRange(0.2,30)][double]$SyntheticSeconds=2,
    [ValidatePattern('^[a-f0-9]{32}$')][string]$RunId=([guid]::NewGuid().ToString('N')),
    [string[]]$ApprovedCopies=@(),
    [ValidateSet('veryfast','fast','medium','slow')][string[]]$CandidatePresets=@(),
    [ValidateRange(0,51)][int[]]$CandidateCRFs=@()
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent $PSScriptRoot
. (Join-Path $repoRoot 'tests/TestSupport.ps1')

function Get-BenchmarkTokens([string[]]$Tokens, [string]$Source, [string]$Output) {
    foreach ($token in $Tokens) {
        if ($token -ceq $Source) {'<SOURCE>'}
        elseif ($token -ceq $Output) {'<OUTPUT>'}
        else {$token}
    }
}

function Get-BenchmarkSpread([object[]]$Values) {
    $sorted=@($Values | Sort-Object)
    if (-not $sorted.Count) {return $null}
    $middle=[int][Math]::Floor($sorted.Count/2)
    $median=if ($sorted.Count % 2) {$sorted[$middle]} else {($sorted[$middle-1]+$sorted[$middle])/2}
    return [pscustomobject]@{Count=$sorted.Count;Minimum=$sorted[0];Median=$median;
        Maximum=$sorted[-1];Range=$sorted[-1]-$sorted[0]}
}

function Invoke-BenchmarkCandidate($Encoder, $Probe, $Source, $OutputDirectory, $Profile) {
    # Experiments use production argument/planning/validation/publication helpers.
    # Only this developer runner changes the candidate's preset/CRF tokens.
    $job=$null; $published=$false; $stage='Probe'; $abort=$false
    $clock=[Diagnostics.Stopwatch]::StartNew();$timer=[Diagnostics.Stopwatch]::StartNew()
    $record=New-JobResult $Source $Profile.CRF
    try {
        $record.InputBytes=Get-JobFileLength $Source
        $inspection=Get-MediaInspection $Probe $Source
        $record.Timings.ProbeSeconds=$timer.Elapsed.TotalSeconds
        if (-not $inspection.Succeeded) {throw $inspection.Reason}
        $record.Diagnostics.Probe=$inspection
        $record.DurationSeconds=$inspection.DurationSeconds;$record.DurationState=$inspection.DurationState
        $plan=Get-StreamPlan $inspection
        $record.SelectedStreams=[pscustomobject]@{Video=$plan.Video.Index;
            Audio=$(if ($null -ne $plan.Audio) {$plan.Audio.Index} else {$null})}
        $nominal=Join-Path $OutputDirectory ([IO.Path]::GetFileNameWithoutExtension($Source)+'.mp4')
        $job=New-OutputJob $Source $OutputDirectory $nominal $nominal
        $record.JobId=$job.JobId;$record.TemporaryPath=$job.TempPath
        [void](Assert-OutputJob $job -BeforeEncode)
        $tokens=@(Get-EncodeArguments $Source $job.TempPath $plan $Profile.CRF (Parse-MetadataFromName ([IO.Path]::GetFileName($Source))))
        $presetIndex=[array]::IndexOf($tokens,'-preset')
        if ($presetIndex -lt 0) {throw 'Production preset token missing.'}
        $tokens[$presetIndex+1]=$Profile.Preset
        $record.Diagnostics.EncodeArguments=$tokens
        $record.Settings.Preset=$Profile.Preset
        if ($null -eq $plan.Audio) {$record.Settings.AudioCodec=$null;$record.Settings.AudioBitrate=$null}
        $stage='Encode';$timer.Restart()
        $native=Invoke-EncodeProcess $Encoder $tokens
        $record.Timings.EncodeAndMuxSeconds=$timer.Elapsed.TotalSeconds
        $record.Diagnostics.Encode=$native;$record.Settings.Applied=$native.Started
        if (-not $native.Succeeded) {throw $native.Error}
        $stage='Validation';$timer.Restart()
        $validation=Get-OutputValidation $Probe $job $inspection $plan
        $record.Timings.ValidationSeconds=$timer.Elapsed.TotalSeconds
        $record.Diagnostics.Validation=$validation
        if (-not $validation.Succeeded) {throw $validation.Reason}
        $stage='Promote';$timer.Restart()
        $publication=Publish-OutputJob $job 'rename'
        $record.Timings.PromotionSeconds=$timer.Elapsed.TotalSeconds
        $published=$publication.Published
        if (-not $published) {throw 'Candidate was not published.'}
        $record.OutputPath=$publication.FinalPath;$record.OutputBytes=Get-JobFileLength $record.OutputPath
        $record.Outcome='Completed';$record.Stage='Complete'
        $size=Get-SizeAccounting $record.Outcome $record.InputBytes $record.OutputBytes
        $record.SizeChangeBytes=$size.SizeChangeBytes;$record.SizeChangePercent=$size.SizeChangePercent
        $record.SavingsPercent=$size.SavingsPercent;$record.SizeState=$size.State
        $record.Reason='Published experimental candidate.'
    } catch {
        $abort=$_.Exception.Data.Contains('WvcAbortBatch')
        if ($abort) {$script:WvcProcessCleanupFailed=$true}
        $record.Outcome='Failed';$record.Stage=$stage;$record.Reason=$_.Exception.Message
        throw
    } finally {
        if ($null -ne $job) {[void](Close-OutputJob $job $published $stage $record.Reason -EncoderMayStillRun:$abort)}
        $clock.Stop();$record.ElapsedSeconds=$clock.Elapsed.TotalSeconds
        Write-WvcTestJson (Join-Path $OutputDirectory 'job.local.json') $record
    }
    return $record
}

if ($MyInvocation.InvocationName -eq '.') {return}
$savedEnvironment=@{APPDATA=$env:APPDATA;FFREPORT=$env:FFREPORT}
$reportDirectory=Join-Path $repoRoot ('.test-results/benchmarks/'+$RunId)
$failure=$null
$ownsReport=$false
try {
    # Refuse links in the entire report path before creating any owned files.
    $parentPath=$reportDirectory
    while ($parentPath) {
        if (Test-Path -LiteralPath $parentPath) {
            if ((Get-Item -LiteralPath $parentPath -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {throw 'Reparse point in benchmark path.'}
        }
        $parentPath=Split-Path -Parent $parentPath
    }
    if (Test-Path -LiteralPath $reportDirectory) {throw 'Benchmark RunId already exists; use a fresh RunId.'}
    [void][IO.Directory]::CreateDirectory($reportDirectory)
    $marker=[IO.File]::Open((Join-Path $reportDirectory '.wvc-benchmark-owner'),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try {$markerBytes=[Text.Encoding]::ASCII.GetBytes($RunId);$marker.Write($markerBytes,0,$markerBytes.Length)} finally {$marker.Dispose()}
    $ownsReport=$true
    $env:APPDATA=Join-Path $reportDirectory 'appdata';$env:FFREPORT=$null
    . (Join-Path $repoRoot 'WinVidCompress.ps1')
    $encoder=(Get-Command $FFmpeg -CommandType Application -ErrorAction Stop).Source
    $probe=(Get-Command $FFprobe -CommandType Application -ErrorAction Stop).Source
    $toolVersions=@()
    foreach ($tool in @(@{Name='FFmpeg';Path=$encoder},@{Name='FFprobe';Path=$probe})) {
        $version=Invoke-WvcTestProcess $tool.Path @('-version')
        if ($version.ExitCode -ne 0) {throw ('Native version query failed: '+$version.StdErr)}
        $toolVersions+=[pscustomobject]@{Name=$tool.Name;Version=($version.StdOut -split '\r?\n')[0];
            SHA256=(Get-FileHash -LiteralPath $tool.Path -Algorithm SHA256).Hash.ToLowerInvariant()}
    }
    $sourceCommit=(& git -C $repoRoot rev-parse HEAD | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $sourceCommit -notmatch '^[a-f0-9]{40}$') {throw 'Git source provenance unavailable.'}
    $dirty=[bool]@(& git -C $repoRoot status --porcelain=v1 --untracked-files=all).Count
    if ($LASTEXITCODE -ne 0) {throw 'Git dirty state unavailable.'}
    $sourceRoot=Join-Path $reportDirectory 'sources';[void][IO.Directory]::CreateDirectory($sourceRoot)
    $sources=@();$originalHashes=@{}
    if ($ApprovedCopies.Count) {
        for ($i=0;$i -lt $ApprovedCopies.Count;$i++) {
            $file=Get-Item -LiteralPath $ApprovedCopies[$i] -Force
            if ($file.PSIsContainer -or ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -or
                $file.Extension.ToLowerInvariant() -notin $VideoExts) {throw 'Approved copy must be a regular supported media file.'}
            $id='copy-{0:D2}' -f ($i+1)
            $source=Join-Path $sourceRoot ($id+$file.Extension)
            $originalHashes[$file.FullName]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
            # File.Copy with overwrite=false never replaces the supplied copy.
            [IO.File]::Copy($file.FullName,$source,$false)
            if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne $originalHashes[$file.FullName]) {throw 'Approved copy changed during duplication.'}
            $sources+=[pscustomobject]@{Id=$id;Path=$source;Provenance='Owner-supplied approved copy; disposable opaque-name duplicate';RecipeTokens=$null}
        }
    } else {
        $source=Join-Path $sourceRoot 'synthetic-01.mkv'
        $seconds=$SyntheticSeconds.ToString([Globalization.CultureInfo]::InvariantCulture)
        $recipe=@('-hide_banner','-nostdin','-v','error','-n','-f','lavfi','-i',('testsrc2=size=320x240:rate=24:duration='+$seconds),
            '-f','lavfi','-i',('sine=frequency=440:sample_rate=48000:duration='+$seconds),
            '-map','0:v:0','-map','1:a:0','-c:v','ffv1','-pix_fmt','yuv420p','-c:a','pcm_s16le',$source)
        $generated=Invoke-WvcTestProcess $encoder $recipe -TimeoutMilliseconds 60000
        if ($generated.ExitCode -ne 0) {throw ('Synthetic generation failed: '+$generated.StdErr)}
        $sources+=[pscustomobject]@{Id='synthetic-01';Path=$source;Provenance='Generated testsrc2 + 440 Hz sine; FFV1/PCM; no private media';
            RecipeTokens=@(Get-BenchmarkTokens $recipe '' $source)}
    }
    $profiles=@([pscustomobject]@{Id='default';Preset='veryfast';CRF=22;Experimental=$false})
    foreach ($preset in $CandidatePresets) {
        if ($preset -ne 'veryfast') {$profiles+=[pscustomobject]@{Id=('preset-'+$preset);Preset=$preset;CRF=22;Experimental=$true}}
    }
    foreach ($crf in $CandidateCRFs) {
        if ($crf -ne 22) {$profiles+=[pscustomobject]@{Id=('crf-'+$crf);Preset='veryfast';CRF=$crf;Experimental=$true}}
    }
    $profiles=@($profiles | Sort-Object Id -Unique)
    $sourceRecords=@();$runs=@();$order=0
    foreach ($source in $sources) {
        $sourceHash=(Get-FileHash -LiteralPath $source.Path -Algorithm SHA256).Hash
        $inspection=Get-MediaInspection $probe $source.Path
        if (-not $inspection.Succeeded) {throw $inspection.Reason}
        $plan=Get-StreamPlan $inspection;$video=$plan.Video
        $sourceRecords+=[pscustomobject]@{Id=$source.Id;Provenance=$source.Provenance;RecipeTokens=$source.RecipeTokens;
            SHA256=$sourceHash.ToLowerInvariant();InputBytes=(Get-JobFileLength $source.Path);Codec=$video.CodecName;
            Width=$video.Width;Height=$video.Height;Rotation=$video.RotationDegrees;SAR=$video.SampleAspectRatio;
            AverageFPS=$video.AverageFrameRate;RealFPS=$video.RealFrameRate;DurationSeconds=$inspection.DurationSeconds;
            DurationState=$inspection.DurationState;DurationSource=$inspection.DurationSource;
            SelectedStreams=[pscustomobject]@{Video=$video.Index;Audio=$(if ($plan.Audio) {$plan.Audio.Index} else {$null})}}
        # Interleave profiles within each repeat to disclose warm-cache/run-order effects.
        for ($repeat=1;$repeat -le $Repeats;$repeat++) {
            foreach ($profile in $profiles) {
                $order++
                $outputDirectory=Join-Path $reportDirectory ('outputs/'+$source.Id+'/'+$repeat+'/'+$profile.Id)
                [void][IO.Directory]::CreateDirectory($outputDirectory)
                if ($profile.Experimental) {
                    $job=Invoke-BenchmarkCandidate $encoder $probe $source.Path $outputDirectory $profile
                } else {
                    $job=Compress-One $encoder $probe $source.Path $outputDirectory 22
                    Write-WvcTestJson (Join-Path $outputDirectory 'job.local.json') $job
                }
                if ($job.Outcome -ne 'Completed') {throw ('Benchmark job failed: '+$job.Reason)}
                $tokens=@($job.Diagnostics.EncodeArguments)
                $size=Get-SizeAccounting $job.Outcome $job.InputBytes $job.OutputBytes
                $runs+=[pscustomobject]@{Order=$order;SourceId=$source.Id;ProfileId=$profile.Id;Repeat=$repeat;
                    Experimental=$profile.Experimental;Settings=$job.Settings;
                    CommandTokens=@(Get-BenchmarkTokens $tokens $source.Path $job.TemporaryPath);
                    Outcome=$job.Outcome;Size=$size;DurationSeconds=$job.DurationSeconds;ElapsedSeconds=$job.ElapsedSeconds;
                    Timings=$job.Timings;FastStartRelocationSeconds=$null;FastStartTiming='Included in EncodeAndMuxSeconds; not separately measured';
                    OutputSHA256=(Get-FileHash -LiteralPath $job.OutputPath -Algorithm SHA256).Hash.ToLowerInvariant();
                    StructuralValidation='Passed';Playback=[pscustomobject]@{Status='NotRun';Observer=$null;ObservedAt=$null;
                        FacialDetail=$null;Text=$null;Motion=$null;Audio=$null;Sync=$null;Notes=$null}}
                if ((Get-FileHash -LiteralPath $source.Path -Algorithm SHA256).Hash -ne $sourceHash) {throw 'Disposable benchmark input changed.'}
            }
        }
    }
    foreach ($original in $originalHashes.Keys) {
        if ((Get-FileHash -LiteralPath $original -Algorithm SHA256).Hash -ne $originalHashes[$original]) {throw 'Supplied approved copy changed.'}
    }
    $spread=@()
    foreach ($source in $sources) {foreach ($profile in $profiles) {
        $group=@($runs | Where-Object {$_.SourceId -eq $source.Id -and $_.ProfileId -eq $profile.Id})
        $spread+=[pscustomobject]@{SourceId=$source.Id;ProfileId=$profile.Id;
            ElapsedSeconds=(Get-BenchmarkSpread @($group.ElapsedSeconds));
            ProbeSeconds=(Get-BenchmarkSpread @($group | ForEach-Object {$_.Timings.ProbeSeconds}));
            EncodeAndMuxSeconds=(Get-BenchmarkSpread @($group | ForEach-Object {$_.Timings.EncodeAndMuxSeconds}));
            ValidationSeconds=(Get-BenchmarkSpread @($group | ForEach-Object {$_.Timings.ValidationSeconds}));
            PromotionSeconds=(Get-BenchmarkSpread @($group | ForEach-Object {$_.Timings.PromotionSeconds}));
            OutputBytes=(Get-BenchmarkSpread @($group | ForEach-Object {$_.Size.OutputBytes}))}
    }}
    $cpu=Get-CimInstance Win32_Processor | Select-Object -First 1
    $os=Get-CimInstance Win32_OperatingSystem
    $report=[pscustomobject]@{SchemaVersion=1;RecordedAt=[DateTime]::UtcNow.ToString('o');SourceCommit=$sourceCommit;Dirty=$dirty;
        ApplicationSHA256=(Get-FileHash -LiteralPath (Join-Path $repoRoot 'WinVidCompress.ps1')).Hash.ToLowerInvariant();
        RunnerSHA256=(Get-FileHash -LiteralPath $PSCommandPath).Hash.ToLowerInvariant();
        Host=[pscustomobject]@{OS=$os.Caption;Version=$os.Version;Build=$os.BuildNumber;Architecture=$os.OSArchitecture;
            PowerShell=$PSVersionTable.PSVersion.ToString();Edition=$PSVersionTable.PSEdition;
            CPU=$cpu.Name;LogicalProcessors=$cpu.NumberOfLogicalProcessors;MemoryBytes=[long]$os.TotalVisibleMemorySize*1024};
        Tools=$toolVersions;Repeats=$Repeats;Sources=$sourceRecords;Profiles=$profiles;Runs=$runs;Spread=$spread;
        Limitations=@('Measured local warm-cache examples; run order recorded. Results vary; valid outputs can grow.',
            'Synthetic patterns do not establish representative interview quality or playback integrity.',
            'Structural validation is not full visual/audio integrity. Playback observations remain NotRun until owner-recorded.',
            'Faststart finalization is inside the encoder/mux process; its independent time is unavailable.',
            'Default uses Compress-One; experimental path uses the same planning/output-safety helpers with only preset or CRF changed.',
            'Paths replaced by placeholders; raw diagnostic objects and input tags excluded. Private reports/media remain outside Git.')}
    Write-WvcTestJson (Join-Path $reportDirectory 'report.json') $report
    Write-Host ('Benchmark report: '+(Join-Path $reportDirectory 'report.json'))
    Write-Host ('Retained review media and local diagnostics: '+$reportDirectory)
} catch {
    $failure=$_
    if ($ownsReport) {
        $failureBytes=(New-Object Text.UTF8Encoding($false)).GetBytes(($_ | Out-String))
        $failureStream=[IO.File]::Open((Join-Path $reportDirectory 'failure.local.txt'),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
        try {$failureStream.Write($failureBytes,0,$failureBytes.Length)} finally {$failureStream.Dispose()}
    }
} finally {
    foreach ($key in $savedEnvironment.Keys) {[Environment]::SetEnvironmentVariable($key,$savedEnvironment[$key],'Process')}
}
if ($null -ne $failure) {Write-Error $failure;exit 1}
