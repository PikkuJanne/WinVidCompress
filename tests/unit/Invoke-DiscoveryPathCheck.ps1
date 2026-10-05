[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$Fixture, [switch]$Automated)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
$metadata = Get-Content -LiteralPath $Fixture -Raw -Encoding UTF8 | ConvertFrom-Json
[void](Assert-WvcTestRoot $metadata.Owner)
$originalAppData = $env:APPDATA
$env:APPDATA = Join-Path $metadata.Owner.Path 'appdata'
$results = @()
$labels = @{
    'unicode-local' = 'Local path with international characters'
    'long-below-260' = 'Long local path'
    'long-above-260' = 'Local path longer than 260 characters'
    'unicode-unc-localhost' = 'Network-style path (UNC)'
}
if (-not $Automated) {
    Write-Host ("`nWindows path check - PowerShell {0}" -f $PSVersionTable.PSVersion)
    Write-Host 'File counts, source hashes and path handling are checked automatically.'
}
try {
    . (Join-Path $metadata.Owner.Path 'WinVidCompress.ps1')
    foreach ($case in $metadata.Cases) {
        $scan = Get-InputScan $case.Path
        $hashes = @($scan.Files | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash })
        $matched = $scan.Succeeded -and $scan.Files.Count -eq 1 -and
            $hashes.Count -eq 1 -and $hashes[0] -eq $case.ExpectedSHA256
        $results += [pscustomobject]@{ Id = $case.Id; PathLength = $case.Path.Length;
            Matched = [bool]$matched; Found = $scan.Files.Count;
            ErrorKinds = @($scan.Errors | ForEach-Object { $_.Kind }) }
        if (-not $Automated) {
            $label = if ($labels.ContainsKey($case.Id)) { $labels[$case.Id] } else { $case.Id }
            if ($matched) {
                Write-Host ("PASS - $label") -ForegroundColor Green
            } else {
                Write-Host ("FAIL - $label") -ForegroundColor Red
                Write-Host ("    Found {0}; expected one matching source." -f $scan.Files.Count)
                foreach ($errorRecord in $scan.Errors) { Write-Host ("    $($errorRecord.Kind): $($errorRecord.Message)") }
            }
        }
    }
} finally { $env:APPDATA = $originalAppData }
$observation = 'NotRun'
if (-not $Automated) {
    $sample = ([char]0x00E4).ToString() + ' ' + [char]0x00FC + ' ' + [char]0x4E2D
    Write-Host ("`nCharacter sample: $sample")
    Write-Host 'Only confirm that the window opened normally and the sample is readable.'
    Write-Host 'You do not need to inspect file paths, hashes or reports. This checks discovery with synthetic files.'
    $answer = Read-Host 'Type PASS, FAIL, or UNSURE if you cannot tell'
    $observation = if ($answer -ceq 'UNSURE') { 'NotRun' }
        elseif ($answer -ceq 'PASS' -and @($results | Where-Object { -not $_.Matched }).Count -eq 0) { 'Passed' }
        else { 'Failed' }
}
$report = [pscustomobject]@{ SourceCommit = $metadata.SourceCommit;
    PowerShell = $PSVersionTable.PSVersion.ToString(); Edition = $PSVersionTable.PSEdition;
    Automated = [bool]$Automated; HumanObservation = $observation; Cases = $results;
    ApplicationSHA256 = (Get-FileHash -LiteralPath (Join-Path $metadata.Owner.Path 'WinVidCompress.ps1')).Hash }
$suffix = if ($Automated) { 'automated' } else { 'manual' }
Write-WvcTestJson (Join-Path $metadata.Owner.Path ("$suffix-$($PSVersionTable.PSEdition).json")) $report
if ($Automated) { $report | ConvertTo-Json -Depth 8 }
else { Write-Host ("Observation: $observation. Detailed results saved automatically.") }
if (-not $Automated) { [void](Read-Host 'Press Enter to close this check') }
if (@($results | Where-Object { -not $_.Matched }).Count -gt 0 -or $observation -eq 'Failed') { exit 1 }
if (-not $Automated -and $observation -eq 'NotRun') { exit 2 }
exit 0
