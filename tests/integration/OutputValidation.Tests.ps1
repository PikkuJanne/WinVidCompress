BeforeDiscovery {
    $script:ValidationMediaToolsAvailable = [bool](Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue) -and
        [bool](Get-Command ffprobe.exe -CommandType Application -ErrorAction SilentlyContinue)
}
BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:SavedEnvironment = @{APPDATA=$env:APPDATA;FFREPORT=$env:FFREPORT;WVC_PROBE_JSON=$env:WVC_PROBE_JSON;
        WVC_PROBE_ARGV=$env:WVC_PROBE_ARGV;WVC_PROBE_MODE=$env:WVC_PROBE_MODE;WVC_ENCODE_PID=$env:WVC_ENCODE_PID}
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    $env:FFREPORT = $null
    $env:WVC_ENCODE_PID = $null
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    $script:PS51 = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $script:ProbeExe = Join-Path $TestDrive 'probe.exe'
    $script:DecoderExe = Join-Path $TestDrive 'decode.exe'
    foreach ($definition in @(
        @{Script=(Join-Path $RepoRoot 'tests/unit/New-ProbeFixture.ps1');Output=$ProbeExe},
        @{Script=(Join-Path $PSScriptRoot 'New-EncodeProcessFixture.ps1');Output=$DecoderExe})) {
        $compiled = Invoke-WvcTestProcess $PS51 @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$definition.Script,'-Destination',$definition.Output)
        if ($compiled.ExitCode -ne 0) { throw ('Validation native fixture compile failed: '+$compiled.StdErr) }
    }
    $script:ValidJson = '{"streams":[{"index":3,"codec_type":"video","codec_name":"h264","width":320,"height":240,"duration":"1","avg_frame_rate":"24/1","nb_frames":"24"}],"format":{"format_name":"mov,mp4,m4a,3gp,3g2,mj2","duration":"1"}}'
    if ($ValidationMediaToolsAvailable) {
        $script:MediaEncoder = (Get-Command ffmpeg.exe -CommandType Application | Select-Object -First 1).Source
        $script:MediaProbe = (Get-Command ffprobe.exe -CommandType Application | Select-Object -First 1).Source
        $script:Definitions = (Get-Content -LiteralPath (Join-Path $RepoRoot 'tests/fixtures/inventory.json') -Raw | ConvertFrom-Json).Items
    }
}
AfterAll { foreach ($key in $SavedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key,$SavedEnvironment[$key],'Process') } }

Describe 'Output validation through actual owned native probe [WVC-M2-05]' {
    BeforeEach {
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Output = Join-Path $Root 'output & [x] !NAME! %PATH%'
        [void][IO.Directory]::CreateDirectory($Output)
        $script:SourcePath = Join-Path $Root ("source O'Brien " + [char]0xe4 + [char]0x4e2d + '.mov')
        [IO.File]::WriteAllText($SourcePath,'source sentinel')
        $script:SourceHash = (Get-FileHash -LiteralPath $SourcePath).Hash
        $script:Final = Join-Path $Output 'existing.mp4'
        [IO.File]::WriteAllText($Final,'existing final sentinel')
        $script:FinalHash = (Get-FileHash -LiteralPath $Final).Hash
        $script:SourceInspection = ConvertFrom-ProbeJson $ValidJson
        $script:Plan = Get-StreamPlan $SourceInspection
        $script:Job = New-OutputJob $SourcePath $Output $Final $Final
        # This is an FTYP/JSON fault fixture, not generated or decoded video.
        [IO.File]::WriteAllBytes($Job.TempPath,[byte[]]@(0,0,0,16,102,116,121,112,105,115,111,109,0,0,0,0))
        $script:TempHash = (Get-FileHash -LiteralPath $Job.TempPath).Hash
        $env:WVC_PROBE_JSON = Join-Path $Root 'response.json'
        $env:WVC_PROBE_ARGV = Join-Path $Root 'probe-argv.txt'
        $env:WVC_PROBE_MODE = ''
        [IO.File]::WriteAllText($env:WVC_PROBE_JSON,$ValidJson)
        Mock Write-Host {}
    }
    AfterEach {
        (Get-FileHash -LiteralPath $SourcePath).Hash | Should -BeExactly $SourceHash
        (Get-FileHash -LiteralPath $Final).Hash | Should -BeExactly $FinalHash
        (Get-FileHash -LiteralPath $Job.TempPath).Hash | Should -BeExactly $TempHash
        @(Get-ChildItem -LiteralPath $Output -File).Count | Should -Be 1
        [void](Close-OutputJob $Job $false 'Test' 'native synthetic validation fixture')
    }
    It 'accepts normalized structure and keeps literal probe argv/stderr without publishing [A01 A04]' {
        $result = Get-OutputValidation $ProbeExe $Job $SourceInspection $Plan
        $result.Succeeded | Should -BeTrue
        $result.Inspection.Native.ExitCode | Should -Be 0
        $result.Inspection.Native.StdErr | Should -Match 'synthetic probe diagnostic'
        $arguments = @(Get-Content -LiteralPath $env:WVC_PROBE_ARGV | Where-Object {$_ -ne 'CALL'} | ForEach-Object {
            [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_))
        })
        $arguments[-1] | Should -BeExactly $Job.TempPath
        $arguments[[array]::IndexOf($arguments,'-protocol_whitelist')+1] | Should -BeExactly 'file'
    }
    It 'rejects actual <Kind> probe outcomes with source/job identity [A01 A04]' -TestCases @(
        @{Kind='native failure'},@{Kind='malformed JSON'},@{Kind='wrong streams'},@{Kind='truncated'},@{Kind='timeout'}
    ) {
        param($Kind)
        $timeout = 10000
        switch ($Kind) {
            'native failure' {$env:WVC_PROBE_MODE='fail'}
            'malformed JSON' {[IO.File]::WriteAllText($env:WVC_PROBE_JSON,'{broken')}
            'wrong streams' {[IO.File]::WriteAllText($env:WVC_PROBE_JSON,$ValidJson.Replace('"h264"','"hevc"'))}
            'truncated' {[IO.File]::WriteAllText($env:WVC_PROBE_JSON,$ValidJson.Replace('"duration":"1"','"duration":"0.1"'))}
            'timeout' {$env:WVC_PROBE_MODE='hang';$timeout=200}
        }
        $result = Get-OutputValidation $ProbeExe $Job $SourceInspection $Plan $timeout
        $result.Succeeded | Should -BeFalse
        $result.Reason | Should -Match ([regex]::Escape($Job.JobId))
        $result.Reason | Should -Match ([regex]::Escape($SourcePath))
        if ($Kind -eq 'native failure') {
            $result.Inspection.Native.ExitCode | Should -Be 23
            $result.Inspection.Native.StdErr | Should -Match 'synthetic probe diagnostic'
        } elseif ($Kind -eq 'timeout') { $result.Inspection.FailureKind | Should -Be 'Timeout' }
    }
    It 'runs the explicit decode adapter as a native argv fixture without publishing' {
        $validation = Get-OutputValidation $ProbeExe $Job $SourceInspection $Plan
        $decoded = Invoke-OutputDecodeCheck $DecoderExe $Job $validation
        $decoded.Succeeded | Should -BeTrue
        $arguments = @($decoded.Native.StdOut -split '\r?\n' | Where-Object {$_} | ForEach-Object {
            [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_))
        })
        $arguments[[array]::IndexOf($arguments,'-i')+1] | Should -BeExactly $Job.TempPath
        $arguments[[array]::IndexOf($arguments,'-map')+1] | Should -BeExactly '0:3'
        $arguments[-1] | Should -BeExactly 'NUL'
    }
}

Describe 'Installed-tool structural and optional decode validation [FFmpeg/FFprobe required]' {
    It 'validates and explicitly decodes real synthetic <Fixture> output before publication [WVC-M2-05]' -Skip:(-not $ValidationMediaToolsAvailable) -TestCases @(
        @{Fixture='silent'},@{Fixture='sdr-av'}
    ) {
        param($Fixture)
        $owner = New-WvcTestRoot
        $job = $null
        try {
            $env:APPDATA = Join-Path $owner.Path 'appdata'
            $definition = $Definitions | Where-Object Id -eq $Fixture
            $source = Join-Path $owner.Path $definition.File
            $arguments = @($definition.Arguments | ForEach-Object {if ($_ -eq '{output}') {$source} else {$_}})
            (Invoke-WvcTestProcess $MediaEncoder $arguments).ExitCode | Should -Be 0
            $sourceHash = (Get-FileHash -LiteralPath $source).Hash
            $inspection = Get-MediaInspection $MediaProbe $source
            $plan = Get-StreamPlan $inspection
            $output = Join-Path $owner.Path 'output'
            [void][IO.Directory]::CreateDirectory($output)
            $final = Join-Path $output ($Fixture+'.mp4')
            $job = New-OutputJob $source $output $final $final
            $arguments = @(Get-EncodeArguments $source $job.TempPath $plan $DefaultCRF (Parse-MetadataFromName ([IO.Path]::GetFileName($source))))
            (Invoke-EncodeProcess $MediaEncoder $arguments).Succeeded | Should -BeTrue
            $validation = Get-OutputValidation $MediaProbe $job $inspection $plan
            $validation.Succeeded | Should -BeTrue
            (Invoke-OutputDecodeCheck $MediaEncoder $job $validation).Succeeded | Should -BeTrue
            Test-Path -LiteralPath $final | Should -BeFalse
            (Publish-OutputJob $job 'rename').Published | Should -BeTrue
            Test-Path -LiteralPath $final | Should -BeTrue
            (Get-FileHash -LiteralPath $source).Hash | Should -BeExactly $sourceHash
        } finally {
            if ($null -ne $job) { [void](Close-OutputJob $job $false 'Test' 'real synthetic media fixture') }
            Remove-WvcTestRoot $owner
        }
    }
}
