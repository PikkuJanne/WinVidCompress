[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'LauncherTestSupport.ps1')
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$owner = New-WvcTestRoot
$restoreAcls = @()
try {
    $argumentApp = Join-Path $owner.Path 'arguments'
    $inputs = Join-Path $owner.Path 'inputs'
    $folder = Join-Path $inputs 'Folder ! & (name) [literal]'
    foreach ($directory in @($argumentApp,$inputs,$folder)) { [void][IO.Directory]::CreateDirectory($directory) }
    $names = @('space name.mov','bang !NAME!.mov','amp & name.mov','paren (name).mov',
        "O'Brien.mov",'square [name].mov','percent 50%.mov','literal %PATH%.mov',
        ('Finnish ' + [char]0x00e4 + [char]0x00f6 + '.mov'),
        ('German ' + [char]0x00fc + [char]0x00df + '.mov'),
        ([string][char]0x4e2d + [char]0x6587 + '.mov'))
    $paths = @($names | ForEach-Object { Join-Path $inputs $_ })
    foreach ($path in $paths) { [IO.File]::WriteAllText($path, 'synthetic filename sentinel') }
    Copy-Item -LiteralPath (Join-Path $repoRoot 'WinVidCompress.bat') -Destination (Join-Path $argumentApp 'WinVidCompress.bat')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'Record-Arguments.ps1') -Destination (Join-Path $argumentApp 'WinVidCompress.ps1')
    [IO.File]::WriteAllText((Join-Path $argumentApp '.wvc-manual-recorder'), $owner.Token)
    $wrapper = @'
@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "APPDATA=%~dp0appdata"
set "PSModulePath="
set "PATH=%SystemRoot%\System32\WindowsPowerShell\v1.0;%SystemRoot%\System32;WVC_PATH_SENTINEL"
set "NAME=WVC_NAME_SENTINEL"
set "WVC_ARGV_REPORT="
set "WVC_ARGV_AUTOMATED="
"%~dp0WinVidCompress.bat" %*
'@
    function Write-ManualWrapper([string]$Directory) {
        [IO.File]::WriteAllText((Join-Path $Directory 'Check.bat'),
            $wrapper.Replace("`r`n", "`n").Replace("`n", "`r`n") + "`r`n", [Text.Encoding]::ASCII)
    }
    Write-ManualWrapper $argumentApp
    $errorDirectories = @()
    foreach ($kind in @('missing-script','missing-ffmpeg','missing-ffprobe','denied-ffmpeg')) {
        $directory = Join-Path $owner.Path $kind
        [void][IO.Directory]::CreateDirectory($directory)
        Copy-Item -LiteralPath (Join-Path $repoRoot 'WinVidCompress.bat') -Destination (Join-Path $directory 'WinVidCompress.bat')
        if ($kind -ne 'missing-script') {
            Copy-Item -LiteralPath (Join-Path $repoRoot 'WinVidCompress.ps1') -Destination (Join-Path $directory 'WinVidCompress.ps1')
        }
        if ($kind -in @('missing-ffprobe','denied-ffmpeg')) {
            $dependency = Join-Path $directory 'ffmpeg.exe'
            [IO.File]::WriteAllText($dependency, 'startup-only synthetic dependency, never executed')
            if ($kind -eq 'denied-ffmpeg') {
                $acl = Get-Acl -LiteralPath $dependency
                $restoreAcls += [pscustomobject]@{ Path = $dependency; Sddl = $acl.Sddl }
                $rule = New-Object Security.AccessControl.FileSystemAccessRule(
                    ([Security.Principal.WindowsIdentity]::GetCurrent().User),
                    [Security.AccessControl.FileSystemRights]::ReadData,
                    [Security.AccessControl.AccessControlType]::Deny)
                $acl.AddAccessRule($rule)
                Set-Acl -LiteralPath $dependency -AclObject $acl
            }
        }
        Write-ManualWrapper $directory
        $errorDirectories += [pscustomobject]@{ Kind = $kind; Launcher = Join-Path $directory 'Check.bat' }
    }
    $instructions = @'
These are owned synthetic fixtures. No real media/config is used.

In Explorer, open this kit's arguments folder:
1. Double-click Check.bat. Confirm Paths is [] and a usable PowerShell prompt
   remains. Type exit. (This is a recorder, not the application menu.)
2. Drag inputs/space name.mov onto arguments/Check.bat. Confirm one exact path;
   type exit. Drag inputs/Folder ! & (name) [literal] similarly; type exit.
3. Select all 11 .mov fixtures (exclude Folder) in inputs and drag the selection
   onto arguments/Check.bat. Inspect the printed paths and type exit. This covers
   spaces, !NAME!, &, (), apostrophe, [], %, Finnish/German/CJK and %PATH%.
   NAME and PATH are set in Check.bat before the actual BAT. An outer Explorer/CMD
   shell may expand %PATH% before Check.bat can protect it. If any name changes,
   report the mismatch; do not call it passed. Reports are local argv-*.json files.
4. Double-click Check.bat in missing-script. Confirm a visible missing PS1 error
   says to keep the two files together; press a key to close.
5. Double-click Check.bat in missing-ffmpeg, missing-ffprobe and denied-ffmpeg.
   Confirm the first two name the missing dependency and PATH/adjacent remedy;
   the last says cannot be read, read/execute permissions and underlying Details.
   Confirm diagnostics remain visible, then type exit to close each prompt.

Run the report checker against manual-fixture.json. Report which Explorer steps
you actually performed, pass/fail, any changed filename and observed errors.
The report checker establishes exact data, not that a human used Explorer.
Do not share raw argv JSON: it contains local paths/environment expansions.
Close every kit console before running the cleanup script. It restores the
single owned fixture's ACL and removes only the marked owned temp root.
'@
    [IO.File]::WriteAllText((Join-Path $owner.Path 'Instructions.txt'), $instructions, [Text.Encoding]::ASCII)
    $metadata = [pscustomobject]@{
        Owner = $owner
        SourceCommit = (& git -C $repoRoot rev-parse HEAD)
        SourceDirty = [bool]@(& git -C $repoRoot status --porcelain).Count
        LauncherSHA256 = (Get-FileHash -LiteralPath (Join-Path $argumentApp 'WinVidCompress.bat')).Hash
        ApplicationSHA256 = (Get-FileHash -LiteralPath (Join-Path $repoRoot 'WinVidCompress.ps1')).Hash
        ArgumentApp = $argumentApp
        Inputs = $paths
        Folder = $folder
        ErrorChecks = $errorDirectories
        RestoreAcls = $restoreAcls
        Instructions = Join-Path $owner.Path 'Instructions.txt'
    }
    $manifest = Join-Path $owner.Path 'manual-fixture.json'
    Write-WvcTestJson $manifest $metadata
    [pscustomobject]@{ Manifest = $manifest; Instructions = $metadata.Instructions;
        ArgumentLauncher = Join-Path $argumentApp 'Check.bat'; Owner = $owner } | ConvertTo-Json -Depth 4
} catch {
    foreach ($saved in $restoreAcls) {
        $acl = Get-Acl -LiteralPath $saved.Path
        $acl.SetSecurityDescriptorSddlForm($saved.Sddl)
        Set-Acl -LiteralPath $saved.Path -AclObject $acl
    }
    Remove-WvcTestRoot $owner
    throw
}
