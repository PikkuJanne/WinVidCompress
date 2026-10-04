[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ModuleRoot,
    [switch]$KnownDefects
)

$ErrorActionPreference = 'Stop'
$dependencies = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Dependencies.psd1')
Import-Module (Join-Path $ModuleRoot ('Pester/' + $dependencies.Pester + '/Pester.psd1')) -ErrorAction Stop
if ((Get-Module Pester).Version -ne [version]$dependencies.Pester) { throw 'Pinned Pester version is required.' }

$configuration = New-PesterConfiguration
$configuration.Run.Path = Join-Path $PSScriptRoot 'WinVidCompress.Characterization.Tests.ps1'
$configuration.Run.PassThru = $true
$configuration.Output.Verbosity = 'Detailed'
if ($KnownDefects) {
    $configuration.Filter.Tag = 'KnownDefect'
} else {
    $configuration.Filter.ExcludeTag = 'KnownDefect'
}
$result = Invoke-Pester -Configuration $configuration
[pscustomobject]@{
    PowerShell = $PSVersionTable.PSVersion.ToString()
    Edition = $PSVersionTable.PSEdition
    Pester = (Get-Module Pester).Version.ToString()
    KnownDefectRun = [bool]$KnownDefects
    Passed = $result.PassedCount
    Failed = $result.FailedCount
    Skipped = $result.SkippedCount
    NotRun = $result.NotRunCount
    FailedTests = @($result.Failed | ForEach-Object { $_.ExpandedName })
} | ConvertTo-Json -Depth 5
if ($result.FailedCount -gt 0 -or $result.Result -ne 'Passed') { exit 1 }
exit 0
