param([Parameter(Mandatory=$true)][string]$CaseRoot,[int]$ObservedExit)
$ErrorActionPreference='Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
$plan=Get-Content -LiteralPath (Join-Path $CaseRoot 'case.json') -Raw | ConvertFrom-Json
[void](Assert-WvcTestRoot $plan.Owner)
$rows=New-Object 'Collections.Generic.List[object]'
function Add-Check([string]$Name,[bool]$Passed) {
    $rows.Add([pscustomobject]@{Name=$Name;Passed=$Passed})
    Write-Host (('{0} {1}' -f $(if ($Passed) {'PASS'} else {'FAIL'}),$Name))
}
Add-Check 'Application exit is 3' ($ObservedExit -eq 3)
$starts=@(); if (Test-Path -LiteralPath (Join-Path $CaseRoot 'started.txt')) { $starts=@(Get-Content -LiteralPath (Join-Path $CaseRoot 'started.txt')) }
Add-Check 'Only the first encoder started' ($starts.Count -eq 1)
$alive=$false
foreach ($childId in $starts) {
    $child=Get-Process -Id ([int]$childId) -ErrorAction SilentlyContinue
    if ($null -ne $child) {
        try { if ([StringComparer]::OrdinalIgnoreCase.Equals($child.Path,(Join-Path $CaseRoot 'bin/ffmpeg.exe'))) { $alive=$true } }
        finally { $child.Dispose() }
    }
}
Add-Check 'Owned encoder stopped' (-not $alive)
$unchanged=$true
foreach ($sentinel in $plan.Sentinels) {
    if (-not (Test-Path -LiteralPath $sentinel.Path) -or (Get-FileHash -LiteralPath $sentinel.Path).Hash -ne $sentinel.Hash) { $unchanged=$false }
}
Add-Check 'Both sources and the existing final are unchanged' $unchanged
Add-Check 'No cancelled partial was published' (@(Get-ChildItem -LiteralPath (Join-Path $CaseRoot 'output') -Filter '*.mp4').Count -eq 1)
$logs=@(Get-ChildItem -LiteralPath (Join-Path $CaseRoot 'appdata/WinVidCompress/logs') -Filter 'results.jsonl' -Recurse -ErrorAction SilentlyContinue)
$jobs=@(); $results=@()
if ($logs.Count -eq 1) {
    $records=@(Get-Content -LiteralPath $logs[0].FullName | ForEach-Object { $_ | ConvertFrom-Json })
    $jobs=@($records | Where-Object Kind -eq 'Job'); $results=@($records | Where-Object Kind -eq 'Result')
}
Add-Check 'Logs contain Cancelled then Unstarted' ((@($jobs | ForEach-Object { $_.Outcome }) -join ',') -ceq 'Cancelled,Unstarted')
$agree=$results.Count -eq 1
if ($agree) { $agree=$results[0].ExitCode -eq 3 -and $results[0].Counters.Found -eq 2 -and $results[0].Counters.Cancelled -eq 1 -and $results[0].Counters.Unstarted -eq 1 }
Add-Check 'Session cancellation and counters agree' $agree
$observation=Read-Host 'Did pressing Ctrl+C stop the batch and return normally (PASS / FAIL / UNSURE)?'
$observation=$observation.Trim().ToUpperInvariant()
if ($observation -notin @('PASS','FAIL','UNSURE')) { $observation='UNSURE' }
$report=[pscustomobject]@{SchemaVersion=1;Kind='PhysicalCancellation';Route=$plan.Route;
    TestedCommit=$plan.TestedCommit;Dirty=$plan.Dirty;ApplicationSHA256=$plan.ApplicationSHA256;
    RecordedUtc=[datetime]::UtcNow.ToString('o');Observation=$observation;ObservedExit=$ObservedExit;
    Rows=$rows.ToArray();PowerShell=$plan.PowerShell;RecorderOnly=$true;
    Limitations=@('Physical observation uses a synthetic encoder/probe; actual FFmpeg private-pipe shutdown is covered separately by native tests.',
        'Console close/Ctrl+Break/hard crash and detached descendants are outside controlled cancellation.')}
$path=Join-Path $CaseRoot ('observation-'+[guid]::NewGuid().ToString('N')+'.json')
Write-WvcTestJson $path $report
Write-Host ('Saved observation: '+$path)
if (@($rows | Where-Object { -not $_.Passed }).Count -or $observation -eq 'FAIL') { exit 1 }
if ($observation -ne 'PASS') { exit 2 }
exit 0
