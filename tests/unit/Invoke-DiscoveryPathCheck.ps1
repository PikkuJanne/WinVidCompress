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
            Write-Host ("`n{0} ({1} characters): {2}" -f $case.Id,$case.Path.Length,$case.Path)
            Write-Host ("Matched expected single source/hash: {0}; found: {1}" -f $matched,$scan.Files.Count)
            foreach ($file in $scan.Files) { Write-Host ("    $file") }
            foreach ($errorRecord in $scan.Errors) { Write-Host ("    $($errorRecord.Kind): $($errorRecord.Message)") }
        }
    }
} finally { $env:APPDATA = $originalAppData }
$observation = 'NotRun'
if (-not $Automated) {
    Write-Host "`nReview the paths, characters, counts and errors. This checks discovery with synthetic text sentinels; it does not encode videos."
    $answer = Read-Host 'Type PASS if every case matches and Unicode is readable; otherwise type FAIL'
    $observation = if ($answer -ceq 'PASS' -and @($results | Where-Object { -not $_.Matched }).Count -eq 0) { 'Passed' } else { 'Failed' }
}
$report = [pscustomobject]@{ SourceCommit = $metadata.SourceCommit;
    PowerShell = $PSVersionTable.PSVersion.ToString(); Edition = $PSVersionTable.PSEdition;
    Automated = [bool]$Automated; HumanObservation = $observation; Cases = $results;
    ApplicationSHA256 = (Get-FileHash -LiteralPath (Join-Path $metadata.Owner.Path 'WinVidCompress.ps1')).Hash }
$suffix = if ($Automated) { 'automated' } else { 'manual' }
Write-WvcTestJson (Join-Path $metadata.Owner.Path ("$suffix-$($PSVersionTable.PSEdition).json")) $report
$report | ConvertTo-Json -Depth 8
if (-not $Automated) { [void](Read-Host 'Press Enter to close this check') }
if (@($results | Where-Object { -not $_.Matched }).Count -gt 0 -or $observation -eq 'Failed') { exit 1 }
exit 0
