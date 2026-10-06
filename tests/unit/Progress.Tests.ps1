BeforeAll {
    $script:SavedAppData=$env:APPDATA
    $env:APPDATA=Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
}
AfterAll { $env:APPDATA=$script:SavedAppData }

Describe 'Machine progress records [WVC-M3-05-A01]' {
    It 'handles records split at every character boundary including CRLF and an unterminated end marker' {
        $text="out_time_us=2000000`r`nspeed=2.0x`r`nprogress=continue`r`nout_time=00:00:04.000`r`nprogress=end"
        for ($i=1; $i -lt $text.Length; $i++) {
            $progress=New-EncodeProgress 4
            Update-EncodeProgress $progress $text.Substring(0,$i)
            Update-EncodeProgress $progress $text.Substring($i) -Flush
            $progress.Records | Should -Be 2
            $progress.MediaSeconds | Should -Be 4
            $progress.State | Should -BeExactly 'Finalizing'
            $progress.Percent | Should -Be 99
            $progress.RemainingSeconds | Should -BeNullOrEmpty
        }
    }
    It 'uses invariant decimals and timestamp priority under <Culture>' -TestCases @(
        @{Culture='en-US'},@{Culture='fi-FI'},@{Culture='de-DE'}
    ) {
        param($Culture)
        $old=[Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [Threading.Thread]::CurrentThread.CurrentCulture=[Globalization.CultureInfo]::GetCultureInfo($Culture)
            $progress=New-EncodeProgress 10
            Update-EncodeProgress $progress "out_time_us=2500000`nout_time_ms=8000000`nout_time=00:00:09.000`nspeed=1.5x`nprogress=continue`n"
            $progress.MediaSeconds | Should -Be 2.5
            $progress.Percent | Should -Be 25
            $progress.RemainingSeconds | Should -Be 5
        } finally { [Threading.Thread]::CurrentThread.CurrentCulture=$old }
    }
    It 'falls back safely from <Case>' -TestCases @(
        @{Case='N/A microseconds';Fields="out_time_us=N/A`nout_time_ms=3000000"},
        @{Case='negative microseconds';Fields="out_time_us=-1`nout_time_ms=N/A`nout_time=00:00:03.0"},
        @{Case='overflow';Fields="out_time_us=1e999`nout_time=00:00:03.0"}
    ) {
        param($Case,$Fields)
        $progress=New-EncodeProgress 6
        Update-EncodeProgress $progress ($Fields+"`nspeed=N/A`nprogress=continue`n")
        $progress.MediaSeconds | Should -Be 3
        $progress.Percent | Should -Be 50
        $progress.RemainingSeconds | Should -BeNullOrEmpty
    }
    It 'does not invent time or ETA for invalid values <Value>' -TestCases @(
        @{Value='N/A'},@{Value='NaN'},@{Value='Infinity'},@{Value='-20'},@{Value='1,25'},@{Value='bad'}
    ) {
        param($Value)
        $progress=New-EncodeProgress 10
        Update-EncodeProgress $progress ("out_time_us=$Value`nspeed=$Value`nprogress=continue`n")
        $progress.MediaSeconds | Should -BeNullOrEmpty
        $progress.Percent | Should -Be -1
        $progress.RemainingSeconds | Should -BeNullOrEmpty
    }
    It 'shows indeterminate progress for duration <Duration>' -TestCases @(
        @{Duration=$null},@{Duration=0},@{Duration=-1},@{Duration='N/A'}
    ) {
        param($Duration)
        $progress=New-EncodeProgress $Duration 2 5
        Update-EncodeProgress $progress "out_time_us=2000000`nspeed=2x`nprogress=continue`n"
        Mock Write-Progress {}
        Write-JobProgress $progress
        $progress.Percent | Should -Be -1
        $progress.RemainingSeconds | Should -BeNullOrEmpty
        Should -Invoke Write-Progress -Times 1 -Exactly -ParameterFilter { $Activity -eq 'File 2/5' -and $PercentComplete -eq -1 -and $Status -like '*elapsed*remaining unknown*' }
    }
    It 'bounds malformed/unfinished lines, ignores unknown fields and recovers at a record boundary' {
        $progress=New-EncodeProgress 10
        Update-EncodeProgress $progress ('x'*8000)
        $progress.Buffer.Length | Should -BeLessOrEqual 4096
        Update-EncodeProgress $progress "tail`nunknown=secret`nout_time_us=1000000`nprogress=bogus`nout_time_ms=2000000`nprogress=continue`n"
        $progress.Fields.Count | Should -Be 0
        $progress.MalformedLines | Should -BeGreaterThan 0
        $progress.MediaSeconds | Should -Be 2
    }
    It 'keeps measured position monotonic and never reverts an end marker to encoding' {
        $progress=New-EncodeProgress 10
        Update-EncodeProgress $progress "out_time_us=8000000`nprogress=continue`n"
        Update-EncodeProgress $progress "out_time_us=1000000`nprogress=continue`n"
        $progress.Percent | Should -Be 80
        Update-EncodeProgress $progress "out_time_us=10000000`nprogress=end`nprogress=continue`n"
        $progress.Percent | Should -Be 99
        $progress.State | Should -BeExactly 'Finalizing'
    }
}

Describe 'Progress completion follows publication [WVC-M3-05-A02]' {
    BeforeEach {
        $script:Root=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Output=Join-Path $Root 'out';[void][IO.Directory]::CreateDirectory($Output)
        $script:Source=Join-Path $Root 'source.mov';[IO.File]::WriteAllText($Source,'source sentinel')
        $script:SourceHash=(Get-FileHash -LiteralPath $Source).Hash
        $script:Final=Join-Path $Output 'source.mp4'
        $script:Displays=New-Object 'Collections.Generic.List[object]'
        Mock Write-Host {}
        Mock Write-Progress { $Displays.Add([pscustomobject]@{Percent=$PercentComplete;Status=$Status;Finished=[bool]$Completed;FinalExists=(Test-Path -LiteralPath $Final)}) }
        Mock Get-MediaInspection { ConvertFrom-ProbeJson '{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":320,"height":240,"pix_fmt":"yuv420p"}],"format":{"duration":"2"}}' }
        Mock Invoke-EncodeProcess {
            [IO.File]::WriteAllText($Arguments[-1],'temporary synthetic bytes')
            Update-EncodeProgress $ProgressContext "out_time_us=2000000`nprogress=end`n"
            Write-JobProgress $ProgressContext
            [pscustomobject]@{Succeeded=$true;Started=$true;StdOutTruncated=$false;StdErrTruncated=$false}
        }
        Mock Get-OutputValidation {
            @($Displays | Where-Object Percent -eq 100).Count | Should -Be 0
            Test-Path -LiteralPath $Final | Should -BeFalse
            [pscustomobject]@{Succeeded=$true;Inspection=$null;Warnings=@()}
        }
    }
    It 'reports 100 only after validation and no-clobber final promotion' {
        $job=Compress-One 'unused' 'unused' $Source $Output 22 -FileIndex 2 -FileTotal 3
        $job.Outcome | Should -BeExactly 'Completed'
        ($job.ProgressStates -join ',') | Should -BeExactly 'Encoding,Finalizing,Validating,Publishing,Completed'
        @($Displays | Where-Object { $_.Percent -eq 100 -and -not $_.FinalExists }).Count | Should -Be 0
        @($Displays | Where-Object Percent -eq 100).Count | Should -BeGreaterThan 0
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
    }
    It 'keeps failed <Stage> below 100 and retains the partial' -TestCases @(@{Stage='validation'},@{Stage='promotion'}) {
        param($Stage)
        if ($Stage -eq 'validation') { Mock Get-OutputValidation {[pscustomobject]@{Succeeded=$false;FailureKind='Invalid';Reason='fixture fault';Inspection=$null;Warnings=@()}} }
        else { Mock Move-OutputFileNoClobber {throw 'fixture promotion fault'} }
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.Outcome | Should -BeExactly 'Failed'
        @($Displays | Where-Object Percent -eq 100).Count | Should -Be 0
        Test-Path -LiteralPath $Final | Should -BeFalse
        @(Get-ChildItem -LiteralPath $Output -Recurse -Filter 'encode.partial.mp4').Count | Should -Be 1
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash
    }
    It 'does not report a publication collision skip as completed' {
        Mock Publish-OutputJob { [pscustomobject]@{Published=$false;FinalPath=$Final;Reason='collision'} }
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.Outcome | Should -BeExactly 'Skipped'
        @($Displays | Where-Object Percent -eq 100).Count | Should -Be 0
    }
    It 'preserves publication while cancellation observed at final display stops scheduling' {
        Mock Write-Progress { throw (New-Object OperationCanceledException 'display cancellation') } -ParameterFilter { $Completed }
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.Outcome | Should -BeExactly 'Completed'
        $job.CancellationRequested | Should -BeTrue
        (Get-BatchResult @($job) @() -Requested).ExitCode | Should -Be 3
        Test-Path -LiteralPath $Final | Should -BeTrue
    }
    It 'does not log an encoding attempt when preparation fails' {
        $job=Compress-One 'unused' 'unused' (Join-Path $Root 'missing.mov') $Output 22
        $job.ProgressStates | Should -Not -Contain 'Encoding'
        Should -Invoke Invoke-EncodeProcess -Times 0 -Exactly
    }
    It 'shows a bounded stderr tail on encoder failure even without persistent logs' {
        Mock Invoke-EncodeProcess {
            [pscustomobject]@{Succeeded=$false;Started=$true;FailureKind='NonZeroExit';Error='exit17';
                StdOutTruncated=$false;StdErrTruncated=$false;StdErr=('x'*5000)+'useful native error'}
        }
        $job=Compress-One 'unused' 'unused' $Source $Output 22
        $job.Outcome | Should -BeExactly 'Failed'
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*useful native error' -and $Object.Length -lt 1100 }
    }
}
