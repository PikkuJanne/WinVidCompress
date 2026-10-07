[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidateSet('WindowsPowerShell','PowerShell7')][string]$HostName,
    [Parameter(Mandatory=$true)][string]$ModuleRoot,[Parameter(Mandatory=$true)][string]$NativeDirectory,
    [Parameter(Mandatory=$true)][string]$BaseCommit,[Parameter(Mandatory=$true)][string]$ResultDirectory)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
. (Join-Path $repo 'tests/TestSupport.ps1')
. (Join-Path $repo 'tests/CiSupport.ps1')
$expected=(& git -C $repo rev-parse HEAD | Out-String).Trim()
$summary=$null; $code=1; $owned=$false
try {
    if($LASTEXITCODE -ne 0 -or $expected -cnotmatch '^[a-f0-9]{40}$'){throw 'CI checkout has no valid HEAD.'}
    if(Test-Path -LiteralPath $ResultDirectory){throw 'CI report directory must be new.'}
    [void][IO.Directory]::CreateDirectory($ResultDirectory); $owned=$true
    $env:Path=$NativeDirectory+';'+$env:Path
    $env:FFREPORT=$null
    $staticPath=Join-Path $ResultDirectory 'static.local.json'
    $static=Invoke-WvcCiAnalysis @(Get-WvcCiChangedPaths $repo $BaseCommit) $ModuleRoot
    Write-WvcTestJson $staticPath $static
    $rawPath=Join-Path $ResultDirectory 'targeted.local.json'
    $child=Invoke-WvcTestProcess (Get-Process -Id $PID).Path @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
        (Join-Path $PSScriptRoot 'test.ps1'),'-Tier','Targeted','-Hosts','Current','-IncludeKnownDefects','-ModuleRoot',$ModuleRoot,'-ReportPath',$rawPath) -TimeoutMilliseconds 600000
    [IO.File]::WriteAllText((Join-Path $ResultDirectory 'stdout.local.log'),$child.StdOut)
    [IO.File]::WriteAllText((Join-Path $ResultDirectory 'stderr.local.log'),$child.StdErr)
    $report=Read-WvcChildReport $rawPath $child.ExitCode
    $summary=ConvertTo-WvcCiSummary $report $child.ExitCode $expected $HostName $static
    $code=$summary.ExitCode
} catch {
    if($owned){[IO.File]::WriteAllText((Join-Path $ResultDirectory 'failure.local.log'),$_.ToString())}
    $summary=[pscustomobject]@{SchemaVersion=1;SourceCommit=$(if($expected -cmatch '^[a-f0-9]{40}$'){$expected}else{$null});HostName=$HostName;
        Host=[pscustomobject]@{Version=$PSVersionTable.PSVersion.ToString();Edition=$PSVersionTable.PSEdition};WindowsVersion=[Environment]::OSVersion.Version.ToString();
        Status='Failed';ExitCode=1;Issues=@('CIExecutionOrReportFailure');ReleaseAcceptance=$false}
}
if($owned){
    Write-WvcTestJson (Join-Path $ResultDirectory 'summary.json') $summary
}
[Console]::WriteLine(('CI {0}: {1}' -f $HostName,$summary.Status))
exit $code
