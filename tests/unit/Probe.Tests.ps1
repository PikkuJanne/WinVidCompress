BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:OriginalEnvironment = @{ APPDATA = $env:APPDATA; WVC_PROBE_JSON = $env:WVC_PROBE_JSON;
        WVC_PROBE_MODE = $env:WVC_PROBE_MODE; WVC_PROBE_ARGV = $env:WVC_PROBE_ARGV }
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    $script:PS51 = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $script:ProbeExe = Join-Path $TestDrive 'probe.exe'
    $compiled = Invoke-WvcTestProcess $PS51 @('-NoProfile','-NonInteractive','-File',
        (Join-Path $PSScriptRoot 'New-ProbeFixture.ps1'),'-Destination',$ProbeExe)
    if ($compiled.ExitCode -ne 0) { throw "Probe fixture compilation failed: $($compiled.StdErr)" }
    $script:ValidJson = '{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":1920,"height":1080}],"format":{"duration":"1.250000","format_name":"mov,mp4,m4a,3gp,3g2,mj2"}}'
    function Set-ProbeJson([string]$Json) { [IO.File]::WriteAllText($env:WVC_PROBE_JSON, $Json, (New-Object Text.UTF8Encoding($false))) }
    function Read-ProbeFixture([string]$Name) { [IO.File]::ReadAllText((Join-Path $RepoRoot ('tests/fixtures/probe/' + $Name + '.json'))) }
}

AfterAll { foreach ($key in $OriginalEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key, $OriginalEnvironment[$key], 'Process') } }

Describe 'Normalized bounded media inspection [WVC-M2-01]' {
    BeforeEach {
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($Root)
        $script:Output = Join-Path $Root 'output'
        [void][IO.Directory]::CreateDirectory($Output)
        $script:Source = Join-Path $Root ("Band & !NAME! %PATH% [x] O'Brien " + [char]0x00e4 + [char]0x4e2d + ' 29092025.mov')
        [IO.File]::WriteAllText($Source, 'synthetic source sentinel')
        $env:WVC_PROBE_JSON = Join-Path $Root 'response.json'
        $env:WVC_PROBE_ARGV = Join-Path $Root 'argv.txt'
        $env:WVC_PROBE_MODE = ''
        Set-ProbeJson $ValidJson
        $script:Counters = [pscustomobject]@{ Done = 0; Skipped = 0; Failed = 0 }
        $script:Encoded = New-Object 'Collections.Generic.List[object]'
        $script:Encoder = { $script:Encoded.Add(@($args)); $global:LASTEXITCODE = 0 }
        Mock Invoke-EncodeProcess {
            $script:Encoded.Add(@($Arguments))
            [IO.File]::WriteAllText($Arguments[-1],'synthetic encoded sentinel')
            [pscustomobject]@{ Succeeded=$true; StdOutTruncated=$false; StdErrTruncated=$false }
        }
        Mock Write-Host {}
    }

    It 'does exactly one bounded all-stream JSON inspection with literal input tokens' {
        $result = Get-MediaInspection $ProbeExe $Source
        $result.Succeeded | Should -BeTrue
        $result.InputPath | Should -BeExactly $Source
        $result.Native.ExitCode | Should -Be 0
        $result.Native.StdErr | Should -BeLike '*synthetic probe diagnostic*'
        $result.PrimaryVideoIndex | Should -Be 0
        $result.PrimaryVideo.Height | Should -Be 1080
        $result.DurationSeconds | Should -Be 1.25
        $result.DurationState | Should -Be 'Known'
        $result.DurationSource | Should -Be 'Format'
        $lines = @(Get-Content -LiteralPath $env:WVC_PROBE_ARGV)
        @($lines | Where-Object { $_ -eq 'CALL' }).Count | Should -Be 1
        $actual = @($lines | Where-Object { $_ -ne 'CALL' } | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) })
        ($actual -join '|') | Should -BeExactly (@('-v','error','-protocol_whitelist','file','-show_streams','-show_format','-of','json','-i',$Source) -join '|')
    }

    It 'returns a structured native exit failure retaining exact diagnostics' {
        $env:WVC_PROBE_MODE = 'fail'
        $result = Get-MediaInspection $ProbeExe $Source
        $result.Succeeded | Should -BeFalse
        $result.FailureKind | Should -Be 'NativeExit'
        $result.Native.ExitCode | Should -Be 23
        $result.Native.StdErr | Should -BeLike '*synthetic probe diagnostic*'
        $before = (Get-FileHash -LiteralPath $Source).Hash
        Compress-One $Encoder $ProbeExe $Source $Output $DefaultCRF ([ref]$Counters)
        $Encoded.Count | Should -Be 0
        $Counters.Failed | Should -Be 1
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $before
        @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 0
    }

    It 'decodes native UTF-8 JSON metadata without losing non-ASCII values' {
        $document = $ValidJson | ConvertFrom-Json
        $language = 'fin ' + [char]0x00e4 + [char]0x4e2d
        $document.streams[0] | Add-Member NoteProperty tags ([pscustomobject]@{ language = $language })
        Set-ProbeJson ($document | ConvertTo-Json -Depth 10)
        $result = Get-MediaInspection $ProbeExe $Source
        $result.Succeeded | Should -BeTrue
        $result.PrimaryVideo.Language | Should -BeExactly $language
        $result.Native.StdOut | Should -BeLike ('*' + $language + '*')
    }

    It 'returns structured timeout and stops its owned native process' {
        $env:WVC_PROBE_MODE = 'hang'
        $watch = [Diagnostics.Stopwatch]::StartNew()
        $result = Get-MediaInspection $ProbeExe $Source 300
        $result.Succeeded | Should -BeFalse
        $result.FailureKind | Should -Be 'Timeout'
        $result.Native.TimedOut | Should -BeTrue
        $result.Native.StdErr | Should -BeLike '*synthetic probe diagnostic*'
        $watch.Elapsed.TotalSeconds | Should -BeLessThan 5
        @(Get-Process | Where-Object { $_.ProcessName -eq 'probe' -and $_.Path -eq $ProbeExe }).Count | Should -Be 0
    }

    It 'returns structured process-start failure without pretending an exit code exists' {
        $result = Get-MediaInspection (Join-Path $Root 'missing.exe') $Source
        $result.Succeeded | Should -BeFalse
        $result.FailureKind | Should -Be 'NativeStart'
        $result.Native.ExitCode | Should -BeNullOrEmpty
        $result.Native.Error | Should -Not -BeNullOrEmpty
    }

    It 'rejects malformed <Case> as a structured failure' -TestCases @(
        @{ Case='invalid JSON'; Json='{broken'; Kind='InvalidJson' },
        @{ Case='root array'; Json='[{"streams":[]}]'; Kind='InvalidJson' },
        @{ Case='null root'; Json='null'; Kind='InvalidJson' },
        @{ Case='missing streams'; Json='{}'; Kind='InvalidStructure' },
        @{ Case='object streams'; Json='{"streams":{"index":0}}'; Kind='InvalidStructure' },
        @{ Case='wrong shape'; Json='{"streams":"wrong"}'; Kind='InvalidStructure' },
        @{ Case='missing index'; Json='{"streams":[{"codec_type":"video","codec_name":"h264","width":320,"height":240}]}'; Kind='InvalidStructure' },
        @{ Case='negative index'; Json='{"streams":[{"index":-1,"codec_type":"video","codec_name":"h264","width":320,"height":240}]}'; Kind='InvalidStructure' },
        @{ Case='missing type'; Json='{"streams":[{"index":0}]}'; Kind='InvalidStructure' },
        @{ Case='missing codec'; Json='{"streams":[{"index":0,"codec_type":"video","width":320,"height":240}]}'; Kind='InvalidVideo' },
        @{ Case='missing height'; Json='{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":320}]}'; Kind='InvalidVideo' },
        @{ Case='zero width'; Json='{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":0,"height":240}]}'; Kind='InvalidVideo' },
        @{ Case='fractional height'; Json='{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":320,"height":2.5}]}'; Kind='InvalidVideo' },
        @{ Case='ambiguous artwork flag'; Json='{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":320,"height":240,"disposition":{"attached_pic":"bad"}}]}'; Kind='InvalidStructure' }
    ) {
        param($Case,$Json,$Kind)
        $result = ConvertFrom-ProbeJson $Json
        $result.Succeeded | Should -BeFalse
        $result.FailureKind | Should -Be $Kind
        $result.Reason | Should -Not -BeNullOrEmpty
    }

    It 'rejects duplicate stream indices' {
        $result = ConvertFrom-ProbeJson '{"streams":[{"index":0,"codec_type":"audio"},{"index":0,"codec_type":"video","codec_name":"h264","width":320,"height":240}]}'
        $result.Succeeded | Should -BeFalse
        $result.FailureKind | Should -Be 'InvalidStructure'
    }

    It 'never starts compression for <Case> and preserves source/final hashes' -TestCases @(
        @{ Case='audio only'; Json='{"streams":[{"index":1,"codec_type":"audio","codec_name":"aac","channels":2,"sample_rate":"48000"}]}'; Kind='NoRealVideo' },
        @{ Case='artwork only'; Json='{"streams":[{"index":0,"codec_type":"video","codec_name":"mjpeg","width":600,"height":600,"disposition":{"attached_pic":1}}]}'; Kind='NoRealVideo' },
        @{ Case='empty streams'; Json='{"streams":[]}'; Kind='NoRealVideo' },
        @{ Case='invalid JSON'; Json='{broken'; Kind='InvalidJson' },
        @{ Case='invalid video'; Json='{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":320}]}'; Kind='InvalidVideo' }
    ) {
        param($Case,$Json,$Kind)
        Set-ProbeJson $Json
        $final = Join-Path $Output ([IO.Path]::GetFileNameWithoutExtension($Source) + '.mp4')
        [IO.File]::WriteAllText($final, 'existing final sentinel')
        $beforeSource = (Get-FileHash -LiteralPath $Source).Hash
        $beforeFinal = (Get-FileHash -LiteralPath $final).Hash
        (Get-MediaInspection $ProbeExe $Source).FailureKind | Should -Be $Kind
        Compress-One $Encoder $ProbeExe $Source $Output $DefaultCRF ([ref]$Counters)
        $Encoded.Count | Should -Be 0
        $Counters.Failed | Should -Be 1
        (Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $beforeSource
        (Get-FileHash -LiteralPath $final).Hash | Should -BeExactly $beforeFinal
        @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 1
    }

    It 'normalizes every stream by numeric index and excludes artwork from real video candidates' {
        $document = Read-ProbeFixture 'attached-picture' | ConvertFrom-Json
        $document.streams = @($document.streams[2],$document.streams[1],$document.streams[0])
        $result = ConvertFrom-ProbeJson ($document | ConvertTo-Json -Depth 20)
        $result.Succeeded | Should -BeTrue
        ($result.Streams.Index -join ',') | Should -Be '0,3,7'
        ($result.RealVideoIndices -join ',') | Should -Be '3'
        $result.PrimaryVideoIndex | Should -Be 3
        $result.Streams[0].Disposition.AttachedPicture | Should -BeTrue
        $result.Streams[1].Disposition.Default | Should -BeTrue
        $result.Streams[2].Channels | Should -Be 2
        $result.Streams[2].SampleRate | Should -Be 48000
    }

    It 'retains optional geometry/colour/frame/audio fields without applying new encode policy' {
        $document = Read-ProbeFixture 'display-geometry' | ConvertFrom-Json
        $document.streams[0] | Add-Member NoteProperty display_aspect_ratio '16:9'
        $document.streams[0] | Add-Member NoteProperty r_frame_rate '30000/1001'
        $document.streams[0].side_data_list[0] | Add-Member NoteProperty displaymatrix 'synthetic matrix'
        $document.streams[0] | Add-Member NoteProperty tags ([pscustomobject]@{ rotate='180'; language='fin' })
        $result = ConvertFrom-ProbeJson ($document | ConvertTo-Json -Depth 20)
        $video = $result.PrimaryVideo
        $video.Width | Should -Be 641
        $video.Height | Should -Be 479
        $video.SampleAspectRatio | Should -Be '16:15'
        $video.DisplayAspectRatio | Should -Be '16:9'
        $video.AverageFrameRate.Value | Should -Be 24
        [Math]::Abs($video.RealFrameRate.Value - (30000/1001)) | Should -BeLessThan 0.0000001
        $video.RotationDegrees | Should -Be 90
        $video.RotationSource | Should -Be 'DisplayMatrix'
        $video.DisplayMatrix | Should -Be 'synthetic matrix'
        $video.Language | Should -Be 'fin'
        $result.GeometryState | Should -Be 'MetadataOnly'
        $result.DisplayGeometry | Should -BeNullOrEmpty
        $hdr = (ConvertFrom-ProbeJson (Read-ProbeFixture 'hdr-pq')).PrimaryVideo
        $hdr.PixelFormat | Should -Be 'yuv420p10le'
        $hdr.ColourPrimaries | Should -Be 'bt2020'
        $hdr.ColourTransfer | Should -Be 'smpte2084'
        $hdr.ColourMatrix | Should -Be 'bt2020nc'
    }

    It 'returns nullable missing optional fields and handles legacy zero rotation' {
        $document = $ValidJson | ConvertFrom-Json
        $document.streams[0] | Add-Member NoteProperty tags ([pscustomobject]@{ rotate='0' })
        $video = (ConvertFrom-ProbeJson ($document | ConvertTo-Json -Depth 10)).PrimaryVideo
        $video.RotationDegrees | Should -Be 0
        $video.RotationSource | Should -Be 'Tag'
        $video.SampleAspectRatio | Should -BeNullOrEmpty
        $video.PixelFormat | Should -BeNullOrEmpty
        $video.Channels | Should -BeNullOrEmpty
    }

    It 'retains unknown <Value> duration as null with an explicit limitation' -TestCases @(
        @{ Value='N/A'; State='Unknown' }, @{ Value='NaN'; State='Invalid' },
        @{ Value='Infinity'; State='Invalid' }, @{ Value='0'; State='Invalid' },
        @{ Value='-1'; State='Invalid' }, @{ Value='1,25'; State='Invalid' }
    ) {
        param($Value,$State)
        $document = $ValidJson | ConvertFrom-Json
        $document.format.duration = $Value
        $result = ConvertFrom-ProbeJson ($document | ConvertTo-Json -Depth 10)
        $result.Succeeded | Should -BeTrue
        $result.DurationSeconds | Should -BeNullOrEmpty
        $result.DurationState | Should -Be $State
        $result.ProgressMode | Should -Be 'Indeterminate'
        ($result.Limitations -join '|') | Should -BeLike '*duration comparison*unavailable*'
    }

    It 'uses valid primary-video duration when format duration is absent' {
        $result = ConvertFrom-ProbeJson '{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":320,"height":240,"duration":"2.500000"}],"format":{}}'
        $result.DurationSeconds | Should -Be 2.5
        $result.DurationSource | Should -Be 'VideoStream'
    }

    It 'proceeds with unknown duration, indeterminate progress and a visible validation limitation' {
        Set-ProbeJson (Read-ProbeFixture 'unknown-duration')
        $result = Get-MediaInspection $ProbeExe $Source
        $result.Succeeded | Should -BeTrue
        $result.DurationSeconds | Should -BeNullOrEmpty
        $result.ProgressMode | Should -Be 'Indeterminate'
        Compress-One $Encoder $ProbeExe $Source $Output $DefaultCRF ([ref]$Counters)
        $Encoded.Count | Should -Be 1
        $Counters.Done | Should -Be 1
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*progress is indeterminate*duration comparison*unavailable*' }
        @($Encoded[0] | Where-Object { $_ -in @('-r','-progress') }).Count | Should -Be 0
        $Encoded[0][[array]::IndexOf($Encoded[0],'-map')+1] | Should -BeExactly '0:0'
    }

    It 'parses decimals/rationals independent of <Culture> while tolerating unknown properties' -TestCases @(
        @{ Culture='fi-FI' }, @{ Culture='de-DE' }, @{ Culture='en-US' }
    ) {
        param($Culture)
        $savedCulture = [Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo($Culture)
            $document = $ValidJson | ConvertFrom-Json
            $document | Add-Member NoteProperty future ([pscustomobject]@{ data=@(1,2) })
            $document.streams[0] | Add-Member NoteProperty avg_frame_rate '30000/1001'
            $document.streams[0] | Add-Member NoteProperty future ([pscustomobject]@{ value='ignored' })
            $result = ConvertFrom-ProbeJson ($document | ConvertTo-Json -Depth 20)
            $result.Succeeded | Should -BeTrue
            $result.DurationSeconds | Should -Be 1.25
            [Math]::Abs($result.PrimaryVideo.AverageFrameRate.Value - (30000/1001)) | Should -BeLessThan 0.0000001
        } finally { [Threading.Thread]::CurrentThread.CurrentCulture = $savedCulture }
    }

    It 'keeps unknown ratios null instead of dividing by zero' {
        $result = ConvertFrom-ProbeJson '{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":320,"height":240,"sample_aspect_ratio":"0:1","display_aspect_ratio":"N/A","avg_frame_rate":"0/0"}]}'
        $result.Succeeded | Should -BeTrue
        $result.PrimaryVideo.SampleAspectRatio | Should -BeNullOrEmpty
        $result.PrimaryVideo.AverageFrameRate | Should -BeNullOrEmpty
    }

    It 'rejects unsupported source/protocol selections before a native process starts' -TestCases @(
        @{ Input='https://example.invalid/video.mov' }, @{ Input='HKCU:\Software' }, @{ Input='missing.mov' }
    ) {
        param($Input)
        Mock Invoke-EnvironmentCall { throw 'Must not run native probe' }
        $result = Get-MediaInspection $ProbeExe $Input
        $result.Succeeded | Should -BeFalse
        $result.FailureKind | Should -Be 'InvalidSource'
        Should -Invoke Invoke-EnvironmentCall -Times 0 -Exactly
    }

    It 'rejects playlist demuxer responses before compression' {
        $document = $ValidJson | ConvertFrom-Json
        $document.format.format_name = 'hls'
        Set-ProbeJson ($document | ConvertTo-Json -Depth 10)
        (Get-MediaInspection $ProbeExe $Source).FailureKind | Should -Be 'UnsupportedFormat'
        Compress-One $Encoder $ProbeExe $Source $Output $DefaultCRF ([ref]$Counters)
        $Encoded.Count | Should -Be 0
        $Counters.Failed | Should -Be 1
    }
}
