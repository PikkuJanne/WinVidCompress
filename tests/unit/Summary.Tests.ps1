BeforeAll {
    $script:SavedAppData=$env:APPDATA
    $env:APPDATA=Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
}
AfterAll { $env:APPDATA=$script:SavedAppData }

Describe 'Honest size and time summaries [WVC-M3-04-A01/A02]' {
    It 'labels <Label> without reversing the legacy signed delta' -TestCases @(
        @{InputSize=100;OutputSize=40;Label='Reduction';Saved=60;Delta=-60},
        @{InputSize=100;OutputSize=140;Label='Growth';Saved=-40;Delta=40},
        @{InputSize=100;OutputSize=100;Label='Unchanged';Saved=0;Delta=0},
        @{InputSize=100;OutputSize=0;Label='Reduction';Saved=100;Delta=-100}
    ) {
        param($InputSize,$OutputSize,$Label,$Saved,$Delta)
        $size=Get-SizeAccounting 'Completed' $InputSize $OutputSize
        $size.State | Should -BeExactly $Label
        $size.SavingsPercent | Should -Be $Saved
        $size.SizeChangeBytes | Should -Be $Delta
        $size.SizeChangePercent | Should -Be $Delta
        (Format-SizeAccounting $size) | Should -Match $Label.ToLowerInvariant()
    }

    It 'does not calculate a ratio for <Case>' -TestCases @(
        @{Case='zero input';InputSize=0;OutputSize=10;State='ZeroInput'},
        @{Case='both zero';InputSize=0;OutputSize=0;State='ZeroInput'},
        @{Case='unknown input';InputSize=$null;OutputSize=10;State='Unknown'},
        @{Case='unknown output';InputSize=100;OutputSize=$null;State='Unknown'}
    ) {
        param($Case,$InputSize,$OutputSize,$State)
        $size=Get-SizeAccounting 'Completed' $InputSize $OutputSize
        $size.State | Should -BeExactly $State
        $size.SavingsPercent | Should -BeNullOrEmpty
        $size.SizeChangePercent | Should -BeNullOrEmpty
        (Format-SizeAccounting $size) | Should -Match 'percentage unavailable'
    }

    It 'never counts <Outcome> as produced bytes' -TestCases @(
        @{Outcome='Cancelled'},@{Outcome='Failed'},@{Outcome='Skipped'},@{Outcome='Unstarted'}
    ) {
        param($Outcome)
        $size=Get-SizeAccounting $Outcome 100 10
        $size.State | Should -BeExactly 'NotProduced'
        $size.OutputBytes | Should -BeNullOrEmpty
        $size.SavingsPercent | Should -BeNullOrEmpty
        $size.SizeChangeBytes | Should -BeNullOrEmpty
    }

    It 'weights completed pairs by bytes and discloses unknown sizes and durations' {
        $jobs=@()
        foreach ($entry in @(
            @{Outcome='Completed';InputSize=100;OutputSize=50;Duration=2},
            @{Outcome='Completed';InputSize=900;OutputSize=1000;Duration=8},
            @{Outcome='Completed';InputSize=$null;OutputSize=12;Duration=$null},
            @{Outcome='Completed';InputSize=0;OutputSize=10;Duration=1},
            @{Outcome='Cancelled';InputSize=1000;OutputSize=1;Duration=3}
        )) {
            $job=New-JobResult 'opaque' 22
            $job.Outcome=$entry.Outcome;$job.InputBytes=$entry.InputSize;$job.OutputBytes=$entry.OutputSize
            $job.DurationSeconds=$entry.Duration;$job.ElapsedSeconds=2
            $jobs+=$job
        }
        $batch=Get-BatchResult $jobs @() -Requested
        $batch.SizeSummary.ComparableJobs | Should -Be 2
        $batch.SizeSummary.UnavailableJobs | Should -Be 2
        $batch.SizeSummary.ExcludedJobs | Should -Be 1
        $batch.SizeSummary.Accounting.InputBytes | Should -Be 1000
        $batch.SizeSummary.Accounting.OutputBytes | Should -Be 1050
        $batch.SizeSummary.Accounting.SavingsPercent | Should -Be -5
        $batch.SizeSummary.Accounting.State | Should -BeExactly 'Growth'
        $batch.DurationSeconds | Should -Be 11
        $batch.DurationKnownJobs | Should -Be 3
        $batch.DurationUnknownJobs | Should -Be 1
        $batch.ElapsedSeconds | Should -Be 10
        $batch.ExitCode | Should -Be 3
    }

    It 'does not fabricate totals for an empty or wholly unavailable batch' {
        $batch=Get-BatchResult @() @()
        $batch.SizeSummary.Accounting.SavingsPercent | Should -BeNullOrEmpty
        $batch.SizeSummary.Accounting.InputBytes | Should -BeNullOrEmpty
        $batch.DurationSeconds | Should -BeNullOrEmpty
    }

    It 'prints literal bytes, growth and measured elapsed time with unknown duration' {
        $job=New-JobResult 'opaque' 22
        $job.Outcome='Completed';$job.InputBytes=100;$job.OutputBytes=140;$job.ElapsedSeconds=1.25
        $text=Format-JobSummary $job
        $text | Should -Match '100 bytes -> 140 bytes'
        $text | Should -Match '40.00% growth'
        $text | Should -Match 'duration unavailable'
        $text | Should -Match 'elapsed 1.25 s'
    }

    It 'keeps the quality profile unchanged and promises no fixed reduction in user copy' {
        $DefaultCRF | Should -Be 22
        $job=New-JobResult 'opaque' 22
        $job.Settings.Preset | Should -BeExactly 'veryfast'
        $job.Settings.VideoCodec | Should -BeExactly 'libx264'
        $job.Settings.AudioBitrate | Should -BeExactly '160k'
        $readme=Get-Content -Raw -LiteralPath (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'README.md')
        $readme | Should -Match 'Results vary'
        $readme | Should -Not -Match '(?i)(?:save|reduc(?:e|tion)|shrink)\s+(?:by\s+|up to\s+)?\d+(?:\.\d+)?\s*%'
    }

    It 'includes a published completion after accounting/display cancellation while returning exit3' {
        $job=New-JobResult 'opaque' 22
        $job.Outcome='Completed';$job.InputBytes=100;$job.OutputBytes=50;$job.CancellationRequested=$true
        $batch=Get-BatchResult @($job) @() -Requested
        $batch.ExitCode | Should -Be 3
        $batch.SizeSummary.ComparableJobs | Should -Be 1
        $batch.SizeSummary.Accounting.SavingsPercent | Should -Be 50
    }

    It 'retains the container-only duration policy when both selected source durations are unavailable' {
        $source=ConvertFrom-ProbeJson '{"format":{"format_name":"matroska","duration":"1"},"streams":[{"index":0,"codec_type":"video","codec_name":"ffv1","pix_fmt":"yuv420p","width":320,"height":240},{"index":1,"codec_type":"audio","codec_name":"pcm_s16le","channels":1,"sample_rate":"48000"}]}'
        $output=ConvertFrom-ProbeJson '{"format":{"format_name":"mov,mp4","duration":"1"},"streams":[{"index":0,"codec_type":"video","codec_name":"h264","pix_fmt":"yuv420p","width":320,"height":240,"duration":"1"},{"index":1,"codec_type":"audio","codec_name":"aac","duration":"1","channels":1,"sample_rate":"48000"}]}'
        $validation=Test-OutputStructure $output $source (Get-StreamPlan $source)
        $validation.DurationChecks.Count | Should -Be 0
        ($validation.Warnings -join '|') | Should -Match 'Source video duration is unknown'
        ($validation.Warnings -join '|') | Should -Match 'Source audio duration is unknown'
        ($validation.Warnings -join '|') | Should -Match 'aggregate comparison is unavailable'
    }
}
