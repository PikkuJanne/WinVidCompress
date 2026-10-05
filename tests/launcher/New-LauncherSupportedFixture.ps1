[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'LauncherTestSupport.ps1')
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$owner = New-WvcTestRoot
try {
    $argumentApp = Join-Path $owner.Path 'Recorder'
    $inputs = Join-Path $owner.Path 'Drop files'
    $folder = Join-Path $owner.Path 'Drop folder ! & (name) [literal]'
    $menu = Join-Path $owner.Path 'Menu check'
    $direct = Join-Path $owner.Path 'Direct PS1'
    foreach ($directory in @($argumentApp,$inputs,$folder,$menu,$direct)) {
        [void][IO.Directory]::CreateDirectory($directory)
    }
    $names = @('space name.mov','bang !NAME!.mov','amp & name.mov','paren (name).mov',
        "O'Brien.mov",'square [name].mov','percent 50%.mov',
        ('Finnish ' + [char]0x00e4 + [char]0x00f6 + '.mov'),
        ('German ' + [char]0x00fc + [char]0x00df + '.mov'),
        ([string][char]0x4e2d + [char]0x6587 + '.mov'))
    $paths = @($names | ForEach-Object { Join-Path $inputs $_ })
    foreach ($path in $paths) { [IO.File]::WriteAllText($path, 'synthetic filename sentinel') }
    Copy-Item -LiteralPath (Join-Path $repoRoot 'WinVidCompress.bat') -Destination (Join-Path $argumentApp 'WinVidCompress.bat')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Record-Arguments.ps1') -Destination (Join-Path $argumentApp 'WinVidCompress.ps1')
    [IO.File]::WriteAllText((Join-Path $argumentApp '.wvc-manual-recorder'), $owner.Token)
    Copy-Item -LiteralPath (Join-Path $repoRoot 'WinVidCompress.ps1') -Destination (Join-Path $menu 'WinVidCompress.ps1')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Record-MenuPaths.ps1') -Destination (Join-Path $menu 'Record-MenuPaths.ps1')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Record-Arguments.ps1') -Destination (Join-Path $direct 'WinVidCompress.ps1')
    [IO.File]::WriteAllText((Join-Path $direct '.wvc-manual-recorder'), $owner.Token)
    [IO.File]::WriteAllText((Join-Path $menu '.wvc-menu-recorder'), $owner.Token)
    $menuFile = Join-Path $menu 'literal %PATH% !NAME!.mov'
    $menuFolder = Join-Path $menu 'Folder %PATH% !NAME!'
    [IO.File]::WriteAllText($menuFile, 'synthetic filename sentinel')
    [void][IO.Directory]::CreateDirectory($menuFolder)
    $launcher = @'
@echo off
setlocal EnableExtensions DisableDelayedExpansion
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -NoExit -File "%~dp0Menu check\Record-MenuPaths.ps1"
'@
    [IO.File]::WriteAllText((Join-Path $owner.Path 'Check-menu.bat'),
        $launcher.Replace("`r`n", "`n").Replace("`n", "`r`n") + "`r`n", [Text.Encoding]::ASCII)
    $instructions = @'
Synthetic recorder only. These three checks finish the supported-path boundary.

1. Drag "Drop folder ! & (name) [literal]" onto Recorder/WinVidCompress.bat.
   Type exit after it records one path.
2. Open "Drop files", select all ten files, and drag onto that same BAT.
   Type exit after it records ten paths.
3. Double-click Check-menu.bat. Choose 2; enter literal %PATH% !NAME!.mov
   Choose 3; enter Folder %PATH% !NAME!
   Choose 4; type exit.

Reply: "Completed both Explorer drops and the menu check" plus any visible error.
The agent will check the local reports. No JSON inspection is needed.
'@
    $instructionPath = Join-Path $owner.Path 'Instructions.txt'
    [IO.File]::WriteAllText($instructionPath, $instructions, [Text.Encoding]::ASCII)
    $metadata = [pscustomobject]@{
        Owner = $owner; SourceCommit = (& git -C $repoRoot rev-parse HEAD)
        SourceDirty = [bool]@(& git -C $repoRoot status --porcelain).Count
        SupportBoundary = 'D005'; ArgumentApp = $argumentApp; Inputs = $paths; Folder = $folder
        LauncherSHA256 = (Get-FileHash -LiteralPath (Join-Path $argumentApp 'WinVidCompress.bat')).Hash
        ArgumentRecorderSHA256 = (Get-FileHash -LiteralPath (Join-Path $argumentApp 'WinVidCompress.ps1')).Hash
        ApplicationSHA256 = (Get-FileHash -LiteralPath (Join-Path $menu 'WinVidCompress.ps1')).Hash
        MenuRecorderSHA256 = (Get-FileHash -LiteralPath (Join-Path $menu 'Record-MenuPaths.ps1')).Hash
        DirectApp = $direct
        DirectRecorderSHA256 = (Get-FileHash -LiteralPath (Join-Path $direct 'WinVidCompress.ps1')).Hash
        MenuApp = $menu; MenuFile = $menuFile; MenuFolder = $menuFolder
        RestoreAcls = @(); Instructions = $instructionPath
    }
    $manifest = Join-Path $owner.Path 'manual-fixture.json'
    Write-WvcTestJson $manifest $metadata
    [pscustomobject]@{ Manifest = $manifest; Instructions = $instructionPath; Owner = $owner } | ConvertTo-Json -Depth 4
} catch {
    Remove-WvcTestRoot $owner
    throw
}
