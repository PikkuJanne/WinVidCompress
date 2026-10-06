BeforeAll {
    $script:PreviousAppData = $env:APPDATA
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
}
AfterAll { $env:APPDATA = $script:PreviousAppData }

Describe 'Job and batch result contract [WVC-M2-06]' {
    BeforeEach { Mock Write-Host {} }

    It 'assigns exact exit <Code> for <Case> [A01]' -TestCases @(
        @{Case='success';Outcomes=@('Completed');Errors=0;Startup=$false;Requested=$true;Code=0},
        @{Case='all valid skips';Outcomes=@('Skipped','Skipped');Errors=0;Startup=$false;Requested=$true;Code=0},
        @{Case='mixed failure';Outcomes=@('Completed','Failed','Skipped');Errors=0;Startup=$false;Requested=$true;Code=1},
        @{Case='scan error with success';Outcomes=@('Completed');Errors=1;Startup=$false;Requested=$true;Code=1},
        @{Case='startup failure';Outcomes=@();Errors=0;Startup=$true;Requested=$false;Code=2},
        @{Case='explicit empty batch';Outcomes=@();Errors=0;Startup=$false;Requested=$true;Code=2},
        @{Case='invalid batch';Outcomes=@();Errors=1;Startup=$false;Requested=$true;Code=2},
        @{Case='menu quit before batch';Outcomes=@();Errors=0;Startup=$false;Requested=$false;Code=0},
        @{Case='cancelled after failure';Outcomes=@('Failed','Cancelled','Unstarted');Errors=1;Startup=$false;Requested=$true;Code=3},
        @{Case='cancelled beats startup';Outcomes=@('Cancelled');Errors=0;Startup=$true;Requested=$true;Code=3},
        @{Case='unstarted after fatal';Outcomes=@('Failed','Unstarted');Errors=0;Startup=$false;Requested=$true;Code=1}
    ) {
        param($Case,$Outcomes,$Errors,$Startup,$Requested,$Code)
        $jobs = @($Outcomes | ForEach-Object { $job = New-JobResult 'synthetic.mov' 22; $job.Outcome=$_; $job })
        $scanErrors = @(1..$Errors | Where-Object { $Errors -gt 0 } | ForEach-Object {
            [pscustomobject]@{Kind='Unreadable';Path='synthetic';Message='scan diagnostic'} })
        $scans = @([pscustomobject]@{Succeeded=($Errors -eq 0);Errors=$scanErrors})
        $batch = Get-BatchResult $jobs $scans -Requested:$Requested -StartupFailed:$Startup
        $batch.ExitCode | Should -Be $Code
        $batch.Jobs.Count | Should -Be $Outcomes.Count
        $batch.Counters.Found | Should -Be $Outcomes.Count
        $batch.Counters.ScanErrors | Should -Be $Errors
        ($batch.Counters.Done+$batch.Counters.Skipped+$batch.Counters.Failed+$batch.Counters.Cancelled+$batch.Counters.Unstarted) |
            Should -Be $batch.Counters.Found
    }

    It 'keeps scan failures distinct from failed jobs [A02]' {
        $done=New-JobResult 'a.mov' 22; $done.Outcome='Completed'
        $failed=New-JobResult 'b.mov' 22; $failed.Outcome='Failed'
        $scans=@([pscustomobject]@{Succeeded=$true;Errors=@()},
            [pscustomobject]@{Succeeded=$false;Errors=@([pscustomobject]@{Kind='Denied'},[pscustomobject]@{Kind='Missing'})})
        $batch=Get-BatchResult @($done,$failed) $scans -Requested
        $batch.Counters.Found | Should -Be 2
        $batch.Counters.Done | Should -Be 1
        $batch.Counters.Failed | Should -Be 1
        $batch.Counters.Scanned | Should -Be 1
        $batch.ScanErrors.Count | Should -Be 2
        $batch.ExitCode | Should -Be 1
    }

    It 'does not prompt or start tools for an empty unattended request [A01 A03]' {
        Mock Ensure-Tool { throw 'tools must not start' }
        Mock Read-Host { throw 'must not prompt' }
        $run=Invoke-WinVidCompress -Unattended
        $run.ExitCode | Should -Be 2
        Should -Invoke Ensure-Tool -Times 0 -Exactly
        Should -Invoke Read-Host -Times 0 -Exactly
        Test-Path -LiteralPath $ConfigDir | Should -BeFalse
    }

    It 'returns startup failure without exiting its helper caller [A01 A03]' {
        Mock Ensure-Tool { throw 'synthetic unavailable dependency' }
        $run=Invoke-WinVidCompress -Paths @('synthetic.mov')
        $continued=$true
        $run.ExitCode | Should -Be 2
        $run.Reason | Should -Match 'unavailable dependency'
        $continued | Should -BeTrue
    }
}

Describe 'Record-driven frozen sequential queue [WVC-M2-06]' {
    BeforeEach {
        $script:Root=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Output=Join-Path $Root 'out'
        [void][IO.Directory]::CreateDirectory($Output)
        $script:Sources=@('a.mov','b.mov','c.mov' | ForEach-Object {
            $path=Join-Path $Root $_; [IO.File]::WriteAllText($path,'source sentinel'); $path })
        $script:Called=New-Object 'Collections.Generic.List[string]'
        Mock Write-Host {}
        Mock Compress-One {
            $script:Called.Add($inPath)
            $job=New-JobResult $inPath $crf; $job.Outcome='Completed'; $job
        }
    }

    It 'derives success counters from records rather than mutable references [A01 A02]' {
        $batch=Process-Paths @($Sources[2],$Root,$Sources[0]) 'unused' 'unused' ([pscustomobject]@{OutputDir=$Output})
        $batch.Jobs.Count | Should -Be 3
        $batch.Counters.Done | Should -Be 3
        $batch.Counters.Failed | Should -Be 0
        $batch.ExitCode | Should -Be 0
        ($Called -join '|') | Should -Be ($Sources -join '|')
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Done:    3' }
    }

    It 'records cancellation and unstarted remainder without scheduling another encoder [A01 A02]' {
        Mock Compress-One {
            $script:Called.Add($inPath)
            $job=New-JobResult $inPath $crf
            $job.Outcome=if ($script:Called.Count -eq 2) {'Cancelled'} else {'Completed'}
            $job
        }
        $batch=Process-Paths @($Root) 'unused' 'unused' ([pscustomobject]@{OutputDir=$Output})
        $Called.Count | Should -Be 2
        ($batch.Jobs.Outcome -join '|') | Should -Be 'Completed|Cancelled|Unstarted'
        $batch.Counters.Done | Should -Be 1
        $batch.Counters.Cancelled | Should -Be 1
        $batch.Counters.Unstarted | Should -Be 1
        $batch.ExitCode | Should -Be 3
    }

    It 'rejects a missing job record instead of inventing success [A01 A02]' {
        Mock Compress-One {}
        $batch=Process-Paths @($Sources[0]) 'unused' 'unused' ([pscustomobject]@{OutputDir=$Output})
        $batch.Counters.Failed | Should -Be 1
        $batch.ExitCode | Should -Be 1
        $batch.Jobs[0].Reason | Should -Match 'record'
    }

    It 'stops scheduling when returned records have <Defect> [A01 A02]' -TestCases @(
        @{Defect='wrong source'}, @{Defect='multiple records'}, @{Defect='unknown outcome'}
    ) {
        param($Defect)
        Mock Compress-One {
            $script:Called.Add($inPath)
            $job=New-JobResult $inPath $crf; $job.Outcome='Completed'
            switch ($Defect) {
                'wrong source' { $job.SourcePath='different.mov'; $job }
                'multiple records' { $job; $job }
                'unknown outcome' { $job.Outcome='Unknown'; $job }
            }
        }
        $batch=Process-Paths @($Root) 'unused' 'unused' ([pscustomobject]@{OutputDir=$Output})
        $Called.Count | Should -Be 1
        ($batch.Jobs.Outcome -join '|') | Should -BeExactly 'Failed|Unstarted|Unstarted'
        $batch.ExitCode | Should -Be 1
    }

    It 'preserves earlier menu completion when the next destination recheck fails [A02]' {
        $script:Checks=0
        Mock Get-OutputEnvironment { $script:Checks++; if ($script:Checks -eq 2) { throw 'destination disappeared' } }
        $choices=New-Object 'Collections.Generic.Queue[string]'
        foreach ($choice in @('3','3','4')) { $choices.Enqueue($choice) }
        Mock Read-Host { $choices.Dequeue() }
        Mock Prompt-Path { $script:Root }
        $run=Run-TUI 'unused' 'unused' ([pscustomobject]@{OutputDir=$Output})
        $run.ExitCode | Should -Be 2
        $run.Counters.Found | Should -Be 3
        $run.Counters.Done | Should -Be 3
        $run.Jobs.Count | Should -Be 3
        $Called.Count | Should -Be 3
        $choices.Count | Should -Be 0
    }

    It 'represents cancellation before queueing without inventing a source job [A01 A02]' {
        Mock Get-OutputEnvironment { throw (New-Object OperationCanceledException 'cancel before queue') }
        $batch=Process-Paths @($Root) 'unused' 'unused' ([pscustomobject]@{OutputDir=$Output})
        $batch.ExitCode | Should -Be 3
        $batch.Cancelled | Should -BeTrue
        $batch.Counters.Found | Should -Be 0
        $batch.Jobs.Count | Should -Be 0
        $Called.Count | Should -Be 0
    }

    It 'retains earlier completed jobs when the next menu prompt <Fault> [A01 A02]' -TestCases @(
        @{Fault='is cancelled';Code=3}, @{Fault='fails';Code=2}
    ) {
        param($Fault,$Code)
        $script:Prompts=0
        Mock Read-Host {
            $script:Prompts++
            if ($script:Prompts -eq 1) { return '3' }
            if ($Fault -eq 'is cancelled') { throw (New-Object System.OperationCanceledException 'later prompt interrupted') }
            throw 'later prompt failed'
        }
        Mock Prompt-Path { $script:Root }
        $run=Run-TUI 'unused' 'unused' ([pscustomobject]@{OutputDir=$Output})
        $run.ExitCode | Should -Be $Code
        $run.Counters.Done | Should -Be 3
        $run.Jobs.Count | Should -Be 3
        $run.Batches.Count | Should -Be 2
        $run.Batches[1].Reason | Should -Match 'later prompt'
        $Called.Count | Should -Be 3
    }

    It 'returns an explicit empty batch as code2 [A01]' {
        $batch=Process-Paths @() 'unused' 'unused' ([pscustomobject]@{OutputDir=$Output})
        $batch.ExitCode | Should -Be 2
        $batch.Jobs.Count | Should -Be 0
        $Called.Count | Should -Be 0
    }

    It 'preserves completed records when summary reporting <Fault> [A01 A02]' -TestCases @(
        @{Fault='fails';Code=0}, @{Fault='is cancelled';Code=3}
    ) {
        param($Fault,$Code)
        Mock Write-Host {
            if ($Fault -eq 'is cancelled') { throw (New-Object OperationCanceledException 'summary cancellation') }
            throw 'summary display fault'
        } -ParameterFilter { $Object -like '*========== Summary*' }
        $batch=Process-Paths @($Root) 'unused' 'unused' ([pscustomobject]@{OutputDir=$Output})
        $batch.ExitCode | Should -Be $Code
        $batch.Counters.Done | Should -Be 3
        $batch.Counters.Found | Should -Be 3
        $batch.Jobs.Count | Should -Be 3
        $batch.Warnings.Count | Should -Be 1
    }
}

Describe 'Published job record and diagnostic provenance [WVC-M2-06]' {
    BeforeEach {
        $script:Root=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Output=Join-Path $Root 'out'
        [void][IO.Directory]::CreateDirectory($Output)
        $script:Source=Join-Path $Root 'Band 29092025.mov'
        [IO.File]::WriteAllText($Source,'source sentinel')
        $script:Final=Join-Path $Output 'Band 29092025.mp4'
        $script:CollisionMode='rename'
        Mock Write-Host {}
        Mock Get-MediaInspection {
            ConvertFrom-ProbeJson '{"streams":[{"index":3,"codec_type":"video","codec_name":"h264","width":320,"height":240,"duration":"1"}]}'
        }
        Mock Get-OutputValidation { [pscustomobject]@{Succeeded=$true;Inspection=$null;Warnings=@('synthetic validation warning')} }
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'synthetic encoded payload')
            [pscustomobject]@{Succeeded=$true;StdOutTruncated=$false;StdErrTruncated=$false;StdErr='native diagnostic';ExitCode=0}
        }
    }

    It 'returns one completed record only after validated publication [A02]' {
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.SchemaVersion | Should -Be 1
        $job.JobId | Should -Match '^[a-f0-9]{32}$'
        $job.SourcePath | Should -BeExactly $Source
        $job.OutputPath | Should -BeExactly $Final
        $job.Outcome | Should -BeExactly 'Completed'
        $job.Stage | Should -BeExactly 'Complete'
        $job.InputBytes | Should -Be 15
        $job.OutputBytes | Should -Be 25
        $job.SizeChangeBytes | Should -Be 10
        $job.ElapsedSeconds | Should -BeGreaterOrEqual 0
        $job.SelectedStreams.Video | Should -Be 3
        $job.SelectedStreams.Audio | Should -BeNullOrEmpty
        $job.Settings.CRF | Should -Be 22
        $job.Settings.Preset | Should -BeExactly 'veryfast'
        $job.Diagnostics.Encode.StdErr | Should -BeExactly 'native diagnostic'
        $job.Diagnostics.Validation.Warnings | Should -Contain 'synthetic validation warning'
        $job.LogPath | Should -BeNullOrEmpty
        [IO.File]::ReadAllText($Source) | Should -BeExactly 'source sentinel'
    }

    It 'returns valid skip without claiming the existing output bytes as produced [A01 A02]' {
        [IO.File]::WriteAllText($Final,'existing final sentinel')
        $CollisionMode='skip'
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.Outcome | Should -BeExactly 'Skipped'
        $job.OutputBytes | Should -BeNullOrEmpty
        $job.SelectedStreams | Should -BeNullOrEmpty
        Should -Invoke Invoke-EncodeProcess -Times 0 -Exactly
        [IO.File]::ReadAllText($Final) | Should -BeExactly 'existing final sentinel'
    }

    It 'returns validation failure and retained provenance without a final [A02]' {
        Mock Get-OutputValidation { [pscustomobject]@{Succeeded=$false;Inspection=$null;Warnings=@();FailureKind='Truncated';Reason='too short'} }
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.Outcome | Should -BeExactly 'Failed' -Because $job.Reason
        $job.Stage | Should -BeExactly 'Validation'
        $job.Reason | Should -Match 'too short'
        $job.OutputPath | Should -BeNullOrEmpty
        $job.RetainedPath | Should -Not -BeNullOrEmpty
        Test-Path -LiteralPath $job.RetainedPath | Should -BeTrue
        Test-Path -LiteralPath $Final | Should -BeFalse
    }

    It 'returns explicit cancellation and retains partial output [A01 A02]' {
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'cancelled partial')
            throw (New-Object OperationCanceledException 'synthetic explicit cancellation')
        }
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.Outcome | Should -BeExactly 'Cancelled'
        $job.Stage | Should -BeExactly 'Interrupted'
        Test-Path -LiteralPath $job.RetainedPath | Should -BeTrue
        Test-Path -LiteralPath $Final | Should -BeFalse
    }

    It 'attaches the failed record to a fatal owned-encoder exception [A02]' {
        Mock Invoke-EncodeProcess {
            $abort=New-Object InvalidOperationException 'owned encoder termination failed'
            $abort.Data['WvcAbortBatch']=$true
            throw $abort
        }
        try { Compress-One 'unused' 'unused' $Source $Output 22; throw 'expected fatal exception' }
        catch {
            $_.Exception.Message | Should -Match 'termination failed'
            $job=$_.Exception.Data['WvcJobResult']
            $job.Outcome | Should -BeExactly 'Failed'
            $job.AbortBatch | Should -BeTrue
            $job.Stage | Should -BeExactly 'Encode'
            Test-Path -LiteralPath $job.RetainedPath | Should -BeTrue
        }
    }

    It 'preserves completion if console reporting fails after publication [A02]' {
        Mock Write-Host { if ($Object -eq 'Done.') { throw 'display fault' } }
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.Outcome | Should -BeExactly 'Completed' -Because $job.Reason
        Test-Path -LiteralPath $job.OutputPath | Should -BeTrue
    }

    It 'stops before encoding when input accounting is cancelled [A01 A02]' {
        Mock Get-Item { throw (New-Object OperationCanceledException 'accounting cancellation') } -ParameterFilter { $LiteralPath -eq $Source }
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.Outcome | Should -BeExactly 'Cancelled'
        Should -Invoke Invoke-EncodeProcess -Times 0 -Exactly
        Test-Path -LiteralPath $Final | Should -BeFalse
    }

    It 'preserves publication when output accounting is cancelled [A01 A02]' {
        Mock Get-Item { throw (New-Object OperationCanceledException 'accounting cancellation') } -ParameterFilter { $LiteralPath -eq $Final }
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.Outcome | Should -BeExactly 'Completed'
        $job.CancellationRequested | Should -BeTrue
        $job.OutputBytes | Should -BeNullOrEmpty
        Test-Path -LiteralPath $Final | Should -BeTrue
    }

    It 'preserves <Outcome> when reporting observes explicit cancellation [A01 A02]' -TestCases @(
        @{Outcome='Completed';ReportPattern='Done.'}, @{Outcome='Skipped';ReportPattern='Skipping*'}
    ) {
        param($Outcome,$ReportPattern)
        if ($Outcome -eq 'Skipped') { [IO.File]::WriteAllText($Final,'existing sentinel'); $CollisionMode='skip' }
        Mock Write-Host { throw (New-Object OperationCanceledException 'reporting cancellation') } -ParameterFilter { $Object -like $ReportPattern }
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.Outcome | Should -BeExactly $Outcome -Because $job.Reason
        $job.CancellationRequested | Should -BeTrue
        $batch=Get-BatchResult @($job) @() -Requested
        $batch.ExitCode | Should -Be 3
        $batch.Counters.Found | Should -Be 1
        $batch.Counters.Cancelled | Should -Be 0
        if ($Outcome -eq 'Completed') { Test-Path -LiteralPath $job.OutputPath | Should -BeTrue; $batch.Counters.Done | Should -Be 1 }
        else { [IO.File]::ReadAllText($Final) | Should -BeExactly 'existing sentinel'; $batch.Counters.Skipped | Should -Be 1 }
    }
}
