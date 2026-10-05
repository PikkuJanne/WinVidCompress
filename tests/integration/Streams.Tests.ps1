BeforeDiscovery {
    $script:StreamMediaToolsAvailable = [bool](Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue) -and
        [bool](Get-Command ffprobe.exe -CommandType Application -ErrorAction SilentlyContinue)
}
BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:OriginalEnvironment = @{ APPDATA=$env:APPDATA; FFREPORT=$env:FFREPORT }
    $script:BootstrapOwner = New-WvcTestRoot
    $env:APPDATA = Join-Path $BootstrapOwner.Path 'appdata'
    $env:FFREPORT = $null
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    if ((Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue) -and
        (Get-Command ffprobe.exe -CommandType Application -ErrorAction SilentlyContinue)) {
        $script:FFmpegExe = (Get-Command ffmpeg.exe -CommandType Application).Source
        $script:FFprobeExe = (Get-Command ffprobe.exe -CommandType Application).Source
        $script:Definitions = (Get-Content (Join-Path $RepoRoot 'tests/fixtures/inventory.json') -Raw | ConvertFrom-Json).Items
    }
}
AfterAll {
    foreach ($key in $OriginalEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key,$OriginalEnvironment[$key],'Process') }
    Remove-WvcTestRoot $BootstrapOwner
}

Describe 'Installed-tool output stream confirmation [WVC-M2-02; FFmpeg/FFprobe required]' {
    BeforeEach {
        $script:Owner = New-WvcTestRoot
        $env:APPDATA = Join-Path $Owner.Path 'appdata'
        $script:Output = Join-Path $Owner.Path 'output'
        [void][IO.Directory]::CreateDirectory($Output)
        $script:Counters = [pscustomobject]@{Done=0;Skipped=0;Failed=0}
    }
    AfterEach { if ($null -ne $Owner) { Remove-WvcTestRoot $Owner } }

    It 'confirms first inspected video and unique-default audio in actual encoded output' -Skip:(-not $StreamMediaToolsAvailable) {
        $definition = $Definitions | Where-Object Id -eq 'multi-stream'
        $source = Join-Path $Owner.Path $definition.File
        # Make the later video larger: automatic highest-resolution selection would fail this check.
        $arguments = @($definition.Arguments | ForEach-Object {
            if ($_ -eq '{output}') { $source }
            elseif ($_ -eq 'color=c=blue:size=160x120:rate=24:duration=1') { 'color=c=blue:size=640x480:rate=24:duration=1' }
            else { $_ }
        })
        $generated = Invoke-WvcTestProcess $FFmpegExe $arguments
        $generated.ExitCode | Should -Be 0
        $sourceHash = (Get-FileHash -LiteralPath $source).Hash
        $inspection = Get-MediaInspection $FFprobeExe $source
        $plan = Get-StreamPlan $inspection
        $plan.VideoIndex | Should -Be 0
        $plan.AudioIndex | Should -Be 3
        Compress-One $FFmpegExe $FFprobeExe $source $Output $DefaultCRF ([ref]$Counters)
        $Counters.Done | Should -Be 1
        $result = Get-MediaInspection $FFprobeExe (Join-Path $Output 'multi-stream.mp4')
        $result.Succeeded | Should -BeTrue
        $result.RealVideoIndices.Count | Should -Be 1
        $result.Streams.Count | Should -Be 2
        $result.PrimaryVideo.Width | Should -Be $plan.Video.Width
        $result.PrimaryVideo.Height | Should -Be $plan.Video.Height
        $audio = @($result.Streams | Where-Object CodecType -eq 'audio')
        $audio.Count | Should -Be 1
        $audio[0].Channels | Should -Be $plan.Audio.Channels
        $audio[0].Language | Should -Be $plan.Audio.Language
        $audio[0].Disposition.Default | Should -BeTrue
        (Get-FileHash -LiteralPath $source).Hash | Should -BeExactly $sourceHash
    }

    It 'completes actual silent video without adding an audio stream' -Skip:(-not $StreamMediaToolsAvailable) {
        $definition = $Definitions | Where-Object Id -eq 'silent'
        $source = Join-Path $Owner.Path $definition.File
        $arguments = @($definition.Arguments | ForEach-Object { if ($_ -eq '{output}') { $source } else { $_ } })
        (Invoke-WvcTestProcess $FFmpegExe $arguments).ExitCode | Should -Be 0
        $sourceHash = (Get-FileHash -LiteralPath $source).Hash
        Compress-One $FFmpegExe $FFprobeExe $source $Output $DefaultCRF ([ref]$Counters)
        $Counters.Done | Should -Be 1
        $result = Get-MediaInspection $FFprobeExe (Join-Path $Output 'silent.mp4')
        $result.Succeeded | Should -BeTrue
        $result.Streams.Count | Should -Be 1
        $result.PrimaryVideo.CodecType | Should -Be 'video'
        @($result.Streams | Where-Object CodecType -eq 'audio').Count | Should -Be 0
        (Get-FileHash -LiteralPath $source).Hash | Should -BeExactly $sourceHash
    }
}
