param([ValidateSet('Race','Crash')][string]$Scenario,[string]$FixtureRoot,[string]$Encoder,[string]$Probe,
    [string]$SourcePath,[string]$OutputRoot,[string]$WorkerId,[ValidateSet('rename','skip')][string]$Policy='rename')
$ErrorActionPreference='Stop'
$env:APPDATA=Join-Path $FixtureRoot 'appdata'; $env:FFREPORT=$null
$env:WVC_SAFETY_FAULT=$null; $env:WVC_SAFETY_ID=$WorkerId; $env:WVC_SAFETY_BARRIER=$null
. (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
if ($Scenario -eq 'Crash') {
    $context=Open-BatchManifest (Join-Path $FixtureRoot 'batch.json') $OutputRoot @($SourcePath)
    $cfg=Load-Config
    $configLock=Open-ConfigLock
    $job=New-OutputJob $SourcePath $OutputRoot (Join-Path $OutputRoot 'a.mp4') (Next-CompressedPath (Join-Path $OutputRoot 'a.mp4'))
    [IO.File]::WriteAllText($job.TempPath,'crashed partial sentinel')
    # Persist a Running checkpoint, then simulate a crash after publication but before Completed save.
    $context.Manifest.Jobs[0].State='Running'; Save-BatchManifest $context
    [IO.File]::WriteAllText((Join-Path $OutputRoot 'a (compressed).mp4'),'uncheckpointed final sentinel')
    [IO.File]::WriteAllText((Join-Path $ConfigDir 'config.crash.tmp'),'unverified config temp sentinel')
    [IO.File]::WriteAllText((Join-Path $FixtureRoot 'batch.json.crash.tmp'),'unverified manifest temp sentinel')
    $readyTemporary=Join-Path $FixtureRoot 'crash-ready.json.tmp'
    [IO.File]::WriteAllText($readyTemporary,
        ([pscustomobject]@{JobId=$job.JobId;JobDirectory=$job.JobDirectory;TemporaryPath=$job.TempPath;ReservationPath=$job.ReservationPath} | ConvertTo-Json))
    [IO.File]::Move($readyTemporary,(Join-Path $FixtureRoot 'crash-ready.json'))
    # Deliberately no finally: parent terminates only this ready worker, with no native child running.
    Start-Sleep -Seconds 45
    throw 'Crash fixture watchdog expired.'
}
function Wait-SafetyBarrier([string]$Pattern) {
    $clock=[Diagnostics.Stopwatch]::StartNew()
    while (@(Get-ChildItem -LiteralPath $FixtureRoot -Filter $Pattern -File).Count -ne 2) {
        if ($clock.ElapsedMilliseconds -gt 10000) { throw 'Config barrier timed out.' }
        Start-Sleep -Milliseconds 20
    }
}
# Cooperating loads take a brief exclusive lock. Retry only in this fixture to obtain two snapshots.
$clock=[Diagnostics.Stopwatch]::StartNew()
while ($true) {
    try { $cfg=Load-Config; break } catch {
        if ($clock.ElapsedMilliseconds -gt 5000) { throw }
        Start-Sleep -Milliseconds 20
    }
}
[IO.File]::WriteAllText((Join-Path $FixtureRoot ($WorkerId+'.config-ready')),'ready')
Wait-SafetyBarrier '*.config-ready'
$cfg | Add-Member NoteProperty Writer $WorkerId
$saved=$false; $saveError=$null
try { Save-Config $cfg; $saved=$true } catch { $saveError=$_.Exception.Message }
$env:WVC_SAFETY_BARRIER=$FixtureRoot; $CollisionMode=$Policy
$job=Compress-One $Encoder $Probe $SourcePath $cfg.OutputDir 22
$report=[pscustomobject]@{Worker=$WorkerId;PowerShell=$PSVersionTable.PSVersion.ToString();ConfigSaved=$saved;ConfigError=$saveError;Outcome=$job.Outcome;OutputPath=$job.OutputPath;TemporaryPath=$job.TemporaryPath;RetainedPath=$job.RetainedPath}
[IO.File]::WriteAllText((Join-Path $FixtureRoot ($WorkerId+'.json')),($report | ConvertTo-Json),(New-Object Text.UTF8Encoding($false)))
if ($job.Outcome -notin @('Completed','Skipped')) { exit 1 }
