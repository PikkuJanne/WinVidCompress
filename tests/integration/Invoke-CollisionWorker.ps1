param([string]$SourcePath,[string]$OutputRoot,[string]$FixtureRoot,[string]$WorkerId,
    [ValidateSet('rename','skip')][string]$Policy,[string]$ReportPath)
$ErrorActionPreference = 'Stop'
$env:APPDATA = Join-Path $FixtureRoot ('appdata-'+$WorkerId)
$env:FFREPORT = $null
$env:WVC_COLLISION_ID = $WorkerId
$env:WVC_COLLISION_BARRIER = $FixtureRoot
. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
$CollisionMode = $Policy
$counters = [pscustomobject]@{Done=0;Skipped=0;Failed=0}
Compress-One (Join-Path $FixtureRoot 'encoder.exe') (Join-Path $FixtureRoot 'probe.exe') $SourcePath $OutputRoot 22 ([ref]$counters)
$report = [pscustomobject]@{PowerShell=$PSVersionTable.PSVersion.ToString();Edition=$PSVersionTable.PSEdition;
    WorkerId=$WorkerId;Done=$counters.Done;Skipped=$counters.Skipped;Failed=$counters.Failed}
[IO.File]::WriteAllText($ReportPath,($report | ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
if ($counters.Failed) { exit 1 }
