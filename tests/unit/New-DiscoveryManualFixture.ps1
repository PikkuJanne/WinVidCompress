[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) { throw 'Prepare long path fixtures with PS7; both hosts then check them.' }
$testsRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $testsRoot
. (Join-Path $testsRoot 'TestSupport.ps1')
$owner = New-WvcTestRoot
try {
    Copy-Item -LiteralPath (Join-Path $repoRoot 'WinVidCompress.ps1') -Destination $owner.Path
    $unicode = ([char]0x00E4).ToString() + [char]0x00FC + [char]0x4E2D
    $unicodeRoot = Join-Path $owner.Path ('source [literal] ' + $unicode)
    $longRoot = $owner.Path
    while ($longRoot.Length -lt 285) { $longRoot = Join-Path $longRoot 'long-directory-0123456789' }
    $nearRoot = $owner.Path
    while ($nearRoot.Length -lt 195) { $nearRoot = Join-Path $nearRoot 'near-limit-0123456789' }
    $cases = @()
    foreach ($entry in @(@{ Id = 'unicode-local'; Path = $unicodeRoot },
        @{ Id = 'long-below-260'; Path = $nearRoot }, @{ Id = 'long-above-260'; Path = $longRoot })) {
        [void][IO.Directory]::CreateDirectory($entry.Path)
        $file = Join-Path $entry.Path ('clip [one] ' + $unicode + '.MOV')
        [IO.File]::WriteAllText($file, 'synthetic discovery sentinel; no media')
        $cases += [pscustomobject]@{ Id = $entry.Id; Path = $entry.Path; ExpectedSHA256 = (Get-FileHash -LiteralPath $file).Hash }
    }
    $drive = [IO.Path]::GetPathRoot($unicodeRoot)
    $unc = '\\localhost\' + $drive.Substring(0,1) + '$\' + $unicodeRoot.Substring($drive.Length)
    if (-not (Test-Path -LiteralPath $unc -PathType Container)) {
        throw 'Existing localhost administrative UNC is unavailable; this kit creates no shares/settings.'
    }
    $cases += [pscustomobject]@{ Id = 'unicode-unc-localhost'; Path = $unc; ExpectedSHA256 = $cases[0].ExpectedSHA256 }
    $head = & git -C $repoRoot rev-parse HEAD
    if ($LASTEXITCODE -ne 0) { throw 'Cannot identify fixture source commit.' }
    $metadata = [pscustomobject]@{ Owner = $owner; SourceCommit = $head; Cases = $cases }
    $fixture = Join-Path $owner.Path 'discovery-fixture.json'
    Write-WvcTestJson $fixture $metadata
    $checker = Join-Path $PSScriptRoot 'Invoke-DiscoveryPathCheck.ps1'
    $ps51 = (Get-Command powershell.exe -ErrorAction Stop).Source
    $ps7 = (Get-Process -Id $PID).Path
    $wrapper = "@echo off`r`nsetlocal DisableDelayedExpansion`r`n" +
        ('"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}" -Fixture "{2}"' -f $ps51,$checker,$fixture) + "`r`n" +
        ('"{0}" -NoProfile -ExecutionPolicy Bypass -File "{1}" -Fixture "{2}"' -f $ps7,$checker,$fixture) + "`r`n"
    [IO.File]::WriteAllText((Join-Path $owner.Path 'Check-Discovery.bat'),$wrapper,[Text.Encoding]::ASCII)
    $metadata | ConvertTo-Json -Depth 8
} catch {
    Remove-WvcTestRoot $owner
    throw
}
