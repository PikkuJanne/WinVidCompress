BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:Saved=@{APPDATA=$env:APPDATA;FFREPORT=$env:FFREPORT;WVC_RESUME_RECORD=$env:WVC_RESUME_RECORD;WVC_RESUME_STOP=$env:WVC_RESUME_STOP;WVC_RESUME_FAIL=$env:WVC_RESUME_FAIL;WVC_RESUME_BAD_PROBE=$env:WVC_RESUME_BAD_PROBE}
    $env:APPDATA=Join-Path $TestDrive 'appdata'; $env:FFREPORT=$null
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    $script:NativeEncoder=Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $script:NativeProbe=Get-Command ffprobe.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $script:Encoder=Join-Path $TestDrive 'ffmpeg.exe'; $script:Probe=Join-Path $TestDrive 'ffprobe.exe'
    $compile=Invoke-WvcTestProcess (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe') @(
        '-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'New-ResumeFixture.ps1'),'-Destination',$Encoder)
    if ($compile.ExitCode -ne 0) { throw $compile.StdErr }
    Copy-Item -LiteralPath $Encoder -Destination $Probe
    $script:RealSave=${function:Save-BatchManifest}
    $script:RealCompress=${function:Compress-One}
    $script:RealCancellation=${function:Test-WvcCancellation}
}
AfterAll { foreach ($name in $Saved.Keys) { Set-Item ('Env:'+$name) $Saved[$name] } }
Describe 'Validated sequential resume through native fixtures [WVC-M3-07]' {
    BeforeEach {
        $script:Root=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Sources=Join-Path $Root 'sources'; $script:Output=Join-Path $Root 'output'
        [void][IO.Directory]::CreateDirectory($Sources); [void][IO.Directory]::CreateDirectory($Output)
        $script:Source=Join-Path $Sources 'a.mov'; [IO.File]::WriteAllText($Source,'source sentinel')
        $script:Manifest=Join-Path $Root 'batch.json'; $script:Cfg=[pscustomobject]@{OutputDir=$Output}
        $env:WVC_RESUME_RECORD=Join-Path $Root 'encodes.txt'; $env:WVC_RESUME_STOP=$null; $env:WVC_RESUME_FAIL=$null; $env:WVC_RESUME_BAD_PROBE=$null
        $script:CancellationContext=[pscustomobject]@{Requested=$false;ConsoleEnabled=$false;RestoreConsole=$false;Warning=$null}
        Mock Write-Host {}; Mock Write-Progress {}
    }
    AfterEach { $script:CancellationContext=$null }
    It 'retains completed provenance across two validated resumes without encoder starts [A01 A02]' {
        $first=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest
        $first.Counters.Done | Should -Be 1
        ((Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json).Jobs[0].JobId) | Should -BeExactly $first.Jobs[0].JobId
        $hash=(Get-FileHash -LiteralPath $first.Jobs[0].OutputPath).Hash
        foreach ($attempt in 1..2) {
            $retry=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest -Resume
            $retry.ExitCode | Should -Be 0; $retry.Counters.Skipped | Should -Be 1
            $retry.Jobs[0].Stage | Should -BeExactly 'Resume'
            ($retry.Jobs[0].Reason) | Should -Match 'structural validation'
            (Get-FileHash -LiteralPath $first.Jobs[0].OutputPath).Hash | Should -BeExactly $hash
            ((Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json).Jobs[0].State) | Should -BeExactly 'Completed'
        }
        @(Get-Content -LiteralPath $env:WVC_RESUME_RECORD).Count | Should -Be 1
    }
    It 'reruns invalid completion for <Change> and preserves old finals [A01]' -TestCases @(
        @{Change='source size'},@{Change='source time'},@{Change='CRF'},@{Change='settings fingerprint'},
        @{Change='missing output'},@{Change='corrupt header'},@{Change='changed output same size/time'},@{Change='bad structure'}
    ) {
        param($Change)
        $first=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest
        $final=$first.Jobs[0].OutputPath; $finalHash=(Get-FileHash -LiteralPath $final).Hash
        switch ($Change) {
            'source size' {[IO.File]::AppendAllText($Source,'changed')}
            'source time' {[IO.File]::SetLastWriteTimeUtc($Source,[datetime]::UtcNow.AddDays(-1))}
            'CRF' {$DefaultCRF=23}
            'settings fingerprint' {$m=Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json; $m.Jobs[0].SettingsFingerprint='0'*64; [IO.File]::WriteAllText($Manifest,($m | ConvertTo-Json -Depth 8))}
            'missing output' {[IO.File]::Move($final,($final+'.sentinel'))}
            'corrupt header' {[IO.File]::WriteAllText($final,'bad header sentinel')}
            'changed output same size/time' {$time=[IO.File]::GetLastWriteTimeUtc($final); $bytes=[IO.File]::ReadAllBytes($final); $bytes[-1]=43; [IO.File]::WriteAllBytes($final,$bytes); [IO.File]::SetLastWriteTimeUtc($final,$time)}
            'bad structure' {$env:WVC_RESUME_BAD_PROBE=$final}
        }
        $currentHash=if ([IO.File]::Exists($final)) {(Get-FileHash -LiteralPath $final).Hash} else {$null}
        $CollisionMode='skip'
        $retry=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest -Resume
        $retry.Counters.Done | Should -Be 1; $retry.Counters.Skipped | Should -Be 0
        @(Get-Content -LiteralPath $env:WVC_RESUME_RECORD).Count | Should -Be 2
        if ($currentHash) { (Get-FileHash -LiteralPath $final).Hash | Should -BeExactly $currentHash }
        if ($Change -eq 'missing output') { (Get-FileHash -LiteralPath ($final+'.sentinel')).Hash | Should -BeExactly $finalHash }
    }
    It 'preserves a validated skip after reporting failure or late cancellation [A02]' {
        [void](Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest)
        Mock Write-Host { throw 'injected display failure' } -ParameterFilter { $Object -like 'Resume validated:*' }
        $retry=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest -Resume
        $retry.Counters.Skipped | Should -Be 1; $retry.ExitCode | Should -Be 0
        Mock Write-Host { $script:CancellationContext.Requested=$true } -ParameterFilter { $Object -like 'Resume validated:*' }
        $cancel=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest -Resume
        $cancel.Counters.Skipped | Should -Be 1; $cancel.ExitCode | Should -Be 3
        $cancel.Jobs[0].CancellationRequested | Should -BeTrue
    }
    It 'retries Cancelled/Unstarted with fresh temp paths and keeps completed final/retained partial [A02]' {
        foreach ($name in @('b.mov','c.mov')) { [IO.File]::WriteAllText((Join-Path $Sources $name),'source sentinel') }
        $env:WVC_RESUME_STOP='b.mov'
        Mock Test-WvcCancellation {
            if ([IO.File]::Exists($env:WVC_RESUME_RECORD+'.ready')) { $script:CancellationContext.Requested=$true }
            & $script:RealCancellation
        }
        $first=Process-Paths @($Sources) $Encoder $Probe $Cfg -ManifestPath $Manifest
        $first.ExitCode | Should -Be 3
        ($first.Jobs.Outcome -join ',') | Should -BeExactly 'Completed,Cancelled,Unstarted'
        ((Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json).Jobs.State -join ',') | Should -BeExactly 'Completed,Cancelled,Unstarted'
        $first.Jobs[1].AbortBatch | Should -BeFalse
        $final=$first.Jobs[0].OutputPath; $finalHash=(Get-FileHash -LiteralPath $final).Hash
        $partial=$first.Jobs[1].TemporaryPath; $partialHash=(Get-FileHash -LiteralPath $partial).Hash
        $record=Join-Path $first.Jobs[1].RetainedPath 'retained.json'; $recordHash=(Get-FileHash -LiteralPath $record).Hash
        $env:WVC_RESUME_STOP=$null; $script:CancellationContext.Requested=$false
        Mock Test-WvcCancellation { & $script:RealCancellation }
        $retry=Process-Paths @($Sources) $Encoder $Probe $Cfg -ManifestPath $Manifest -Resume
        $retry.ExitCode | Should -Be 0
        ($retry.Jobs.Outcome -join ',') | Should -BeExactly 'Skipped,Completed,Completed'
        $retry.Jobs[1].TemporaryPath | Should -Not -BeExactly $partial
        (Get-FileHash -LiteralPath $final).Hash | Should -BeExactly $finalHash
        (Get-FileHash -LiteralPath $partial).Hash | Should -BeExactly $partialHash
        (Get-FileHash -LiteralPath $record).Hash | Should -BeExactly $recordHash
        @(Get-Content -LiteralPath $env:WVC_RESUME_RECORD).Count | Should -Be 4
    }
    It 'retries failed jobs from source without adopting their old partial [A02]' {
        $env:WVC_RESUME_FAIL='a.mov'
        $first=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest
        $first.Counters.Failed | Should -Be 1
        $partial=$first.Jobs[0].TemporaryPath; $hash=(Get-FileHash -LiteralPath $partial).Hash
        $env:WVC_RESUME_FAIL=$null
        $retry=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest -Resume
        $retry.Counters.Done | Should -Be 1
        $retry.Jobs[0].TemporaryPath | Should -Not -BeExactly $partial
        (Get-FileHash -LiteralPath $partial).Hash | Should -BeExactly $hash
    }
    It 'detects same-size/time edits with opt-in hashing and refuses downgrade [A03]' {
        $first=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest -StrongSourceHash
        $time=[IO.File]::GetLastWriteTimeUtc($Source); [IO.File]::WriteAllText($Source,'source SENTINEL'); [IO.File]::SetLastWriteTimeUtc($Source,$time)
        (Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest -Resume).ExitCode | Should -Be 2
        $retry=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest -Resume -StrongSourceHash
        $retry.Counters.Done | Should -Be 1; $retry.Counters.Skipped | Should -Be 0
    }
    It 'upgrades fast identity by retrying rather than retroactively trusting current hashes [A03]' {
        [IO.File]::WriteAllText((Join-Path $Sources 'b.mov'),'source sentinel')
        $first=Process-Paths @($Sources) $Encoder $Probe $Cfg -ManifestPath $Manifest
        $CollisionMode='skip'
        $retry=Process-Paths @($Sources) $Encoder $Probe $Cfg -ManifestPath $Manifest -Resume -StrongSourceHash
        $retry.Counters.Done | Should -Be 2
        ((Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json).Jobs[0].SourceIdentity.SHA256).Length | Should -Be 64
    }
    It 'preserves published Done and stops dispatch after checkpoint failure with <SourceCount> sources [A02 A04]' -TestCases @(@{SourceCount=1},@{SourceCount=2}) {
        param($SourceCount)
        if ($SourceCount -eq 2) { [IO.File]::WriteAllText((Join-Path $Sources 'b.mov'),'second') }
        Mock Save-BatchManifest {
            if ($Context.Manifest.Jobs[0].State -eq 'Completed') { throw 'injected checkpoint failure' }
            & $script:RealSave $Context
        }
        $result=Process-Paths @($Sources) $Encoder $Probe $Cfg -ManifestPath $Manifest
        $result.ExitCode | Should -Be 1
        ($result.Jobs.Outcome -join ',') | Should -BeExactly $(if ($SourceCount -eq 2) {'Completed,Unstarted'} else {'Completed'})
        $result.Jobs[0].AbortBatch | Should -BeTrue
        [IO.File]::Exists($result.Jobs[0].OutputPath) | Should -BeTrue
        @(Get-Content -LiteralPath $env:WVC_RESUME_RECORD).Count | Should -Be 1
        ((Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json).Jobs[0].State) | Should -BeExactly 'Running'
    }
    It 'does not claim resumable completion if source changes during encoding [A01]' {
        Mock Compress-One {
            $result=& $script:RealCompress $ffmpeg $ffprobe $inPath $outDir $crf -FileIndex $FileIndex -FileTotal $FileTotal
            [IO.File]::AppendAllText($inPath,'changed'); return $result
        }
        $first=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest
        $first.Counters.Done | Should -Be 1
        ((Get-Content -LiteralPath $Manifest -Raw | ConvertFrom-Json).Jobs[0].State) | Should -BeExactly 'Failed'
    }
    It 'rejects foreign manifests before native job dispatch and leaves sentinel bytes [A04]' {
        [IO.File]::WriteAllText($Manifest,'{"Owner":"foreign","Commands":"delete source"}')
        $result=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest -Resume
        $result.ExitCode | Should -Be 2
        [IO.File]::Exists($env:WVC_RESUME_RECORD) | Should -BeFalse
        [IO.File]::ReadAllText($Source) | Should -BeExactly 'source sentinel'
        [IO.File]::ReadAllText($Manifest) | Should -BeExactly '{"Owner":"foreign","Commands":"delete source"}'
    }
    It 'refuses moved/expanded batch scope without following stored source paths [A01 A04]' {
        [void](Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath $Manifest)
        [IO.File]::WriteAllText((Join-Path $Sources 'b.mov'),'foreign queue')
        $retry=Process-Paths @($Sources) $Encoder $Probe $Cfg -ManifestPath $Manifest -Resume
        $retry.ExitCode | Should -Be 2
        @(Get-Content -LiteralPath $env:WVC_RESUME_RECORD).Count | Should -Be 1
    }
    It 'supports actual PS1 and unattended BAT manifest/resume flags, exit and logs [A02 A04]' {
        $appdata=Join-Path $Root 'appdata'; $config=Join-Path $appdata 'WinVidCompress'
        [void][IO.Directory]::CreateDirectory($config); Write-WvcTestJson (Join-Path $config 'config.json') $Cfg
        $environment=@{APPDATA=$appdata;PATH=($TestDrive+';'+$env:SystemRoot+'/System32');WVC_RESUME_RECORD=$env:WVC_RESUME_RECORD;FFREPORT=''}
        $ps1=Invoke-WvcTestProcess (Get-Process -Id $PID).Path @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
            (Join-Path $RepoRoot 'WinVidCompress.ps1'),'-Unattended','-ManifestPath',$Manifest,$Source) -Environment $environment
        $ps1.ExitCode | Should -Be 0
        $command='"'+(Join-Path $RepoRoot 'WinVidCompress.bat')+'" -Unattended -Resume -ManifestPath "'+$Manifest+'" "'+$Source+'"'
        $wrapper=Join-Path $Root 'resume.bat'; [IO.File]::WriteAllText($wrapper,('@echo off'+"`r`n"+$command+"`r`n"))
        $bat=Invoke-WvcTestProcess (Join-Path $env:SystemRoot 'System32/cmd.exe') @('/d','/c',$wrapper) -Environment $environment
        $bat.ExitCode | Should -Be 0 -Because ($bat.StdOut+$bat.StdErr)
        @(Get-Content -LiteralPath $env:WVC_RESUME_RECORD).Count | Should -Be 1
        $logs=@(Get-ChildItem -LiteralPath (Join-Path $config 'logs') -Filter 'results.jsonl' -Recurse)
        $logs.Count | Should -Be 2
        $records=@($logs | ForEach-Object { Get-Content -LiteralPath $_.FullName } | ForEach-Object { $_ | ConvertFrom-Json })
        @($records | Where-Object { $_.Kind -eq 'Job' -and $_.Outcome -eq 'Skipped' }).Count | Should -Be 1
        @($records | Where-Object { $_.Kind -eq 'Result' -and $_.ExitCode -eq 0 }).Count | Should -Be 2
    }
    It 'requires manifest controls to have an explicit batch scope [A04]' {
        (Invoke-WinVidCompress -Unattended -Resume -Paths @($Source)).ExitCode | Should -Be 2
        (Invoke-WinVidCompress -ManifestPath $Manifest).ExitCode | Should -Be 2
        (Invoke-WinVidCompress -CheckEnvironment -ManifestPath $Manifest -Paths @($Source)).ExitCode | Should -Be 2
        [IO.File]::Exists($Manifest) | Should -BeFalse
    }
    It 'validates an installed FFmpeg/FFprobe MP4 on real resumed source [A01 A02]' {
        $ffmpeg=$script:NativeEncoder
        $ffprobe=$script:NativeProbe
        if (-not $ffmpeg -or -not $ffprobe) { Set-ItResult -Skipped -Because 'Installed native media tools unavailable.'; return }
        $generated=Invoke-WvcTestProcess $ffmpeg.Source @('-hide_banner','-nostdin','-n','-f','lavfi','-i',
            'testsrc2=size=64x64:rate=24:duration=0.5','-c:v','libx264','-pix_fmt','yuv420p',($Source+'.mp4'))
        $generated.ExitCode | Should -Be 0 -Because $generated.StdErr
        $media=$Source+'.mp4'
        $first=Process-Paths @($media) $ffmpeg.Source $ffprobe.Source $Cfg -ManifestPath $Manifest -StrongSourceHash
        $first.Counters.Done | Should -Be 1
        $retry=Process-Paths @($media) $ffmpeg.Source $ffprobe.Source $Cfg -ManifestPath $Manifest -Resume -StrongSourceHash
        $retry.Counters.Skipped | Should -Be 1; $retry.Jobs[0].Stage | Should -BeExactly 'Resume'
    }
}
