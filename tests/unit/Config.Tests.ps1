BeforeAll {
    $script:OriginalAppData = $env:APPDATA
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
    $script:FixtureRoot = $TestDrive
    function Set-TestConfig([string]$Text) {
        [void][IO.Directory]::CreateDirectory($ConfigDir)
        [IO.File]::WriteAllText($ConfigPath, $Text, (New-Object Text.UTF8Encoding($false)))
    }
    function Get-TestConfigBytes {
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($ConfigPath))
    }
}

AfterAll { $env:APPDATA = $script:OriginalAppData }

Describe 'Configuration validation and recovery [WVC-M1-03]' {
    BeforeEach {
        # Every case uses a new config root; no shared real profile or output.
        $env:APPDATA = Join-Path $script:FixtureRoot ([guid]::NewGuid().ToString('N'))
        $ConfigDir = Join-Path $env:APPDATA 'WinVidCompress'
        $ConfigPath = Join-Path $ConfigDir 'config.json'
        $script:ConfigSnapshot = $null
        $script:Output = Join-Path $env:APPDATA 'output'
        [void][IO.Directory]::CreateDirectory($script:Output)
        Mock Get-DefaultOutputDir { $script:Output }
        Mock Write-Host {}
    }

    It 'creates OutputDir-only defaults on first run inside isolated APPDATA' {
        $cfg = Load-Config
        $cfg.OutputDir | Should -Be $script:Output
        $ConfigPath.StartsWith($script:FixtureRoot, [StringComparison]::OrdinalIgnoreCase) | Should -BeTrue
        (Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json).OutputDir | Should -Be $script:Output
        @(Get-ChildItem -LiteralPath $ConfigDir -Filter '*.previous-*.json').Count | Should -Be 0
    }

    It 'recovers <Label> with exact diagnostic backup and explicit notice' -TestCases @(
        @{ Label = 'empty file'; Text = '' },
        @{ Label = 'invalid JSON'; Text = '{broken' },
        @{ Label = 'null'; Text = 'null' },
        @{ Label = 'empty object'; Text = '{}' },
        @{ Label = 'empty array'; Text = '[]' },
        @{ Label = 'one-object array'; Text = '[{"OutputDir":"C:\\video"}]' },
        @{ Label = 'numeric root'; Text = '7' },
        @{ Label = 'string root'; Text = '"text"' },
        @{ Label = 'boolean root'; Text = 'true' },
        @{ Label = 'null output'; Text = '{"OutputDir":null}' },
        @{ Label = 'numeric output'; Text = '{"OutputDir":7}' },
        @{ Label = 'boolean output'; Text = '{"OutputDir":true}' },
        @{ Label = 'array output'; Text = '{"OutputDir":["C:\\video"]}' },
        @{ Label = 'object output'; Text = '{"OutputDir":{}}' },
        @{ Label = 'blank output'; Text = '{"OutputDir":"  "}' },
        @{ Label = 'relative output'; Text = '{"OutputDir":"relative"}' },
        @{ Label = 'drive-relative output'; Text = '{"OutputDir":"C:video"}' },
        @{ Label = 'provider output'; Text = '{"OutputDir":"HKCU:\\Software"}' },
        @{ Label = 'URL output'; Text = '{"OutputDir":"https://example.invalid/video"}' },
        @{ Label = 'wildcard output'; Text = '{"OutputDir":"C:\\video*"}' }
    ) {
        param($Label, $Text)
        Set-TestConfig $Text
        $before = Get-TestConfigBytes
        (Load-Config).OutputDir | Should -Be $script:Output
        $backups = @(Get-ChildItem -LiteralPath $ConfigDir -Filter 'config.invalid-*.json')
        $backups.Count | Should -Be 1
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($backups[0].FullName)) | Should -Be $before
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'Invalid config*preserved*' }
    }

    It 'keeps a legacy valid config unchanged on load' {
        Set-TestConfig ([pscustomobject]@{ OutputDir = $script:Output } | ConvertTo-Json)
        $before = Get-TestConfigBytes
        (Load-Config).OutputDir | Should -Be $script:Output
        Get-TestConfigBytes | Should -Be $before
        @(Get-ChildItem -LiteralPath $ConfigDir -Filter 'config.*-*.json').Count | Should -Be 0
    }

    It 'preserves an unavailable <Label> preference without fallback' -TestCases @(
        @{ Label = 'drive'; Destination = 'Z:\wvc-offline' },
        @{ Label = 'UNC'; Destination = '\\wvc-offline.invalid\share\output' }
    ) {
        param($Label, $Destination)
        Set-TestConfig ([pscustomobject]@{ OutputDir = $Destination } | ConvertTo-Json)
        $before = Get-TestConfigBytes
        Mock Get-Item { throw 'Synthetic destination unavailable' } -ParameterFilter { $LiteralPath -eq $Destination }
        { Load-Config } | Should -Throw '*Output folder*unavailable*'
        Get-TestConfigBytes | Should -Be $before
        Should -Invoke Get-DefaultOutputDir -Times 0 -Exactly
    }

    It 'preserves a permission-denied output preference' {
        Set-TestConfig ([pscustomobject]@{ OutputDir = $script:Output } | ConvertTo-Json)
        $before = Get-TestConfigBytes
        Mock Get-Item { throw [UnauthorizedAccessException]::new('Synthetic permission denial') } -ParameterFilter {
            $LiteralPath -eq $script:Output
        }
        { Load-Config } | Should -Throw '*Output folder*permission denial*'
        Get-TestConfigBytes | Should -Be $before
        Should -Invoke Get-DefaultOutputDir -Times 0 -Exactly
    }

    It 'preserves preferences on a real Windows output listing ACL denial' {
        Set-TestConfig ([pscustomobject]@{ OutputDir = $script:Output } | ConvertTo-Json)
        $before = Get-TestConfigBytes
        $originalAcl = Get-Acl -LiteralPath $script:Output
        $deniedAcl = Get-Acl -LiteralPath $script:Output
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $rule = New-Object Security.AccessControl.FileSystemAccessRule($identity,
            [Security.AccessControl.FileSystemRights]::ListDirectory,
            [Security.AccessControl.AccessControlType]::Deny)
        $deniedAcl.AddAccessRule($rule)
        try {
            Set-Acl -LiteralPath $script:Output -AclObject $deniedAcl
            { Load-Config } | Should -Throw '*Output folder*inaccessible*'
        } finally { Set-Acl -LiteralPath $script:Output -AclObject $originalAcl }
        Get-TestConfigBytes | Should -Be $before
        Should -Invoke Get-DefaultOutputDir -Times 0 -Exactly
    }

    It 'rejects a real file as output directory without modifying config or file' {
        $file = Join-Path $env:APPDATA 'file-output'
        [IO.File]::WriteAllText($file, 'file sentinel')
        Set-TestConfig ([pscustomobject]@{ OutputDir = $file } | ConvertTo-Json)
        $before = Get-TestConfigBytes
        { Load-Config } | Should -Throw '*Output folder*directory*'
        Get-TestConfigBytes | Should -Be $before
        [IO.File]::ReadAllText($file) | Should -Be 'file sentinel'
    }

    It 'fails clearly for unusable default <Label> without creating config' -TestCases @(
        @{ Label = 'empty known folder'; Destination = '' },
        @{ Label = 'relative known folder'; Destination = 'video' },
        @{ Label = 'missing known folder'; Destination = 'Z:\wvc-offline' }
    ) {
        param($Label, $Destination)
        Mock Get-DefaultOutputDir { $Destination }
        Mock Get-Item { throw 'Synthetic known folder unavailable' } -ParameterFilter { $LiteralPath -eq $Destination }
        { Load-Config } | Should -Throw '*default Videos folder*'
        Test-Path -LiteralPath $ConfigPath | Should -BeFalse
    }

    It 'retains malformed bytes if defaults cannot be used' {
        Set-TestConfig '{}'
        $before = Get-TestConfigBytes
        Mock Get-DefaultOutputDir { '' }
        { Load-Config } | Should -Throw '*default Videos folder*'
        Get-TestConfigBytes | Should -Be $before
    }

    It 'preserves unknown nested keys and Unicode through a compatible save' {
        $unicode = ([char]0x00e4).ToString() + [char]0x65e5
        $original = [pscustomobject]@{
            OutputDir = $script:Output
            Future = [pscustomobject]@{ Nested = [pscustomobject]@{ Deeper = [pscustomobject]@{
                Values = @('one', $unicode, $null, 3, $true)
            } } }
        }
        Set-TestConfig ($original | ConvertTo-Json -Depth 20)
        $before = Get-TestConfigBytes
        $cfg = Load-Config
        $selected = Join-Path $env:APPDATA 'new [x] !NAME! %PATH% output'
        [void][IO.Directory]::CreateDirectory($selected)
        $cfg.OutputDir = $selected
        Save-Config $cfg
        $saved = Load-Config
        $saved.OutputDir | Should -Be $selected
        ($saved.Future | ConvertTo-Json -Depth 20 -Compress) | Should -Be ($original.Future | ConvertTo-Json -Depth 20 -Compress)
        $backups = @(Get-ChildItem -LiteralPath $ConfigDir -Filter 'config.previous-*.json')
        $backups.Count | Should -Be 1
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($backups[0].FullName)) | Should -Be $before
    }

    It 'preserves the last valid config on a real sharing-denied replacement' {
        Save-Config ([pscustomobject]@{ OutputDir = $script:Output })
        $cfg = Load-Config
        $before = Get-TestConfigBytes
        $handle = [IO.File]::Open($ConfigPath, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        try { { Save-Config $cfg } | Should -Throw '*Cannot save config*' } finally { $handle.Dispose() }
        Get-TestConfigBytes | Should -Be $before
        @(Get-ChildItem -LiteralPath $ConfigDir -Filter '*.tmp').Count | Should -Be 0
    }

    It 'does not overwrite a first-run racing file on no-clobber promotion' {
        Mock Publish-ConfigFile {
            [IO.File]::WriteAllText($ConfigPath, 'racing writer sentinel')
            [IO.File]::Move($TemporaryPath, $ConfigPath)
        }
        { Load-Config } | Should -Throw '*Cannot save config*'
        [IO.File]::ReadAllText($ConfigPath) | Should -Be 'racing writer sentinel'
        @(Get-ChildItem -LiteralPath $ConfigDir -Filter '*.tmp').Count | Should -Be 0
    }

    It 'preserves the last valid config when temp creation fails' {
        Save-Config ([pscustomobject]@{ OutputDir = $script:Output })
        $before = Get-TestConfigBytes
        Mock Write-ConfigTemporaryFile { throw 'Synthetic disk/write denial' }
        { Save-Config (Load-Config) } | Should -Throw '*Cannot save config*disk/write denial*'
        Get-TestConfigBytes | Should -Be $before
    }

    It 'refuses excessive unknown-key depth without truncating or replacing the last valid file' {
        Save-Config ([pscustomobject]@{ OutputDir = $script:Output })
        $cfg = Load-Config
        $before = Get-TestConfigBytes
        $nested = [pscustomobject]@{ Sentinel = 'terminal value' }
        foreach ($level in 1..102) { $nested = [pscustomobject]@{ Next = $nested } }
        $cfg | Add-Member -NotePropertyName Future -NotePropertyValue $nested
        { Save-Config $cfg } | Should -Throw '*Cannot save config*nesting*'
        Get-TestConfigBytes | Should -Be $before
        @(Get-ChildItem -LiteralPath $ConfigDir -Filter '*.tmp').Count | Should -Be 0
    }

    It 'does not treat a real config read sharing failure as malformed JSON' {
        Set-TestConfig ([pscustomobject]@{ OutputDir = $script:Output } | ConvertTo-Json)
        $before = Get-TestConfigBytes
        $handle = [IO.File]::Open($ConfigPath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        try { { Load-Config } | Should -Throw '*Cannot read config*No recovery*' } finally { $handle.Dispose() }
        Get-TestConfigBytes | Should -Be $before
        @(Get-ChildItem -LiteralPath $ConfigDir -Filter 'config.invalid-*.json').Count | Should -Be 0
        Should -Invoke Get-DefaultOutputDir -Times 0 -Exactly
    }

    It 'backs up with no clobber when a diagnostic filename already exists' {
        Set-TestConfig 'original sentinel'
        $backup = Join-Path $ConfigDir 'existing-backup.json'
        [IO.File]::WriteAllText($backup, 'backup sentinel')
        { Backup-ConfigFile $backup } | Should -Throw
        [IO.File]::ReadAllText($backup) | Should -Be 'backup sentinel'
        [IO.File]::ReadAllText($ConfigPath) | Should -Be 'original sentinel'
    }

    It 'does not overwrite an existing temporary filename' {
        $temporary = Join-Path $env:APPDATA 'occupied.tmp'
        [IO.File]::WriteAllText($temporary, 'temporary sentinel')
        { Write-ConfigTemporaryFile $temporary ([byte[]]@(1, 2, 3)) } | Should -Throw
        [IO.File]::ReadAllText($temporary) | Should -Be 'temporary sentinel'
    }

    It 'retains an unknown timestamp string when the host supports string date parsing' {
        $timestamp = '2026-10-05T01:02:03.1200000Z'
        Set-TestConfig ([pscustomobject]@{ OutputDir = $script:Output; FutureDate = $timestamp } | ConvertTo-Json)
        $cfg = Load-Config
        $parsed = $cfg.FutureDate
        Save-Config $cfg
        (Load-Config).FutureDate | Should -Be $parsed
        if ($PSVersionTable.PSVersion.Major -eq 5 -or
            (Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
            (Load-Config).FutureDate | Should -BeExactly $timestamp
        }
    }

    It 'preserves the last valid config when no-clobber backup fails' {
        Save-Config ([pscustomobject]@{ OutputDir = $script:Output })
        $before = Get-TestConfigBytes
        Mock Backup-ConfigFile { throw 'Synthetic backup denial' }
        { Save-Config (Load-Config) } | Should -Throw '*Cannot save config*backup denial*'
        Get-TestConfigBytes | Should -Be $before
        @(Get-ChildItem -LiteralPath $ConfigDir -Filter '*.tmp').Count | Should -Be 0
    }

    It 'diagnoses simultaneous writer lock contention and retains current bytes' {
        Save-Config ([pscustomobject]@{ OutputDir = $script:Output })
        $cfg = Load-Config
        $before = Get-TestConfigBytes
        $handle = [IO.File]::Open(($ConfigPath + '.lock'), [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        try { { Save-Config $cfg } | Should -Throw '*config lock*' } finally { $handle.Dispose() }
        Get-TestConfigBytes | Should -Be $before
    }

    It 'rejects a stale save after another writer changes the config' {
        Save-Config ([pscustomobject]@{ OutputDir = $script:Output })
        $cfg = Load-Config
        Set-TestConfig ([pscustomobject]@{ OutputDir = $script:Output; NewKey = 'other writer' } | ConvertTo-Json)
        $before = Get-TestConfigBytes
        { Save-Config $cfg } | Should -Throw '*changed since*reload*'
        Get-TestConfigBytes | Should -Be $before
    }

    It 'compares the saved byte fingerprint with case-sensitive semantics' {
        Save-Config ([pscustomobject]@{ OutputDir = $script:Output })
        $cfg = Load-Config
        $before = Get-TestConfigBytes
        $different = $script:ConfigSnapshot.Signature.ToLowerInvariant()
        $different | Should -Not -BeExactly $script:ConfigSnapshot.Signature
        Mock Read-ConfigFile { [pscustomobject]@{ Path = $ConfigPath; Exists = $true; Signature = $different; Text = '' } }
        { Save-Config $cfg } | Should -Throw '*changed since*reload*'
        Get-TestConfigBytes | Should -Be $before
    }

    It 'refuses replacing a pre-existing config that this session never loaded' {
        Set-TestConfig ([pscustomobject]@{ OutputDir = $script:Output; Other = 'sentinel' } | ConvertTo-Json)
        $before = Get-TestConfigBytes
        { Save-Config ([pscustomobject]@{ OutputDir = $script:Output }) } | Should -Throw '*load*before*'
        Get-TestConfigBytes | Should -Be $before
    }

    It 'keeps a config-path directory and its sentinel untouched' {
        [void][IO.Directory]::CreateDirectory($ConfigPath)
        [IO.File]::WriteAllText((Join-Path $ConfigPath 'sentinel'), 'directory sentinel')
        { Load-Config } | Should -Throw '*Cannot read config*'
        [IO.File]::ReadAllText((Join-Path $ConfigPath 'sentinel')) | Should -Be 'directory sentinel'
    }

    It 'keeps the active menu preference after a failed save' {
        $cfg = [pscustomobject]@{ OutputDir = $script:Output; Unknown = 'retained' }
        $script:Choices = New-Object 'Collections.Generic.Queue[string]'
        foreach ($choice in @('1','4')) { $script:Choices.Enqueue($choice) }
        Mock Read-Host { $script:Choices.Dequeue() }
        Mock Prompt-Path { Join-Path $env:APPDATA 'new-output' }
        Mock Save-Config { throw 'Synthetic save failure' }
        { Run-TUI 'unused' 'unused' $cfg } | Should -Not -Throw
        $cfg.OutputDir | Should -Be $script:Output
        $cfg.Unknown | Should -Be 'retained'
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like '*Synthetic save failure*' }
    }
}
