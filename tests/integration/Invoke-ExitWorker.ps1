param([string]$Application,[string]$SourceRoot,[ValidateSet('Skip','Cancel')][string]$Mode)
$ErrorActionPreference='Stop'
. $Application
if ($Mode -eq 'Skip') { $CollisionMode='skip' }
if ($Mode -eq 'Cancel') {
    # Controlled application cancellation seam. Physical Ctrl+C is M3-06 work.
    function Invoke-EncodeProcess { throw (New-Object OperationCanceledException 'controlled worker cancellation') }
}
$run=Invoke-WinVidCompress -Paths @($SourceRoot) -Unattended
Write-Output ('WVC_RESULTS:' + ($run.Counters | ConvertTo-Json -Compress))
exit $run.ExitCode
