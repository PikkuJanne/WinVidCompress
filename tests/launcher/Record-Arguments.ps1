[CmdletBinding()]
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Path
)

# Test-only replacement for the adjacent PS1. No application/media startup.
Set-StrictMode -Version Latest
$received = @()
if ($null -ne $Path) { $received = @($Path) }
$record = [pscustomobject]@{
    RawArguments = @([Environment]::GetCommandLineArgs())
    Paths = $received
    PowerShell = $PSVersionTable.PSVersion.ToString()
    Edition = $PSVersionTable.PSEdition
}
$json = $record | ConvertTo-Json -Depth 5 -Compress
Write-Output ('WVC_ARGV:' + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($json)))
if (-not $env:WVC_ARGV_REPORT -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.wvc-manual-recorder'))) {
    $env:WVC_ARGV_REPORT = Join-Path $PSScriptRoot ('argv-' + [guid]::NewGuid().ToString('N') + '.json')
}
if ($env:WVC_ARGV_REPORT) {
    # Human fixture reports are new files only; preserve previous observations.
    $stream = [IO.File]::Open($env:WVC_ARGV_REPORT, [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $bytes = [Text.Encoding]::UTF8.GetBytes($json)
        $stream.Write($bytes, 0, $bytes.Length)
    } finally { $stream.Dispose() }
    Write-Output ('Local argument report: ' + $env:WVC_ARGV_REPORT)
}
if ($env:WVC_ARGV_AUTOMATED -eq '1') { exit 0 }
Write-Output $json
Write-Output 'Argument recorder only. Type exit to close this PowerShell prompt.'
