[CmdletBinding()]
param()

# Explicit developer preparation for an actual human Explorer check. No UI automation.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop' -or $PSVersionTable.PSVersion.Major -ne 5) {
    throw 'Prepare this isolated fixture with Windows PowerShell 5.1.'
}
$testsRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $testsRoot
. (Join-Path $testsRoot 'TestSupport.ps1')
$owner = New-WvcTestRoot
try {
    $app = Join-Path $owner.Path 'app'
    $bin = Join-Path $owner.Path 'bin'
    $config = Join-Path $owner.Path 'appdata/WinVidCompress'
    $output = Join-Path $owner.Path 'output'
    foreach ($directory in @($app,$bin,$config,$output)) { [void][IO.Directory]::CreateDirectory($directory) }
    foreach ($file in @('WinVidCompress.ps1','WinVidCompress.bat')) {
        Copy-Item -LiteralPath (Join-Path $repoRoot $file) -Destination (Join-Path $app $file)
    }
    # Startup dependency sentinels, never encoders. An accidental invocation fails.
    Add-Type -TypeDefinition 'public static class WvcMenuSentinel { public static int Main(string[] args) { return 13; } }' `
        -OutputAssembly (Join-Path $bin 'ffmpeg.exe') -OutputType ConsoleApplication
    Copy-Item -LiteralPath (Join-Path $bin 'ffmpeg.exe') -Destination (Join-Path $bin 'ffprobe.exe')
    Write-WvcTestJson (Join-Path $config 'config.json') ([pscustomobject]@{ OutputDir = $output })
    $bootstrap = @'
@echo off
setlocal
set "APPDATA=%~dp0appdata"
set "PSModulePath="
set "PATH=%~dp0bin;%SystemRoot%\System32\WindowsPowerShell\v1.0;%SystemRoot%\System32;%SystemRoot%"
call "%~dp0app\WinVidCompress.bat"
'@
    [IO.File]::WriteAllText((Join-Path $owner.Path 'Check-Menu.bat'),
        ($bootstrap.Replace("`r`n", "`n").Replace("`n", "`r`n") + "`r`n"), [Text.Encoding]::ASCII)
    $head = & git -C $repoRoot rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Cannot identify fixture source commit.' }
    $metadata = [pscustomobject]@{
        Owner = $owner; SourceCommit = $head
        ApplicationSHA256 = (Get-FileHash -LiteralPath (Join-Path $app 'WinVidCompress.ps1')).Hash
        LauncherSHA256 = (Get-FileHash -LiteralPath (Join-Path $app 'WinVidCompress.bat')).Hash
        Launcher = Join-Path $owner.Path 'Check-Menu.bat'
        Instructions = 'In Explorer, double-click Check-Menu.bat. Choose 4 once. Confirm the menu disappears and a usable PowerShell prompt remains; type exit to close. Report the actual result. This preparation is not a passed manual check. Do not choose compression options: these dependency sentinels are not encoders.'
    }
    Write-WvcTestJson (Join-Path $owner.Path 'manual-fixture.json') $metadata
    $metadata | ConvertTo-Json -Depth 5
} catch {
    Remove-WvcTestRoot $owner
    throw
}
