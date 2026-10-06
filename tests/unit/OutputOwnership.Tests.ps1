BeforeAll {
    $script:OriginalAppData = $env:APPDATA
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
    $script:RealNewOutputJob = ${function:New-OutputJob}
}
AfterAll { $env:APPDATA = $script:OriginalAppData }

Describe 'Owned output publication [WVC-M2-04]' {
    BeforeEach {
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Output = Join-Path $Root 'output'
        [void][IO.Directory]::CreateDirectory($Output)
        $script:Source = Join-Path $Root 'Band & [x] !NAME! %PATH% 29092025.mov'
        [IO.File]::WriteAllText($Source,'original source sentinel')
        $script:SourceHash = (Get-FileHash -LiteralPath $Source).Hash
        $script:Final = Join-Path $Output 'Band & [x] !NAME! %PATH% 29092025.mp4'
        $script:Job = $null
        $script:Counters = [pscustomobject]@{Done=0;Skipped=0;Failed=0}
        $script:CollisionMode = 'rename'
        Mock Write-Host {}
        Mock Get-MediaInspection {
            ConvertFrom-ProbeJson '{"streams":[{"index":3,"codec_type":"video","codec_name":"h264","width":320,"height":240}]}'
        }
        Mock New-OutputJob {
            $script:Job = & $script:RealNewOutputJob $SourcePath $OutputDirectory $NominalPath $CandidatePath
            return $script:Job
        }
        Mock Invoke-EncodeProcess {
            $Arguments[-1] | Should -BeExactly $script:Job.TempPath
            $Arguments | Should -Contain '-n'
            $Arguments | Should -Not -Contain '-y'
            Test-Path -LiteralPath $Arguments[-1] | Should -BeFalse
            [IO.File]::WriteAllText($Arguments[-1],'synthetic encoded payload')
            [pscustomobject]@{Succeeded=$true;StdOutTruncated=$false;StdErrTruncated=$false}
        }
    }

    It 'keeps the final unavailable during encoding and publishes only after native success [A01]' {
        Mock Invoke-EncodeProcess {
            Test-Path -LiteralPath $Final | Should -BeFalse
            Test-Path -LiteralPath $Arguments[-1] | Should -BeFalse
            { [IO.File]::Open($Job.ReservationPath,[IO.FileMode]::Open,[IO.FileAccess]::Write,[IO.FileShare]::None) } | Should -Throw
            [IO.File]::WriteAllText($Arguments[-1],'synthetic encoded payload')
            [pscustomobject]@{Succeeded=$true;StdOutTruncated=$false;StdErrTruncated=$false}
        }
        Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
        $Counters.Done | Should -Be 1
        $Counters.Failed | Should -Be 0
        [IO.File]::ReadAllText($Final) | Should -BeExactly 'synthetic encoded payload'
        [IO.Path]::GetDirectoryName($Job.JobDirectory) | Should -BeExactly $Output
        Test-Path -LiteralPath $Job.JobDirectory | Should -BeFalse
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
        @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 1
    }

    It 'retains failed partials and provenance while preserving every source/final/sibling sentinel [A01 A03]' {
        [IO.File]::WriteAllText($Final,'existing final sentinel')
        $hash = (Get-FileHash -LiteralPath $Final).Hash
        $foreign = Join-Path $Output 'foreign.partial.mp4'
        [IO.File]::WriteAllText($foreign,'foreign media sentinel')
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'unfinished owned payload')
            [pscustomobject]@{Succeeded=$false;FailureKind='NonZeroExit';Error='exit17';StdOutTruncated=$false;StdErrTruncated=$false}
        }
        Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
        $Counters.Done | Should -Be 0
        $Counters.Failed | Should -Be 1
        Test-Path -LiteralPath (Next-CompressedPath $Final) | Should -BeFalse
        [IO.File]::ReadAllText($Job.TempPath) | Should -BeExactly 'unfinished owned payload'
        $record = Get-Content -LiteralPath (Join-Path $Job.JobDirectory 'retained.json') -Raw | ConvertFrom-Json
        $record.JobId | Should -BeExactly $Job.JobId
        $record.Stage | Should -BeExactly 'Encode'
        $record.Reason | Should -Match 'exit17'
        (Get-FileHash -LiteralPath $Final).Hash | Should -BeExactly $hash
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
        [IO.File]::ReadAllText($foreign) | Should -BeExactly 'foreign media sentinel'
        Test-Path -LiteralPath $Job.ReservationPath | Should -BeFalse
        Should -Invoke Write-Host -ParameterFilter { $Object -like '*Retained*encode.partial.mp4*' }
    }

    It 'removes only an empty owned job directory after native start failure [A03]' {
        Mock Invoke-EncodeProcess { [pscustomobject]@{Succeeded=$false;FailureKind='StartFailed';Error='synthetic start failure';StdOutTruncated=$false;StdErrTruncated=$false} }
        Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
        $Counters.Failed | Should -Be 1
        $Counters.Done | Should -Be 0
        @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 0
    }

    It 'normalizes a destination ending in <Suffix> before publication [A01]' -TestCases @(
        @{Suffix='\'}, @{Suffix='\.\'}
    ) {
        param($Suffix)
        Compress-One 'unused' 'unused' $Source ($Output+$Suffix) 22 ([ref]$Counters)
        $Counters.Done | Should -Be 1
        $Counters.Failed | Should -Be 0
        [IO.File]::ReadAllText($Final) | Should -BeExactly 'synthetic encoded payload'
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
    }

    It 'refuses native success without a temporary file instead of inventing Done [A03]' {
        Mock Invoke-EncodeProcess { [pscustomobject]@{Succeeded=$true;StdOutTruncated=$false;StdErrTruncated=$false} }
        Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
        $Counters.Done | Should -Be 0
        $Counters.Failed | Should -Be 1
        Test-Path -LiteralPath $Final | Should -BeFalse
    }

    It 'reports promotion sharing failure and retains the partial without a finished final [A04]' {
        $script:Lock = $null
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'locked partial sentinel')
            $script:Lock = [IO.File]::Open($Arguments[-1],[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
            [pscustomobject]@{Succeeded=$true;StdOutTruncated=$false;StdErrTruncated=$false}
        }
        try {
            Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
            $Counters.Failed | Should -Be 1
            $Counters.Done | Should -Be 0
            Test-Path -LiteralPath $Final | Should -BeFalse
            Should -Invoke Write-Host -ParameterFilter { $Object -like '*Promote*' }
        } finally { if ($null -ne $Lock) { $Lock.Dispose() } }
        [IO.File]::ReadAllText($Job.TempPath) | Should -BeExactly 'locked partial sentinel'
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
    }

    It 'refuses a pre-existing temporary path and retains foreign bytes without launching [A03]' {
        Mock New-OutputJob {
            $script:Job = & $script:RealNewOutputJob $SourcePath $OutputDirectory $NominalPath $CandidatePath
            [IO.File]::WriteAllText($Job.TempPath,'foreign pre-existing sentinel')
            return $Job
        }
        Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
        Should -Invoke Invoke-EncodeProcess -Times 0 -Exactly
        $Counters.Failed | Should -Be 1
        [IO.File]::ReadAllText($Job.TempPath) | Should -BeExactly 'foreign pre-existing sentinel'
    }

    It 'retains a substituted failed temporary file and an extra file without broad cleanup [A03]' {
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'owned original partial')
            [IO.File]::Move($Arguments[-1],(Join-Path $Job.JobDirectory 'extra.mp4'))
            [IO.File]::WriteAllText($Arguments[-1],'foreign replacement sentinel')
            [pscustomobject]@{Succeeded=$false;FailureKind='NonZeroExit';Error='failure after substitution';StdOutTruncated=$false;StdErrTruncated=$false}
        }
        Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
        [IO.File]::ReadAllText($Job.TempPath) | Should -BeExactly 'foreign replacement sentinel'
        [IO.File]::ReadAllText((Join-Path $Job.JobDirectory 'extra.mp4')) | Should -BeExactly 'owned original partial'
        Test-Path -LiteralPath $Final | Should -BeFalse
    }

    It 'retries a real final-name race from the original basename without clobber or suffix stacking [A01 A02]' {
        [IO.File]::WriteAllText($Final,'existing final sentinel')
        $script:Raced = $false
        Mock Move-OutputFileNoClobber {
            if (-not $script:Raced) { [IO.File]::WriteAllText($Destination,'raced final sentinel'); $script:Raced=$true }
            [IO.File]::Move($Source,$Destination)
        }
        Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
        $Counters.Done | Should -Be 1
        [IO.File]::ReadAllText($Final) | Should -BeExactly 'existing final sentinel'
        [IO.File]::ReadAllText((Join-Path $Output 'Band & [x] !NAME! %PATH% 29092025 (compressed).mp4')) | Should -BeExactly 'raced final sentinel'
        [IO.File]::ReadAllText((Join-Path $Output 'Band & [x] !NAME! %PATH% 29092025 (compressed 2).mp4')) | Should -BeExactly 'synthetic encoded payload'
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
    }

    It 'uses explicit skip when a final appears after encoding and retains the unused partial [A02 A04]' {
        $previousPolicy = $CollisionMode
        $CollisionMode = 'skip'
        Mock Move-OutputFileNoClobber {
            [IO.File]::WriteAllText($Destination,'raced final sentinel')
            [IO.File]::Move($Source,$Destination)
        }
        try { Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters) }
        finally { $CollisionMode = $previousPolicy }
        $Counters.Done | Should -Be 0
        $Counters.Failed | Should -Be 0
        $Counters.Skipped | Should -Be 1
        [IO.File]::ReadAllText($Final) | Should -BeExactly 'raced final sentinel'
        [IO.File]::ReadAllText($Job.TempPath) | Should -BeExactly 'synthetic encoded payload'
    }

    It 'refuses an existing GUID job directory without adopting or deleting foreign files [A03]' {
        $id = '0123456789abcdef0123456789abcdef'
        $directory = Join-Path $Output ('.wvc-job-'+$id)
        [void][IO.Directory]::CreateDirectory($directory)
        $foreign = Join-Path $directory 'encode.partial.mp4'
        [IO.File]::WriteAllText($foreign,'foreign reserved-directory sentinel')
        { & $script:RealNewOutputJob $Source $Output $Final $Final -JobId $id } | Should -Throw
        [IO.File]::ReadAllText($foreign) | Should -BeExactly 'foreign reserved-directory sentinel'
    }

    It 'refuses a mutated job path without moving or deleting source bytes [A03 A04]' {
        $job = & $script:RealNewOutputJob $Source $Output $Final $Final
        try {
            $job.TempPath = $Source
            { Publish-OutputJob $job 'rename' } | Should -Throw
            $cleanup = Close-OutputJob $job $false 'Promote' 'mutated record'
            $cleanup.Warning | Should -Not -BeNullOrEmpty
            (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
            Test-Path -LiteralPath $Final | Should -BeFalse
        } finally { $job.Reservation.Dispose() }
    }

    It 'preserves fatal encoder cleanup propagation and reports a still-owned partial [A03 A04]' {
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'possibly still-written partial')
            $abort = New-Object InvalidOperationException 'Injected encoder cleanup failure'
            $abort.Data['WvcAbortBatch']=$true
            throw $abort
        }
        { Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters) } | Should -Throw '*cleanup failure*'
        [IO.File]::ReadAllText($Job.TempPath) | Should -BeExactly 'possibly still-written partial'
        Test-Path -LiteralPath $Final | Should -BeFalse
    }

    It 'retains an empty job and provenance when a live encoder could still create its temporary file [A03 A04]' {
        Mock Invoke-EncodeProcess {
            $abort = New-Object InvalidOperationException 'Owned encoder termination failed before output creation'
            $abort.Data['WvcAbortBatch']=$true
            throw $abort
        }
        { Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters) } | Should -Throw '*termination failed*'
        Test-Path -LiteralPath $Job.JobDirectory | Should -BeTrue
        Test-Path -LiteralPath $Job.TempPath | Should -BeFalse
        $record = Get-Content -LiteralPath (Join-Path $Job.JobDirectory 'retained.json') -Raw | ConvertFrom-Json
        $record.EncoderMayStillRun | Should -BeTrue
        $record.Reason | Should -Match 'termination failed'
        Test-Path -LiteralPath $Final | Should -BeFalse
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
    }

    It 'excludes active and orphaned reserved job directories and explicit partials from future scans [A03]' {
        $active = & $script:RealNewOutputJob $Source $Output $Final $Final
        $orphan = Join-Path $Output ('.wvc-job-'+[guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($orphan)
        [IO.File]::WriteAllText((Join-Path $orphan 'encode.partial.mp4'),'orphan unverified sentinel')
        $ordinary = Join-Path $Output '.wvc-job-not-a-guid'
        [void][IO.Directory]::CreateDirectory($ordinary)
        $ordinaryFile = Join-Path $ordinary 'original.partial.mp4'
        [IO.File]::WriteAllText($ordinaryFile,'ordinary original sentinel')
        try {
            [IO.File]::WriteAllText($active.TempPath,'active partial sentinel')
            $scan = Get-InputScan $Root
            $scan.Files | Should -Contain $ordinaryFile
            $scan.Files | Should -Contain $Source
            $scan.Files.Count | Should -Be 2
            $scan.Warnings.Count | Should -Be 2
            @(Get-OutputJobWarnings $Output).Count | Should -Be 2
            $scan.Succeeded | Should -BeTrue
            @(Collect-InputFiles $active.TempPath).Count | Should -Be 0
            @(Collect-InputFiles $orphan).Count | Should -Be 0
        } finally { [void](Close-OutputJob $active $false 'Test' 'synthetic active job') }
    }

    It 'refuses a temporary junction and does not traverse its foreign target during cleanup [A03 A04]' {
        $job = & $script:RealNewOutputJob $Source $Output $Final $Final
        $outside = Join-Path $Root 'foreign target'
        [void][IO.Directory]::CreateDirectory($outside)
        $foreign = Join-Path $outside 'source.mov'
        [IO.File]::WriteAllText($foreign,'outside original sentinel')
        try {
            New-Item -ItemType Junction -Path $job.TempPath -Target $outside -ErrorAction Stop | Out-Null
            { Publish-OutputJob $job 'rename' } | Should -Throw
            $cleanup = Close-OutputJob $job $false 'Promote' 'temporary junction refused'
            $cleanup.Warning | Should -Not -BeNullOrEmpty
            [IO.File]::ReadAllText($foreign) | Should -BeExactly 'outside original sentinel'
            Test-Path -LiteralPath $Final | Should -BeFalse
            Test-Path -LiteralPath (Join-Path $job.JobDirectory 'retained.json') | Should -BeFalse
        } finally {
            $job.Reservation.Dispose()
            # Remove only the owned junction object, never its target directory.
            if ([IO.Directory]::Exists($job.TempPath)) { [IO.Directory]::Delete($job.TempPath) }
        }
    }

    It 'does not overwrite a foreign retained record when failure reporting encounters a collision [A04]' {
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'failed partial sentinel')
            [IO.File]::WriteAllText((Join-Path $Job.JobDirectory 'retained.json'),'foreign record sentinel')
            [pscustomobject]@{Succeeded=$false;FailureKind='NonZeroExit';Error='synthetic failure';StdOutTruncated=$false;StdErrTruncated=$false}
        }
        Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
        [IO.File]::ReadAllText((Join-Path $Job.JobDirectory 'retained.json')) | Should -BeExactly 'foreign record sentinel'
        [IO.File]::ReadAllText($Job.TempPath) | Should -BeExactly 'failed partial sentinel'
        $Counters.Failed | Should -Be 1
    }

    It 'does not mark a published output failed if its completion display throws [A04]' {
        Mock Write-Host { throw 'Injected completion display failure' } -ParameterFilter { $Object -eq 'Done.' }
        Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
        $Counters.Done | Should -Be 1
        $Counters.Failed | Should -Be 0
        [IO.File]::ReadAllText($Final) | Should -BeExactly 'synthetic encoded payload'
        Test-Path -LiteralPath $Job.JobDirectory | Should -BeFalse
    }

    It 'keeps an explicit <Phase> collision skip when its display throws [A04]' -TestCases @(
        @{Phase='early'}, @{Phase='promotion'}
    ) {
        param($Phase)
        $previous = $CollisionMode
        try {
            $CollisionMode = 'skip'
            if ($Phase -eq 'early') { [IO.File]::WriteAllText($Final,'raced final sentinel') }
            else {
                Mock Invoke-EncodeProcess {
                    [IO.File]::WriteAllText($Arguments[-1],'synthetic encoded payload')
                    [IO.File]::WriteAllText($Final,'raced final sentinel')
                    [pscustomobject]@{Succeeded=$true;StdOutTruncated=$false;StdErrTruncated=$false}
                }
            }
            Mock Write-Host { throw 'Injected skip display failure' } -ParameterFilter { $Object -like 'Skipping*' }
            Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
        } finally { $CollisionMode = $previous }
        $Counters.Done | Should -Be 0
        $Counters.Skipped | Should -Be 1
        $Counters.Failed | Should -Be 0
        [IO.File]::ReadAllText($Final) | Should -BeExactly 'raced final sentinel'
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
        if ($Phase -eq 'promotion') {
            [IO.File]::ReadAllText($Job.TempPath) | Should -BeExactly 'synthetic encoded payload'
        } else { Should -Invoke Invoke-EncodeProcess -Times 0 }
    }

    It 'preserves fatal cleanup exception when retained-partial display also fails [A03 A04]' {
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'possibly still-written partial')
            $abort = New-Object InvalidOperationException 'Original owned encoder cleanup failure'
            $abort.Data['WvcAbortBatch']=$true
            throw $abort
        }
        Mock Write-Host { throw 'Secondary retention display failure' } -ParameterFilter { $Object -like '*Retained*' }
        { Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters) } | Should -Throw '*Original owned encoder cleanup failure*'
        [IO.File]::ReadAllText($Job.TempPath) | Should -BeExactly 'possibly still-written partial'
        Test-Path -LiteralPath $Final | Should -BeFalse
    }

    It 'refuses native-success publication with extra job artifacts that make authorship ambiguous [A03 A04]' {
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'original partial')
            [IO.File]::Move($Arguments[-1],(Join-Path $Job.JobDirectory 'extra.mp4'))
            [IO.File]::WriteAllText($Arguments[-1],'foreign replacement sentinel')
            [pscustomobject]@{Succeeded=$true;StdOutTruncated=$false;StdErrTruncated=$false}
        }
        Compress-One 'unused' 'unused' $Source $Output 22 ([ref]$Counters)
        $Counters.Failed | Should -Be 1
        $Counters.Done | Should -Be 0
        [IO.File]::ReadAllText($Job.TempPath) | Should -BeExactly 'foreign replacement sentinel'
        [IO.File]::ReadAllText((Join-Path $Job.JobDirectory 'extra.mp4')) | Should -BeExactly 'original partial'
        Test-Path -LiteralPath $Final | Should -BeFalse
    }
}
