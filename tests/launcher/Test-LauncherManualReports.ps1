[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Manifest,
    [ValidateSet('zero','single','folder','multiple')]
    [string[]]$Case = @('zero','single','folder','multiple')
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'LauncherTestSupport.ps1')
$metadata = Get-Content -LiteralPath $Manifest -Raw -Encoding UTF8 | ConvertFrom-Json
[void](Assert-WvcTestRoot $metadata.Owner)
if ((Get-FileHash -LiteralPath (Join-Path $metadata.ArgumentApp 'WinVidCompress.bat')).Hash -ne $metadata.LauncherSHA256) {
    throw 'Prepared BAT hash changed.'
}
$reports = @(Get-ChildItem -LiteralPath $metadata.ArgumentApp -Filter 'argv-*.json' -File | ForEach-Object {
    Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
})
$expected = @(
    @{ Id = 'zero'; Paths = @() },
    @{ Id = 'single'; Paths = @($metadata.Inputs[0]) },
    @{ Id = 'folder'; Paths = @($metadata.Folder) },
    @{ Id = 'multiple'; Paths = @($metadata.Inputs) }
)
$checks = @()
function Test-ExactPaths($Record, [string[]]$Expected) {
    $received = @($Record.Paths)
    if ($received.Count -ne $Expected.Count) { return $false }
    foreach ($value in $Expected) {
        if (@($received | Where-Object { [string]::Equals($_, $value, [StringComparison]::Ordinal) }).Count -ne 1) { return $false }
    }
    return $true
}
function Test-RawArguments($Record) {
    $raw = @($Record.RawArguments)
    $paths = @($Record.Paths)
    $index = [Array]::IndexOf([object[]]$raw, '-File')
    if ($index -lt 0 -or $index+1 -ge $raw.Count -or
        $raw[$index + 1] -cne (Join-Path $metadata.ArgumentApp 'WinVidCompress.ps1')) { return $false }
    $pathOffset=$index+2
    # Accept retained historical records and the explicit current keep-open flag.
    if ($raw.Count -gt $pathOffset -and $raw[$pathOffset] -ceq '-KeepOpen') { $pathOffset++ }
    if ($raw.Count -ne ($pathOffset+$paths.Count)) { return $false }
    for ($i = 0; $i -lt $paths.Count; $i++) {
        if (-not [string]::Equals($raw[$pathOffset + $i], $paths[$i], [StringComparison]::Ordinal)) { return $false }
    }
    return $Record.Edition -eq 'Desktop' -and $Record.PowerShell -like '5.1.*'
}
foreach ($expectedCase in @($expected | Where-Object { $_.Id -in $Case })) {
    $matches = @($reports | Where-Object {
        # Explorer selection order is not guaranteed; count and ordinal membership are.
        (Test-RawArguments $_) -and (Test-ExactPaths $_ @($expectedCase.Paths))
    })
    $state = if ($matches.Count) { 'Passed' } else { 'NotRun' }
    $checks += New-WvcTestCase $expectedCase.Id $state 'Data check only; Explorer/human observation must be recorded separately.'
}
$unmatched = @($reports | Where-Object {
    $record = $_
    -not (Test-RawArguments $record) -or -not @($expected | Where-Object { Test-ExactPaths $record @($_.Paths) }).Count
})
if ($unmatched.Count) { $checks += New-WvcTestCase 'unexpected-arguments' 'Failed' 'Recorded paths differ from the fixture; inspect local reports for caller expansion.' }
$summary = Get-WvcTierSummary 'Manual' $checks
[pscustomobject]@{ Kind = 'ManualRecorderData'; Counts = $summary.Counts; Cases = $checks;
    Reports = $reports.Count; HumanExplorerObservation = 'Not established by this checker' } | ConvertTo-Json -Depth 5
exit $summary.ExitCode
