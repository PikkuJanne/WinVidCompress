BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:OriginalEnvironment=@{APPDATA=$env:APPDATA;WVC_CANCEL_MARKER=$env:WVC_CANCEL_MARKER;WVC_CANCEL_MODE=$env:WVC_CANCEL_MODE}
    $env:APPDATA=Join-Path $TestDrive 'appdata'
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    $script:RealTestCancellation=${function:Test-WvcCancellation}
    $script:RealGetQueue=${function:Get-InputQueue}
    $script:Encoder=Join-Path $TestDrive 'ffmpeg.exe'
    $compile=Invoke-WvcTestProcess (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe') @(
        '-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'New-CancelFixture.ps1'),'-Destination',$Encoder)
    if ($compile.ExitCode -ne 0) { throw $compile.StdErr }
    $script:Probe=Join-Path $TestDrive 'ffprobe.exe'
    Copy-Item -LiteralPath $Encoder -Destination $Probe
}
AfterAll { foreach ($name in $OriginalEnvironment.Keys) { Set-Item ('Env:'+ $name) $OriginalEnvironment[$name] } }

Describe 'Controlled native cancellation [WVC-M3-06]' {
    BeforeEach {
        $script:CaseRoot=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Output=Join-Path $CaseRoot 'output'
        $script:Sources=Join-Path $CaseRoot 'sources'
        [void][IO.Directory]::CreateDirectory($Output)
        [void][IO.Directory]::CreateDirectory($Sources)
        $script:Source=Join-Path $Sources 'a.mov'; [IO.File]::WriteAllText($Source,'source sentinel')
        $script:Final=Join-Path $Output 'a.mp4'; [IO.File]::WriteAllText($Final,'existing final sentinel')
        $script:SourceHash=(Get-FileHash -LiteralPath $Source).Hash
        $script:FinalHash=(Get-FileHash -LiteralPath $Final).Hash
        $env:WVC_CANCEL_MARKER=Join-Path $CaseRoot 'started.txt'; $env:WVC_CANCEL_MODE='Graceful'
        $script:CancellationContext=[pscustomobject]@{Requested=$false;ConsoleEnabled=$false;PreviousControlC=$false}
        Mock Write-Host {}; Mock Write-Progress {}
        Mock Test-WvcCancellation {
            if (Test-Path -LiteralPath $env:WVC_CANCEL_MARKER) { $script:CancellationContext.Requested=$true }
            & $script:RealTestCancellation
        }
    }
    AfterEach {
        $script:CancellationContext=$null
        if (Test-Path -LiteralPath $env:WVC_CANCEL_MARKER) {
            foreach ($childId in @(Get-Content -LiteralPath $env:WVC_CANCEL_MARKER)) {
                $child=Get-Process -Id ([int]$childId) -ErrorAction SilentlyContinue
                if ($null -ne $child) {
                    try {
                        if (-not [StringComparer]::OrdinalIgnoreCase.Equals($child.Path,$Encoder)) { throw 'Fixture child identity mismatch.' }
                        $child.Kill(); if (-not $child.WaitForExit(2000)) { throw 'Fixture child cleanup failed.' }
                    } finally { $child.Dispose() }
                }
            }
        }
    }

    It 'marks native exit0 as cancelled after private graceful q, preserving stderr [A03 A04]' {
        $result=Invoke-EncodeProcess $Encoder @('-stdin') -GracefulQuit
        $result.Started | Should -BeTrue
        $result.Succeeded | Should -BeFalse
        $result.ExitCode | Should -Be 0
        $result.FailureKind | Should -BeExactly 'Cancelled'
        $result.Cancellation.Requested | Should -BeTrue
        $result.Cancellation.ExitedDuringGrace | Should -BeTrue
        $result.Cancellation.Forced | Should -BeFalse
        $result.StdErr | Should -Match 'private graceful q received'
        (Get-LogNative $result).Cancellation.ExitedDuringGrace | Should -BeTrue
        $result.ElapsedSeconds | Should -BeLessThan 5
    }

    It 'forces only the owned child when it ignores q [A02 A03]' {
        $env:WVC_CANCEL_MODE='Ignore'
        $result=Invoke-EncodeProcess $Encoder @('-stdin') -GracefulQuit -GraceMilliseconds 200
        $result.FailureKind | Should -BeExactly 'Cancelled'
        $result.Cancellation.GracefulAttempted | Should -BeTrue
        $result.Cancellation.ExitedDuringGrace | Should -BeFalse
        $result.Cancellation.Forced | Should -BeTrue
        $result.ElapsedSeconds | Should -BeLessThan 5
        $childId=[int](Get-Content -LiteralPath $env:WVC_CANCEL_MARKER)
        Get-Process -Id $childId -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }

    It 'does not start an encoder after a prior request [A03]' {
        $script:CancellationContext.Requested=$true
        $result=Invoke-EncodeProcess $Encoder @('-stdin') -GracefulQuit
        $result.Started | Should -BeFalse
        $result.FailureKind | Should -BeExactly 'Cancelled'
        Test-Path -LiteralPath $env:WVC_CANCEL_MARKER | Should -BeFalse
    }

    It 'keeps the cancelled owned partial unverified and source/final hashes intact [A03]' {
        $job=Compress-One $Encoder $Probe $Source $Output 22
        $job.Outcome | Should -BeExactly 'Cancelled'
        $job.CancellationRequested | Should -BeTrue
        $job.Diagnostics.Encode.ExitCode | Should -Be 0
        $job.Diagnostics.Encode.Cancellation.ExitedDuringGrace | Should -BeTrue
        Test-Path -LiteralPath $job.TemporaryPath | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $job.RetainedPath 'active.owner') | Should -BeFalse
        $retained=Get-Content -LiteralPath (Join-Path $job.RetainedPath 'retained.json') -Raw | ConvertFrom-Json
        $retained.Stage | Should -BeExactly 'Interrupted'
        $retained.Reason | Should -Match 'cancelled'
        @(Get-ChildItem -LiteralPath $Output -Filter '*.mp4').Count | Should -Be 1
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
        (Get-FileHash -LiteralPath $Final).Hash | Should -BeExactly $FinalHash
        Should -Invoke Write-Progress -Times 0 -ParameterFilter { $PercentComplete -eq 100 -and -not $Completed }
    }

    It 'keeps an unrelated actual FFmpeg alive during forced cancellation [A02]' {
        $ffmpeg=Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue
        if (-not $ffmpeg) { Set-ItResult -Skipped -Because 'Installed FFmpeg unavailable.'; return }
        $start=New-Object Diagnostics.ProcessStartInfo
        $start.FileName=$ffmpeg.Source
        $start.Arguments='-hide_banner -nostdin -re -f lavfi -i testsrc2=size=64x64:rate=10:duration=30 -f null NUL'
        $start.UseShellExecute=$false; $start.CreateNoWindow=$true
        $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
        $other=New-Object Diagnostics.Process; $other.StartInfo=$start
        try {
            [void]$other.Start(); $identity=$other.StartTime
            $stdout=$other.StandardOutput.ReadToEndAsync(); $stderr=$other.StandardError.ReadToEndAsync()
            $env:WVC_CANCEL_MODE='Ignore'
            $result=Invoke-EncodeProcess $Encoder @('-stdin') -GracefulQuit -GraceMilliseconds 200
            $result.Cancellation.Forced | Should -BeTrue
            $other.HasExited | Should -BeFalse
            $other.StartTime | Should -Be $identity
        } finally {
            if (-not $other.HasExited) { $other.Kill(); if (-not $other.WaitForExit(2000)) { throw 'Unrelated fixture cleanup failed.' } }
            $other.Dispose()
        }
    }

    It 'gracefully stops the installed FFmpeg through its private pipe [A02 A04]' {
        $ffmpeg=Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue
        if (-not $ffmpeg) { Set-ItResult -Skipped -Because 'Installed FFmpeg unavailable.'; return }
        Mock Test-WvcCancellation { & $script:RealTestCancellation }
        $progress=New-EncodeProgress 30
        Mock Write-JobProgress { if ($Progress.Clock.Elapsed.TotalSeconds -gt 0.7) { $script:CancellationContext.Requested=$true } }
        $result=Invoke-EncodeProcess $ffmpeg.Source @('-hide_banner','-stdin','-nostats','-progress','pipe:1',
            '-re','-f','lavfi','-i','testsrc2=size=64x64:rate=10:duration=30','-f','null','NUL') -ProgressContext $progress -GracefulQuit
        $result.StdErr | Should -Match '\[q\] command received'
        $result.FailureKind | Should -BeExactly 'Cancelled'
        $result.Cancellation.ExitedDuringGrace | Should -BeTrue
        $result.Cancellation.Forced | Should -BeFalse
        $result.ElapsedSeconds | Should -BeLessThan 5
    }

    It 'returns process code3 with one Cancelled and one Unstarted, matching logs and summary [A03 A04]' {
        [IO.File]::WriteAllText((Join-Path $Sources 'b.mov'),'second source sentinel')
        $appdata=Join-Path $CaseRoot 'appdata'; $config=Join-Path $appdata 'WinVidCompress'
        [void][IO.Directory]::CreateDirectory($config)
        Write-WvcTestJson (Join-Path $config 'config.json') ([pscustomobject]@{OutputDir=$Output})
        $worker=Invoke-WvcTestProcess (Get-Process -Id $PID).Path @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass',
            '-File',(Join-Path $PSScriptRoot 'Invoke-CancelWorker.ps1'),'-Application',(Join-Path $RepoRoot 'WinVidCompress.ps1'),
            '-SourceRoot',$Sources,'-Marker',$env:WVC_CANCEL_MARKER) -Environment @{
                APPDATA=$appdata;PATH=($TestDrive+';'+$env:SystemRoot+'/System32');FFREPORT='';
                WVC_CANCEL_MARKER=$env:WVC_CANCEL_MARKER;WVC_CANCEL_MODE='Graceful'}
        $worker.ExitCode | Should -Be 3
        $worker.StdOut | Should -Match 'Cancelled: 1'
        $worker.StdOut | Should -Match 'Unstarted: 1'
        @(Get-Content -LiteralPath $env:WVC_CANCEL_MARKER).Count | Should -Be 1
        $log=@(Get-ChildItem -LiteralPath (Join-Path $config 'logs') -Filter 'results.jsonl' -Recurse)[0]
        $records=@(Get-Content -LiteralPath $log.FullName | ForEach-Object { $_ | ConvertFrom-Json })
        $jobs=@($records | Where-Object Kind -eq 'Job')
        ($jobs.Outcome -join ',') | Should -BeExactly 'Cancelled,Unstarted'
        $jobs[0].CancellationRequested | Should -BeTrue
        $jobs[0].Encode.Cancellation.ExitedDuringGrace | Should -BeTrue
        $result=@($records | Where-Object Kind -eq 'Result')[0]
        $result.ExitCode | Should -Be 3
        $result.Cancelled | Should -BeTrue
        $result.Counters.Found | Should -Be 2
        $result.Counters.Cancelled | Should -Be 1
        $result.Counters.Unstarted | Should -Be 1
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
        (Get-FileHash -LiteralPath $Final).Hash | Should -BeExactly $FinalHash
        @(Get-ChildItem -LiteralPath $Output -Filter '*.mp4').Count | Should -Be 1
    }

    It 'cancels after native success before validation without promoting [A03]' {
        Mock Test-WvcCancellation { & $script:RealTestCancellation }
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'unfinished payload')
            $script:CancellationContext.Requested=$true
            [pscustomobject]@{Succeeded=$true;Started=$true;StdOutTruncated=$false;StdErrTruncated=$false}
        }
        Mock Get-OutputValidation { throw 'Validation must not start.' }
        $job=Compress-One $Encoder $Probe $Source $Output 22
        $job.Outcome | Should -BeExactly 'Cancelled'
        Should -Invoke Get-OutputValidation -Times 0 -Exactly
        @(Get-ChildItem -LiteralPath $Output -Filter '*.mp4').Count | Should -Be 1
    }

    It 'checks cancellation again after validation and immediately before publication [A03]' {
        Mock Test-WvcCancellation { & $script:RealTestCancellation }
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'unfinished payload')
            [pscustomobject]@{Succeeded=$true;Started=$true;StdOutTruncated=$false;StdErrTruncated=$false}
        }
        Mock Get-OutputValidation { [pscustomobject]@{Succeeded=$true;Inspection=$null;Warnings=@()} }
        Mock Write-JobProgress { if ($Progress.State -eq 'Publishing') { $script:CancellationContext.Requested=$true } }
        Mock Publish-OutputJob { throw 'Publication must not start.' }
        $job=Compress-One $Encoder $Probe $Source $Output 22
        $job.Outcome | Should -BeExactly 'Cancelled'
        Should -Invoke Publish-OutputJob -Times 0 -Exactly
        @(Get-ChildItem -LiteralPath $Output -Filter '*.mp4').Count | Should -Be 1
    }

    It 'preserves a published result while cancelling the next job [A03 A04]' {
        Mock Test-WvcCancellation { & $script:RealTestCancellation }
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'synthetic validated payload')
            [pscustomobject]@{Succeeded=$true;Started=$true;StdOutTruncated=$false;StdErrTruncated=$false}
        }
        Mock Get-OutputValidation { [pscustomobject]@{Succeeded=$true;Inspection=$null;Warnings=@()} }
        Mock Write-JobProgress { if ($Progress.State -eq 'Completed') { $script:CancellationContext.Requested=$true } }
        [IO.File]::WriteAllText((Join-Path $Sources 'b.mov'),'second source sentinel')
        $batch=Process-Paths @($Sources) $Encoder $Probe ([pscustomobject]@{OutputDir=$Output})
        $batch.ExitCode | Should -Be 3
        ($batch.Jobs.Outcome -join ',') | Should -BeExactly 'Completed,Unstarted'
        $batch.Jobs[0].CancellationRequested | Should -BeTrue
        [IO.File]::ReadAllText($batch.Jobs[0].OutputPath) | Should -BeExactly 'synthetic validated payload'
        (Get-FileHash -LiteralPath $Final).Hash | Should -BeExactly $FinalHash
    }

    It 'preserves a valid skip and stops later scheduling [A03 A04]' {
        Mock Test-WvcCancellation { & $script:RealTestCancellation }
        $CollisionMode='skip'
        Mock Invoke-EncodeProcess { throw 'A skip must not start an encoder.' }
        Mock Write-Host { if ($Object -like 'Skipping (exists):*') { $script:CancellationContext.Requested=$true } }
        [IO.File]::WriteAllText((Join-Path $Sources 'b.mov'),'second source sentinel')
        try {
            $batch=Process-Paths @($Sources) $Encoder $Probe ([pscustomobject]@{OutputDir=$Output})
            $batch.ExitCode | Should -Be 3
            ($batch.Jobs.Outcome -join ',') | Should -BeExactly 'Skipped,Unstarted'
            $batch.Jobs[0].CancellationRequested | Should -BeTrue
            Test-Path -LiteralPath $env:WVC_CANCEL_MARKER | Should -BeFalse
        } finally { $script:CollisionMode='rename' }
    }

    It 'marks a request before first dispatch without fabricating an active job [A04]' {
        Mock Test-WvcCancellation { & $script:RealTestCancellation }
        Mock Get-InputQueue {
            $queue=& $script:RealGetQueue $paths
            $script:CancellationContext.Requested=$true
            return $queue
        }
        Mock Compress-One { throw 'Must not dispatch.' }
        $batch=Process-Paths @($Sources) $Encoder $Probe ([pscustomobject]@{OutputDir=$Output})
        $batch.ExitCode | Should -Be 3
        $batch.Counters.Found | Should -Be 1
        $batch.Counters.Unstarted | Should -Be 1
        $batch.Counters.Cancelled | Should -Be 0
        Should -Invoke Compress-One -Times 0 -Exactly
    }

    It 'restores its context after failure and permits the next batch [A04]' {
        Mock Test-WvcCancellation { & $script:RealTestCancellation }
        $script:CancellationContext=$null
        Mock New-WvcCancellationContext { [pscustomobject]@{Requested=$true;ConsoleEnabled=$false;PreviousControlC=$false} }
        $first=Process-Paths @($Sources) $Encoder $Probe ([pscustomobject]@{OutputDir=$Output})
        $first.ExitCode | Should -Be 3
        $script:CancellationContext | Should -BeNullOrEmpty
        Mock New-WvcCancellationContext { [pscustomobject]@{Requested=$false;ConsoleEnabled=$false;PreviousControlC=$false} }
        Mock Compress-One { $job=New-JobResult $inPath $crf; $job.Outcome='Completed'; $job }
        $second=Process-Paths @($Sources) $Encoder $Probe ([pscustomobject]@{OutputDir=$Output})
        $second.ExitCode | Should -Be 0
        $script:CancellationContext | Should -BeNullOrEmpty
    }

    It 'records cancellation during summary without relabelling completed jobs [A04]' {
        Mock Test-WvcCancellation { & $script:RealTestCancellation }
        Mock Compress-One { $job=New-JobResult $inPath $crf; $job.Outcome='Completed'; $job }
        Mock Write-Host { if ($Object -like 'Results vary;*') { $script:CancellationContext.Requested=$true } }
        $batch=Process-Paths @($Sources) $Encoder $Probe ([pscustomobject]@{OutputDir=$Output})
        $batch.ExitCode | Should -Be 3
        $batch.Cancelled | Should -BeTrue
        $batch.Jobs[0].Outcome | Should -BeExactly 'Completed'
    }

    It 'stops scheduling and retains provenance when cancellation cannot stop its child [A03 A04]' {
        Mock Test-WvcCancellation { & $script:RealTestCancellation }
        Mock Invoke-EncodeProcess {
            $failure=New-Object InvalidOperationException 'Injected owned termination failure'
            $failure.Data['WvcAbortBatch']=$true; $failure.Data['WvcCancellationRequested']=$true
            throw $failure
        }
        [IO.File]::WriteAllText((Join-Path $Sources 'b.mov'),'second source sentinel')
        $batch=Process-Paths @($Sources) $Encoder $Probe ([pscustomobject]@{OutputDir=$Output})
        $batch.ExitCode | Should -Be 3
        ($batch.Jobs.Outcome -join ',') | Should -BeExactly 'Failed,Unstarted'
        $batch.Jobs[0].AbortBatch | Should -BeTrue
        $batch.Jobs[0].CancellationRequested | Should -BeTrue
        Test-Path -LiteralPath (Join-Path $batch.Jobs[0].RetainedPath 'retained.json') | Should -BeTrue
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
        (Get-FileHash -LiteralPath $Final).Hash | Should -BeExactly $FinalHash
    }

    It 'keeps cancellation precedence when requested during failing batch setup [A04]' {
        Mock Test-WvcCancellation { & $script:RealTestCancellation }
        Mock Get-OutputEnvironment { $script:CancellationContext.Requested=$true; throw 'Injected output setup failure' }
        $batch=Process-Paths @($Sources) $Encoder $Probe ([pscustomobject]@{OutputDir=$Output})
        $batch.ExitCode | Should -Be 3
        $batch.Cancelled | Should -BeTrue
        $batch.Jobs.Count | Should -Be 0
        Test-Path -LiteralPath $env:WVC_CANCEL_MARKER | Should -BeFalse
    }
}
