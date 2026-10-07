BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:Saved=@{APPDATA=$env:APPDATA;FFREPORT=$env:FFREPORT;WVC_SAFETY_FAULT=$env:WVC_SAFETY_FAULT;WVC_SAFETY_ID=$env:WVC_SAFETY_ID;WVC_SAFETY_BARRIER=$env:WVC_SAFETY_BARRIER}
    $env:APPDATA=Join-Path $TestDrive 'appdata'; $env:FFREPORT=$null
    $env:WVC_SAFETY_FAULT=$null; $env:WVC_SAFETY_ID=$null; $env:WVC_SAFETY_BARRIER=$null
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    $script:HostExe=(Get-Process -Id $PID).Path
    $script:Encoder=Join-Path $TestDrive 'encoder.exe'; $script:Probe=Join-Path $TestDrive 'probe.exe'
    $compile=Invoke-WvcTestProcess (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe') @(
        '-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'New-SafetyFixture.ps1'),'-Destination',$Encoder)
    if ($compile.ExitCode -ne 0) { throw $compile.StdErr }
    [IO.File]::Copy($Encoder,$Probe)
    $script:NativeEncoder=Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $script:NativeProbe=Get-Command ffprobe.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    function Get-SafetyHashes([string[]]$Paths) {
        @($Paths | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash }) -join '|'
    }
    function Get-SafetySnapshot([string]$Directory) {
        # NTFS can defer directory timestamp updates from fixture construction; file timestamps remain checked.
        @(Get-ChildItem -LiteralPath $Directory -Recurse -Force | Sort-Object FullName | ForEach-Object {
            $_.FullName+'|'+$_.Attributes+'|'+$(if($_ -is [IO.FileInfo]){$_.Length.ToString()+'|'+$_.LastWriteTimeUtc.Ticks+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash}else{'dir'})
        }) -join "`n"
    }
    function Remove-SafetyLongRoot($Owner) {
        # Extended spelling is developer-fixture cleanup only. Validate the final absolute target first.
        $temporary=[IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')+'\'
        $absolute=[IO.Path]::GetFullPath($Owner.Path)
        if (-not $absolute.StartsWith($temporary,[StringComparison]::OrdinalIgnoreCase) -or
            [IO.Path]::GetFileName($absolute) -cne ('wvc-tests-'+$Owner.Token) -or
            [IO.File]::ReadAllText((Join-Path $absolute '.wvc-owner')) -cne $Owner.Token) { throw 'Long fixture ownership mismatch; retain root.' }
        $prefix='\\?\'+$absolute; $pending=New-Object 'Collections.Generic.Stack[string]'; $pending.Push($prefix)
        $dirs=New-Object 'Collections.Generic.List[string]'; $files=New-Object 'Collections.Generic.List[string]'
        while($pending.Count) {
            $dir=$pending.Pop(); $dirs.Add($dir)
            if ([IO.File]::GetAttributes($dir) -band [IO.FileAttributes]::ReparsePoint) { throw 'Long fixture reparse point; retain root.' }
            foreach($path in [IO.Directory]::GetFileSystemEntries($dir)) {
                if (-not $path.StartsWith($prefix+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Long cleanup escaped owned root.' }
                $attributes=[IO.File]::GetAttributes($path)
                if ($attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Long fixture reparse point; retain root.' }
                if ($attributes -band [IO.FileAttributes]::Directory) {$pending.Push($path)} else {$files.Add($path)}
            }
        }
        foreach($file in $files) { [IO.File]::Delete($file) }
        for($i=$dirs.Count-1;$i -ge 0;$i--) { [IO.Directory]::Delete($dirs[$i],$false) }
    }
    function Start-SafetyWorker([string]$Scenario,[string]$Id,[string]$Policy='rename') {
        $tokens=@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Invoke-SafetyWorker.ps1'),
            '-Scenario',$Scenario,'-FixtureRoot',$Root,'-Encoder',$Encoder,'-Probe',$Probe,'-SourcePath',$Source,'-OutputRoot',$Output,'-WorkerId',$Id,'-Policy',$Policy)
        $start=New-Object Diagnostics.ProcessStartInfo
        $start.FileName=$HostExe; $start.Arguments=(@($tokens | ForEach-Object { ConvertTo-WvcNativeArgument $_ }) -join ' ')
        $start.UseShellExecute=$false; $start.CreateNoWindow=$true; $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
        $start.EnvironmentVariables.Remove('PSModulePath')
        $process=New-Object Diagnostics.Process; $process.StartInfo=$start
        $tracked=@{Process=$process;Started=$false;Out=$null;Err=$null}
        $script:Workers.Add($tracked)
        [void]$process.Start(); $tracked.Started=$true
        $tracked.Out=$process.StandardOutput.ReadToEndAsync(); $tracked.Err=$process.StandardError.ReadToEndAsync()
        $tracked
    }
    function Wait-SafetyReady([string]$Path) {
        $clock=[Diagnostics.Stopwatch]::StartNew()
        while (-not [IO.File]::Exists($Path)) {
            if ($clock.ElapsedMilliseconds -gt 15000) { throw 'Safety worker readiness timeout.' }
            Start-Sleep -Milliseconds 20
        }
    }
    function Invoke-SafetyDeny([string]$Directory,[Security.AccessControl.FileSystemRights]$Rights,[scriptblock]$Action) {
        $original=Get-Acl -LiteralPath $Directory; $acl=Get-Acl -LiteralPath $Directory
        $sid=[Security.Principal.WindowsIdentity]::GetCurrent().User
        $rule=New-Object Security.AccessControl.FileSystemAccessRule($sid,$Rights,[Security.AccessControl.AccessControlType]::Deny)
        [void]$acl.AddAccessRule($rule)
        try { Set-Acl -LiteralPath $Directory -AclObject $acl; & $Action } finally { Set-Acl -LiteralPath $Directory -AclObject $original }
    }
    $script:RealMove=${function:Move-OutputFileNoClobber}
    $script:RealManifestPublish=${function:Publish-BatchManifestFile}
}
AfterAll { foreach($name in $Saved.Keys) { Set-Item ('Env:'+$name) $Saved[$name] } }
Describe 'Safety stress with owned native and Windows fixtures [WVC-M4-03]' {
    BeforeEach {
        $script:CaseOwner=New-WvcTestRoot; $script:Root=$CaseOwner.Path
        $script:Output=Join-Path $Root 'output'; $script:Sources=Join-Path $Root 'sources'
        [void][IO.Directory]::CreateDirectory($Output); [void][IO.Directory]::CreateDirectory($Sources)
        $script:Source=Join-Path $Sources 'a.mov'; $script:Final=Join-Path $Output 'a.mp4'
        $script:Foreign=Join-Path $Output 'foreign.partial.mp4'
        foreach($path in @($Source,$Final,$Foreign)) { [IO.File]::WriteAllText($path,'protected sentinel '+[IO.Path]::GetFileName($path)) }
        $env:APPDATA=Join-Path $Root 'appdata'; $ConfigDir=Join-Path $env:APPDATA 'WinVidCompress'; $ConfigPath=Join-Path $ConfigDir 'config.json'
        $script:ConfigSnapshot=$null; $script:Cfg=[pscustomobject]@{OutputDir=$Output;Future='preserved'}
        Save-Config $Cfg
        $script:Protected=@($Source,$Final,$Foreign,$ConfigPath); $script:Hashes=Get-SafetyHashes $Protected
        $script:CollisionMode='rename'; $script:CancellationContext=$null
        $script:Workers=New-Object 'Collections.Generic.List[object]'
        $env:WVC_SAFETY_FAULT=$null; $env:WVC_SAFETY_ID=$null; $env:WVC_SAFETY_BARRIER=$null
        $script:HostMessages=New-Object 'Collections.Generic.List[string]'
        Mock Write-Host { $script:HostMessages.Add([string]$Object) }; Mock Write-Progress {}
    }
    AfterEach {
        foreach($worker in $Workers) {
            try {
                if ($worker.Started -and -not $worker.Process.HasExited) {
                    # Workers have no live native children once crash-ready; race failures use the owned tree.
                    & (Join-Path $env:SystemRoot 'System32/taskkill.exe') /PID $worker.Process.Id /T /F *> $null
                    if ($LASTEXITCODE -ne 0 -or -not $worker.Process.WaitForExit(5000)) {
                        $script:WvcProcessCleanupFailed=$true; throw 'Safety worker cleanup failed; retain fixtures.'
                    }
                }
                if ($worker.Started) {
                    $worker.Out.Wait(2000) | Should -BeTrue; $worker.Err.Wait(2000) | Should -BeTrue
                }
            } finally {
                if ($worker.Started) { $worker.Process.StandardOutput.Dispose(); $worker.Process.StandardError.Dispose() }
                $worker.Process.Dispose()
            }
        }
        (Get-SafetyHashes $Protected) | Should -BeExactly $Hashes
        Remove-WvcTestRoot $CaseOwner
    }
    It 'reports an unverified nested job once before encoding without changing any retained bytes [A03]' {
        $scene=Join-Path $Sources 'scene'; [void][IO.Directory]::CreateDirectory($scene)
        $nestedSource=Join-Path $scene 'clip.mov'; [IO.File]::WriteAllText($nestedSource,'nested source sentinel')
        [IO.File]::WriteAllText((Join-Path $scene 'other.mov'),'second nested source sentinel')
        $nestedOutput=Join-Path $Output 'scene'; [void][IO.Directory]::CreateDirectory($nestedOutput)
        $script:Stale=Join-Path $nestedOutput ('.wvc-job-'+[guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($stale)
        $partial=Join-Path $stale 'encode.partial.mp4'; [IO.File]::WriteAllText($partial,'unverified crash sentinel')
        $hash=(Get-FileHash -LiteralPath $partial).Hash
        $layout=Get-RelativeOutputLayout (Get-InputQueue @($Sources)) $Output
        $batch=Process-Paths @($Sources) $Encoder $Probe $Cfg -BatchLayout $layout
        $batch.ExitCode | Should -Be 0
        @($HostMessages | Where-Object { $_ -like 'Reserved WinVidCompress job directory present*' -and $_.Contains($stale) }).Count | Should -Be 1
        (Get-FileHash -LiteralPath $partial).Hash | Should -BeExactly $hash
        @(Get-ChildItem -LiteralPath $stale -Force).Count | Should -Be 1
    }
    It 'preserves all sentinels after native <Fault> failure with exact stage and stderr [A01]' -TestCases @(
        @{Fault='source-probe';Stage='Probe'},@{Fault='encode';Stage='Encode'},@{Fault='output-probe';Stage='Validation'}
    ) {
        param($Fault,$Stage)
        $env:WVC_SAFETY_FAULT=$Fault
        $job=Compress-One $Encoder $Probe $Source $Output 22
        $job.Outcome | Should -BeExactly 'Failed'; $job.Stage | Should -BeExactly $Stage
        @(Get-ChildItem -LiteralPath $Output -File -Filter '*.mp4').Count | Should -Be 2
        $native=switch($Fault) { 'source-probe' {$job.Diagnostics.Probe.Native}; 'encode' {$job.Diagnostics.Encode}; 'output-probe' {$job.Diagnostics.Validation.Inspection.Native} }
        $native.ExitCode | Should -Be 17; $native.StdErr | Should -Match ('injected '+$Fault+' diagnostic')
        if ($Fault -ne 'source-probe') {
            $record=Get-Content -LiteralPath (Join-Path $job.RetainedPath 'retained.json') -Raw | ConvertFrom-Json
            $record.Stage | Should -BeExactly $Stage; $record.State | Should -BeExactly 'RetainedUnverified'
            $record.JobId | Should -BeExactly $job.JobId; Test-Path -LiteralPath $job.TemporaryPath | Should -BeTrue
        }
    }
    It 'refuses real denied temporary-directory creation without publishing or deleting files [A01]' {
        Invoke-SafetyDeny $Output ([Security.AccessControl.FileSystemRights]::CreateDirectories) {
            $job=Compress-One $Encoder $Probe $Source $Output 22
            $job.Outcome | Should -BeExactly 'Failed'; $job.Stage | Should -BeExactly 'Allocate'
        }
        @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 2
    }
    It 'retains a validated partial on an actual sharing-denied promotion [A01]' {
        Mock Move-OutputFileNoClobber {
            $handle=[IO.File]::Open($Source,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
            try { & $script:RealMove $Source $Destination } finally { $handle.Dispose() }
        }
        $job=Compress-One $Encoder $Probe $Source $Output 22
        $job.Outcome | Should -BeExactly 'Failed'; $job.Stage | Should -BeExactly 'Promote'
        $job.Diagnostics.Validation.Succeeded | Should -BeTrue
        Test-Path -LiteralPath $job.TemporaryPath | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $Output 'a (compressed).mp4') | Should -BeFalse
    }
    It 'preserves the previous config on real <Boundary> failure [A01]' -TestCases @(@{Boundary='temp creation'},@{Boundary='replacement'}) {
        param($Boundary)
        $cfg=Load-Config; $cfg.Future='intentional new preference'
        if ($Boundary -eq 'temp creation') {
            Invoke-SafetyDeny $ConfigDir ([Security.AccessControl.FileSystemRights]::CreateFiles) {
                { Save-Config $cfg } | Should -Throw '*Cannot save config*'
            }
        } else {
            $handle=[IO.File]::Open($ConfigPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
            try { { Save-Config $cfg } | Should -Throw '*Cannot save config*' } finally { $handle.Dispose() }
            $backup=@(Get-ChildItem -LiteralPath $ConfigDir -Filter 'config.previous-*.json')
            $backup.Count | Should -Be 1; (Get-FileHash -LiteralPath $backup[0].FullName).Hash | Should -BeExactly (Get-FileHash -LiteralPath $ConfigPath).Hash
        }
        @(Get-ChildItem -LiteralPath $ConfigDir -Filter '*.tmp').Count | Should -Be 0
    }
    It 'preserves the previous manifest on real <Boundary> failure [A01]' -TestCases @(@{Boundary='temp creation'},@{Boundary='replacement'}) {
        param($Boundary)
        $manifest=Join-Path $Root 'batch.json'; $context=Open-BatchManifest $manifest $Output @($Source)
        try {
            $hash=(Get-FileHash -LiteralPath $manifest).Hash; $context.Manifest.Jobs[0].State='Running'
            if ($Boundary -eq 'temp creation') {
                Invoke-SafetyDeny $Root ([Security.AccessControl.FileSystemRights]::CreateFiles) { { Save-BatchManifest $context } | Should -Throw }
                @(Get-ChildItem -LiteralPath $Root -Filter 'batch.json.*.tmp').Count | Should -Be 0
            } else {
                $handle=[IO.File]::Open($manifest,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
                try { { Save-BatchManifest $context } | Should -Throw } finally { $handle.Dispose() }
                $temps=@(Get-ChildItem -LiteralPath $Root -Filter 'batch.json.*.tmp'); $temps.Count | Should -Be 1
                ((Get-Content -LiteralPath $temps[0].FullName -Raw | ConvertFrom-Json).Jobs[0].State) | Should -BeExactly 'Running'
            }
            (Get-FileHash -LiteralPath $manifest).Hash | Should -BeExactly $hash
        } finally { $context.Lock.Dispose() }
    }
    It 'preserves a published outcome and stops scheduling on a real checkpoint replacement failure [A01]' {
        $secondSource=Join-Path $Sources 'b.mov'; [IO.File]::WriteAllText($secondSource,'second source sentinel')
        $Protected+=@($secondSource); $Hashes=Get-SafetyHashes $Protected
        Mock Publish-BatchManifestFile {
            if ($Replacing) {
                $value=Get-Content -LiteralPath $TemporaryPath -Raw | ConvertFrom-Json
                if ($value.Jobs[0].State -eq 'Completed') {
                    $handle=[IO.File]::Open($DestinationPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
                    try { & $script:RealManifestPublish $TemporaryPath $DestinationPath $Replacing } finally { $handle.Dispose() }
                    return
                }
            }
            & $script:RealManifestPublish $TemporaryPath $DestinationPath $Replacing
        }
        $batch=Process-Paths @($Sources) $Encoder $Probe $Cfg -ManifestPath (Join-Path $Root 'batch.json')
        $batch.ExitCode | Should -Be 1; ($batch.Jobs.Outcome -join ',') | Should -BeExactly 'Completed,Unstarted'
        $batch.Jobs[0].AbortBatch | Should -BeTrue
        Test-Path -LiteralPath $batch.Jobs[0].OutputPath | Should -BeTrue
        ((Get-Content -LiteralPath (Join-Path $Root 'batch.json') -Raw | ConvertFrom-Json).Jobs.State -join ',') | Should -BeExactly 'Running,Unstarted'
    }
    It 'safely races shared config snapshots and final names with <Policy>, existing=<Existing>, round=<Round> [A01 A02]' -TestCases @(
        @{Policy='rename';Existing=$true;Round=1},@{Policy='rename';Existing=$true;Round=2},
        @{Policy='rename';Existing=$false;Round=1},@{Policy='skip';Existing=$false;Round=1}
    ) {
        param($Policy,$Existing,$Round)
        if (-not $Existing) { [IO.File]::Move($Final,($Final+'.sentinel')); $Protected=@($Source,($Final+'.sentinel'),$Foreign,$ConfigPath); $Hashes=Get-SafetyHashes $Protected }
        $oldConfigHash=(Get-FileHash -LiteralPath $ConfigPath).Hash
        # Successful saves are intentional; its exact previous bytes must survive in the backup.
        $Protected=@($Protected | Where-Object { $_ -ne $ConfigPath }); $Hashes=Get-SafetyHashes $Protected
        $one=Start-SafetyWorker 'Race' 'one' $Policy; $two=Start-SafetyWorker 'Race' 'two' $Policy
        foreach($worker in @($one,$two)) {
            $worker.Process.WaitForExit(20000) | Should -BeTrue
            $worker.Out.Wait(2000) | Should -BeTrue; $worker.Err.Wait(2000) | Should -BeTrue
            $worker.Process.ExitCode | Should -Be 0; $worker.Err.Result | Should -BeExactly ''
        }
        $reports=@('one','two') | ForEach-Object { Get-Content -LiteralPath (Join-Path $Root ($_+'.json')) -Raw | ConvertFrom-Json }
        @($reports | Where-Object ConfigSaved).Count | Should -Be 1
        @($reports | Where-Object { -not $_.ConfigSaved })[0].ConfigError | Should -Match 'config lock|changed since'
        $current=Load-Config; $current.Writer | Should -BeExactly @($reports | Where-Object ConfigSaved)[0].Worker
        $current.OutputDir | Should -BeExactly $Output; $current.Future | Should -BeExactly 'preserved'
        $backup=@(Get-ChildItem -LiteralPath $ConfigDir -Filter 'config.previous-*.json'); $backup.Count | Should -Be 1
        (Get-FileHash -LiteralPath $backup[0].FullName).Hash | Should -BeExactly $oldConfigHash
        @($reports.TemporaryPath | Select-Object -Unique).Count | Should -Be 2
        @($reports | Where-Object Outcome -eq 'Completed').Count | Should -Be $(if($Policy -eq 'rename'){2}else{1})
        @($reports | Where-Object Outcome -eq 'Skipped').Count | Should -Be $(if($Policy -eq 'skip'){1}else{0})
        $payloads=@($reports | ForEach-Object {
            $path=if($_.Outcome -eq 'Completed'){$_.OutputPath}else{$_.TemporaryPath}
            $bytes=[IO.File]::ReadAllBytes($path); [Text.Encoding]::UTF8.GetString($bytes,16,$bytes.Length-16)
        })
        $payloads | Should -Contain 'synthetic payload one'; $payloads | Should -Contain 'synthetic payload two'
    }
    It 'retains actual forced-host crash artifacts, reports without writes and resumes with fresh jobs [A01 A03]' {
        $worker=Start-SafetyWorker 'Crash' 'crash'
        $ready=Join-Path $Root 'crash-ready.json'; Wait-SafetyReady $ready
        $crash=Get-Content -LiteralPath $ready -Raw | ConvertFrom-Json
        { Load-Config } | Should -Throw '*config lock*'
        { Open-BatchManifest (Join-Path $Root 'batch.json') $Output @($Source) -Resume } | Should -Throw
        $worker.Process.Kill(); $worker.Process.WaitForExit(5000) | Should -BeTrue
        $worker.Out.Wait(2000) | Should -BeTrue; $worker.Err.Wait(2000) | Should -BeTrue
        $worker.Process.ExitCode | Should -Not -Be 0
        Test-Path -LiteralPath $crash.ReservationPath | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $crash.JobDirectory 'retained.json') | Should -BeFalse
        $uncheckpointed=Join-Path $Output 'a (compressed).mp4'
        $artifacts=@($crash.TemporaryPath,$uncheckpointed,(Join-Path $ConfigDir 'config.crash.tmp'),(Join-Path $Root 'batch.json.crash.tmp'))
        $script:CrashArtifactHashes=Get-SafetyHashes $artifacts
        # Foreign matching/nonmatching directory names confer no authority to recover or delete.
        $foreignJob=Join-Path $Output ('.wvc-job-'+[guid]::NewGuid().ToString('N')); [void][IO.Directory]::CreateDirectory($foreignJob)
        [IO.File]::WriteAllText((Join-Path $foreignJob 'retained.json'),'foreign provenance sentinel')
        $ordinary=Join-Path $Output '.wvc-job-not-a-guid'; [void][IO.Directory]::CreateDirectory($ordinary)
        [IO.File]::WriteAllText((Join-Path $ordinary 'ordinary.mov'),'ordinary source sentinel')
        $allBefore=Get-SafetySnapshot $Root
        $warnings=@(Get-OutputJobWarnings $Output); $warnings.Count | Should -Be 2
        ($warnings -join '|') | Should -Match ([regex]::Escape($crash.JobDirectory))
        $scan=Get-InputScan $Output; $scan.Files | Should -Not -Contain $crash.TemporaryPath
        $scan.Files | Should -Contain (Join-Path $ordinary 'ordinary.mov')
        $allAfter=Get-SafetySnapshot $Root
        $allAfter | Should -BeExactly $allBefore
        (Load-Config).OutputDir | Should -BeExactly $Output
        $retry=Process-Paths @($Source) $Encoder $Probe $Cfg -ManifestPath (Join-Path $Root 'batch.json') -Resume
        $retry.ExitCode | Should -Be 0; $retry.Counters.Done | Should -Be 1
        $retry.Jobs[0].JobId | Should -Not -BeExactly $crash.JobId
        $retry.Jobs[0].TemporaryPath | Should -Not -BeExactly $crash.TemporaryPath
        $retry.Jobs[0].OutputPath | Should -Not -BeExactly $uncheckpointed
        (Get-SafetyHashes $artifacts) | Should -BeExactly $CrashArtifactHashes
        [IO.File]::ReadAllText((Join-Path $foreignJob 'retained.json')) | Should -BeExactly 'foreign provenance sentinel'
    }
    It 'preserves real unavailable <Kind> output preferences without fallback [A04]' -TestCases @(@{Kind='drive'},@{Kind='loopback UNC share'}) {
        param($Kind)
        $destination=if($Kind -eq 'drive') {
            $used=@([IO.DriveInfo]::GetDrives() | ForEach-Object {$_.Name.Substring(0,1)})+@(Get-PSDrive | Select-Object -ExpandProperty Name)
            $letter=@('Z','Y','X','W','V','U' | Where-Object {$_ -notin $used})[0]
            if(-not $letter){throw 'No unused drive letter for fixture.'}; $letter+':\wvc-absent-'+[guid]::NewGuid().ToString('N')
        } else { '\\localhost\wvc-missing-'+[guid]::NewGuid().ToString('N')+'\output' }
        $cfg=[pscustomobject]@{OutputDir=$destination;Future='preserved'}
        [IO.File]::WriteAllText($ConfigPath,($cfg | ConvertTo-Json))
        $Hashes=Get-SafetyHashes $Protected
        { Load-Config } | Should -Throw '*unavailable or inaccessible*'
        @(Get-ChildItem -LiteralPath $ConfigDir -Filter 'config.*-*.json').Count | Should -Be 0
        Test-Path -LiteralPath $destination | Should -BeFalse
    }
    It 'observes a real <Length>-character local output path and preserves sentinels on support or refusal [A04]' -TestCases @(@{Length=240},@{Length=300}) {
        param($Length)
        if(-not $NativeEncoder -or -not $NativeProbe) { Set-ItResult -Skipped -Because 'Installed FFmpeg/FFprobe required for actual long-path media observation.'; return }
        $nativeSource=Join-Path $Sources 'long-source.mov'
        $created=Invoke-WvcTestProcess $NativeEncoder.Source @('-nostdin','-hide_banner','-loglevel','error','-n','-f','lavfi','-i','testsrc2=size=320x240:rate=24:duration=1','-an','-c:v','libx264','-pix_fmt','yuv420p',$nativeSource)
        $created.ExitCode | Should -Be 0
        $nativeHash=(Get-FileHash -LiteralPath $nativeSource).Hash
        $owner=New-WvcTestRoot; $completed=$false
        try {
            $long=$owner.Path
            while($long.Length -lt $Length) {
                $count=[Math]::Min(40,$Length-$long.Length-1)
                if($count -lt 1){throw 'Cannot construct exact long fixture length.'}
                $long+='\'+('d'*$count); [void][IO.Directory]::CreateDirectory(('\\?\'+$long))
            }
            $long.Length | Should -Be $Length
            $sentinel='\\?\'+$long+'\long-source.mp4'; [IO.File]::WriteAllText($sentinel,'long final sentinel')
            [IO.File]::WriteAllText($ConfigPath,([pscustomobject]@{OutputDir=$long;Future='preserved'} | ConvertTo-Json))
            $Hashes=Get-SafetyHashes $Protected
            $outcome=''; $stage=''; $reason=''
            try {
                $cfg=Load-Config
                $job=Compress-One $NativeEncoder.Source $NativeProbe.Source $nativeSource $cfg.OutputDir 22
                $outcome=$job.Outcome; $stage=$job.Stage; $reason=$job.Reason
                if ($job.Outcome -eq 'Completed') {
                    [IO.Path]::GetDirectoryName($job.OutputPath) | Should -BeExactly $long
                    [IO.File]::Exists(('\\?\'+$job.OutputPath)) | Should -BeTrue
                } else {
                    $job.Outcome | Should -BeExactly 'Failed'
                    [IO.File]::Exists(('\\?\'+$long+'\long-source (compressed).mp4')) | Should -BeFalse
                }
            } catch {
                if ($_.Exception.Message -notlike '*unavailable or inaccessible*') { throw }
                $outcome='Refused'; $stage='Config'; $reason=$_.Exception.Message
                [IO.File]::Exists(('\\?\'+$long+'\long-source (compressed).mp4')) | Should -BeFalse
            }
            [IO.File]::ReadAllText($sentinel) | Should -BeExactly 'long final sentinel'
            (Get-FileHash -LiteralPath $nativeSource).Hash | Should -BeExactly $nativeHash
            [Console]::WriteLine(('WVC-LONG-PATH host={0} rootLength={1} outcome={2} stage={3}' -f $PSVersionTable.PSVersion,$Length,$outcome,$stage))
            [Console]::WriteLine(('WVC-LONG-PATH reason='+$reason))
            $completed=$true
        } finally { if($completed) { Remove-SafetyLongRoot $owner } else { [Console]::WriteLine('Failed owned long-path fixture retained: '+$owner.Path) } }
    }
}
