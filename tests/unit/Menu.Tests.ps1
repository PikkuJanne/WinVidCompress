BeforeAll {
    $script:OriginalAppData = $env:APPDATA
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
}

AfterAll { $env:APPDATA = $script:OriginalAppData }

Describe 'Menu exit and selection intent [WVC-M1-01]' {
    BeforeEach {
        $script:Choices = New-Object 'Collections.Generic.Queue[string]'
        $script:Config = [pscustomobject]@{ OutputDir = (Join-Path $TestDrive 'output') }
        Mock Read-Host {
            if (-not $script:Choices.Count) { throw 'Unexpected menu redisplay/read' }
            $script:Choices.Dequeue()
        }
        Mock Write-Host {}
        Mock Save-Config {}
        Mock Process-Paths {}
    }

    It 'Quit returns once and preserves the caller runspace' {
        $script:Choices.Enqueue('4')
        $continued = $false
        Run-TUI 'unused-encoder' 'unused-probe' $script:Config
        $continued = $true
        $continued | Should -BeTrue
        Should -Invoke Read-Host -Times 1 -Exactly
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -eq '========== WinVidCompress =========='
        }
        Should -Invoke Process-Paths -Times 0 -Exactly
    }

    It 'retains the four options and lets invalid choices return to the menu' {
        $script:Choices.Enqueue('invalid')
        $script:Choices.Enqueue('4')
        Run-TUI 'unused-encoder' 'unused-probe' $script:Config
        Should -Invoke Read-Host -Times 2 -Exactly
        foreach ($label in @('1) Set output folder','2) Compress ONE file',
            '3) Compress ALL videos in a folder (recursive)','4) Quit')) {
            Should -Invoke Write-Host -Times 2 -Exactly -ParameterFilter { $Object -eq $label }
        }
    }

    It 'requests creation only when choosing an output folder' {
        $script:Choices.Enqueue('1')
        $script:Choices.Enqueue('4')
        Mock Prompt-Path { Join-Path $TestDrive 'selected-output' }
        Run-TUI 'unused-encoder' 'unused-probe' $script:Config
        Should -Invoke Prompt-Path -Times 1 -Exactly -ParameterFilter { $Folder -and $CreateIfMissing }
        Should -Invoke Save-Config -Times 1 -Exactly -ParameterFilter {
            $cfg.OutputDir -eq (Join-Path $TestDrive 'selected-output')
        }
        Should -Invoke Process-Paths -Times 0 -Exactly
    }

    It 'requests an existing source folder without permission to create it' {
        $script:Choices.Enqueue('3')
        $script:Choices.Enqueue('4')
        Mock Prompt-Path { Join-Path $TestDrive 'selected-source' }
        Run-TUI 'unused-encoder' 'unused-probe' $script:Config
        Should -Invoke Prompt-Path -Times 1 -Exactly -ParameterFilter { $Folder -and -not $CreateIfMissing }
        Should -Invoke Process-Paths -Times 1 -Exactly -ParameterFilter {
            $paths[0] -eq (Join-Path $TestDrive 'selected-source')
        }
        Should -Invoke Save-Config -Times 0 -Exactly
    }

    It 'retains source file selection without directory creation' {
        $script:Choices.Enqueue('2')
        $script:Choices.Enqueue('4')
        Mock Prompt-Path { Join-Path $TestDrive 'selected.mov' }
        Run-TUI 'unused-encoder' 'unused-probe' $script:Config
        Should -Invoke Prompt-Path -Times 1 -Exactly -ParameterFilter { -not $Folder -and -not $CreateIfMissing }
        Should -Invoke Process-Paths -Times 1 -Exactly -ParameterFilter {
            $paths[0] -eq (Join-Path $TestDrive 'selected.mov')
        }
        Should -Invoke Save-Config -Times 0 -Exactly
    }

    It 'cancels all three selections without saving config or processing' {
        foreach ($choice in @('1','2','3','4')) { $script:Choices.Enqueue($choice) }
        Mock Prompt-Path { $null }
        $before = $script:Config.OutputDir
        Run-TUI 'unused-encoder' 'unused-probe' $script:Config
        $script:Config.OutputDir | Should -Be $before
        Should -Invoke Save-Config -Times 0 -Exactly
        Should -Invoke Process-Paths -Times 0 -Exactly
    }

    It 'does not create or process a missing source selected through the real prompt' {
        $missing = Join-Path $TestDrive 'missing-source'
        foreach ($choice in @('3',$missing,'','4')) { $script:Choices.Enqueue($choice) }
        Run-TUI 'unused-encoder' 'unused-probe' $script:Config
        Test-Path -LiteralPath $missing | Should -BeFalse
        Should -Invoke Process-Paths -Times 0 -Exactly
        Should -Invoke Save-Config -Times 0 -Exactly
    }

    It 'creates an explicit output selection through the real prompt and saves only that choice' {
        $output = Join-Path $TestDrive 'menu-created-output/nested'
        foreach ($choice in @('1',$output,'4')) { $script:Choices.Enqueue($choice) }
        Run-TUI 'unused-encoder' 'unused-probe' $script:Config
        Test-Path -LiteralPath $output -PathType Container | Should -BeTrue
        $script:Config.OutputDir | Should -Be $output
        Should -Invoke Save-Config -Times 1 -Exactly -ParameterFilter { $cfg.OutputDir -eq $output }
        Should -Invoke Process-Paths -Times 0 -Exactly
    }
}
