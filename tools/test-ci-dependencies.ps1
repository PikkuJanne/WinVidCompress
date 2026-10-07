[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$RuntimeRoot)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
. (Join-Path $repo 'tests/TestSupport.ps1')
. (Join-Path $repo 'tests/CiSupport.ps1')
$pins=Import-PowerShellDataFile (Join-Path $repo 'tests/CiDependencies.psd1')
$owned=$false
try {
    $RuntimeRoot=[IO.Path]::GetFullPath($RuntimeRoot)
    if(Test-Path -LiteralPath $RuntimeRoot){throw 'CI dependency root must be new.'}
    [void][IO.Directory]::CreateDirectory($RuntimeRoot); $owned=$true
    [IO.File]::WriteAllText((Join-Path $RuntimeRoot '.wvc-ci-owner'),[guid]::NewGuid().ToString('N'))
    $modules=Join-Path $RuntimeRoot 'modules'
    $items=@($pins.Modules | ForEach-Object {[pscustomobject]@{Label=$_.Name;Pin=$_;Destination=(Join-Path $modules ($_.Name+'/'+$_.Version))}})
    $items+=@([pscustomobject]@{Label='powershell';Pin=$pins.PowerShell;Destination=(Join-Path $RuntimeRoot 'powershell')},
        [pscustomobject]@{Label='native';Pin=$pins.FFmpeg;Destination=(Join-Path $RuntimeRoot 'native')})
    foreach($item in $items) {
        $archive=Join-Path $RuntimeRoot ($item.Label+'.zip')
        if($item.Pin.Url -notmatch '^https://(www\.powershellgallery\.com|github\.com)/'){throw 'Unexpected dependency origin.'}
        Invoke-WebRequest -Uri $item.Pin.Url -OutFile $archive -UseBasicParsing -TimeoutSec 180
        Assert-WvcCiArchive $archive $item.Pin
        Assert-WvcCiZipPaths $archive $item.Destination
        Expand-Archive -LiteralPath $archive -DestinationPath $item.Destination
    }
    $modulePins=Import-PowerShellDataFile (Join-Path $repo 'tests/Dependencies.psd1')
    foreach($module in $pins.Modules) {
        if($module.Version -cne $modulePins[$module.Name]){throw 'CI and developer module pins disagree.'}
        $manifest=Import-PowerShellDataFile (Join-Path $modules ($module.Name+'/'+$module.Version+'/'+$module.Name+'.psd1'))
        if($manifest.ModuleVersion -ne $module.Version){throw 'Extracted module version mismatch.'}
    }
    $ps7=Join-Path $RuntimeRoot 'powershell/pwsh.exe'; $info=Get-WvcHostInfo $ps7 'PowerShell7'
    if($info.Version -cne $pins.PowerShell.Version){throw 'Extracted PowerShell version mismatch.'}
    $native=Join-Path (Join-Path $RuntimeRoot 'native') $pins.FFmpeg.Bin
    foreach($pair in @(@('ffmpeg.exe',$pins.FFmpeg.FFmpegHash),@('ffprobe.exe',$pins.FFmpeg.FFprobeHash))) {
        if((Get-FileHash -LiteralPath (Join-Path $native $pair[0])).Hash -ine $pair[1]){throw 'Extracted native executable hash mismatch.'}
    }
    Write-WvcTestJson (Join-Path $RuntimeRoot 'dependencies.json') ([pscustomobject]@{ModuleRoot=$modules;PowerShell7=$ps7;NativeDirectory=$native})
    [Console]::WriteLine('Pinned CI dependencies verified and prepared in the requested isolated root.')
    exit 0
} catch {
    if($owned){[IO.File]::WriteAllText((Join-Path $RuntimeRoot 'setup-error.local.log'),$_.ToString())}
    [Console]::Error.WriteLine('CI dependency setup failed. No unverified archive was imported or executed.')
    exit 1
}
