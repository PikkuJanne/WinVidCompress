[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ModuleRoot,
    [Parameter(Mandatory = $true)][string[]]$TestPath,
    [Parameter(Mandatory = $true)][string]$ReportPath,
    [switch]$IncludeKnownDefects
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'TestSupport.ps1')
$dependencies = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Dependencies.psd1')
$pesterManifest = Join-Path $ModuleRoot ('Pester/' + $dependencies.Pester + '/Pester.psd1')
Import-Module $pesterManifest -ErrorAction Stop
if ((Get-Module Pester).Version -ne [version]$dependencies.Pester) { throw 'Unexpected Pester version.' }
$config = New-PesterConfiguration
$containers = @($TestPath | ForEach-Object { $_ -split '\|' } | ForEach-Object {
    if ([IO.Path]::GetFileName($_) -in @('Harness.Tests.ps1','Ci.Tests.ps1')) {
        New-PesterContainer -Path $_ -Data @{ ModuleRoot = $ModuleRoot }
    } else { New-PesterContainer -Path $_ }
})
$config.Run.Container = $containers
$config.Run.PassThru = $true
$config.Output.Verbosity = 'Detailed'
if (-not $IncludeKnownDefects) { $config.Filter.ExcludeTag = 'KnownDefect' }
$result = Invoke-Pester -Configuration $config
$index = 0
$cases = @($result.Tests | ForEach-Object {
    $index++
    $reason = if ($_.Result -eq 'NotRun') { 'Excluded by selected tier/filter; not executed.' } else { '' }
    New-WvcTestCase ('{0:D3}:{1}' -f $index,$_.ExpandedName) $_.Result $reason
})
if ($result.Result -ne 'Passed' -and -not @($cases | Where-Object Status -eq 'Failed').Count) {
    $cases += New-WvcTestCase 'pester-container' 'Failed' 'Pester failed outside a test case.'
}
$summary = Get-WvcTierSummary 'Quick' $cases
$report = [pscustomobject][ordered]@{
    SchemaVersion = 1
    Kind = 'Pester'
    PowerShell = $PSVersionTable.PSVersion.ToString()
    Edition = $PSVersionTable.PSEdition
    Pester = (Get-Module Pester).Version.ToString()
    Counts = $summary.Counts
    Cases = $cases
}
Write-WvcTestJson $ReportPath $report
exit $summary.ExitCode
