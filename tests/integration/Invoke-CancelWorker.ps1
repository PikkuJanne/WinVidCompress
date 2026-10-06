param([Parameter(Mandatory=$true)][string]$Application,
    [Parameter(Mandatory=$true)][string]$SourceRoot,
    [Parameter(Mandatory=$true)][string]$Marker)
$ErrorActionPreference='Stop'
. $Application
# A native ready marker requests cancellation through the real batch context.
# This is an automated seam, not a physical Ctrl+C observation.
function Test-WvcCancellation {
    if ($null -eq $script:CancellationContext) { return $false }
    if (Test-Path -LiteralPath $Marker) { $script:CancellationContext.Requested=$true }
    return $script:CancellationContext.Requested
}
$run=Invoke-WinVidCompress -Paths @($SourceRoot) -Unattended
Write-Output ('WVC_CANCEL_RESULT:' + ($run.Counters | ConvertTo-Json -Compress))
if ($null -ne $script:CancellationContext) { throw 'Cancellation context leaked.' }
exit $run.ExitCode
