BeforeAll {
    $script:Application = Join-Path (Split-Path -Parent $PSScriptRoot) 'WinVidCompress.ps1'
    $script:OriginalAppData = $env:APPDATA
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    New-Item -ItemType Directory -Path $env:APPDATA | Out-Null
    # The script redefines its own functions when included. Protect the first
    # include with a lower-level command it does not redefine, even if the guard regresses.
    Mock Get-Command { throw 'Native tool discovery during helper loading' } -ParameterFilter {
        $Name -contains 'ffmpeg.exe' -or $Name -contains 'ffprobe.exe'
    }
    . $script:Application

    $script:OutputRoot = Join-Path $TestDrive 'output'
    New-Item -ItemType Directory -Path $script:OutputRoot | Out-Null
    $script:SourceRoot = Join-Path $TestDrive 'source'
    New-Item -ItemType Directory -Path $script:SourceRoot | Out-Null
    $script:Source = Join-Path $script:SourceRoot 'Band Name 29092025 - CamA.mov'
    Set-Content -LiteralPath $script:Source -Value 'synthetic source sentinel'

    # Load the real entry helper for mocked dispatch checks; executable exit stays
    # at the top-level boundary and must never end the Pester process.
    $script:Tokens = $null
    $script:ParseErrors = $null
    $script:ApplicationAst = [Management.Automation.Language.Parser]::ParseFile(
        $script:Application, [ref]$script:Tokens, [ref]$script:ParseErrors)
    $script:Main = { Invoke-WinVidCompress -Paths $Path }
}

AfterAll {
    $env:APPDATA = $script:OriginalAppData
}

Describe 'Helper loading and entry compatibility' {
    It 'parses on this PowerShell host' {
        @($script:ParseErrors).Count | Should -Be 0
    }

    It 'loads defaults and helpers without creating application config' {
        Get-Command Compress-One -CommandType Function | Should -Not -BeNullOrEmpty
        $DefaultCRF | Should -Be 22
        $CollisionMode | Should -Be 'rename'
        Test-Path -LiteralPath $ConfigDir | Should -BeFalse
        $ConfigDir | Should -Be (Join-Path $env:APPDATA 'WinVidCompress')
    }

    It 'does not discover tools, load config or start the menu when dot-sourced' {
        Mock Ensure-Tool { throw 'Tool discovery during helper loading' }
        Mock Load-Config { throw 'Config load during helper loading' }
        Mock Run-TUI { throw 'Menu startup during helper loading' }
        . $script:Application
        Should -Invoke Ensure-Tool -Times 0 -Exactly
        Should -Invoke Load-Config -Times 0 -Exactly
        Should -Invoke Run-TUI -Times 0 -Exactly
        Should -Invoke Get-Command -Times 0 -Exactly -ParameterFilter {
            $Name -contains 'ffmpeg.exe' -or $Name -contains 'ffprobe.exe'
        }
    }

    It 'retains direct path dispatch in the actual entry statements' {
        Mock Ensure-Tool { $exe }
        Mock Get-ToolEnvironment {}
        Mock Get-OutputEnvironment {}
        Mock Write-EnvironmentReport {}
        Mock Load-Config { [pscustomobject]@{ OutputDir = $script:OutputRoot } }
        Mock Process-Paths {}
        Mock Run-TUI {}
        $Path = @($script:Source, $script:SourceRoot)
        & $script:Main
        Should -Invoke Ensure-Tool -Times 2 -Exactly
        Should -Invoke Load-Config -Times 1 -Exactly
        Should -Invoke Process-Paths -Times 1 -Exactly -ParameterFilter {
            $paths.Count -eq 2 -and $paths[0] -eq $script:Source -and
            $cfg.OutputDir -eq $script:OutputRoot
        }
        Should -Invoke Run-TUI -Times 0 -Exactly
    }

    It 'retains no-argument menu dispatch with the menu mocked' {
        Mock Ensure-Tool { $exe }
        Mock Get-ToolEnvironment {}
        Mock Get-OutputEnvironment {}
        Mock Write-EnvironmentReport {}
        Mock Load-Config { [pscustomobject]@{ OutputDir = $script:OutputRoot } }
        Mock Process-Paths {}
        Mock Run-TUI {}
        $Path = @()
        & $script:Main
        Should -Invoke Run-TUI -Times 1 -Exactly
        Should -Invoke Process-Paths -Times 0 -Exactly
    }
}

Describe 'Default encode arguments with a recorder, never FFmpeg' {
    BeforeEach {
        $script:RecordedArguments = $null
        $script:Height = 1080
        # This suite tests its existing boundary; validation has separate real-helper tests.
        Mock Get-OutputValidation { [pscustomobject]@{Succeeded=$true;Inspection=$null;Warnings=@()} }
        $script:EncoderExit = 0
        $script:Counters = [pscustomobject]@{ Found = 0; Done = 0; Skipped = 0; Failed = 0 }
        Mock Get-MediaInspection {
            ConvertFrom-ProbeJson ('{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":1920,"height":' +
                $(if ($null -ne $script:Height) { $script:Height } else { 'null' }) +
                '},{"index":1,"codec_type":"audio","codec_name":"aac","channels":2}],"format":{"duration":"1"}}')
        }
        Mock Write-Host {}
        $script:Recorder = {
            $script:RecordedArguments = @($args)
            $global:LASTEXITCODE = $script:EncoderExit
        }
        Mock Invoke-EncodeProcess {
            $script:RecordedArguments = @($Arguments)
            if ($script:EncoderExit -eq 0) { [IO.File]::WriteAllText($Arguments[-1],'synthetic encoded sentinel') }
            [pscustomobject]@{ Succeeded=($script:EncoderExit -eq 0); FailureKind='NonZeroExit'; Error="FFmpeg exit code: $script:EncoderExit"; StdOutTruncated=$false; StdErrTruncated=$false }
        }
    }

    It 'preserves the complete default argument sequence and flat MP4 naming' {
        Compress-One $script:Recorder 'unused-probe' $script:Source $script:OutputRoot $DefaultCRF ([ref]$script:Counters)
        $expected = @('-hide_banner','-stdin','-nostats','-progress','pipe:1','-n','-i',$script:Source,
            '-map','0:0','-map','0:1',
            '-c:v','libx264','-preset','veryfast','-crf','22','-pix_fmt:v:0','yuv420p','-c:a','aac','-b:a','160k',
            '-movflags','+faststart','-metadata','title=Band Name 29092025 - CamA',
            '-metadata','artist=Band Name','-metadata','date=2025-09-29',
            '-metadata','comment=Interview date 29.09.2025; Band: Band Name',
            $script:RecordedArguments[-1])
        ($script:RecordedArguments -join "`n") | Should -Be ($expected -join "`n")
        $script:Counters.Done | Should -Be 1
        $script:Counters.Failed | Should -Be 0
        Test-Path -LiteralPath $expected[-1] | Should -BeFalse
        [IO.Path]::GetFileName($expected[-1]) | Should -BeExactly 'encode.partial.mp4'
        Test-Path -LiteralPath (Join-Path $script:OutputRoot 'Band Name 29092025 - CamA.mp4') | Should -BeTrue
    }

    It 'adds only the height-cap filter above 1080' {
        $script:Height = 2160
        Compress-One $script:Recorder 'unused-probe' $script:Source $script:OutputRoot $DefaultCRF ([ref]$script:Counters)
        $filterIndex = [array]::IndexOf($script:RecordedArguments, '-vf')
        $filterIndex | Should -BeGreaterThan 0
        $script:RecordedArguments[$filterIndex + 1] | Should -Be 'scale=960:1080'
        $script:RecordedArguments | Should -Not -Contain '-r'
    }

    It 'does not upscale a 720-high input' {
        $script:Height = 720
        Compress-One $script:Recorder 'unused-probe' $script:Source $script:OutputRoot $DefaultCRF ([ref]$script:Counters)
        $script:RecordedArguments | Should -Not -Contain '-vf'
    }

    It 'refuses compression when required probe height is unavailable [WVC-M2-01]' {
        $script:Height = $null
        Compress-One $script:Recorder 'unused-probe' $script:Source $script:OutputRoot $DefaultCRF ([ref]$script:Counters)
        $script:RecordedArguments | Should -BeNullOrEmpty
        $script:Counters.Done | Should -Be 0
        $script:Counters.Failed | Should -Be 1
    }

    It 'records an encoder failure instead of counting Done' {
        $script:EncoderExit = 9
        Compress-One $script:Recorder 'unused-probe' $script:Source $script:OutputRoot $DefaultCRF ([ref]$script:Counters)
        $script:Counters.Done | Should -Be 0
        $script:Counters.Failed | Should -Be 1
    }

    It 'passes source and metadata with special characters as separate values' {
        $specialSource = Join-Path $script:SourceRoot 'Band & (A) [x] !NAME! %PATH% 29092025.mov'
        Set-Content -LiteralPath $specialSource -Value 'synthetic'
        Compress-One $script:Recorder 'unused-probe' $specialSource $script:OutputRoot $DefaultCRF ([ref]$script:Counters)
        $script:RecordedArguments[[array]::IndexOf($script:RecordedArguments,'-i')+1] | Should -Be $specialSource
        $script:RecordedArguments | Should -Contain 'artist=Band & (A) [x] !NAME! %PATH%'
    }

    It 'renames collisions and preserves source and existing final sentinels' {
        $final = Join-Path $script:OutputRoot 'Band Name 29092025 - CamA.mp4'
        Set-Content -LiteralPath $final -Value 'existing final sentinel'
        $sourceHash = (Get-FileHash -LiteralPath $script:Source).Hash
        $finalHash = (Get-FileHash -LiteralPath $final).Hash
        Compress-One $script:Recorder 'unused-probe' $script:Source $script:OutputRoot $DefaultCRF ([ref]$script:Counters)
        [IO.Path]::GetFileName($script:RecordedArguments[-1]) | Should -BeExactly 'encode.partial.mp4'
        Test-Path -LiteralPath (Join-Path $script:OutputRoot 'Band Name 29092025 - CamA (compressed).mp4') | Should -BeTrue
        (Get-FileHash -LiteralPath $script:Source).Hash | Should -Be $sourceHash
        (Get-FileHash -LiteralPath $final).Hash | Should -Be $finalHash
    }
}

Describe 'Filename metadata and collision helpers' {
    It 'parses compact, dotted and dashed interview dates' -TestCases @(
        @{ Name = 'Band Name 29092025 - CamA.mov' },
        @{ Name = 'Band Name 29.09.2025.mov' },
        @{ Name = 'Band Name 29-09-2025.mkv' }
    ) {
        param($Name)
        $metadata = Parse-MetadataFromName $Name
        $metadata.Band | Should -Be 'Band Name'
        $metadata.DateISO | Should -Be '2025-09-29'
        $metadata.DateHuman | Should -Be '29.09.2025'
        $metadata.Title | Should -Be ([IO.Path]::GetFileNameWithoutExtension($Name))
    }

    It 'uses the existing fallback for a compact date followed by unseparated text' {
        (Parse-MetadataFromName 'Band 29092025 CamA.mov').DateISO | Should -Be '2025-09-29'
    }

    It 'retains the title without band/date tags when parsing fails' {
        $metadata = Parse-MetadataFromName 'Untitled clip.mov'
        $metadata.Title | Should -Be 'Untitled clip'
        $metadata.Band | Should -Be ''
        $metadata.DateISO | Should -Be ''
    }

    It 'selects the next available numbered suffix without writing it' {
        $target = Join-Path $script:OutputRoot 'Collision.mp4'
        Set-Content -LiteralPath (Join-Path $script:OutputRoot 'Collision (compressed).mp4') -Value 'sentinel'
        Set-Content -LiteralPath (Join-Path $script:OutputRoot 'Collision (compressed 2).mp4') -Value 'sentinel'
        $candidate = Next-CompressedPath $target
        $candidate | Should -Be (Join-Path $script:OutputRoot 'Collision (compressed 3).mp4')
        Test-Path -LiteralPath $candidate | Should -BeFalse
    }
}

Describe 'Isolated config and enumeration' {
    It 'wrong-shaped valid JSON recovers without a property exception [WVC-M1-03]' {
        Mock Get-DefaultOutputDir { $script:OutputRoot }
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
        Set-Content -LiteralPath $ConfigPath -Value '{}'
        { Load-Config } | Should -Not -Throw
    }

    It 'round-trips a valid config entirely inside fixture APPDATA' {
        Save-Config ([pscustomobject]@{ OutputDir = $script:OutputRoot })
        (Load-Config).OutputDir | Should -Be $script:OutputRoot
        Test-Path -LiteralPath $ConfigPath | Should -BeTrue
        $ConfigPath.StartsWith($TestDrive, [StringComparison]::OrdinalIgnoreCase) | Should -BeTrue
    }

    It 'collects an explicit file as a one-element selection' {
        $files = @(Collect-InputFiles $script:Source)
        $files.Count | Should -Be 1
        $files[0] | Should -Be $script:Source
    }

    It 'collects supported files recursively and filters unsupported extensions' {
        $folder = Join-Path $TestDrive 'many'
        $nested = Join-Path $folder 'nested'
        New-Item -ItemType Directory -Path $nested | Out-Null
        $first = Join-Path $folder 'first.MOV'
        $second = Join-Path $nested 'second.mkv'
        Set-Content -LiteralPath $first -Value 'synthetic'
        Set-Content -LiteralPath $second -Value 'synthetic'
        Set-Content -LiteralPath (Join-Path $folder 'ignore.txt') -Value 'synthetic'
        $files = @(Collect-InputFiles $folder)
        $files.Count | Should -Be 2
        $files | Should -Contain $first
        $files | Should -Contain $second
    }

    It 'returns no selection for a missing path without creating it' {
        $missing = Join-Path $TestDrive 'missing'
        @(Collect-InputFiles $missing).Count | Should -Be 0
        Test-Path -LiteralPath $missing | Should -BeFalse
    }
}

Describe 'Repaired strict enumeration regressions [WVC-M1-04]' {
    It 'empty folder collection returns an empty queue [WVC-M1-04]' {
        $empty = Join-Path $TestDrive 'empty'
        New-Item -ItemType Directory -Path $empty | Out-Null
        { @(Collect-InputFiles $empty).Count | Should -Be 0 } | Should -Not -Throw
    }

    It 'single-video folder reaches processing without scalar Count failure [WVC-M1-04]' {
        $single = Join-Path $TestDrive 'single'
        New-Item -ItemType Directory -Path $single | Out-Null
        Set-Content -LiteralPath (Join-Path $single 'one.mov') -Value 'synthetic'
        Mock Compress-One {}
        Mock Write-Host {}
        { Process-Paths @($single) 'unused-encoder' 'unused-probe' ([pscustomobject]@{ OutputDir = $script:OutputRoot }) } |
            Should -Not -Throw
        Should -Invoke Compress-One -Times 1 -Exactly
    }

    It 'explicit single file reaches processing without scalar Count failure [WVC-M1-04]' {
        Mock Compress-One {}
        Mock Write-Host {}
        { Process-Paths @($script:Source) 'unused-encoder' 'unused-probe' ([pscustomobject]@{ OutputDir = $script:OutputRoot }) } |
            Should -Not -Throw
        Should -Invoke Compress-One -Times 1 -Exactly
    }
}
