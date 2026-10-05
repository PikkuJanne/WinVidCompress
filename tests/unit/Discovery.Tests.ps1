BeforeAll {
    $script:OriginalAppData = $env:APPDATA
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
}

AfterAll { $env:APPDATA = $script:OriginalAppData }

Describe 'Literal discovery and scan records [WVC-M1-04]' {
    BeforeEach {
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($script:Root)
        Mock Write-Host {}
    }

    It 'materializes an empty directory into empty arrays with a successful scan' {
        $scan = Get-InputScan $script:Root
        $scan.Files -is [array] | Should -BeTrue
        $scan.Errors -is [array] | Should -BeTrue
        $scan.Files.Count | Should -Be 0
        $scan.Errors.Count | Should -Be 0
        $scan.Succeeded | Should -BeTrue
        @(Collect-InputFiles $script:Root).Count | Should -Be 0
    }

    It 'handles <Count> supported files with mixed extensions under strict mode' -TestCases @(
        @{ Count = 1 }, @{ Count = 3 }
    ) {
        param($Count)
        $nested = Join-Path $script:Root 'nested [literal]'
        [void][IO.Directory]::CreateDirectory($nested)
        $expected = @(1..$Count | ForEach-Object {
            $file = Join-Path $nested ("clip $_.MOV")
            [IO.File]::WriteAllText($file, 'synthetic sentinel')
            $file
        })
        [IO.File]::WriteAllText((Join-Path $script:Root 'ignore.txt'), 'unsupported sentinel')
        $scan = Get-InputScan $script:Root
        $scan.Files -is [array] | Should -BeTrue
        $scan.Files.Count | Should -Be $Count
        foreach ($file in $expected) { $scan.Files | Should -Contain $file }
        $scan.Succeeded | Should -BeTrue
    }

    It 'normalizes a literal relative file, dot segments and a filesystem PSDrive' {
        $unicode = ([char]0x00E4).ToString() + [char]0x00FC + [char]0x4E2D
        $file = Join-Path $script:Root ("clip [x] !NAME! %PATH% & ' " + $unicode + '.mov')
        [IO.File]::WriteAllText($file, 'synthetic sentinel')
        $hash = (Get-FileHash -LiteralPath $file).Hash
        Push-Location $script:Root
        try {
            $relative = '.\' + [IO.Path]::GetFileName($file)
            $scan = Get-InputScan $relative
            $scan.NormalizedPath | Should -Be $file
            $scan.Files.Count | Should -Be 1
            $scan.Files[0] | Should -Be $file
            (Get-InputScan ($script:Root + '\..\' + [IO.Path]::GetFileName($script:Root))).NormalizedPath |
                Should -Be $script:Root
            (Get-InputScan ('TestDrive:\' + [IO.Path]::GetFileName($script:Root))).NormalizedPath |
                Should -Be $script:Root
        } finally { Pop-Location }
        (Get-FileHash -LiteralPath $file).Hash | Should -Be $hash
        Test-Path -LiteralPath $ConfigDir | Should -BeFalse
    }

    It 'rejects an explicit unsupported file with an explicit record' {
        $file = Join-Path $script:Root 'ignore.txt'
        [IO.File]::WriteAllText($file, 'sentinel')
        $scan = Get-InputScan $file
        $scan.Succeeded | Should -BeFalse
        $scan.Files.Count | Should -Be 0
        $scan.Errors.Count | Should -Be 1
        $scan.Errors[0].Kind | Should -Be 'UnsupportedExtension'
        $scan.Errors[0].Path | Should -Be $file
    }

    It 'records missing and blank requests without creating anything' -TestCases @(
        @{ Missing = $true }, @{ Missing = $false }
    ) {
        param($Missing)
        $path = if ($Missing) { Join-Path $script:Root 'missing' } else { '' }
        $scan = Get-InputScan $path
        $scan.Succeeded | Should -BeFalse
        $scan.Files.Count | Should -Be 0
        $scan.Errors.Count | Should -Be 1
        $scan.Errors[0].Message | Should -Not -BeNullOrEmpty
        if ($Missing) { Test-Path -LiteralPath $path | Should -BeFalse }
    }

    It 'rejects non-filesystem inputs: <Path>' -TestCases @(
        @{ Path = 'Env:\PATH' }, @{ Path = 'HKCU:\Software' },
        @{ Path = 'https://example.invalid/video.mov' }, @{ Path = 'Variable:\true' },
        @{ Path = 'FileSystem::https://example.invalid/video.mov' }
    ) {
        param($Path)
        $scan = Get-InputScan $Path
        $scan.Succeeded | Should -BeFalse
        $scan.Files.Count | Should -Be 0
        $scan.Errors.Count | Should -Be 1
        $scan.Errors[0].Message | Should -Not -BeNullOrEmpty
    }

    It 'records a directory listing denial and never calls it empty' {
        Mock Get-ChildItem { throw (New-Object UnauthorizedAccessException('Synthetic listing denial')) } -ParameterFilter {
            $LiteralPath -eq $script:Root
        }
        $scan = Get-InputScan $script:Root
        $scan.Succeeded | Should -BeFalse
        $scan.Errors[0].Kind | Should -Be 'DirectoryReadFailed'
        $scan.Errors[0].Message | Should -BeLike '*Synthetic listing denial*'
        Process-Paths @($script:Root) 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Root })
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { $Object -like 'No videos found:*' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Scanned: 0' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Scan errors: 1' }
    }

    It 'retains readable files and records an inaccessible nested directory separately' {
        $denied = Join-Path $script:Root 'denied'
        [void][IO.Directory]::CreateDirectory($denied)
        $file = Join-Path $script:Root 'readable.mov'
        [IO.File]::WriteAllText($file, 'sentinel')
        Mock Get-ChildItem { throw (New-Object UnauthorizedAccessException('Synthetic subtree denial')) } -ParameterFilter {
            $LiteralPath -eq $denied
        }
        $scan = Get-InputScan $script:Root
        $scan.Files.Count | Should -Be 1
        $scan.Files[0] | Should -Be $file
        $scan.Succeeded | Should -BeFalse
        $scan.Errors.Count | Should -Be 1
        $scan.Errors[0].Path | Should -Be $denied
        Mock Compress-One {}
        Process-Paths @($script:Root) 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Root })
        Should -Invoke Compress-One -Times 1 -Exactly
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Synthetic subtree denial*' }
    }

    It 'preserves nonterminating enumeration diagnostics and partial results' {
        $file = Join-Path $script:Root 'readable.mov'
        [IO.File]::WriteAllText($file, 'sentinel')
        $script:PartialItem = Get-Item -LiteralPath $file
        Mock Get-ChildItem {
            $script:PartialItem
            Write-Error 'Synthetic nonterminating enumeration fault' -ErrorAction SilentlyContinue
        } -ParameterFilter { $LiteralPath -eq $script:Root }
        $scan = Get-InputScan $script:Root
        $scan.Files.Count | Should -Be 1
        $scan.Succeeded | Should -BeFalse
        $scan.Errors.Count | Should -Be 1
        $scan.Errors[0].Message | Should -BeLike '*Synthetic nonterminating enumeration fault*'
    }

    It 'records an unreadable explicit file without changing its bytes' {
        $file = Join-Path $script:Root 'locked.mov'
        [IO.File]::WriteAllText($file, 'sentinel')
        $hash = (Get-FileHash -LiteralPath $file).Hash
        $lock = [IO.File]::Open($file, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        try {
            $scan = Get-InputScan $file
            $scan.Files.Count | Should -Be 0
            $scan.Succeeded | Should -BeFalse
            $scan.Errors[0].Kind | Should -Be 'FileReadFailed'
        } finally { $lock.Dispose() }
        (Get-FileHash -LiteralPath $file).Hash | Should -Be $hash
    }

    It 'records real Windows listing and file-read ACL denials with readable siblings preserved' {
        $denied = Join-Path $script:Root 'denied'
        [void][IO.Directory]::CreateDirectory($denied)
        $locked = Join-Path $script:Root 'denied.mov'
        $readable = Join-Path $script:Root 'readable.mov'
        [IO.File]::WriteAllText($locked, 'denied sentinel')
        [IO.File]::WriteAllText($readable, 'readable sentinel')
        $directoryAcl = Get-Acl -LiteralPath $denied
        $fileAcl = Get-Acl -LiteralPath $locked
        $denyDirectory = Get-Acl -LiteralPath $denied
        $denyFile = Get-Acl -LiteralPath $locked
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $denyDirectory.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($identity,
            [Security.AccessControl.FileSystemRights]::ListDirectory, [Security.AccessControl.AccessControlType]::Deny)))
        $denyFile.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($identity,
            [Security.AccessControl.FileSystemRights]::ReadData, [Security.AccessControl.AccessControlType]::Deny)))
        try {
            Set-Acl -LiteralPath $denied -AclObject $denyDirectory
            Set-Acl -LiteralPath $locked -AclObject $denyFile
            $scan = Get-InputScan $script:Root
            $scan.Files.Count | Should -Be 1
            $scan.Files[0] | Should -Be $readable
            $scan.Succeeded | Should -BeFalse
            $scan.Errors.Count | Should -Be 2
            $scan.Errors.Kind | Should -Contain 'DirectoryReadFailed'
            $scan.Errors.Kind | Should -Contain 'FileReadFailed'
            (Get-InputScan $denied).Succeeded | Should -BeFalse
            (Get-InputScan $locked).Succeeded | Should -BeFalse
        } finally {
            Set-Acl -LiteralPath $locked -AclObject $fileAcl
            Set-Acl -LiteralPath $denied -AclObject $directoryAcl
        }
        [IO.File]::ReadAllText($locked) | Should -Be 'denied sentinel'
        [IO.File]::ReadAllText($readable) | Should -Be 'readable sentinel'
    }

    It 'handles provider-qualified filesystem paths and literal extended Windows path syntax' {
        $file = Join-Path $script:Root 'clip [literal].mov'
        [IO.File]::WriteAllText($file, 'sentinel')
        foreach ($path in @(('FileSystem::' + $file),('\\?\' + $file))) {
            $scan = Get-InputScan $path
            $scan.Files.Count | Should -Be 1
            $scan.Succeeded | Should -BeTrue
            [IO.File]::ReadAllText($scan.Files[0]) | Should -Be 'sentinel'
        }
    }

    It 'counts only complete scans and continues a mixed selection sequentially' {
        $file = Join-Path $script:Root 'one.mov'
        [IO.File]::WriteAllText($file, 'sentinel')
        Mock Compress-One {}
        Process-Paths @((Join-Path $script:Root 'missing'),$file) 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Root })
        Should -Invoke Compress-One -Times 1 -Exactly -ParameterFilter { $inPath -eq $file }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Scanned: 1' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Scan errors: 1' }
    }

    It 'refuses repeated directory traversal as a second cycle guard' {
        $script:RepeatedRoot = Get-Item -LiteralPath $script:Root
        Mock Get-ChildItem { $script:RepeatedRoot } -ParameterFilter { $LiteralPath -eq $script:Root }
        $scan = Get-InputScan $script:Root
        $scan.Succeeded | Should -BeFalse
        $scan.Files.Count | Should -Be 0
        $scan.Errors.Count | Should -Be 1
        $scan.Errors[0].Kind | Should -Be 'RepeatedDirectory'
        Should -Invoke Get-ChildItem -Times 1 -Exactly
    }

    It 'refuses a real junction loop, an outside junction and explicit selections through them' {
        $outside = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($outside)
        $foreign = Join-Path $outside 'foreign.mov'
        [IO.File]::WriteAllText($foreign, 'outside sentinel')
        $inside = Join-Path $script:Root 'inside.mov'
        [IO.File]::WriteAllText($inside, 'inside sentinel')
        $loop = Join-Path $script:Root 'loop'
        $escape = Join-Path $script:Root 'escape'
        try {
            New-Item -ItemType Junction -Path $loop -Target $script:Root -ErrorAction Stop | Out-Null
            New-Item -ItemType Junction -Path $escape -Target $outside -ErrorAction Stop | Out-Null
            $scan = Get-InputScan $script:Root
            $scan.Files.Count | Should -Be 1
            $scan.Files[0] | Should -Be $inside
            $scan.Errors.Count | Should -Be 2
            @($scan.Errors | Where-Object Kind -ne 'ReparsePointSkipped').Count | Should -Be 0
            foreach ($path in @($loop,$escape,(Join-Path $escape 'foreign.mov'))) {
                $selected = Get-InputScan $path
                $selected.Succeeded | Should -BeFalse
                $selected.Files.Count | Should -Be 0
                $selected.Errors[0].Kind | Should -Be 'ReparsePointSkipped'
            }
            [IO.File]::ReadAllText($foreign) | Should -Be 'outside sentinel'
        } finally {
            # Delete only owned junction objects, never their target directories.
            foreach ($link in @($loop,$escape)) {
                if ([IO.Directory]::Exists($link)) { [IO.Directory]::Delete($link) }
            }
        }
        [IO.File]::ReadAllText($inside) | Should -Be 'inside sentinel'
        [IO.File]::ReadAllText($foreign) | Should -Be 'outside sentinel'
    }
}
