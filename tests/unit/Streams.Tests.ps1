BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:OriginalEnvironment = @{ APPDATA=$env:APPDATA; WVC_PROBE_JSON=$env:WVC_PROBE_JSON;
        WVC_PROBE_MODE=$env:WVC_PROBE_MODE; WVC_PROBE_ARGV=$env:WVC_PROBE_ARGV; WVC_STREAM_ARGV=$env:WVC_STREAM_ARGV }
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    $ps51 = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $script:ProbeExe = Join-Path $TestDrive 'probe.exe'
    $script:EncoderExe = Join-Path $TestDrive 'encoder.exe'
    foreach ($definition in @(@{Script='New-ProbeFixture.ps1';Output=$ProbeExe},@{Script='New-StreamFixture.ps1';Output=$EncoderExe})) {
        $compiled = Invoke-WvcTestProcess $ps51 @('-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot $definition.Script),'-Destination',$definition.Output)
        if ($compiled.ExitCode -ne 0) { throw ('Native stream fixture compilation failed: ' + $compiled.StdErr) }
    }
    $script:MultiJson = '{"streams":[{"index":9,"codec_type":"video","codec_name":"h264","width":3840,"height":2160,"disposition":{"default":1}},{"index":7,"codec_type":"audio","codec_name":"aac","channels":6,"sample_rate":"48000","channel_layout":"5.1","tags":{"language":"fin"},"disposition":{"default":1,"original":1}},{"index":3,"codec_type":"video","codec_name":"h264","width":1280,"height":720,"disposition":{"default":0}},{"index":1,"codec_type":"audio","codec_name":"aac","channels":2,"disposition":{"default":0}},{"index":10,"codec_type":"subtitle","codec_name":"subrip"},{"index":11,"codec_type":"data"},{"index":12,"codec_type":"attachment"},{"index":14,"codec_type":"unknown"}],"format":{"duration":"1"}}'
    function Set-StreamJson([string]$Json) { [IO.File]::WriteAllText($env:WVC_PROBE_JSON,$Json,(New-Object Text.UTF8Encoding($false))) }
    function Read-EncoderArguments {
        @(Get-Content -LiteralPath $env:WVC_STREAM_ARGV | Where-Object { $_ -ne 'CALL' } | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) })
    }
    function Read-Maps([string[]]$Arguments) {
        for ($i=0; $i -lt $Arguments.Count; $i++) { if ($Arguments[$i] -eq '-map') { $Arguments[$i+1] } }
    }
}
AfterAll { foreach ($key in $OriginalEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key,$OriginalEnvironment[$key],'Process') } }

Describe 'One explicit video/audio stream plan [WVC-M2-02]' {
    BeforeEach {
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Output = Join-Path $Root 'output'
        [void][IO.Directory]::CreateDirectory($Output)
        $script:Source = Join-Path $Root ("Band & !NAME! %PATH% [x] O'Brien " + [char]0xe4 + [char]0x4e2d + ' 29092025.mov')
        [IO.File]::WriteAllText($Source,'synthetic source sentinel')
        $env:WVC_PROBE_JSON = Join-Path $Root 'probe.json'
        $env:WVC_PROBE_ARGV = Join-Path $Root 'probe-argv.txt'
        $env:WVC_STREAM_ARGV = Join-Path $Root 'encode-argv.txt'
        $env:WVC_PROBE_MODE = ''
        Set-StreamJson $MultiJson
        $script:Counters = [pscustomobject]@{ Done=0; Skipped=0; Failed=0 }
        Mock Write-Host {}
    }

    It 'carries the inspected first real video reference despite later default/larger alternatives' {
        $inspection = ConvertFrom-ProbeJson $MultiJson
        $before = $inspection | ConvertTo-Json -Depth 20
        $plan = Get-StreamPlan $inspection
        $plan.VideoIndex | Should -Be 3
        [object]::ReferenceEquals($inspection.PrimaryVideo,$plan.Video) | Should -BeTrue
        $plan.Video.Height | Should -Be 720
        $plan.VideoSelection | Should -Be 'FirstRealByIndex'
        ($inspection | ConvertTo-Json -Depth 20) | Should -BeExactly $before
    }

    It 'selects the unique default audio and preserves nullable metadata and disposition flags' {
        $plan = Get-StreamPlan (ConvertFrom-ProbeJson $MultiJson)
        $plan.AudioIndex | Should -Be 7
        $plan.AudioSelection | Should -Be 'UniqueDefault'
        $plan.Audio.Channels | Should -Be 6
        $plan.Audio.ChannelLayout | Should -Be '5.1'
        $plan.Audio.SampleRate | Should -Be 48000
        $plan.Audio.Language | Should -Be 'fin'
        $plan.Audio.Disposition.Flags.original | Should -Be 1
    }

    It 'falls back to first audio for <Case>, including a lower nondefault stream' -TestCases @(
        @{Case='zero defaults';Defaults=@(0,0,0)}, @{Case='multiple defaults';Defaults=@(0,1,1)}
    ) {
        param($Case,$Defaults)
        $document = $MultiJson | ConvertFrom-Json
        $document.streams = @($document.streams | Where-Object codec_type -ne 'audio') + @(
            [pscustomobject]@{index=8;codec_type='audio';disposition=[pscustomobject]@{default=$Defaults[2]}},
            [pscustomobject]@{index=1;codec_type='audio';disposition=[pscustomobject]@{default=$Defaults[0]}},
            [pscustomobject]@{index=7;codec_type='audio';disposition=[pscustomobject]@{default=$Defaults[1]}})
        $plan = Get-StreamPlan (ConvertFrom-ProbeJson ($document | ConvertTo-Json -Depth 10))
        $plan.AudioIndex | Should -Be 1
        $plan.AudioSelection | Should -Be 'FirstByIndex'
        $plan.Audio.Channels | Should -BeNullOrEmpty
        ($plan.OmittedStreams | Where-Object CodecType -eq 'audio').Index -join ',' | Should -Be '7,8'
    }

    It 'reports all discarded indices/types and distinct reasons' {
        $plan = Get-StreamPlan (ConvertFrom-ProbeJson $MultiJson)
        ($plan.OmittedStreams.Index -join ',') | Should -Be '1,9,10,11,12,14'
        ($plan.OmittedStreams.CodecType -join ',') | Should -Be 'audio,video,subtitle,data,attachment,unknown'
        @($plan.OmittedStreams | Where-Object { [string]::IsNullOrWhiteSpace($_.Reason) }).Count | Should -Be 0
        Write-StreamPlan $plan
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Video stream: 3*1280x720*' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Audio stream: 7*6 channels*5.1*48000*fin*unique default audio*' }
        foreach ($stream in $plan.OmittedStreams) {
            $script:ExpectedOmission = '*Omitting stream ' + $stream.Index + ' (' + $stream.CodecType + ')*'
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like $script:ExpectedOmission }
        }
    }

    It 'maps precisely the inspected absolute indices in one native encode and uses the same coded height' {
        Compress-One $EncoderExe $ProbeExe $Source $Output $DefaultCRF ([ref]$Counters)
        $Counters.Done | Should -Be 1
        $arguments = Read-EncoderArguments
        ((Read-Maps $arguments) -join ',') | Should -BeExactly '0:3,0:7'
        $arguments | Should -Not -Contain '-vf'
        @($arguments | Where-Object { $_ -in @('-ac','-ar','-r','-filter_complex','-disposition:a:0') }).Count | Should -Be 0
        $arguments[[array]::IndexOf($arguments,'-i')+1] | Should -BeExactly $Source
        @((Get-Content -LiteralPath $env:WVC_PROBE_ARGV) | Where-Object { $_ -eq 'CALL' }).Count | Should -Be 1
        @((Get-Content -LiteralPath $env:WVC_STREAM_ARGV) | Where-Object { $_ -eq 'CALL' }).Count | Should -Be 1
    }

    It 'caps the mapped first video when a smaller alternative is present' {
        $document = $MultiJson | ConvertFrom-Json
        $document.streams[2].height = 2160
        $document.streams[0].height = 720
        Set-StreamJson ($document | ConvertTo-Json -Depth 10)
        Compress-One $EncoderExe $ProbeExe $Source $Output $DefaultCRF ([ref]$Counters)
        $arguments = Read-EncoderArguments
        ((Read-Maps $arguments) -join ',') | Should -BeExactly '0:3,0:7'
        $arguments[[array]::IndexOf($arguments,'-vf')+1] | Should -BeExactly 'scale=-2:1080'
    }

    It 'omits oversized cover artwork without mistaking it for video or applying its height cap' {
        $document = Get-Content (Join-Path $RepoRoot 'tests/fixtures/probe/attached-picture.json') -Raw | ConvertFrom-Json
        $document.streams[0].height = 4000
        $document.streams[1].height = 720
        Set-StreamJson ($document | ConvertTo-Json -Depth 10)
        $plan = Get-StreamPlan (ConvertFrom-ProbeJson ($document | ConvertTo-Json -Depth 10))
        $plan.VideoIndex | Should -Be 3
        $plan.OmittedStreams[0].Reason | Should -Be 'AttachedPicture'
        Compress-One $EncoderExe $ProbeExe $Source $Output $DefaultCRF ([ref]$Counters)
        $arguments = Read-EncoderArguments
        ((Read-Maps $arguments) -join ',') | Should -BeExactly '0:3,0:7'
        $arguments | Should -Not -Contain '-vf'
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Omitting stream 0 (video)*attached artwork*' }
    }

    It 'permits silence without invented audio, audio options or hidden stream mappings' {
        Set-StreamJson '{"streams":[{"index":4,"codec_type":"video","codec_name":"h264","width":320,"height":240}]}'
        $plan = Get-StreamPlan (Get-MediaInspection $ProbeExe $Source)
        $plan.Audio | Should -BeNullOrEmpty
        $plan.AudioIndex | Should -BeNullOrEmpty
        $plan.AudioSelection | Should -Be 'None'
        Compress-One $EncoderExe $ProbeExe $Source $Output $DefaultCRF ([ref]$Counters)
        $arguments = Read-EncoderArguments
        ((Read-Maps $arguments) -join ',') | Should -BeExactly '0:4'
        @($arguments | Where-Object { $_ -in @('-c:a','-b:a','-ac','-ar') }).Count | Should -Be 0
        $Counters.Done | Should -Be 1
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Audio stream: none*' }
    }

    It 'reports unknown channel/layout/language values without fabricating stereo' {
        $document = $MultiJson | ConvertFrom-Json
        $document.streams = @($document.streams | Where-Object codec_type -ne 'audio') + @([pscustomobject]@{index=2;codec_type='audio'})
        $plan = Get-StreamPlan (ConvertFrom-ProbeJson ($document | ConvertTo-Json -Depth 10))
        $plan.Audio.Channels | Should -BeNullOrEmpty
        Write-StreamPlan $plan
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Audio stream: 2*unknown channels*' }
    }

    It 'preserves source/existing-final hashes and no-clobber/default quality tokens' {
        $final = Join-Path $Output ([IO.Path]::GetFileNameWithoutExtension($Source)+'.mp4')
        [IO.File]::WriteAllText($final,'existing final sentinel')
        $sourceHash = (Get-FileHash -LiteralPath $Source).Hash
        $finalHash = (Get-FileHash -LiteralPath $final).Hash
        Compress-One $EncoderExe $ProbeExe $Source $Output $DefaultCRF ([ref]$Counters)
        $arguments = Read-EncoderArguments
        foreach ($token in @('-n','libx264','veryfast','22','aac','160k','+faststart')) { $arguments | Should -Contain $token }
        [IO.Path]::GetFileName($arguments[-1]) | Should -BeExactly 'encode.partial.mp4'
        Test-Path -LiteralPath (Join-Path $Output ([IO.Path]::GetFileNameWithoutExtension($Source)+' (compressed).mp4')) | Should -BeTrue
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $sourceHash
        (Get-FileHash -LiteralPath $final).Hash | Should -BeExactly $finalHash
        @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 2
    }

    It 'refuses plans for failed inspection without launching a native encoder' {
        { Get-StreamPlan (ConvertFrom-ProbeJson '{"streams":[]}') } | Should -Throw
        Set-StreamJson '{"streams":[]}'
        Compress-One $EncoderExe $ProbeExe $Source $Output $DefaultCRF ([ref]$Counters)
        $Counters.Failed | Should -Be 1
        Test-Path -LiteralPath $env:WVC_STREAM_ARGV | Should -BeFalse
    }

    It 'rejects malformed stream-type arrays instead of treating them as an explicit unknown type' {
        $result = ConvertFrom-ProbeJson '{"streams":[{"index":0,"codec_type":["unknown"]},{"index":3,"codec_type":"video","codec_name":"h264","width":320,"height":240}]}'
        $result.Succeeded | Should -BeFalse
        $result.FailureKind | Should -Be 'InvalidStructure'
    }
}
