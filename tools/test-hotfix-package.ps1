<#
.SYNOPSIS
Prove installed-tool discovery and conversion through an extracted release BAT.
.DESCRIPTION
Developer-only Windows integration. All child environments replace inherited PATH.
Persistent User variables and masking of unrelated Machine tool hints are changed
only with an explicit switch on a disposable GitHub-hosted runner, and restored
in finally. No owner-machine persistent environment is changed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$PackagePath,
    [Parameter(Mandatory=$true)][string]$NativeDirectory,
    [Parameter(Mandatory=$true)][string]$ResultPath,
    [string]$OldPackagePath,
    [switch]$EphemeralUserScope
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
. (Join-Path $repo 'tests/TestSupport.ps1')
. (Join-Path $repo 'tests/CiSupport.ps1')
$cases=New-Object 'Collections.Generic.List[object]'
$owner=$null; $drive=$null; $saved=@{}; $registryScopes=@{}; $stage='Preparation'; $failure=$null
$packageHash=$null; $packageCommit=$null

function Assert-Hotfix([bool]$Condition,[string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Complete-HotfixCase([string]$Id) {
    $cases.Add([pscustomobject]@{Id=$Id;Status='Passed'})
    [Console]::WriteLine(('PASS '+$Id))
}
function Set-HotfixScope([string]$Name,$Value,[string]$Scope,
    [Microsoft.Win32.RegistryValueKind]$Kind=[Microsoft.Win32.RegistryValueKind]::String) {
    # Only handles opened after the disposable-runner guard can reach this helper.
    if($null -eq $Value) {$registryScopes[$Scope].DeleteValue($Name,$false)}
    else {$registryScopes[$Scope].SetValue($Name,$Value,$Kind)}
}
function Invoke-HotfixChild([string]$Executable,[string]$Arguments,[hashtable]$Variables,
    [string]$InputText='',[int]$TimeoutMilliseconds=45000) {
    $start=New-Object Diagnostics.ProcessStartInfo
    $start.FileName=$Executable; $start.Arguments=$Arguments
    $start.WorkingDirectory=$script:working
    $start.UseShellExecute=$false; $start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true; $start.RedirectStandardInput=$true
    foreach($key in @('FFMPEG','FFREPORT','PSModulePath')) {$start.EnvironmentVariables.Remove($key)}
    # This intentionally overrides test-ci.ps1's native-directory PATH prepend.
    $start.EnvironmentVariables['PATH']=$script:emptyPath
    $start.EnvironmentVariables['APPDATA']=$script:appData
    $start.EnvironmentVariables['NO_COLOR']='1'
    foreach($key in $Variables.Keys) {
        if($null -eq $Variables[$key]) {$start.EnvironmentVariables.Remove($key)}
        else {$start.EnvironmentVariables[$key]=[string]$Variables[$key]}
    }
    $process=New-Object Diagnostics.Process; $process.StartInfo=$start; $started=$false
    try {
        [void]$process.Start(); $started=$true
        $stdout=$process.StandardOutput.ReadToEndAsync(); $stderr=$process.StandardError.ReadToEndAsync()
        if($InputText) {$process.StandardInput.Write($InputText)}
        $process.StandardInput.Close()
        if(-not $process.WaitForExit($TimeoutMilliseconds)) {throw 'Bounded child process timed out.'}
        if(-not $stdout.Wait(5000) -or -not $stderr.Wait(5000)) {throw 'Bounded child pipe drain timed out.'}
        $result=[pscustomobject]@{ExitCode=$process.ExitCode;StdOut=$stdout.Result;StdErr=$stderr.Result}
        $ordinal=($script:rawOrdinal++).ToString('D3')
        [IO.File]::WriteAllText((Join-Path $owner.Path ($ordinal+'.stdout.local.log')),$result.StdOut)
        [IO.File]::WriteAllText((Join-Path $owner.Path ($ordinal+'.stderr.local.log')),$result.StdErr)
        return $result
    } finally {
        if($started -and -not $process.HasExited) {
            & (Join-Path $env:SystemRoot 'System32/taskkill.exe') /PID $process.Id /T /F | Out-Null
            if($LASTEXITCODE -ne 0 -or -not $process.WaitForExit(5000)) {
                $script:WvcProcessCleanupFailed=$true
                throw 'Owned child tree termination failed; fixtures retained.'
            }
        }
        $process.Dispose()
    }
}
function Invoke-HotfixBat([string]$Application,[string]$Mode,[hashtable]$Variables,
    [string]$InputText='') {
    $copy=$Variables.Clone(); $copy.WVC_PROOF_BAT=Join-Path $Application 'WinVidCompress.bat'
    $copy.WVC_PROOF_OUTPUT=$script:output; $copy.WVC_PROOF_INPUT=$script:clip
    $arguments=switch($Mode) {
        'Doctor' {'/d /v:off /s /c ""%WVC_PROOF_BAT%" -Unattended -CheckEnvironment -OutputDir "%WVC_PROOF_OUTPUT%""'}
        'Encode' {'/d /v:off /s /c ""%WVC_PROOF_BAT%" -Unattended -OutputDir "%WVC_PROOF_OUTPUT%" "%WVC_PROOF_INPUT%""'}
        'Interactive' {'/d /v:off /s /c ""%WVC_PROOF_BAT%""'}
    }
    Invoke-HotfixChild (Join-Path $env:SystemRoot 'System32/cmd.exe') $arguments $copy $InputText
}
function Invoke-HotfixNative([string]$Executable,[string[]]$Arguments) {
    Invoke-HotfixChild $Executable (($Arguments | ForEach-Object {ConvertTo-WvcNativeArgument $_}) -join ' ') @{}
}
function Assert-HotfixSelection($Result,[string]$Bin,[string]$Source) {
    Assert-Hotfix ($Result.ExitCode -eq 0) 'Doctor must return exit 0.'
    foreach($pair in @(@('FFmpeg','ffmpeg.exe'),@('FFprobe','ffprobe.exe'))) {
        $line=$pair[0]+': '+(Join-Path $Bin $pair[1])
        Assert-Hotfix ($Result.StdOut -match ('(?m)^'+[regex]::Escape($line)+'\r?$')) ('Wrong exact '+$pair[0]+' selection.')
        Assert-Hotfix ($Result.StdOut -match ('(?m)^'+$pair[0]+' source: '+[regex]::Escape($Source)+'\r?$')) ('Wrong '+$pair[0]+' discovery provenance.')
    }
    Assert-Hotfix ($Result.StdOut -notmatch 'MEDIA OPERATIONS|Select \[1-4\]|Choose \[1-4\]|\x1b\[') 'Doctor output contains interactive decoration.'
}
function Expand-HotfixPackage([string]$Zip,[string]$Destination) {
    Assert-WvcCiZipPaths $Zip $Destination
    Expand-Archive -LiteralPath $Zip -DestinationPath $Destination
    Assert-Hotfix (Test-Path -LiteralPath (Join-Path $Destination 'WinVidCompress.bat') -PathType Leaf) 'Package BAT is missing.'
    foreach($exe in @('ffmpeg.exe','ffprobe.exe')) {
        Assert-Hotfix (-not (Test-Path -LiteralPath (Join-Path $Destination $exe))) 'Package unexpectedly bundles native tools.'
    }
}

try {
    Assert-Hotfix ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) 'This proof requires Windows.'
    Assert-Hotfix (-not (Test-Path -LiteralPath $ResultPath)) 'ResultPath must be new.'
    if($EphemeralUserScope) {
        Assert-Hotfix ($env:GITHUB_ACTIONS -eq 'true' -and $env:RUNNER_ENVIRONMENT -eq 'github-hosted') 'Persistent-scope proof is restricted to disposable GitHub-hosted runners.'
        $registryScopes.User=[Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment',$true)
        $registryScopes.Machine=[Microsoft.Win32.Registry]::LocalMachine.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\Environment',$true)
        foreach($scope in @('User','Machine')) {
            Assert-Hotfix ($null -ne $registryScopes[$scope]) 'Disposable runner environment key is unavailable.'
            $saved[$scope]=@{}
            foreach($name in @('FFMPEG','PATH')) {
                $exists=$registryScopes[$scope].GetValueNames() -contains $name
                $saved[$scope][$name]=[pscustomobject]@{Exists=$exists;
                    Value=$(if($exists){$registryScopes[$scope].GetValue($name,$null,[Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)}else{$null});
                    Kind=$(if($exists){$registryScopes[$scope].GetValueKind($name)}else{[Microsoft.Win32.RegistryValueKind]::String})}
            }
        }
        # Hosted images can contain unrelated codecs on persisted Machine PATH.
        # Mask only these two values in this disposable runner; keep the current
        # process intact and replace every child's PATH explicitly below.
        foreach($scope in @('User','Machine')) {
            Set-HotfixScope 'FFMPEG' $null $scope
            Set-HotfixScope 'PATH' '' $scope
        }
    }
    $owner=New-WvcTestRoot
    $script:rawOrdinal=1
    $script:working=Join-Path $owner.Path 'unrelated working directory'
    $script:appData=Join-Path $owner.Path 'profile'
    $script:output=Join-Path $owner.Path 'outputs'
    $script:clip=Join-Path $owner.Path 'Synthetic Discovery 29.02.2024 - Proof.mp4'
    foreach($path in @($working,$output)) {[void][IO.Directory]::CreateDirectory($path)}
    $script:emptyPath=(Join-Path $env:SystemRoot 'System32')+';'+(Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0')
    $application=Join-Path $owner.Path 'extracted application'
    $packageHash=(Get-FileHash -LiteralPath $PackagePath -Algorithm SHA256).Hash.ToLowerInvariant()
    Expand-HotfixPackage $PackagePath $application
    $metadata=Get-Content -LiteralPath (Join-Path $application 'PACKAGE.json') -Raw | ConvertFrom-Json
    $packageCommit=$metadata.SourceCommit
    $nativeEncoder=(Get-Item -LiteralPath (Join-Path $NativeDirectory 'ffmpeg.exe')).FullName
    $nativeProbe=(Get-Item -LiteralPath (Join-Path $NativeDirectory 'ffprobe.exe')).FullName
    $install=Join-Path $owner.Path 'installed codecs'; $bin=Join-Path $install 'bin'
    [void][IO.Directory]::CreateDirectory($bin)
    Copy-Item -LiteralPath $nativeEncoder,$nativeProbe -Destination $bin
    $hint=@{FFMPEG=$bin}

    if($OldPackagePath) {
        $stage='OldTaggedZipMiss'
        Assert-Hotfix ((Get-FileHash -LiteralPath $OldPackagePath -Algorithm SHA256).Hash -ieq '5c26d993e482204f80b81f10b8833315ac40c2c8d800b5bdaa7424567298b858') 'Historical public v1.0.0 ZIP digest differs.'
        $old=Join-Path $owner.Path 'old tagged application'; Expand-HotfixPackage $OldPackagePath $old
        $run=Invoke-HotfixBat $old 'Doctor' $hint
        Assert-Hotfix ($run.ExitCode -eq 2 -and ($run.StdOut+$run.StdErr) -match 'ffmpeg.exe not found') 'Old tagged BAT did not reproduce the startup resolver miss.'
        Complete-HotfixCase $stage
    }
    foreach($form in @('Bin','Root','Executable','QuotedTrailingSeparator')) {
        $stage='BatHint'+$form
        $value=switch($form) {'Bin' {$bin} 'Root' {$install} 'Executable' {Join-Path $bin 'ffmpeg.exe'} 'QuotedTrailingSeparator' {' "'+$bin+'\" '}}
        Assert-HotfixSelection (Invoke-HotfixBat $application 'Doctor' @{FFMPEG=$value}) $bin 'FFMPEG (Process)'
        Complete-HotfixCase $stage
    }
    $stage='DifferentDynamicDriveWithSpaces'
    $driveDirectory=Join-Path $owner.Path 'dynamic drive'; [void][IO.Directory]::CreateDirectory($driveDirectory)
    foreach($letter in @('Z','Y','X','W','V','U','T','S','R','Q')) {
        if(-not (Test-Path -LiteralPath ($letter+':\'))) {$drive=$letter+':';break}
    }
    Assert-Hotfix ([bool]$drive) 'No disposable drive letter is available.'
    & (Join-Path $env:SystemRoot 'System32/subst.exe') $drive $driveDirectory
    Assert-Hotfix ($LASTEXITCODE -eq 0) 'Dynamic fixture drive assignment failed.'
    $secondBin=$drive+'\Other Codec Suite\bin'; [void][IO.Directory]::CreateDirectory($secondBin)
    Copy-Item -LiteralPath $nativeEncoder,$nativeProbe -Destination $secondBin
    Assert-HotfixSelection (Invoke-HotfixBat $application 'Doctor' @{FFMPEG=$secondBin}) $secondBin 'FFMPEG (Process)'
    Complete-HotfixCase $stage

    $stage='ProcessPathPrecedence'
    Assert-HotfixSelection (Invoke-HotfixBat $application 'Doctor' @{PATH=$bin+';'+$emptyPath;FFMPEG=$secondBin}) $bin 'Process PATH'
    Complete-HotfixCase $stage
    $stage='ScriptAdjacentFromUnrelatedDirectory'
    $adjacent=Join-Path $owner.Path 'adjacent application'; Expand-HotfixPackage $PackagePath $adjacent
    Copy-Item -LiteralPath $nativeEncoder,$nativeProbe -Destination $adjacent
    Assert-HotfixSelection (Invoke-HotfixBat $adjacent 'Doctor' @{FFMPEG=$secondBin}) $adjacent 'Script directory'
    Complete-HotfixCase $stage

    $stage='ActualBatSyntheticConversion'
    $generated=Invoke-HotfixNative $nativeEncoder @('-hide_banner','-nostdin','-v','error','-n',
        '-f','lavfi','-i','testsrc2=size=160x120:rate=24:duration=0.6',
        '-f','lavfi','-i','sine=frequency=440:sample_rate=48000:duration=0.6',
        '-map','0:v:0','-map','1:a:0','-c:v','libx264','-preset','veryfast','-crf','18',
        '-pix_fmt','yuv420p','-c:a','aac',$clip)
    Assert-Hotfix ($generated.ExitCode -eq 0) 'Absolute fixture encoder failed.'
    $sourceHash=(Get-FileHash -LiteralPath $clip).Hash
    $sentinel=Join-Path $output ([IO.Path]::GetFileName($clip)); [IO.File]::WriteAllText($sentinel,'existing final protection sentinel')
    $sentinelHash=(Get-FileHash -LiteralPath $sentinel).Hash
    $converted=Invoke-HotfixBat $application 'Encode' $hint
    Assert-Hotfix ($converted.ExitCode -eq 0) 'Actual packaged BAT conversion failed.'
    Assert-Hotfix ($converted.StdOut -notmatch 'MEDIA OPERATIONS|Select \[1-4\]|Choose \[1-4\]|\x1b\[') 'Unattended conversion contains interactive decoration.'
    Assert-Hotfix ((Get-FileHash -LiteralPath $clip).Hash -ceq $sourceHash) 'Input source hash changed.'
    Assert-Hotfix ((Get-FileHash -LiteralPath $sentinel).Hash -ceq $sentinelHash) 'Existing final hash changed.'
    $produced=@(Get-ChildItem -LiteralPath $output -Filter '*.mp4' -File | Where-Object FullName -NE $sentinel)
    Assert-Hotfix ($produced.Count -eq 1) 'Expected one newly published MP4.'
    $inspection=Invoke-HotfixNative $nativeProbe @('-v','error','-show_streams','-show_format','-of','json',$produced[0].FullName)
    Assert-Hotfix ($inspection.ExitCode -eq 0) 'Published MP4 could not be probed.'
    $media=$inspection.StdOut | ConvertFrom-Json
    $video=@($media.streams | Where-Object codec_type -EQ 'video'); $audio=@($media.streams | Where-Object codec_type -EQ 'audio')
    Assert-Hotfix ($video.Count -eq 1 -and $video[0].codec_name -eq 'h264' -and $video[0].width -eq 160 -and $video[0].height -eq 120) 'Published H.264 video stream differs.'
    Assert-Hotfix ($audio.Count -eq 1 -and $audio[0].codec_name -eq 'aac') 'Published AAC audio stream is missing.'
    Assert-Hotfix ($media.format.format_name -match '\bmp4\b') 'Published file is not readable MP4.'
    $decode=Invoke-HotfixNative $nativeEncoder @('-hide_banner','-nostdin','-v','error','-i',$produced[0].FullName,'-map','0:v:0','-map','0:a:0','-f','null','-')
    Assert-Hotfix ($decode.ExitCode -eq 0) 'Published MP4 full synthetic decode failed.'
    Complete-HotfixCase $stage

    $stage='CurrentHostDirectPs1Doctor'
    $hostExe=(Get-Process -Id $PID).Path
    $argv=@('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $application 'WinVidCompress.ps1'),'-Unattended','-CheckEnvironment','-OutputDir',$output)
    Assert-HotfixSelection (Invoke-HotfixChild $hostExe (($argv | ForEach-Object {ConvertTo-WvcNativeArgument $_}) -join ' ') $hint) $bin 'FFMPEG (Process)'
    Complete-HotfixCase $stage

    $stage='CurrentHostDirectPs1Conversion'
    $directOutput=Join-Path $owner.Path 'current host output'; [void][IO.Directory]::CreateDirectory($directOutput)
    $argv=@('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $application 'WinVidCompress.ps1'),'-Unattended','-OutputDir',$directOutput,$clip)
    $direct=Invoke-HotfixChild $hostExe (($argv | ForEach-Object {ConvertTo-WvcNativeArgument $_}) -join ' ') $hint
    Assert-Hotfix ($direct.ExitCode -eq 0) 'Current-host extracted PS1 conversion failed.'
    Assert-Hotfix ((Get-FileHash -LiteralPath $clip).Hash -ceq $sourceHash) 'Current-host conversion changed the input hash.'
    $directFiles=@(Get-ChildItem -LiteralPath $directOutput -Filter '*.mp4' -File)
    Assert-Hotfix ($directFiles.Count -eq 1) 'Current-host conversion did not publish one MP4.'
    $directProbe=Invoke-HotfixNative $nativeProbe @('-v','error','-show_streams','-show_format','-of','json',$directFiles[0].FullName)
    Assert-Hotfix ($directProbe.ExitCode -eq 0) 'Current-host MP4 probe failed.'
    $directMedia=$directProbe.StdOut | ConvertFrom-Json
    Assert-Hotfix (@($directMedia.streams | Where-Object {$_.codec_type -eq 'video' -and $_.codec_name -eq 'h264'}).Count -eq 1) 'Current-host output H.264 stream missing.'
    Assert-Hotfix (@($directMedia.streams | Where-Object {$_.codec_type -eq 'audio' -and $_.codec_name -eq 'aac'}).Count -eq 1) 'Current-host output AAC stream missing.'
    Complete-HotfixCase $stage

    $stage='ShellEquivalentInteractiveQuit'
    [void][IO.Directory]::CreateDirectory((Join-Path $appData 'WinVidCompress'))
    [IO.File]::WriteAllText((Join-Path $appData 'WinVidCompress/config.json'),(@{OutputDir=$output}|ConvertTo-Json))
    # Read-Host needs real console input on headless runners. The driver launches
    # the actual BAT in a hidden native console, waits for the real menu, sends
    # Quit, then proves return to -NoExit's prompt with an executed file marker.
    $consoleTranscript=Join-Path $owner.Path 'interactive-console.local.txt'
    $quitMarker=Join-Path $owner.Path 'after-quit.marker'
    $driver=Join-Path $repo 'tests/launcher/Invoke-HotfixConsole.ps1'
    $argv=@('-NoLogo','-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$driver,
        '-BatPath',(Join-Path $application 'WinVidCompress.bat'),'-WorkingDirectory',$working,
        '-TranscriptPath',$consoleTranscript,'-MarkerPath',$quitMarker)
    $quit=Invoke-HotfixChild (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe') (($argv | ForEach-Object {ConvertTo-WvcNativeArgument $_}) -join ' ') $hint -TimeoutMilliseconds 60000
    if(Test-Path -LiteralPath $consoleTranscript -PathType Leaf) {$quit.StdOut=[IO.File]::ReadAllText($consoleTranscript)+$quit.StdOut}
    Assert-Hotfix (Test-Path -LiteralPath $quitMarker -PathType Leaf) 'Interactive retained-prompt file marker is missing.'
    Assert-Hotfix ($quit.ExitCode -eq 0 -and $quit.StdOut -match 'WVC_PROOF_AFTER_QUIT') 'Interactive Quit did not return to the retained PowerShell prompt.'
    Assert-Hotfix ($quit.StdOut -match 'MEDIA OPERATIONS' -and ($quit.StdOut+$quit.StdErr) -notmatch 'not found|\x1b\[') 'Interactive shell-equivalent startup failed or emitted ANSI.'
    Complete-HotfixCase $stage

    if($EphemeralUserScope) {
        $stage='ActualBatGenuinelyMissingTool'
        $missing=Invoke-HotfixBat $application 'Doctor' @{}
        Assert-Hotfix ($missing.ExitCode -eq 2 -and ($missing.StdOut+$missing.StdErr) -match 'ffmpeg.exe not found') 'Missing encoder startup failure differs.'
        Complete-HotfixCase $stage
        $stage='ActualBatOnlyFfprobeMissing'
        $partialBin=Join-Path $owner.Path 'encoder only'; [void][IO.Directory]::CreateDirectory($partialBin)
        Copy-Item -LiteralPath $nativeEncoder -Destination $partialBin
        $missing=Invoke-HotfixBat $application 'Doctor' @{FFMPEG=$partialBin}
        Assert-Hotfix ($missing.ExitCode -eq 2 -and ($missing.StdOut+$missing.StdErr) -match 'ffprobe.exe not found') 'Missing FFprobe startup failure differs.'
        Complete-HotfixCase $stage
        $stage='ActualBatInvalidExecutable'
        $invalidBin=Join-Path $owner.Path 'invalid executable'; [void][IO.Directory]::CreateDirectory($invalidBin)
        [IO.File]::WriteAllText((Join-Path $invalidBin 'ffmpeg.exe'),'This is an invalid synthetic executable, never a script.')
        Copy-Item -LiteralPath $nativeProbe -Destination $invalidBin
        $invalid=Invoke-HotfixBat $application 'Doctor' @{FFMPEG=$invalidBin}
        Assert-Hotfix ($invalid.ExitCode -eq 2 -and ($invalid.StdOut+$invalid.StdErr) -match 'ffmpeg.exe' -and ($invalid.StdOut+$invalid.StdErr) -notmatch 'ffmpeg.exe not found') 'Invalid executable must retain a distinct tool-specific startup error.'
        Complete-HotfixCase $stage
        $stage='PersistedUserHintStaleChild'
        Set-HotfixScope 'PATH' '' 'User'
        Set-HotfixScope 'FFMPEG' $bin 'User'
        Assert-HotfixSelection (Invoke-HotfixBat $application 'Doctor' @{}) $bin 'FFMPEG (User)'
        Complete-HotfixCase $stage
        $stage='BadProcessHintValidPersistedFallback'
        Assert-HotfixSelection (Invoke-HotfixBat $application 'Doctor' @{FFMPEG=(Join-Path $owner.Path 'absent codec')}) $bin 'FFMPEG (User)'
        Complete-HotfixCase $stage
        $stage='PersistedUserConcretePathStaleChild'
        Set-HotfixScope 'FFMPEG' $null 'User'
        Set-HotfixScope 'PATH' $bin 'User'
        Assert-HotfixSelection (Invoke-HotfixBat $application 'Doctor' @{}) $bin 'PATH (User)'
        Complete-HotfixCase $stage
        $stage='PersistedUserExpandedPathStaleChild'
        # This FFMPEG root has neither executables nor bin; only the PATH suffix
        # reaches tools, so success proves PATH expansion rather than hint lookup.
        $expandedRoot=Join-Path $owner.Path 'expanded installation'; $expandedBin=Join-Path $expandedRoot 'tools'
        [void][IO.Directory]::CreateDirectory($expandedBin); Copy-Item -LiteralPath $nativeEncoder,$nativeProbe -Destination $expandedBin
        Set-HotfixScope 'FFMPEG' $expandedRoot 'User'
        Set-HotfixScope 'PATH' '%FFMPEG%\tools' 'User' ([Microsoft.Win32.RegistryValueKind]::ExpandString)
        Assert-HotfixSelection (Invoke-HotfixBat $application 'Doctor' @{FFMPEG=(Join-Path $owner.Path 'stale inherited installation')}) $expandedBin 'PATH (User)'
        Complete-HotfixCase $stage
    }
} catch {
    $failure=$_.Exception.Message
    $cases.Add([pscustomobject]@{Id=$stage;Status='Failed'})
    [Console]::Error.WriteLine(('FAIL '+$stage+': '+$failure))
} finally {
    foreach($scope in $saved.Keys) {
        foreach($name in $saved[$scope].Keys) {
            $original=$saved[$scope][$name]
            if($original.Exists) {$registryScopes[$scope].SetValue($name,$original.Value,$original.Kind)}
            else {$registryScopes[$scope].DeleteValue($name,$false)}
        }
    }
    foreach($scope in $registryScopes.Keys) {if($null -ne $registryScopes[$scope]) {$registryScopes[$scope].Dispose()}}
    if($drive) {
        & (Join-Path $env:SystemRoot 'System32/subst.exe') $drive /d
        if($LASTEXITCODE -ne 0) {$failure='Fixture drive cleanup failed.'}
    }
    if($owner -and -not $failure) {Remove-WvcTestRoot $owner}
}
$passed=@($cases | Where-Object Status -EQ 'Passed').Count
$failed=@($cases | Where-Object Status -EQ 'Failed').Count
$report=[ordered]@{SchemaVersion=1;SourceCommit=$packageCommit;PackageSHA256=$packageHash;
    Host=[ordered]@{Version=$PSVersionTable.PSVersion.ToString();Edition=$PSVersionTable.PSEdition};
    WindowsVersion=[Environment]::OSVersion.Version.ToString();Status=$(if($failure){'Failed'}else{'Passed'});
    Passed=$passed;Failed=$failed;Skipped=0;NotRun=0;PersistedUserScope=[bool]$EphemeralUserScope;
    InteractiveCoverage='Automated shell-equivalent BAT launch from unrelated working directory; not physical Explorer mouse coverage';
    Cases=$cases.ToArray()}
Write-WvcTestJson $ResultPath $report
if($failure) {exit 1}
[Console]::WriteLine(('Packaged Windows proof: '+$passed+' passed; ZIP SHA256 '+$packageHash))
exit 0
