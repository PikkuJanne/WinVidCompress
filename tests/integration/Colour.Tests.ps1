BeforeDiscovery {
    $script:ColourToolsAvailable=[bool](Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue) -and
        [bool](Get-Command ffprobe.exe -CommandType Application -ErrorAction SilentlyContinue)
}
BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    . (Join-Path $PSScriptRoot 'ColourTestSupport.ps1')
    $script:SavedEnvironment=@{APPDATA=$env:APPDATA;FFREPORT=$env:FFREPORT}
    $script:BootstrapOwner=New-WvcTestRoot
    $env:APPDATA=Join-Path $BootstrapOwner.Path 'appdata';$env:FFREPORT=$null
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    if ($ColourToolsAvailable) {
        $script:ColourEncoder=(Get-Command ffmpeg.exe -CommandType Application).Source
        $script:ColourProbe=(Get-Command ffprobe.exe -CommandType Application).Source
    }
    function Invoke-ColourCompression($SourcePath) {
        try {Compress-One $ColourEncoder $ColourProbe $SourcePath $Output 22}
        catch {
            if ($_.Exception.Data.Contains('WvcAbortBatch')) {$script:WvcProcessCleanupFailed=$true}
            throw
        }
    }
}
AfterAll {
    foreach ($key in $SavedEnvironment.Keys) {[Environment]::SetEnvironmentVariable($key,$SavedEnvironment[$key],'Process')}
    if (-not (Get-Variable WvcProcessCleanupFailed -Scope Script -ErrorAction SilentlyContinue)) {Remove-WvcTestRoot $BootstrapOwner}
}

Describe 'Actual SDR compatibility and HDR refusal [WVC-M3-02-A01/A02/A03; FFmpeg/FFprobe required]' {
    BeforeEach {
        if (Get-Variable WvcProcessCleanupFailed -Scope Script -ErrorAction SilentlyContinue) {throw 'Process cleanup failed; retain roots and stop.'}
        $script:Owner=New-WvcTestRoot
        $env:APPDATA=Join-Path $Owner.Path 'appdata'
        $script:Output=Join-Path $Owner.Path 'output';[void][IO.Directory]::CreateDirectory($Output)
        $script:Source=Join-Path $Owner.Path 'colour.mkv'
        $script:Sentinel=Join-Path $Output 'colour.mp4';[IO.File]::WriteAllText($Sentinel,'existing final sentinel')
        $script:FinalHash=(Get-FileHash -LiteralPath $Sentinel).Hash
        $script:CollisionMode='rename'
    }
    AfterEach {
        if (Test-Path -LiteralPath $Sentinel) {(Get-FileHash -LiteralPath $Sentinel).Hash | Should -BeExactly $FinalHash}
        if ($null -ne $Owner -and -not (Get-Variable WvcProcessCleanupFailed -Scope Script -ErrorAction SilentlyContinue)) {Remove-WvcTestRoot $Owner}
    }
    It 'encodes <Name> to 8bit yuv420p, retains tags and checks decoded ramp samples' -Skip:(-not $ColourToolsAvailable) -TestCases @(
        @{Name='8bit SDR';Pixels='yuv420p';Range='tv';Transfer='bt709';Primaries='bt709';Matrix='bt709'},
        @{Name='10bit SDR';Pixels='yuv420p10le';Range='tv';Transfer='bt709';Primaries='bt709';Matrix='bt709'},
        @{Name='422 SDR';Pixels='yuv422p10le';Range='tv';Transfer='bt709';Primaries='bt709';Matrix='bt709'},
        @{Name='444 SDR';Pixels='yuv444p';Range='tv';Transfer='bt709';Primaries='bt709';Matrix='bt709'},
        @{Name='10bit full range';Pixels='yuv420p10le';Range='pc';Transfer='bt709';Primaries='bt709';Matrix='bt709'},
        @{Name='8bit full range';Pixels='yuvj420p';Range='pc';Transfer='bt709';Primaries='bt709';Matrix='bt709'},
        @{Name='601 SDR';Pixels='yuv420p';Range='tv';Transfer='smpte170m';Primaries='smpte170m';Matrix='smpte170m'},
        @{Name='2020 SDR';Pixels='yuv420p10le';Range='tv';Transfer='bt2020-10';Primaries='bt2020';Matrix='bt2020nc'}
    ) {
        param($Name,$Pixels,$Range,$Transfer,$Primaries,$Matrix)
        New-ColourSample $ColourEncoder $Source $Pixels $Range $Transfer $Primaries $Matrix
        $sourceHash=(Get-FileHash -LiteralPath $Source).Hash
        $inspection=Get-MediaInspection $ColourProbe $Source
        $inspection.Succeeded | Should -BeTrue
        $inspection.PrimaryVideo.PixelFormat | Should -BeExactly $Pixels
        $inspection.PrimaryVideo.ColourRange | Should -BeExactly $Range
        (Get-VideoColourPlan $inspection.PrimaryVideo).State | Should -Be 'SDR'
        $job=Invoke-ColourCompression $Source
        $job.Outcome | Should -Be 'Completed' -Because $job.Reason
        $video=$job.Diagnostics.Validation.Inspection.PrimaryVideo
        $video.PixelFormat | Should -BeExactly 'yuv420p'
        $video.ColourTransfer | Should -BeExactly $Transfer
        $video.ColourPrimaries | Should -BeExactly $Primaries
        $video.ColourMatrix | Should -BeExactly $Matrix
        $video.ColourRange | Should -BeExactly 'tv'
        $video.Width | Should -Be 640;$video.Height | Should -Be 360
        $bytes=Get-ColourLuma $ColourEncoder $job.OutputPath (Join-Path $Owner.Path 'decoded.yuv')
        foreach ($x in @(0,160,320,480,639)) {
            $expected=16+219*$x/639.0
            [Math]::Abs($bytes[180*640+$x]-$expected) | Should -BeLessOrEqual 3
            [Math]::Abs($bytes[640*360+90*320+[int][Math]::Floor($x/2.0)]-128) | Should -BeLessOrEqual 2
        }
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $sourceHash
        @(Get-ChildItem -LiteralPath $Output -File).Count | Should -Be 2
        @(Get-ChildItem -LiteralPath $Output -Directory -Filter '.wvc-job-*').Count | Should -Be 0
    }
    It 'keeps tagged <Transfer> chroma patches close to the decoded source' -Skip:(-not $ColourToolsAvailable) -TestCases @(
        @{Transfer='bt709'},@{Transfer='smpte170m'}
    ) {
        param($Transfer)
        New-ColourSample $ColourEncoder $Source 'yuv420p10le' 'tv' $Transfer $Transfer $Transfer -Pattern Bars
        $sourceHash=(Get-FileHash -LiteralPath $Source).Hash
        $job=Invoke-ColourCompression $Source
        $job.Outcome | Should -Be 'Completed' -Because $job.Reason
        $decoded=@()
        foreach ($path in @($Source,$job.OutputPath)) {
            $raw=Join-Path $Owner.Path (([guid]::NewGuid().ToString('N'))+'.rgb')
            $native=Invoke-WvcTestProcess $ColourEncoder @('-hide_banner','-nostdin','-v','error','-n','-i',$path,
                '-frames:v','1','-pix_fmt','rgb24','-f','rawvideo',$raw)
            $native.ExitCode | Should -Be 0
            $bytes=[IO.File]::ReadAllBytes($raw);$bytes.Length | Should -Be (640*360*3)
            $decoded+=,$bytes
        }
        foreach ($x in @(45,135,225,315,405,495,585)) {
            foreach ($channel in 0..2) {
                $offset=3*(80*640+$x)+$channel
                [Math]::Abs([int]$decoded[0][$offset]-[int]$decoded[1][$offset]) | Should -BeLessOrEqual 12
            }
        }
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $sourceHash
    }
    It 'refuses native <Transfer> metadata without any partial output or changed source/final' -Skip:(-not $ColourToolsAvailable) -TestCases @(
        @{Transfer='smpte2084'},@{Transfer='arib-std-b67'}
    ) {
        param($Transfer)
        New-ColourSample $ColourEncoder $Source 'yuv420p10le' 'tv' $Transfer 'bt2020' 'bt2020nc'
        $sourceHash=(Get-FileHash -LiteralPath $Source).Hash
        (Get-MediaInspection $ColourProbe $Source).PrimaryVideo.ColourTransfer | Should -BeExactly $Transfer
        $job=Invoke-ColourCompression $Source
        $job.Outcome | Should -Be 'Failed';$job.Stage | Should -Be 'Colour'
        $job.Reason | Should -Match 'Unsupported HDR'
        $job.TemporaryPath | Should -BeNullOrEmpty
        @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 1
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $sourceHash
    }
    It 'warns on actual untagged input and keeps output colour unspecified' -Skip:(-not $ColourToolsAvailable) {
        New-ColourSample $ColourEncoder $Source -Untagged
        $job=Invoke-ColourCompression $Source
        $job.Outcome | Should -Be 'Completed' -Because $job.Reason
        ($job.Diagnostics.Warnings -join ' ') | Should -Match 'ambiguous'
        $video=$job.Diagnostics.Validation.Inspection.PrimaryVideo
        $video.PixelFormat | Should -BeExactly 'yuv420p'
        $video.ColourPrimaries | Should -BeNullOrEmpty
        $video.ColourTransfer | Should -BeNullOrEmpty
        $video.ColourMatrix | Should -BeNullOrEmpty
    }
}
