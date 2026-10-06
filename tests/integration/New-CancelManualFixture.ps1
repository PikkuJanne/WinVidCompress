param([string]$ReportPath)
$ErrorActionPreference='Stop'
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
$owner=New-WvcTestRoot
$repo=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ps51=Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
$ps7=(Get-Command pwsh.exe -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$sha=(& git -C $repo rev-parse HEAD | Out-String).Trim()
$dirty=[bool]@(& git -C $repo status --porcelain=v1 --untracked-files=all).Count
$applicationHash=(Get-FileHash -LiteralPath (Join-Path $repo 'WinVidCompress.ps1')).Hash
$encoder=Join-Path $owner.Path 'cancel-recorder.exe'
$compile=Invoke-WvcTestProcess $ps51 @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
    (Join-Path $PSScriptRoot 'New-CancelFixture.ps1'),'-Destination',$encoder)
if ($compile.ExitCode -ne 0) { throw $compile.StdErr }
$launchers=@()
foreach ($route in @('PS51','PS7','BAT-unattended','BAT-menu','BAT-drop')) {
    $root=Join-Path $owner.Path $route
    foreach ($dir in @('app','bin','sources','output','appdata/WinVidCompress')) { [void][IO.Directory]::CreateDirectory((Join-Path $root $dir)) }
    foreach ($file in @('WinVidCompress.ps1','WinVidCompress.bat')) { Copy-Item -LiteralPath (Join-Path $repo $file) -Destination (Join-Path $root ('app/'+$file)) }
    foreach ($file in @('ffmpeg.exe','ffprobe.exe')) { Copy-Item -LiteralPath $encoder -Destination (Join-Path $root ('bin/'+$file)) }
    $sentinels=@()
    foreach ($file in @('sources/a.mov','sources/b.mov','output/a.mp4')) {
        $path=Join-Path $root $file; [IO.File]::WriteAllText($path,'synthetic cancellation sentinel '+$file)
        $sentinels+=@([pscustomobject]@{Path=$path;Hash=(Get-FileHash -LiteralPath $path).Hash})
    }
    Write-WvcTestJson (Join-Path $root 'appdata/WinVidCompress/config.json') ([pscustomobject]@{OutputDir=(Join-Path $root 'output')})
    $hostExe=if ($route -eq 'PS7') { $ps7 } else { $ps51 }
    $version=Get-WvcHostInfo $hostExe $(if ($route -eq 'PS7') {'PowerShell7'} else {'WindowsPowerShell'})
    Write-WvcTestJson (Join-Path $root 'case.json') ([pscustomobject]@{Owner=$owner;Route=$route;
        TestedCommit=$sha;Dirty=$dirty;ApplicationSHA256=$applicationHash;Sentinels=$sentinels;PowerShell=$version})
    $lines=@('@echo off','setlocal DisableDelayedExpansion',
        'set "APPDATA=%~dp0appdata"','set "PATH=%~dp0bin;%SystemRoot%\System32"','set "FFREPORT="',
        'set "WVC_CANCEL_MARKER=%~dp0started.txt"','set "WVC_CANCEL_MODE=Graceful"','set "WVC_CANCEL_WATCHDOG=120"',
        'echo Press Ctrl+C once after the first file starts. Run each check only once.')
    if ($route -in @('BAT-menu','BAT-drop')) { $lines+='echo After cancellation, type: exit $LASTEXITCODE' }
    if ($route -eq 'BAT-menu') {
        $lines+=@('echo Choose 3, then paste this source folder:','echo %~dp0sources','call "%~dp0app\WinVidCompress.bat"')
    } elseif ($route -eq 'BAT-drop') {
        $lines+=@('if "%~1"=="" (echo Drag both a.mov and b.mov from the sources folder onto this check. & pause & exit /b 2)',
            'call "%~dp0app\WinVidCompress.bat" %*')
    } elseif ($route -eq 'BAT-unattended') {
        $lines+='call "%~dp0app\WinVidCompress.bat" -Unattended "%~dp0sources"'
    } else {
        $lines+=('"'+$hostExe+'" -NoProfile -ExecutionPolicy Bypass -File "%~dp0app\WinVidCompress.ps1" -Unattended "%~dp0sources"')
    }
    $lines+=@('set "WVC_OBSERVED_EXIT=%ERRORLEVEL%"',
        ('"'+$ps51+'" -NoProfile -ExecutionPolicy Bypass -File "'+(Join-Path $PSScriptRoot 'Test-CancelManualResult.ps1')+'" -CaseRoot "%~dp0." -ObservedExit %WVC_OBSERVED_EXIT%'),
        'pause','endlocal')
    $launcher=Join-Path $root ('Check-'+$route+'.bat')
    [IO.File]::WriteAllText($launcher,($lines -join "`r`n")+"`r`n",[Text.Encoding]::ASCII)
    $launchers+=@([pscustomobject]@{Route=$route;Launcher=$launcher;Sources=(Join-Path $root 'sources')})
}
$report=[pscustomobject]@{SchemaVersion=1;Kind='PreparedCancellationChecks';Owner=$owner;
    TestedCommit=$sha;Dirty=$dirty;ApplicationSHA256=$applicationHash;Launchers=$launchers;
    ManualAcceptance='NotRun; fixture preparation is not a physical Ctrl+C observation.'}
if (-not $ReportPath) { $ReportPath=Join-Path $owner.Path 'prepared.json' }
Write-WvcTestJson $ReportPath $report
Write-Host ('Prepared checks: '+$owner.Path)
Write-Host 'Double-click PS51, PS7, BAT-unattended and BAT-menu checks. For BAT-drop, drag both sources onto its check.'
Write-Host 'Press Ctrl+C once after encoding starts; the verifier checks files/logs/counters and asks PASS/FAIL/UNSURE.'
Write-Host ('Preparation report: '+[IO.Path]::GetFullPath($ReportPath))
