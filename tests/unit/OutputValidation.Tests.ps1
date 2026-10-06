BeforeAll {
    $script:SavedAppData=$env:APPDATA
    $env:APPDATA=Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
    function New-ValidationDocument([switch]$Audio,[string]$VideoDuration='10',[string]$AudioDuration='10',[string]$Duration='10') {
        $streams=@([pscustomobject]@{index=3;codec_type='video';codec_name='h264';width=320;height=240;duration=$VideoDuration;avg_frame_rate='24/1';nb_frames='240'})
        if ($Audio) { $streams += [pscustomobject]@{index=8;codec_type='audio';codec_name='aac';channels=2;sample_rate='48000';duration=$AudioDuration} }
        [pscustomobject]@{streams=$streams;format=[pscustomobject]@{format_name='mov,mp4,m4a,3gp,3g2,mj2';duration=$Duration}}
    }
    function Convert-ValidationDocument($Document) { ConvertFrom-ProbeJson ($Document | ConvertTo-Json -Depth 12) }
    function Write-ValidationHeader([string]$Path,[string]$Brand='isom') {
        $bytes=[byte[]]@(0,0,0,16,102,116,121,112) + [Text.Encoding]::ASCII.GetBytes($Brand) + [byte[]]@(0,0,0,0)
        [IO.File]::WriteAllBytes($Path,$bytes)
    }
    function Initialize-ValidationFixture {
        $script:Root=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Output=Join-Path $Root 'output'
        [void][IO.Directory]::CreateDirectory($Output)
        $script:SourcePath=Join-Path $Root 'source & [x] !NAME! %PATH%.mov'
        [IO.File]::WriteAllText($SourcePath,'source sentinel')
        $script:SourceHash=(Get-FileHash -LiteralPath $SourcePath).Hash
        $script:Final=Join-Path $Output 'source & [x] !NAME! %PATH%.mp4'
        $script:SourceDocument=New-ValidationDocument
        $script:OutputDocument=New-ValidationDocument
        $script:SourceInspection=Convert-ValidationDocument $SourceDocument
        $script:Plan=Get-StreamPlan $SourceInspection
    }
}
AfterAll {$env:APPDATA=$script:SavedAppData}

Describe 'Structural output validation [WVC-M2-05]' {
    BeforeEach {
        Initialize-ValidationFixture
        $script:Job=New-OutputJob $SourcePath $Output $Final $Final
        Write-ValidationHeader $Job.TempPath
        Mock Get-MediaInspection { Convert-ValidationDocument $script:OutputDocument }
    }
    AfterEach { [void](Close-OutputJob $Job $false 'Test' 'owned synthetic fixture') }

    It 'accepts silent H264 MP4 structure with known duration, preserving source and unpublished temp [A01 A02]' {
        $result=Get-OutputValidation 'unused' $Job $SourceInspection $Plan
        $result.Succeeded | Should -BeTrue
        $result.DurationChecks.Count | Should -Be 2
        Test-Path -LiteralPath $Final | Should -BeFalse
        (Get-FileHash -LiteralPath $SourcePath).Hash | Should -BeExactly $SourceHash
    }
    It 'refuses <Kind> files before probing [A01 A04]' -TestCases @(@{Kind='zero'},@{Kind='wrongbrand'},@{Kind='short'},@{Kind='badbox'}) {
        param($Kind)
        switch ($Kind) {
            zero {[IO.File]::WriteAllBytes($Job.TempPath,[byte[]]@())}
            wrongbrand {Write-ValidationHeader $Job.TempPath 'qt  '}
            short {[IO.File]::WriteAllBytes($Job.TempPath,[byte[]]@(1,2,3))}
            badbox {$bytes=[IO.File]::ReadAllBytes($Job.TempPath);$bytes[3]=64;[IO.File]::WriteAllBytes($Job.TempPath,$bytes)}
        }
        $hash=(Get-FileHash -LiteralPath $Job.TempPath).Hash
        $result=Get-OutputValidation 'unused' $Job $SourceInspection $Plan
        $result.Succeeded | Should -BeFalse
        $result.Reason | Should -Match ([regex]::Escape($Job.JobId))
        $result.SourcePath | Should -BeExactly $SourcePath
        Should -Invoke Get-MediaInspection -Times 0
        (Get-FileHash -LiteralPath $Job.TempPath).Hash | Should -BeExactly $hash
    }
    It 'rejects an actually unreadable sharing-locked temp without touching its bytes [A01 A04]' {
        $hash=(Get-FileHash -LiteralPath $Job.TempPath).Hash
        $lock=[IO.File]::Open($Job.TempPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try {(Get-OutputValidation 'unused' $Job $SourceInspection $Plan).Succeeded | Should -BeFalse}
        finally {$lock.Dispose()}
        (Get-FileHash -LiteralPath $Job.TempPath).Hash | Should -BeExactly $hash
        Should -Invoke Get-MediaInspection -Times 0
    }
    It 'refuses wrong <Kind> structure/duration despite native-success-style probe metadata [A01]' -TestCases @(
        @{Kind='container'},@{Kind='codec'},@{Kind='artwork'},@{Kind='extraVideo'},@{Kind='extraAudio'},
        @{Kind='extraData'},@{Kind='dimensions'},@{Kind='zeroFrames'},@{Kind='truncated'},@{Kind='long'},@{Kind='unknownOutput'}
    ) {
        param($Kind)
        switch ($Kind) {
            container {$OutputDocument.format.format_name='matroska,webm'}
            codec {$OutputDocument.streams[0].codec_name='hevc'}
            artwork {$OutputDocument.streams[0] | Add-Member disposition ([pscustomobject]@{attached_pic=1})}
            extraVideo {$other=$OutputDocument.streams[0].PSObject.Copy();$other.index=4;$OutputDocument.streams += $other}
            extraAudio {$OutputDocument.streams += [pscustomobject]@{index=8;codec_type='audio';codec_name='aac';channels=2;sample_rate='48000';duration='10'}}
            extraData {$OutputDocument.streams += [pscustomobject]@{index=7;codec_type='data'}}
            dimensions {$OutputDocument.streams[0].height=120}
            zeroFrames {$OutputDocument.streams[0].nb_frames='0'}
            truncated {$OutputDocument.streams[0].duration='5';$OutputDocument.format.duration='5'}
            long {$OutputDocument.streams[0].duration='20';$OutputDocument.format.duration='20'}
            unknownOutput {$OutputDocument.streams[0].duration='N/A';$OutputDocument.format.duration='N/A'}
        }
        (Get-OutputValidation 'unused' $Job $SourceInspection $Plan).Succeeded | Should -BeFalse
    }
    It 'checks selected AAC presence, codec, channels and observable audio duration [A01 A02]' -TestCases @(
        @{Kind='valid'},@{Kind='missing'},@{Kind='codec'},@{Kind='channels'},@{Kind='duration'}
    ) {
        param($Kind)
        $SourceInspection=Convert-ValidationDocument (New-ValidationDocument -Audio)
        $Plan=Get-StreamPlan $SourceInspection
        $OutputDocument=New-ValidationDocument -Audio
        switch ($Kind) {
            missing {$OutputDocument.streams=@($OutputDocument.streams[0])}
            codec {$OutputDocument.streams[1].codec_name='opus'}
            channels {$OutputDocument.streams[1].channels=1}
            duration {$OutputDocument.streams[1].duration='N/A'}
        }
        $script:OutputDocument=$OutputDocument
        (Get-OutputValidation 'unused' $Job $SourceInspection $Plan).Succeeded | Should -Be ($Kind -eq 'valid')
    }
    It 'does not let long audio or an aggregate container conceal truncated video [A01]' {
        $SourceInspection=Convert-ValidationDocument (New-ValidationDocument -Audio -AudioDuration '20' -Duration '20')
        $Plan=Get-StreamPlan $SourceInspection
        $script:OutputDocument=New-ValidationDocument -Audio -VideoDuration '5' -AudioDuration '20' -Duration '20'
        (Get-OutputValidation 'unused' $Job $SourceInspection $Plan).Succeeded | Should -BeFalse
    }
    It 'ignores duration of omitted streams when comparing the retained selection [A02]' {
        $doc=New-ValidationDocument -VideoDuration '1' -Duration '100'
        $doc.streams += [pscustomobject]@{index=9;codec_type='audio';codec_name='aac';duration='100';disposition=[pscustomobject]@{default=0}}
        $doc.streams += [pscustomobject]@{index=8;codec_type='audio';codec_name='aac';duration='1';channels=2;sample_rate='48000';disposition=[pscustomobject]@{default=1}}
        $SourceInspection=Convert-ValidationDocument $doc;$Plan=Get-StreamPlan $SourceInspection
        $script:OutputDocument=New-ValidationDocument -Audio -VideoDuration '1' -AudioDuration '1' -Duration '1'
        (Get-OutputValidation 'unused' $Job $SourceInspection $Plan).Succeeded | Should -BeTrue
    }
    It 'allows unknown source duration with explicit unavailable-comparison warnings [A02]' {
        $SourceInspection=Convert-ValidationDocument (New-ValidationDocument -VideoDuration 'N/A' -Duration 'N/A')
        $result=Get-OutputValidation 'unused' $Job $SourceInspection (Get-StreamPlan $SourceInspection)
        $result.Succeeded | Should -BeTrue
        $result.DurationChecks.Count | Should -Be 0
        ($result.Warnings -join ' ') | Should -Match 'duration is unknown'
    }
    It 'uses only a silent-video container fallback and discloses it [A02]' {
        $OutputDocument.streams[0].duration='N/A'
        $result=Get-OutputValidation 'unused' $Job $SourceInspection $Plan
        $result.Succeeded | Should -BeTrue
        ($result.Warnings -join ' ') | Should -Match 'sole-video container fallback'
    }
    It 'follows deterministic timestamp allowance at <Actual> [A01 A02]' -TestCases @(
        @{Actual='10.25';Pass=$true},@{Actual='10.25001';Pass=$false},@{Actual='9.75';Pass=$true},@{Actual='9.74999';Pass=$false}
    ) {
        param($Actual,$Pass)
        $OutputDocument.streams[0].duration=$Actual;$OutputDocument.format.duration=$Actual
        (Get-OutputValidation 'unused' $Job $SourceInspection $Plan).Succeeded | Should -Be $Pass
    }
    It 'rejects material short-clip truncation while allowing sub-frame timestamp offsets [A02]' -TestCases @(
        @{Reference='0.1';Actual='0.01';Pass=$false},@{Reference='0.04';Actual='0.06';Pass=$true}
    ) {
        param($Reference,$Actual,$Pass)
        $SourceInspection=Convert-ValidationDocument (New-ValidationDocument -VideoDuration $Reference -Duration $Reference)
        $script:OutputDocument=New-ValidationDocument -VideoDuration $Actual -Duration $Actual
        (Get-OutputValidation 'unused' $Job $SourceInspection (Get-StreamPlan $SourceInspection)).Succeeded | Should -Be $Pass
    }
    It 'compares selected stream durations without substituting video for missing aggregate or rebased offsets [A02]' -TestCases @(
        @{SourceFormat='20';OutputFormat='N/A'},@{SourceFormat='30';OutputFormat='20'}
    ) {
        param($SourceFormat,$OutputFormat)
        $SourceDocument=New-ValidationDocument -Audio -VideoDuration '10' -AudioDuration '20' -Duration $SourceFormat
        $script:OutputDocument=New-ValidationDocument -Audio -VideoDuration '10' -AudioDuration '20' -Duration $OutputFormat
        $SourceInspection=Convert-ValidationDocument $SourceDocument;$Plan=Get-StreamPlan $SourceInspection
        $result=Get-OutputValidation 'unused' $Job $SourceInspection $Plan
        $result.Succeeded | Should -BeTrue
        $result.DurationChecks.Count | Should -Be 2
        ($result.Warnings -join ' ') | Should -Match 'aggregate comparison|aggregate comparison is unavailable'
    }
    It 'does not hide major short-clip truncation under the positive timestamp-padding floor [A02]' {
        $SourceDocument=New-ValidationDocument -VideoDuration '0.1' -Duration '0.1'
        $script:OutputDocument=New-ValidationDocument -VideoDuration '0.051' -Duration '0.051'
        $SourceInspection=Convert-ValidationDocument $SourceDocument;$Plan=Get-StreamPlan $SourceInspection
        (Get-OutputValidation 'unused' $Job $SourceInspection $Plan).Succeeded | Should -BeFalse
    }
    It 'bounds fractional/low/missing frame-rate tolerance [A02]' -TestCases @(
        @{Rate='30000/1001';Expected=0.25},@{Rate='1/10';Expected=2.0},@{Rate='0/0';Expected=0.25}
    ) {
        param($Rate,$Expected)
        $SourceDocument.streams[0].avg_frame_rate=$Rate
        $Plan=Get-StreamPlan (Convert-ValidationDocument $SourceDocument)
        Get-OutputDurationTolerance $Plan | Should -Be $Expected
    }
    It 'checks height-cap width plausibility without changing geometry [A01]' -TestCases @(@{Width=1920;Pass=$true},@{Width=320;Pass=$false}) {
        param($Width,$Pass)
        $SourceDocument.streams[0].width=3840;$SourceDocument.streams[0].height=2160
        $SourceInspection=Convert-ValidationDocument $SourceDocument;$Plan=Get-StreamPlan $SourceInspection
        $OutputDocument.streams[0].width=$Width;$OutputDocument.streams[0].height=1080
        (Get-OutputValidation 'unused' $Job $SourceInspection $Plan).Succeeded | Should -Be $Pass
    }
    It 'recognizes only a generated tmcd track matching selected video timecode [A01]' -TestCases @(@{Matches=$true},@{Matches=$false}) {
        param($Matches)
        $SourceDocument.streams[0] | Add-Member tags ([pscustomobject]@{timecode='01:02:03:04'})
        $SourceInspection=Convert-ValidationDocument $SourceDocument;$Plan=Get-StreamPlan $SourceInspection
        $OutputDocument.streams[0] | Add-Member tags ([pscustomobject]@{timecode=$(if ($Matches){'01:02:03:04'}else{'00:00:00:00'})})
        $OutputDocument.streams += [pscustomobject]@{index=9;codec_type='data';codec_tag_string='tmcd';tags=[pscustomobject]@{timecode='01:02:03:04'}}
        (Get-OutputValidation 'unused' $Job $SourceInspection $Plan).Succeeded | Should -Be $Matches
    }
    It 'accepts generated format timecode, including priority over a different video tag [A01]' -TestCases @(
        @{VideoTimecode=$null},@{VideoTimecode='00:00:00:00'}
    ) {
        param($VideoTimecode)
        $SourceDocument.format | Add-Member tags ([pscustomobject]@{timecode='01:02:03:04'})
        $SourceDocument.streams[0] | Add-Member tags ([pscustomobject]@{timecode=$VideoTimecode})
        $SourceInspection=Convert-ValidationDocument $SourceDocument;$Plan=Get-StreamPlan $SourceInspection
        $OutputDocument.streams[0] | Add-Member tags ([pscustomobject]@{timecode='01:02:03:04'})
        $OutputDocument.streams += [pscustomobject]@{index=9;codec_type='data';codec_tag_string='tmcd';tags=[pscustomobject]@{timecode='01:02:03:04'}}
        (Get-OutputValidation 'unused' $Job $SourceInspection $Plan).Succeeded | Should -BeTrue
    }
    It 'refuses missing/mismatched tmcd metadata and its unsafe video-duration fallback [A01 A02]' -TestCases @(
        @{Timecode=$null;VideoDuration='10'},@{Timecode='00:00:00:00';VideoDuration='10'},@{Timecode='01:02:03:04';VideoDuration='N/A'}
    ) {
        param($Timecode,$VideoDuration)
        $SourceDocument.streams[0] | Add-Member tags ([pscustomobject]@{timecode='01:02:03:04'})
        $SourceInspection=Convert-ValidationDocument $SourceDocument;$Plan=Get-StreamPlan $SourceInspection
        $OutputDocument.streams[0] | Add-Member tags ([pscustomobject]@{timecode='01:02:03:04'})
        $OutputDocument.streams[0].duration=$VideoDuration
        $OutputDocument.streams += [pscustomobject]@{index=9;codec_type='data';codec_tag_string='tmcd';tags=[pscustomobject]@{timecode=$Timecode}}
        (Get-OutputValidation 'unused' $Job $SourceInspection $Plan).Succeeded | Should -BeFalse
    }
}

Describe 'Validation precedes final publication [WVC-M2-05-A03/A04]' {
    BeforeEach {
        Initialize-ValidationFixture
        $script:LastJob=$null
        $script:Counters=[pscustomobject]@{Done=0;Skipped=0;Failed=0}
        Mock Write-Host {}
        Mock Invoke-OutputDecodeCheck {throw 'Normal conversions must not run the optional decode check.'}
        Mock Get-MediaInspection {
            if ($InputPath -eq $script:SourcePath) {return $script:SourceInspection}
            Convert-ValidationDocument $script:OutputDocument
        }
        Mock Invoke-EncodeProcess {
            Write-ValidationHeader $Arguments[-1]
            [pscustomobject]@{Succeeded=$true;StdOutTruncated=$false;StdErrTruncated=$false}
        }
    }
    It 'counts Done only after validation and no-clobber promotion' {
        Compress-One 'unused' 'unused' $SourcePath $Output 22 ([ref]$Counters)
        $Counters.Done | Should -Be 1
        $Counters.Failed | Should -Be 0
        Test-Path -LiteralPath $Final | Should -BeTrue
        Should -Invoke Get-MediaInspection -Times 2
        Should -Invoke Invoke-OutputDecodeCheck -Times 0 -Exactly
    }
    It 'retains failed validation with source/job identity and no new final or changed sentinels' {
        [IO.File]::WriteAllText($Final,'existing final sentinel');$hash=(Get-FileHash -LiteralPath $Final).Hash
        $OutputDocument.streams[0].duration='1';$OutputDocument.format.duration='1'
        Compress-One 'unused' 'unused' $SourcePath $Output 22 ([ref]$Counters)
        $Counters.Done | Should -Be 0;$Counters.Failed | Should -Be 1
        $partials=@(Get-ChildItem -LiteralPath $Output -Recurse -Filter 'encode.partial.mp4')
        $partials.Count | Should -Be 1
        $record=Get-Content -LiteralPath (Join-Path $partials[0].DirectoryName 'retained.json') -Raw | ConvertFrom-Json
        $record.Stage | Should -BeExactly 'Validation'
        $record.Reason | Should -Match ([regex]::Escape($record.JobId))
        $record.SourcePath | Should -BeExactly $SourcePath
        @(Get-ChildItem -LiteralPath $Output -File).Count | Should -Be 1
        (Get-FileHash -LiteralPath $Final).Hash | Should -BeExactly $hash
        (Get-FileHash -LiteralPath $SourcePath).Hash | Should -BeExactly $SourceHash
    }
    It 'keeps valid-but-unpromoted sharing failure out of Done' {
        Mock Move-OutputFileNoClobber {throw 'Injected promotion sharing failure'}
        Compress-One 'unused' 'unused' $SourcePath $Output 22 ([ref]$Counters)
        $Counters.Done | Should -Be 0;$Counters.Failed | Should -Be 1
        Test-Path -LiteralPath $Final | Should -BeFalse
    }
}

Describe 'Explicit optional output decode check [WVC-M2-05]' {
    BeforeEach {
        Initialize-ValidationFixture
        $script:Job=New-OutputJob $SourcePath $Output $Final $Final
        Write-ValidationHeader $Job.TempPath
        Mock Get-MediaInspection {Convert-ValidationDocument $script:OutputDocument}
        $script:Validation=Get-OutputValidation 'unused' $Job $SourceInspection $Plan
        Mock Invoke-EncodeProcess {
            $script:DecodeArguments=@($Arguments)
            [pscustomobject]@{Succeeded=$true;FailureKind=$null;Error=$null}
        }
    }
    AfterEach {[void](Close-OutputJob $Job $false 'Test' 'owned synthetic fixture')}
    It 'maps validated output indices to a literal null sink without encoding or publication' {
        $hash=(Get-FileHash -LiteralPath $Job.TempPath).Hash
        (Invoke-OutputDecodeCheck 'unused' $Job $Validation).Succeeded | Should -BeTrue
        $DecodeArguments | Should -Contain '-xerror'
        $DecodeArguments | Should -Contain 'empty_output_stream'
        $DecodeArguments | Should -Contain '0:3'
        $DecodeArguments[-2] | Should -BeExactly 'null'
        $DecodeArguments[-1] | Should -BeExactly 'NUL'
        @($DecodeArguments | Where-Object {$_ -in @('-c:v','-crf','-y')}).Count | Should -Be 0
        (Get-FileHash -LiteralPath $Job.TempPath).Hash | Should -BeExactly $hash
        Test-Path -LiteralPath $Final | Should -BeFalse
    }
    It 'refuses another job or failed structural record before native decode' {
        $Validation.JobId='wrong-job'
        {Invoke-OutputDecodeCheck 'unused' $Job $Validation} | Should -Throw
        Should -Invoke Invoke-EncodeProcess -Times 0
    }
    It 'reports a decoder error with job/source identity and retained diagnostics' {
        Mock Invoke-EncodeProcess {[pscustomobject]@{Succeeded=$false;FailureKind='NonZeroExit';Error='exit17';StdErr='decoder sentinel'}}
        $result=Invoke-OutputDecodeCheck 'unused' $Job $Validation
        $result.Succeeded | Should -BeFalse
        $result.Reason | Should -Match ([regex]::Escape($Job.JobId))
        $result.Native.StdErr | Should -BeExactly 'decoder sentinel'
    }
}
