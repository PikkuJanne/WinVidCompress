BeforeAll {
    . (Join-Path $PSScriptRoot 'LauncherTestSupport.ps1')
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:Owner = New-WvcTestRoot
    $script:App = Join-Path $Owner.Path ("app !NAME! & (round) [literal] %PATH% O'Brien " + [char]0x00e4 + [char]0x4e2d)
    [void][IO.Directory]::CreateDirectory($App)
    $script:Bat = Join-Path $App 'WinVidCompress.bat'
    $script:Recorder = Join-Path $App 'WinVidCompress.ps1'
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'WinVidCompress.bat') -Destination $Bat
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Record-Arguments.ps1') -Destination $Recorder
    $script:PS51 = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $script:Names = @('space name.mov','bang !NAME!.mov','amp & name.mov','paren (name).mov',
        "O'Brien.mov",'square [name].mov','percent 50%.mov','literal %PATH%.mov',
        ('Finnish ' + [char]0x00e4 + [char]0x00f6 + '.mov'),
        ('German ' + [char]0x00fc + [char]0x00df + '.mov'),
        ([string][char]0x4e2d + [char]0x6587 + '.mov'))
    $script:Paths = @($Names | ForEach-Object { Join-Path $Owner.Path $_ })
    foreach ($path in $Paths) { [IO.File]::WriteAllText($path, 'synthetic filename sentinel') }
    $script:Folder = Join-Path $Owner.Path 'folder ! & [literal]'
    [void][IO.Directory]::CreateDirectory($Folder)
    $script:Environment = @{
        APPDATA = (Join-Path $Owner.Path 'appdata'); WVC_ARGV_AUTOMATED = '1'; WVC_ARGV_REPORT = ''
        WVC_TEST_BAT = $Bat; NAME = 'EXPANSION_SENTINEL'
        PATH = (Split-Path -Parent $PS51) + ';PERCENT_EXPANSION_SENTINEL'
    }

    function Invoke-BatchRecord([string[]]$Values, [string]$Delayed = 'off') {
        $environmentCopy = $Environment.Clone()
        $slots = @()
        for ($i = 0; $i -lt $Values.Count; $i++) {
            $key = 'WVC_INPUT_' + $i
            $environmentCopy[$key] = $Values[$i]
            $slots += ('"%' + $key + '%"')
        }
        $arguments = '/d /v:' + $Delayed + ' /s /c ""%WVC_TEST_BAT%" ' + ($slots -join ' ') + '"'
        Read-WvcArgumentRecord (Invoke-WvcLauncherProcess $env:ComSpec $arguments $environmentCopy)
    }

    function Assert-RecordedPaths($Record, [string[]]$Expected) {
        $actual = @($Record.Paths)
        $actual.Count | Should -Be $Expected.Count
        # Raw argv records the separate powershell.exe -File boundary too.
        $fileIndex = [Array]::IndexOf([object[]]$Record.RawArguments, '-File')
        $fileIndex | Should -BeGreaterThan -1
        $Record.RawArguments[$fileIndex + 1] | Should -BeExactly $Recorder
        @($Record.RawArguments).Count | Should -Be ($fileIndex + 2 + $Expected.Count)
        for ($i = 0; $i -lt $Expected.Count; $i++) {
            $actual[$i] | Should -BeExactly $Expected[$i]
            $Record.RawArguments[$fileIndex + 2 + $i] | Should -BeExactly $Expected[$i]
        }
    }
}

AfterAll { if ($Owner) { Remove-WvcTestRoot $Owner } }

Describe 'Accepted literal-path menu route [WVC-M1-02-A02]' {
    BeforeAll {
        $script:MenuEnvironment = @{ APPDATA = $env:APPDATA; PATH = $env:PATH; NAME = $env:NAME }
        $env:APPDATA = Join-Path $Owner.Path 'menu-appdata'
        $env:PATH = 'WVC_PATH_SENTINEL'
        $env:NAME = 'WVC_NAME_SENTINEL'
        . (Join-Path $RepoRoot 'WinVidCompress.ps1')
        $script:LiteralMenuFolder = Join-Path $Owner.Path 'Folder %PATH% !NAME! [literal]'
        [void][IO.Directory]::CreateDirectory($LiteralMenuFolder)
        $script:LiteralMenuFile = Join-Path $LiteralMenuFolder 'literal %PATH% !NAME!.mov'
        [IO.File]::WriteAllText($LiteralMenuFile, 'synthetic filename sentinel')
    }
    AfterAll {
        foreach ($key in $MenuEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key, $MenuEnvironment[$key], 'Process') }
    }
    It 'passes a literal variable-like <Kind> selection to processing without expansion' -TestCases @(
        @{ Kind = 'file'; Choice = '2' }, @{ Kind = 'folder'; Choice = '3' }
    ) {
        param($Kind,$Choice)
        $selected = if ($Kind -eq 'file') { $LiteralMenuFile } else { $LiteralMenuFolder }
        $script:MenuResponses = New-Object 'Collections.Generic.Queue[string]'
        foreach ($response in @($Choice,$selected,'4')) { $script:MenuResponses.Enqueue($response) }
        Mock Read-Host { $script:MenuResponses.Dequeue() }
        Mock Write-Host {}
        Mock Process-Paths {}
        Mock Save-Config { throw 'Unexpected config save' }
        Run-TUI 'unused-encoder' 'unused-probe' ([pscustomobject]@{ OutputDir = (Join-Path $Owner.Path 'output') })
        Should -Invoke Process-Paths -Times 1 -Exactly -ParameterFilter {
            $paths.Count -eq 1 -and $paths[0] -ceq $selected
        }
        $script:MenuResponses.Count | Should -Be 0
        [IO.File]::ReadAllText($LiteralMenuFile) | Should -BeExactly 'synthetic filename sentinel'
        Test-Path -LiteralPath (Join-Path $env:APPDATA 'WinVidCompress/config.json') | Should -BeFalse
    }
}

Describe 'Measured launcher arguments [WVC-M1-02]' {
    It 'forwards zero arguments for double-click menu startup' {
        $record = Invoke-BatchRecord @()
        Assert-RecordedPaths $record @()
        $record.Edition | Should -Be 'Desktop'
        $record.PowerShell | Should -BeLike '5.1.*'
    }

    It 'forwards one file without changing special filename segments' {
        foreach ($path in $Paths) { Assert-RecordedPaths (Invoke-BatchRecord @($path)) @($path) }
    }

    It 'forwards a folder' { Assert-RecordedPaths (Invoke-BatchRecord @($Folder)) @($Folder) }

    It 'characterizes native quote handling for a CMD folder ending in backslash' {
        # CMD preserves the slash; powershell.exe's native argv parser consumes it
        # as an escape for the closing quote. Supported BAT spelling omits it.
        $value = $Folder + '\'
        (Invoke-BatchRecord @($value)).Paths[0] | Should -BeExactly ($Folder + '"')
    }

    It 'forwards multiple files and a folder in order with matching variables set' {
        $values = @($Paths) + @($Folder)
        Assert-RecordedPaths (Invoke-BatchRecord $values) $values
    }

    It 'preserves all names through direct PS1 -File on the current supported host' {
        $arguments = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$Recorder) + $Paths
        $native = ($arguments | ForEach-Object { ConvertTo-WvcNativeArgument $_ }) -join ' '
        Assert-RecordedPaths (Read-WvcArgumentRecord (Invoke-WvcLauncherProcess (Get-Process -Id $PID).Path $native $Environment)) $Paths
    }

    It 'supports no-argument invocation from a caller with delayed expansion enabled' {
        # No bangs in the caller-expanded values: cmd can destroy those BEFORE BAT starts.
        $plainApp = Join-Path $Owner.Path 'plain-app'
        [void][IO.Directory]::CreateDirectory($plainApp)
        Copy-Item -LiteralPath $Bat -Destination (Join-Path $plainApp 'WinVidCompress.bat')
        Copy-Item -LiteralPath $Recorder -Destination (Join-Path $plainApp 'WinVidCompress.ps1')
        $copy = $Environment.Clone()
        $copy.WVC_TEST_BAT = Join-Path $plainApp 'WinVidCompress.bat'
        $result = Invoke-WvcLauncherProcess $env:ComSpec '/d /v:on /s /c ""%WVC_TEST_BAT%""' $copy
        @( (Read-WvcArgumentRecord $result).Paths ).Count | Should -Be 0
    }

    It 'characterizes percent expansion in a literal cmd command before BAT starts' {
        $copy = $Environment.Clone()
        $plainApp = Join-Path $Owner.Path 'cmd-percent'
        [void][IO.Directory]::CreateDirectory($plainApp)
        Copy-Item -LiteralPath $Bat -Destination (Join-Path $plainApp 'WinVidCompress.bat')
        Copy-Item -LiteralPath $Recorder -Destination (Join-Path $plainApp 'WinVidCompress.ps1')
        $copy.WVC_TEST_BAT = Join-Path $plainApp 'WinVidCompress.bat'
        $result = Invoke-WvcLauncherProcess $env:ComSpec '/d /v:off /s /c ""%WVC_TEST_BAT%" "literal %PATH%.mov""' $copy
        (Read-WvcArgumentRecord $result).Paths[0] | Should -BeExactly ('literal ' + $Environment.PATH + '.mov')
    }

    It 'keeps the launcher free of expression evaluation and argument reconstruction [A03]' {
        $text = [IO.File]::ReadAllText($Bat)
        $text | Should -Not -Match '(?i)EnableDelayedExpansion|set\s+"?ARGS=|!ARGS!|\bcall\b|Invoke-Expression|\bcmd\s+/c\b|Set-ExecutionPolicy'
        $text | Should -Match '(?i)DisableDelayedExpansion'
        $text | Should -Match '(?im)^.*-File "%SCRIPT%" %\*\s*$'
        $text | Should -Not -Match '(?i)-Command\b'
        $source = [IO.File]::ReadAllText((Join-Path $RepoRoot 'WinVidCompress.ps1'))
        $source | Should -Not -Match '(?i)Invoke-Expression|Set-ExecutionPolicy'
    }

    It 'uses the production parameter declaration in the recorder' {
        $tokens = $null; $errors = $null
        $production = [Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $RepoRoot 'WinVidCompress.ps1'), [ref]$tokens, [ref]$errors)
        $recording = [Management.Automation.Language.Parser]::ParseFile($Recorder, [ref]$tokens, [ref]$errors)
        $recording.ParamBlock.Extent.Text.Replace("`r`n", "`n") |
            Should -BeExactly $production.ParamBlock.Extent.Text.Replace("`r`n", "`n")
    }

    It 'preserves synthetic filename sentinels without creating app config or media' {
        foreach ($path in $Paths) { [IO.File]::ReadAllText($path) | Should -BeExactly 'synthetic filename sentinel' }
        Test-Path -LiteralPath $Environment.APPDATA | Should -BeFalse
    }
}

Describe 'Actionable launcher startup errors [WVC-M1-02-A04]' {
    BeforeEach {
        $script:ErrorApp = Join-Path $Owner.Path ('error-' + [guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($ErrorApp)
        Copy-Item -LiteralPath $Bat -Destination (Join-Path $ErrorApp 'WinVidCompress.bat')
        $script:ErrorEnvironment = $Environment.Clone()
        $ErrorEnvironment.WVC_TEST_BAT = Join-Path $ErrorApp 'WinVidCompress.bat'
        $ErrorEnvironment.APPDATA = Join-Path $ErrorApp 'appdata'
        $ErrorEnvironment.PATH = (Split-Path -Parent $PS51)
    }

    It 'reports the missing adjacent PS1 and how to fix it' {
        $result = Invoke-WvcLauncherProcess $env:ComSpec '/d /v:off /s /c ""%WVC_TEST_BAT%""' $ErrorEnvironment
        $result.ExitCode | Should -Be 2
        $result.StdErr | Should -Match 'cannot find.*WinVidCompress.ps1'
        $result.StdErr | Should -Match 'same folder'
        Test-Path -LiteralPath $ErrorEnvironment.APPDATA | Should -BeFalse
    }

    It 'reports unavailable Windows PowerShell' {
        Copy-Item -LiteralPath $Recorder -Destination (Join-Path $ErrorApp 'WinVidCompress.ps1')
        $ErrorEnvironment.SystemRoot = Join-Path $ErrorApp 'synthetic-windows-root'
        $result = Invoke-WvcLauncherProcess $env:ComSpec '/d /v:off /s /c ""%WVC_TEST_BAT%""' $ErrorEnvironment
        $result.ExitCode | Should -Be 2
        $result.StdErr | Should -Match 'cannot find Windows PowerShell'
        $result.StdErr | Should -Match 'Windows PowerShell 5.1'
    }

    It 'retains native launch diagnostics and a nonzero code for an unusable PowerShell executable' {
        Copy-Item -LiteralPath $Recorder -Destination (Join-Path $ErrorApp 'WinVidCompress.ps1')
        $ErrorEnvironment.SystemRoot = Join-Path $ErrorApp 'synthetic-windows-root'
        $directory = Join-Path $ErrorEnvironment.SystemRoot 'System32/WindowsPowerShell/v1.0'
        [void][IO.Directory]::CreateDirectory($directory)
        [IO.File]::WriteAllText((Join-Path $directory 'powershell.exe'), 'unusable synthetic executable')
        $result = Invoke-WvcLauncherProcess $env:ComSpec '/d /v:off /s /c ""%WVC_TEST_BAT%""' $ErrorEnvironment
        $result.ExitCode | Should -Not -Be 0
        $result.StdErr | Should -Match 'PowerShell returned error'
        $result.StdErr | Should -Match 'Check access'
    }

    It 'reports missing FFmpeg before config or output creation' {
        Copy-Item -LiteralPath (Join-Path $RepoRoot 'WinVidCompress.ps1') -Destination (Join-Path $ErrorApp 'WinVidCompress.ps1')
        $result = Invoke-WvcLauncherProcess $env:ComSpec '/d /v:off /s /c ""%WVC_TEST_BAT%""' $ErrorEnvironment "exit`r`n"
        $result.StdErr | Should -Match 'ffmpeg.exe not found.*PATH or next to this script'
        Test-Path -LiteralPath $ErrorEnvironment.APPDATA | Should -BeFalse
    }

    It 'reports missing FFprobe before config or output creation' {
        Copy-Item -LiteralPath (Join-Path $RepoRoot 'WinVidCompress.ps1') -Destination (Join-Path $ErrorApp 'WinVidCompress.ps1')
        [IO.File]::WriteAllText((Join-Path $ErrorApp 'ffmpeg.exe'), 'startup-only readable sentinel, never executed')
        $result = Invoke-WvcLauncherProcess $env:ComSpec '/d /v:off /s /c ""%WVC_TEST_BAT%""' $ErrorEnvironment "exit`r`n"
        $result.StdErr | Should -Match 'ffprobe.exe not found.*PATH or next to this script'
        Test-Path -LiteralPath $ErrorEnvironment.APPDATA | Should -BeFalse
    }

    It 'rejects an adjacent directory masquerading as a dependency' {
        Copy-Item -LiteralPath (Join-Path $RepoRoot 'WinVidCompress.ps1') -Destination (Join-Path $ErrorApp 'WinVidCompress.ps1')
        [void][IO.Directory]::CreateDirectory((Join-Path $ErrorApp 'ffmpeg.exe'))
        $result = Invoke-WvcLauncherProcess $env:ComSpec '/d /v:off /s /c ""%WVC_TEST_BAT%""' $ErrorEnvironment "exit`r`n"
        $result.StdErr | Should -Match 'ffmpeg.exe not found.*PATH or next to this script'
        Test-Path -LiteralPath $ErrorEnvironment.APPDATA | Should -BeFalse
    }

    It 'reports a real read-denied dependency with the underlying diagnostic' {
        Copy-Item -LiteralPath (Join-Path $RepoRoot 'WinVidCompress.ps1') -Destination (Join-Path $ErrorApp 'WinVidCompress.ps1')
        $dependency = Join-Path $ErrorApp 'ffmpeg.exe'
        [IO.File]::WriteAllText($dependency, 'permission fixture, never executed')
        $originalAcl = Get-Acl -LiteralPath $dependency
        $deniedAcl = Get-Acl -LiteralPath $dependency
        $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $rule = New-Object Security.AccessControl.FileSystemAccessRule($sid,
            [Security.AccessControl.FileSystemRights]::ReadData, [Security.AccessControl.AccessControlType]::Deny)
        $deniedAcl.AddAccessRule($rule)
        try {
            Set-Acl -LiteralPath $dependency -AclObject $deniedAcl
            $result = Invoke-WvcLauncherProcess $env:ComSpec '/d /v:off /s /c ""%WVC_TEST_BAT%""' $ErrorEnvironment "exit`r`n"
            $result.StdErr | Should -Match 'ffmpeg.exe cannot be read'
            $result.StdErr | Should -Match 'Check read/execute permissions'
            $result.StdErr | Should -Match 'Details:'
            Test-Path -LiteralPath $ErrorEnvironment.APPDATA | Should -BeFalse
        } finally { Set-Acl -LiteralPath $dependency -AclObject $originalAcl }
    }
}
