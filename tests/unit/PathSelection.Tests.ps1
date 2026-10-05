BeforeAll {
    $script:OriginalAppData = $env:APPDATA
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
}

AfterAll { $env:APPDATA = $script:OriginalAppData }

Describe 'Literal source validation and explicit output creation [WVC-M1-01]' {
    BeforeEach {
        $script:Responses = New-Object 'Collections.Generic.Queue[string]'
        Mock Read-Host {
            if (-not $script:Responses.Count) { throw 'Unexpected path prompt read' }
            $script:Responses.Dequeue()
        }
        Mock Write-Host {}
    }

    It 'leaves a missing source folder missing and allows cancellation' {
        $missing = Join-Path $TestDrive 'missing-source'
        $script:Responses.Enqueue($missing)
        $script:Responses.Enqueue('')
        Prompt-Path 'source folder' -Folder | Should -BeNullOrEmpty
        Test-Path -LiteralPath $missing | Should -BeFalse
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Invalid path. Try again.' }
    }

    It 'creates only an explicitly selected output directory' {
        $output = Join-Path $TestDrive 'new-output/nested'
        $script:Responses.Enqueue($output)
        Prompt-Path 'output folder' -Folder -CreateIfMissing | Should -Be $output
        Test-Path -LiteralPath $output -PathType Container | Should -BeTrue
    }

    It 'returns an existing source folder without changing its contents' {
        $source = Join-Path $TestDrive 'existing-source'
        [void][IO.Directory]::CreateDirectory($source)
        $sentinel = Join-Path $source 'keep.txt'
        [IO.File]::WriteAllText($sentinel, 'source sentinel')
        $script:Responses.Enqueue($source)
        Prompt-Path 'source folder' -Folder | Should -Be $source
        [IO.File]::ReadAllText($sentinel) | Should -Be 'source sentinel'
        @(Get-ChildItem -LiteralPath $source).Count | Should -Be 1
    }

    It 'cancels blank or whitespace input without writing' -TestCases @(
        @{ InputText = ''; FolderMode = $false; CreateMode = $false },
        @{ InputText = '   '; FolderMode = $true; CreateMode = $false },
        @{ InputText = ''; FolderMode = $true; CreateMode = $true }
    ) {
        param($InputText,$FolderMode,$CreateMode)
        $script:Responses.Enqueue($InputText)
        Prompt-Path 'path' -Folder:$FolderMode -CreateIfMissing:$CreateMode | Should -BeNullOrEmpty
        Should -Invoke Write-Host -Times 0 -Exactly
    }

    It 'cancels quoted whitespace after normalization' {
        $script:Responses.Enqueue('"   "')
        $originalDirectory = [IO.Directory]::GetCurrentDirectory()
        try {
            [IO.Directory]::SetCurrentDirectory($TestDrive)
            Prompt-Path 'output folder' -Folder -CreateIfMissing | Should -BeNullOrEmpty
        } finally { [IO.Directory]::SetCurrentDirectory($originalDirectory) }
        Should -Invoke Write-Host -Times 0 -Exactly
    }

    It 'uses literal brackets and Unicode in existing file and folder selections' {
        # ASCII source remains compatible with PS5.1; these are Finnish/German/CJK characters.
        $unicode = ([char]0x00E4).ToString() + [char]0x00FC + [char]0x4E2D
        $folder = Join-Path $TestDrive ('source [literal] ' + $unicode)
        [void][IO.Directory]::CreateDirectory($folder)
        $file = Join-Path $folder ('clip [one] ' + $unicode + '.mov')
        [IO.File]::WriteAllText($file, 'synthetic source sentinel')
        $script:Responses.Enqueue('"' + $folder + '"')
        Prompt-Path 'source folder' -Folder | Should -Be $folder
        $script:Responses.Enqueue($file)
        Prompt-Path 'source file' | Should -Be $file
        [IO.File]::ReadAllText($file) | Should -Be 'synthetic source sentinel'
    }

    It 'creates a literal bracket and Unicode output without touching its wildcard neighbor' {
        $unicode = ([char]0x00E4).ToString() + [char]0x00FC + [char]0x4E2D
        $neighbor = Join-Path $TestDrive ('output l ' + $unicode)
        [void][IO.Directory]::CreateDirectory($neighbor)
        $sentinel = Join-Path $neighbor 'keep.txt'
        [IO.File]::WriteAllText($sentinel, 'existing output sentinel')
        $output = Join-Path $TestDrive ('output [literal] ' + $unicode)
        $script:Responses.Enqueue($output)
        Prompt-Path 'output folder' -Folder -CreateIfMissing | Should -Be $output
        Test-Path -LiteralPath $output -PathType Container | Should -BeTrue
        [IO.File]::ReadAllText($sentinel) | Should -Be 'existing output sentinel'
    }

    It 'rejects a directory in file mode and a file in folder mode' {
        $folder = Join-Path $TestDrive 'type-check'
        [void][IO.Directory]::CreateDirectory($folder)
        $file = Join-Path $folder 'keep.txt'
        [IO.File]::WriteAllText($file, 'sentinel')
        foreach ($text in @($folder,'',$file,'')) { $script:Responses.Enqueue($text) }
        Prompt-Path 'source file' | Should -BeNullOrEmpty
        Prompt-Path 'output folder' -Folder -CreateIfMissing | Should -BeNullOrEmpty
        [IO.File]::ReadAllText($file) | Should -Be 'sentinel'
    }

    It 'reports permission errors clearly and permits retry or cancellation' {
        $denied = Join-Path $TestDrive 'denied-source'
        $script:Responses.Enqueue($denied)
        $script:Responses.Enqueue('')
        Mock Test-Path { throw (New-Object UnauthorizedAccessException('Synthetic access denied')) } -ParameterFilter {
            $LiteralPath -eq $denied
        }
        Prompt-Path 'source folder' -Folder | Should -BeNullOrEmpty
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter {
            $Object -like '*Cannot access path*' -and $Object -like '*Synthetic access denied*'
        }
    }

    It 'reports output creation errors and leaves existing files unchanged' {
        $file = Join-Path $TestDrive 'parent-file'
        [IO.File]::WriteAllText($file, 'existing sentinel')
        $output = Join-Path $file 'child-output'
        $script:Responses.Enqueue($output)
        $script:Responses.Enqueue('')
        Prompt-Path 'output folder' -Folder -CreateIfMissing | Should -BeNullOrEmpty
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Cannot access path*' }
        [IO.File]::ReadAllText($file) | Should -Be 'existing sentinel'
    }
}
