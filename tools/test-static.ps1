[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ModuleRoot,[string[]]$Paths,[string]$BaseCommit,
    [Parameter(Mandatory=$true)][string]$ReportPath)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
. (Join-Path $repo 'tests/TestSupport.ps1')
. (Join-Path $repo 'tests/CiSupport.ps1')
try {
    if ($BaseCommit) {
        if ($Paths) {throw 'Select explicit paths or a Git base.'}
        $Paths=@(Get-WvcCiChangedPaths $repo $BaseCommit)
    }
    $report=Invoke-WvcCiAnalysis @($Paths) $ModuleRoot
    Write-WvcTestJson $ReportPath $report
    if(-not $report.Passed){exit 1}
    exit 0
} catch {
    [Console]::Error.WriteLine('Static policy execution failed; no success report was produced.')
    exit 1
}
