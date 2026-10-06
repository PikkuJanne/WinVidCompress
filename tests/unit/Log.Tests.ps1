BeforeAll {
    $script:SavedAppData=$env:APPDATA
    $env:APPDATA=Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
}
AfterAll { $env:APPDATA=$script:SavedAppData }

Describe 'Bounded local session results [WVC-M3-05-A03/A04]' {
    BeforeEach {
        $script:Root=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Tools=[pscustomobject]@{FFmpeg='C:\tools\ffmpeg.exe';FFprobe='C:\tools\ffprobe.exe';FFmpegBuild='ffmpeg version test-build';FFprobeBuild='ffprobe version test-build'}
        Mock Write-Host {}
    }
    It 'captures actual identity/settings/native error tails and all ordinary outcomes incrementally' {
        $session=New-SessionLog $Tools $Root
        $jobs=@('Completed','Skipped','Failed','Cancelled','Unstarted' | ForEach-Object {
            $job=New-JobResult 'D:\interviews\private.mov' 22;$job.Outcome=$_;$job.Stage='Encode'
            $job.Diagnostics.EncodeArguments=@('-crf','22','-preset','veryfast','-metadata','title=Private title')
            $job.Diagnostics.Encode=[pscustomobject]@{ExitCode=17;FailureKind='NonZeroExit';Error='encode failed';StdOut='machine';StdErr=('x'*10000)+'useful error tail'}
            Write-SessionJob $session $job
            $job.LogPath | Should -BeExactly $session.JsonPath
            $job
        })
        $result=Get-BatchResult $jobs @() -Requested
        Complete-SessionLog $session $result
        $records=@(Get-Content -LiteralPath $session.JsonPath -Encoding UTF8 | ForEach-Object { $_ | ConvertFrom-Json })
        $records.Count | Should -Be 7
        $records[0].SchemaVersion | Should -Be 1
        $records[0].ApplicationSHA256 | Should -BeExactly (Get-FileHash -LiteralPath $ApplicationPath).Hash
        $records[0].FFmpegVersion | Should -Match 'test-build'
        $records[1].Settings.CRF | Should -Be 22
        $records[1].Encode.StdErr | Should -Match 'useful error tail$'
        $records[1].Encode.StdErr.Length | Should -BeLessThan 8220
        $records[1].Encode.ExitCode | Should -Be 17
        $records[1].JobId | Should -Match '^[a-f0-9]{32}$'
        $records[-1].Counters.Found | Should -Be 5
        $result.ExitCode | Should -Be 3
        (Get-Content -LiteralPath $session.TextPath -Raw) | Should -Match 'Session exit 3'
    }
    It 'keeps both files bounded and emits valid truncation records' {
        $session=New-SessionLog $Tools $Root -LimitBytes 4096
        for ($i=0;$i -lt 10;$i++) {
            $job=New-JobResult ('source'+$i) 22;$job.Reason='error'*500
            Write-SessionJob $session $job
        }
        $session.Enabled | Should -BeFalse
        $session.Warnings.Count | Should -Be 1
        (Get-Item -LiteralPath $session.JsonPath).Length | Should -BeLessOrEqual 4096
        (Get-Item -LiteralPath $session.TextPath).Length | Should -BeLessOrEqual 4096
        $records=@(Get-Content -LiteralPath $session.JsonPath | ForEach-Object { $_ | ConvertFrom-Json })
        $records[-1].Kind | Should -BeExactly 'Truncated'
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*byte limit*' }
    }
    It 'makes write failure visible without relabeling a published final or altering exit status' {
        $session=New-SessionLog $Tools $Root
        $final=Join-Path $Root 'final.mp4';[IO.File]::WriteAllText($final,'published sentinel')
        $hash=(Get-FileHash -LiteralPath $final).Hash
        $job=New-JobResult 'source' 22;$job.Outcome='Completed';$job.OutputPath=$final
        $lock=New-Object IO.FileStream($session.JsonPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try { Write-SessionJob $session $job } finally { $lock.Dispose() }
        $result=Get-BatchResult @($job) @() -Requested
        Complete-SessionLog $session $result
        $result.ExitCode | Should -Be 0
        $job.Outcome | Should -BeExactly 'Completed'
        $result.Warnings.Count | Should -Be 1
        (Get-FileHash -LiteralPath $final).Hash | Should -BeExactly $hash
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*logging failed*' }
    }
    It 'refuses new sessions at the retention quota without removing older logs' {
        [void][IO.Directory]::CreateDirectory($Root)
        for ($i=0;$i -lt 128;$i++) { [void][IO.Directory]::CreateDirectory((Join-Path $Root ('old'+$i))) }
        $session=New-SessionLog $Tools $Root
        $session.Enabled | Should -BeFalse
        $session.Warnings[0] | Should -Match 'quota'
        @(Get-ChildItem -LiteralPath $Root -Directory).Count | Should -Be 128
    }
    It 'serializes quota admission with a real exclusive file handle and recovers after release' {
        [void][IO.Directory]::CreateDirectory($Root)
        $lock=New-Object IO.FileStream((Join-Path $Root 'quota.lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try {
            $blocked=New-SessionLog $Tools $Root
            $blocked.Enabled | Should -BeFalse
            $blocked.Warnings.Count | Should -Be 1
            @(Get-ChildItem -LiteralPath $Root -Directory).Count | Should -Be 0
        } finally { $lock.Dispose() }
        $session=New-SessionLog $Tools $Root
        $session.Enabled | Should -BeTrue
        @(Get-ChildItem -LiteralPath $Root -Directory).Count | Should -Be 1
    }
    It 'leaves doctor non-persisting and restores a caller session after a normal run' {
        Mock Ensure-Tool { 'unused.exe' }
        Mock Get-ToolEnvironment { $Tools }
        Mock Get-EnvironmentConfig { [pscustomobject]@{OutputDir=$Root} }
        Mock Get-OutputEnvironment { [pscustomobject]@{} }
        Mock Write-EnvironmentReport {}
        Mock Load-Config { [pscustomobject]@{OutputDir=$Root} }
        Mock Process-Paths {
            $job=New-JobResult 'opaque.mov' 22;$job.Outcome='Failed';$job.Reason='synthetic error'
            Write-SessionJob $script:SessionLog $job
            Get-BatchResult @($job) @() -Requested
        }
        $script:Prepared=New-SessionLog $Tools $Root
        Mock New-SessionLog { $Prepared }
        $previous=$script:SessionLog
        Invoke-WinVidCompress -CheckEnvironment | Out-Null
        Should -Invoke New-SessionLog -Times 0 -Exactly
        $run=Invoke-WinVidCompress -Paths @('opaque.mov')
        $run.LogPath | Should -Not -BeNullOrEmpty
        Test-Path -LiteralPath $run.LogPath | Should -BeTrue
        $script:SessionLog | Should -Be $previous
        $run.ExitCode | Should -Be 1
    }
}

Describe 'Explicit private diagnostic export [WVC-M3-05-A04]' {
    BeforeEach {
        $script:Root=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Name='Band '+[char]0x00E4+[char]0x4E2D+' 29092025'
        $script:PrivateRoot='C:\Users\Sensitive Owner\nested'
        $script:Tools=[pscustomobject]@{FFmpeg='C:\Users\Sensitive Owner\tools\ffmpeg.exe';FFprobe='C:\Users\Sensitive Owner\tools\ffprobe.exe';FFmpegBuild='ffmpeg version measured';FFprobeBuild='ffprobe version measured'}
        Mock Write-Host {}
        $script:Session=New-SessionLog $Tools $Root
        $script:Job=New-JobResult ($PrivateRoot+'\'+$Name+'.mov') 22
        $Job.Outcome='Failed';$Job.Stage='Encode';$Job.Reason='Failed opening '+$Job.SourcePath
        $Job.CandidatePath='\\private-server\private-share\'+$Name+'.mp4'
        $Job.Diagnostics.EncodeArguments=@('-i',$Job.SourcePath,'-metadata',('title='+$Name),'-metadata','artist=Private artist',$Job.CandidatePath)
        $Job.Diagnostics.Encode=[pscustomobject]@{ExitCode=17;FailureKind='NonZeroExit';Error=$Job.Reason;
            StdErr=('Input "'+$Job.SourcePath+'"; title: '+$Name+'; artist: unknown inherited private tag; '+($Job.SourcePath -replace '\\','/'))}
        Write-SessionJob $Session $Job
    }
    It 'redacts nested Unicode paths, filename stems, generated metadata and unknown inherited diagnostic tags by default' {
        $target=Join-Path $Root 'share.json'
        Export-WvcDiagnostic $Session.JsonPath $target -Roots @('\\private-server\private-share') | Out-Null
        $text=Get-Content -LiteralPath $target -Raw -Encoding UTF8
        $text | Should -Not -Match 'Sensitive Owner|private-server|private-share|Private artist|unknown inherited private tag'
        $text.Contains($Name) | Should -BeFalse
        $report=$text | ConvertFrom-Json
        $report.SchemaVersion | Should -Be 1
        $report.Records[1].JobId | Should -BeExactly $Job.JobId
        $report.Records[1].Encode.ExitCode | Should -Be 17
        $report.Records[1].Encode.FailureKind | Should -BeExactly 'NonZeroExit'
        $report.Records[1].Settings.CRF | Should -Be 22
        $report.Records[1].Encode.StdErr | Should -Match 'omitted'
    }
    It 'can retain explicitly selected metadata while redacting configured roots and filenames in diagnostics' {
        $target=Join-Path $Root 'selected.json'
        Export-WvcDiagnostic $Session.JsonPath $target -Roots @('Sensitive Owner','private-server','private-share') -RedactMetadata $false | Out-Null
        $text=Get-Content -LiteralPath $target -Raw -Encoding UTF8
        $text | Should -Match 'unknown inherited private tag|Private artist'
        $text | Should -Not -Match 'Sensitive Owner|private-server|private-share'
        $text.Contains($Name) | Should -BeFalse
    }
    It 'allows explicit filename retention only in metadata values while absolute paths remain redacted' {
        $target=Join-Path $Root 'names.json'
        Export-WvcDiagnostic $Session.JsonPath $target -RedactFilenames $false -RedactMetadata $false | Out-Null
        $report=Get-Content -LiteralPath $target -Raw -Encoding UTF8 | ConvertFrom-Json
        $report.Records[1].EncodeArguments | Should -Contain ('title='+$Name)
        $report.Records[1].SourcePath | Should -BeExactly '[path]'
    }
    It 'never overwrites an existing export or the original local report' {
        $target=Join-Path $Root 'sentinel.json';[IO.File]::WriteAllText($target,'existing sentinel')
        $before=(Get-FileHash -LiteralPath $Session.JsonPath).Hash
        { Export-WvcDiagnostic $Session.JsonPath $target } | Should -Throw
        (Get-Content -LiteralPath $target -Raw) | Should -BeExactly 'existing sentinel'
        { Export-WvcDiagnostic $Session.JsonPath $Session.JsonPath } | Should -Throw
        (Get-FileHash -LiteralPath $Session.JsonPath).Hash | Should -BeExactly $before
    }
    It 'preserves structural identities/settings when a filename stem and artist are one character' {
        $session=New-SessionLog $Tools (Join-Path $Root 'short')
        $job=New-JobResult 'C:\private\a.mov' 22
        $job.JobId='a1234567890abcdef1234567890abcdef';$job.Outcome='Failed'
        $job.Diagnostics.EncodeArguments=@('-i',$job.SourcePath,'-c:a','aac','-metadata','artist=a','C:\private\a.mp4')
        Write-SessionJob $session $job
        $target=Join-Path $Root 'short.json'
        Export-WvcDiagnostic $session.JsonPath $target | Out-Null
        $report=Get-Content -LiteralPath $target -Raw | ConvertFrom-Json
        $report.Records[1].JobId | Should -BeExactly $job.JobId
        $report.Records[1].Outcome | Should -BeExactly 'Failed'
        $report.Records[1].Settings.AudioCodec | Should -BeExactly 'aac'
        $report.Records[1].EncodeArguments | Should -Contain 'aac'
        $report.Records[1].EncodeArguments | Should -Contain 'artist=[metadata]'
    }
    It 'omits unknown spaced compiler/build paths from default export' {
        $tools=[pscustomobject]@{FFmpeg='C:\tools\ffmpeg.exe';FFprobe='C:\tools\ffprobe.exe';
            FFmpegBuild="ffmpeg version build-123`nconfiguration: --prefix=C:\build area\PrivateOwner\prefix";
            FFprobeBuild='ffprobe version build-123 --prefix=C:\other area\PrivateOwner\prefix'}
        $session=New-SessionLog $tools (Join-Path $Root 'build')
        $target=Join-Path $Root 'build.json'
        Export-WvcDiagnostic $session.JsonPath $target | Out-Null
        $text=Get-Content -LiteralPath $target -Raw
        $text | Should -Not -Match 'PrivateOwner|configuration|prefix|build area|other area'
        ($text | ConvertFrom-Json).Records[0].FFmpegVersion | Should -BeExactly 'ffmpeg version build-123'
    }
}
