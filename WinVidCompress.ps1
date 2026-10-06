<#
WinVidCompress.ps1
Minimal Win11 video compressor for personal interview archiving

Author: Janne Vuorela
Target OS: Windows 11
Dependencies: ffmpeg.exe + ffprobe.exe (in PATH or next to this script)

SYNOPSIS
    One-preset, no-frills video compressor intended for my own workflow.
    Archiving band interview videos with consistent quality and embedded metadata.

WHAT THIS IS (AND ISN’T)
    - Personal, purpose-built tool for my specific use case.
      I don’t expect most people to need this, it trades options for speed and repeatability.
    - Text-UI (TUI) when run directly, also supports drag-and-drop via the .bat wrapper.
    - Single compression profile modeled after HandBrake “Very Fast 1080p”:
        - Video: H.264 (libx264), -preset veryfast, -crf 22
        - Audio: AAC 160 kbps
        - Container: MP4 with +faststart (moov moved to front)
        - Scaling: no crop; only downscale if source height > 1080 (never upscale)
    - Filename-driven metadata tagging for interviews.

FEATURES
    - Zero decision surface: exactly one quality level.
    - Drag & drop batch mode:
        - Drop one file -> compress that file
        - Drop one folder -> queue and compress all videos inside (recursive)
        - Drop multiple files/folders -> queue everything and run sequentially
        - Prints a simple summary at the end (found/done/skipped/failed)
    - Output collision behavior:
        - If an output .mp4 already exists, the script will auto-rename to
          " (compressed)" / " (compressed 2)" etc. (configurable in script).
    - Writes MP4 metadata parsed from the filename:
        - Expected filename forms (examples):
            "Band Name 29092025 - CamA.mov"
            "Band Name 29.09.2025.mov"
            "Band Name 29-09-2025.mkv"
        - Tags written:
            artist = Band Name
            date   = YYYY-MM-DD
            title  = base filename (without extension)
            comment = "Interview date dd.mm.yyyy; Band: <name>"
      If parsing fails, the file is still compressed (no prompt, no block).
    - Remembers output folder in %APPDATA%\WinVidCompress\config.json.
      Default output is the Windows “Videos” folder (e.g., C:\Users\<you>\Videos).

MY INTENDED USAGE
    - I drag a single video file (or a whole folder after a shoot) onto WinVidCompress.bat in my Downloads folder.
    - The script compresses and drops the MP4(s) into my Videos folder.
    - That’s it, no clicking around HandBrake.

SETUP
    1) Download a recent static FFmpeg build for Windows (includes ffmpeg.exe and ffprobe.exe).
    2) Put ffmpeg.exe and ffprobe.exe somewhere in PATH, or in the same folder as this script.
    3) Keep these two files together:
         • WinVidCompress.ps1
         • WinVidCompress.bat   (wrapper to allow double-click + drag-and-drop)
    4) First run will create %APPDATA%\WinVidCompress\config.json with OutputDir = Videos.

USAGE
    A) Drag & drop (my default)
        - Drag a single video file onto WinVidCompress.bat.
        - Or drag a folder to batch-compress all videos inside (recursive).
        - Output MP4(s) will appear in:  %USERPROFILE%\Videos
    B) Double-click for TUI
        - Options:
            1) Set output folder (persists in config)
            2) Compress ONE file (paste full path)
            3) Compress ALL videos in a folder (recursive)
            4) Quit (the .bat window remains at its PowerShell prompt)
    C) Direct PowerShell
        - Run:  .\WinVidCompress.ps1  "D:\Interviews\Band 29092025 - CamA.mov"
        - Or:   .\WinVidCompress.ps1  "D:\Interviews\FolderWithVideos"
        - Diagnose without conversion: .\WinVidCompress.ps1 -CheckEnvironment
          Reports exact PATH-before-adjacent binaries, versions and capabilities.
          Checks writing with an owned temporary file removed on close; no config,
          backups or output folders are created. Capacity is advisory.
        - Unattended: .\WinVidCompress.ps1 -Unattended 'D:\Interviews\Folder'
          Or: WinVidCompress.bat -Unattended "D:\Interviews\Folder"
          Put -Unattended first in the BAT command; no menu or closing pause.
          Exit: 0 success/valid skips; 1 job/scan failure; 2 startup/invalid/empty
          requested batch; 3 observed application cancellation (takes precedence).
          Default BAT uses -KeepOpen for its retained prompt. Do not combine it
          with -Unattended. Physical Ctrl+C/console-close handling is unverified.

NOTES
    - BAT drag/drop does not support %NAME% segments such as %PATH% anywhere in
      the full path, including folder names. Paste these literal paths into menu
      option 2/3 or call this PS1 from PowerShell with a single-quoted literal path.
      An outer CMD caller can also expand !NAME! when delayed expansion is enabled.
    - In a CMD/BAT command, omit a quoted folder's trailing backslash; for a drive
      root use D:\. or paste D:\ into the menu. Native quoting can change the slash.
    - CMD/batch command lines are limited to 8191 characters, including expanded
      paths and quotes. Drop a folder or use smaller selections for large batches.
    - If you ever want smaller files, change $DefaultCRF from 22 to 23–24.
    - Invalid config is preserved in a diagnostic backup before recovery to Videos.
    - An unavailable saved output folder stops startup without changing the preference.
    - Saves retain previous config backups and coordinate instances through config.json.lock.
    - Final files land directly in OutputDir. Reserved GUID job directories hold
      active or retained partials and are excluded from input discovery.

LIMITATIONS
    - No batch parameterization of quality/presets (by design).
    - Only tags the first video stream and encodes to H.264/AAC MP4.
    - Cropping, denoise, filters, and subtitles pass-through are out of scope for this tool.

TROUBLESHOOTING
    - “ffmpeg not found”: place ffmpeg.exe and ffprobe.exe next to the script or add them to PATH.
    - Drag-and-drop opens TUI instead of compressing:
        • Ensure you dropped onto the .bat, not the .ps1, and that the .bat and .ps1 are together.
    - Want a clean slate:
        • Delete %APPDATA%\WinVidCompress\config.json (it will be recreated with defaults).

LICENSE / WARRANTY
    - Personal tool; provided as-is, without warranty. Use at your own risk.

#>

[CmdletBinding()]
param(
    [switch]$CheckEnvironment,
    [switch]$Unattended,
    [switch]$KeepOpen,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Config ---
$AppName    = 'WinVidCompress'
$ConfigDir  = Join-Path $env:APPDATA $AppName
$ConfigPath = Join-Path $ConfigDir 'config.json'
$script:ConfigSnapshot = $null

$DefaultCRF = 22
$VideoExts  = @('.mp4','.mov','.mkv','.m4v','.avi','.mpg','.mpeg','.mts','.m2ts','.wmv')

# Collision behavior when output file already exists:
# "skip": do nothing
# "rename": create " (compressed)" / " (compressed 2)" suffix
$CollisionMode = 'rename'

# --- Helpers ---
function Ensure-Tool([string]$exe) {
    # Preserve PATH-before-adjacent selection, but refuse shell-command shadows.
    $cmd = Get-Command $exe -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd -and $cmd.CommandType -ne 'Application') {
        throw "$exe resolves to a $($cmd.CommandType), not an application. Remove the shadowing command before retrying."
    }
    $candidate = Join-Path (Split-Path -Parent $PSCommandPath) $exe
    if ($cmd) { $candidate = $cmd.Source }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
        throw "$exe not found. Put it in PATH or next to this script."
    }
    try {
        $stream = [IO.File]::Open($candidate, [IO.FileMode]::Open,
            [IO.FileAccess]::Read, [IO.FileShare]::ReadWrite)
        $stream.Dispose()
    } catch {
        throw "$exe cannot be read at '$candidate'. Check read/execute permissions or use an accessible copy in PATH or next to this script. Details: $($_.Exception.Message)"
    }
    return (Get-Item -LiteralPath $candidate -Force).FullName
}

function Get-DefaultOutputDir {
    [Environment]::GetFolderPath('MyVideos')
}

function ConvertTo-NativeArgument([string]$Value) {
    # Windows argv quoting, including quotes and trailing backslashes. No shell.
    '"' + [regex]::Replace($Value, '(\\*)"', '$1$1\"') +
        ('\' * ([regex]::Match($Value, '\\*$').Length)) + '"'
}

function Invoke-EnvironmentCall([string]$Executable, [string[]]$Arguments,
    [ValidateRange(100,30000)][int]$TimeoutMilliseconds = 10000, [switch]$ReturnFailure, [switch]$Utf8Output) {
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $Executable
    $start.Arguments = (@($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' ')
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.RedirectStandardInput = $true
    if ($Utf8Output) {
        $start.StandardOutputEncoding = New-Object Text.UTF8Encoding($false)
        $start.StandardErrorEncoding = New-Object Text.UTF8Encoding($false)
    }
    # FFREPORT would otherwise create logs during even a version/help check.
    $start.EnvironmentVariables.Remove('FFREPORT')
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $start
    $started = $false
    $stdout = $null
    $stderr = $null
    $exitCode = $null
    $timedOut = $false
    $clock = [Diagnostics.Stopwatch]::StartNew()
    try {
        [void]$process.Start()
        $started = $true
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $process.StandardInput.Close()
        $remaining = [Math]::Max(0, $TimeoutMilliseconds - [int]$clock.ElapsedMilliseconds)
        if (-not $process.WaitForExit($remaining)) {
            $timedOut = $true
            throw "Timed out after $TimeoutMilliseconds ms."
        }
        $exitCode = $process.ExitCode
        # An exited child can leave inherited pipe handles open; bound drains too.
        foreach ($reader in @($stdout,$stderr)) {
            $remaining = [Math]::Max(0, $TimeoutMilliseconds - [int]$clock.ElapsedMilliseconds)
            if (-not $reader.Wait($remaining)) {
                $timedOut = $true
                throw "Timed out draining diagnostics after $TimeoutMilliseconds ms."
            }
        }
        $result = [pscustomobject]@{ Succeeded = ($exitCode -eq 0); ExitCode = $exitCode;
            StdOut = $stdout.Result; StdErr = $stderr.Result; TimedOut = $false; Error = $null }
        if ($result.ExitCode -ne 0) {
            throw "Exit code $($result.ExitCode). stderr: $($result.StdErr) stdout: $($result.StdOut)"
        }
        return $result
    } catch {
        $reason = $_.Exception.Message
        $outputText = ''; $errorText = ''
        if ($started) {
            if (-not $process.HasExited) {
                $process.Kill()
                if (-not $process.WaitForExit(2000)) { throw 'Could not stop the owned environment-check process.' }
            }
            # Preserve available diagnostics on timeout too, without an unbounded Result.
            try {
                if ($null -ne $stdout -and $stdout.Wait(500)) { $outputText = $stdout.Result }
            } catch { } # A failed drain must not hide the original diagnostic.
            try {
                if ($null -ne $stderr -and $stderr.Wait(500)) { $errorText = $stderr.Result }
            } catch { }
        }
        if ($ReturnFailure) {
            return [pscustomobject]@{ Succeeded = $false; ExitCode = $exitCode; StdOut = $outputText;
                StdErr = $errorText; TimedOut = $timedOut; Error = $reason }
        }
        if ($errorText) { $reason += " stderr: $errorText" }
        throw "Environment check failed for '$Executable' [$($Arguments -join ' ')]: $reason"
    } finally {
        try {
            if ($started -and -not $process.HasExited) {
                # Kill only the process we started; this is available on .NET Framework.
                $process.Kill()
                if (-not $process.WaitForExit(2000)) { throw 'Could not stop the owned environment-check process.' }
            }
        } finally { $process.Dispose() }
    }
}

function Get-ToolEnvironment([string]$FFmpeg, [string]$FFprobe,
    [ValidateRange(100,30000)][int]$TimeoutMilliseconds = 10000) {
    $calls = New-Object 'Collections.Generic.List[object]'
    $versions = @{}
    foreach ($tool in @(@{ Name = 'ffmpeg'; Path = $FFmpeg }, @{ Name = 'ffprobe'; Path = $FFprobe })) {
        $call = Invoke-EnvironmentCall $tool.Path @('-version') $TimeoutMilliseconds
        $calls.Add($call)
        if ($call.StdOut -notmatch ('(?m)^' + $tool.Name + ' version\s+\S+')) {
            throw "Wrong tool at '$($tool.Path)': expected $($tool.Name) version identification. stderr: $($call.StdErr)"
        }
        $versions[$tool.Name] = $call.StdOut.Trim()
    }
    $encoders = Invoke-EnvironmentCall $FFmpeg @('-hide_banner','-encoders') $TimeoutMilliseconds
    $calls.Add($encoders)
    foreach ($encoder in @(@{ Name = 'libx264'; Kind = 'V' }, @{ Name = 'aac'; Kind = 'A' })) {
        if ($encoders.StdOut -notmatch ('(?m)^\s*' + $encoder.Kind + '[A-Z.]{5}\s+' + $encoder.Name + '\s')) {
            throw "Required encoder '$($encoder.Name)' is unavailable in '$FFmpeg'. stderr: $($encoders.StdErr)"
        }
    }
    $muxer = Invoke-EnvironmentCall $FFmpeg @('-hide_banner','-h','muxer=mp4') $TimeoutMilliseconds
    $calls.Add($muxer)
    if ($muxer.StdOut -notmatch '(?m)^Muxer mp4\s' -or $muxer.StdOut -notmatch '\bfaststart\b') {
        throw "Required MP4 muxer/faststart capability is unavailable in '$FFmpeg'. stderr: $($muxer.StdErr)"
    }
    $filter = Invoke-EnvironmentCall $FFmpeg @('-hide_banner','-h','filter=scale') $TimeoutMilliseconds
    $calls.Add($filter)
    if ($filter.StdOut -notmatch '(?m)^Filter scale\s') {
        throw "Required scale filter is unavailable in '$FFmpeg'. stderr: $($filter.StdErr)"
    }
    # Program metadata exercises the actual writers/options without a media file.
    $csv = Invoke-EnvironmentCall $FFprobe @('-v','error','-show_program_version',
        '-show_entries','program_version=version','-select_streams','v:0','-of','csv=p=0') $TimeoutMilliseconds
    $calls.Add($csv)
    if ([string]::IsNullOrWhiteSpace($csv.StdOut)) {
        throw "FFprobe CSV/program inspection returned no version at '$FFprobe'. stderr: $($csv.StdErr)"
    }
    $json = Invoke-EnvironmentCall $FFprobe @('-v','error','-show_program_version',
        '-show_entries','program_version=version','-select_streams','v:0','-of','json') $TimeoutMilliseconds
    $calls.Add($json)
    try {
        $program = $json.StdOut | ConvertFrom-Json
        if (-not $program.program_version.version -or
            $program.program_version.version -isnot [string]) { throw 'Missing program version.' }
    } catch { throw "FFprobe JSON/program inspection failed at '$FFprobe': $($_.Exception.Message) stderr: $($json.StdErr)" }
    return [pscustomobject]@{
        FFmpeg = $FFmpeg; FFprobe = $FFprobe
        FFmpegBuild = $versions.ffmpeg; FFprobeBuild = $versions.ffprobe
        Capabilities = 'libx264, AAC, MP4/faststart, scale, FFprobe CSV/JSON and selection/entries options'
        Calls = $calls.ToArray()
    }
}

function Get-OutputEnvironment([string]$Destination) {
    Assert-OutputDirectory $Destination
    $temporary = Join-Path $Destination ('.wvc-write-check-' + [guid]::NewGuid().ToString('N') + '.tmp')
    $stream = $null
    try {
        # CreateNew cannot clobber a neighbor. DeleteOnClose removes only this handle's file.
        $stream = New-Object IO.FileStream($temporary, [IO.FileMode]::CreateNew,
            [IO.FileAccess]::ReadWrite, [IO.FileShare]::None, 4096, [IO.FileOptions]::DeleteOnClose)
        $stream.WriteByte(0)
        $stream.Flush()
    } catch {
        throw "Output folder '$Destination' cannot safely create/write/remove a temporary file. Check permissions and capacity. Saved preferences were not changed. Details: $($_.Exception.Message)"
    } finally { if ($null -ne $stream) { $stream.Dispose() } }
    $available = $null
    try {
        # Drive-root bytes can misrepresent nested mount points; stay conservative.
        $item = Get-Item -LiteralPath $Destination -Force
        while ($null -ne $item) {
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse/mount destination.' }
            $item = $item.Parent
        }
        $root = [IO.Path]::GetPathRoot($Destination)
        if ($root.StartsWith('\\')) { throw 'UNC capacity unavailable.' }
        $drive = New-Object IO.DriveInfo($root)
        $available = $drive.AvailableFreeSpace
    } catch { } # Unknown capacity is an advisory, never a reason to redirect output.
    return [pscustomobject]@{ Destination = $Destination; AvailableBytes = $available }
}

function Get-EnvironmentConfig {
    # Doctor must not create config, locks, backups or recover malformed preferences.
    if (Test-Path -LiteralPath $ConfigPath) { return (ConvertFrom-ConfigText (Read-ConfigFile).Text) }
    $cfg = [pscustomobject]@{ OutputDir = (Get-DefaultOutputDir) }
    Assert-ConfigShape $cfg
    return $cfg
}

function Write-EnvironmentReport($Tools, $Output) {
    Write-Host "Dependency selection: PATH before script-adjacent applications."
    Write-Host "FFmpeg: $($Tools.FFmpeg)"
    Write-Host $Tools.FFmpegBuild
    Write-Host "FFprobe: $($Tools.FFprobe)"
    Write-Host $Tools.FFprobeBuild
    Write-Host "Capabilities: $($Tools.Capabilities)"
    foreach ($call in $Tools.Calls) {
        if ($call.StdErr) { Write-Host ("Tool diagnostics: " + $call.StdErr.Trim()) -ForegroundColor Yellow }
    }
    Write-Host "Output folder: $($Output.Destination)"
    Write-Host 'Temporary create/write/remove check passed (point-in-time only).'
    if ($null -eq $Output.AvailableBytes) {
        Write-Host 'Available capacity: unknown for this destination.' -ForegroundColor Yellow
    } else {
        Write-Host "Available capacity now: $($Output.AvailableBytes) bytes."
        if ($Output.AvailableBytes -lt 1GB) { Write-Host 'Capacity concern: less than 1 GiB available.' -ForegroundColor Yellow }
    }
    Write-Host 'Output size is not guaranteed; free space and permissions can change during a batch.'
}

function Assert-ConfigShape($cfg) {
    if ($null -eq $cfg -or $cfg -isnot [Management.Automation.PSCustomObject]) {
        throw 'Config root must be a JSON object.'
    }
    $property = $cfg.PSObject.Properties['OutputDir']
    if ($null -eq $property -or $property.Value -isnot [string] -or
        [string]::IsNullOrWhiteSpace($property.Value)) {
        throw 'Config OutputDir must be a nonempty string.'
    }
    $destination = $property.Value
    # Only absolute Windows filesystem paths; never expand shell/provider values.
    if ($destination -notmatch '^(?:[A-Za-z]:[\\/]|\\\\[^\\/]+\\[^\\/]+(?:\\|$))' -or
        $destination.Substring(2) -match '[<>:"|?*\x00-\x1f]') {
        throw 'Config OutputDir must be an absolute drive or UNC directory path without wildcards.'
    }
    [void][IO.Path]::GetFullPath($destination)
}

function ConvertFrom-ConfigText([string]$Text) {
    # PS5.1 can unwrap a one-element JSON array, so inspect the raw root too.
    if (-not $Text.TrimStart().StartsWith('{')) { throw 'Config root must be a JSON object.' }
    $jsonArguments = @{ InputObject = $Text; ErrorAction = 'Stop' }
    if ((Get-Command ConvertFrom-Json).Parameters.ContainsKey('DateKind')) {
        $jsonArguments.DateKind = 'String'
    }
    $cfg = ConvertFrom-Json @jsonArguments
    Assert-ConfigShape $cfg
    return $cfg
}

function Assert-OutputDirectory([string]$Destination) {
    try {
        $item = Get-Item -LiteralPath $Destination -Force -ErrorAction Stop
        if ($item.PSProvider.Name -ne 'FileSystem' -or -not $item.PSIsContainer) {
            throw 'The destination is not a filesystem directory.'
        }
        # Force directory access without creating a test file or output.
        $entries = [IO.Directory]::EnumerateFileSystemEntries($Destination).GetEnumerator()
        try { [void]$entries.MoveNext() } finally { $entries.Dispose() }
    } catch {
        throw "Output folder '$Destination' is unavailable or inaccessible. Check the drive/share and permissions. Saved preferences were not redirected. Details: $($_.Exception.Message)"
    }
}

function Open-ConfigLock {
    try {
        [void][IO.Directory]::CreateDirectory($ConfigDir)
        # Keep this small sidecar: deleting it after unlock races another writer.
        return [IO.File]::Open(($ConfigPath + '.lock'), [IO.FileMode]::OpenOrCreate,
            [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    } catch {
        throw "Cannot acquire config lock. Another instance may be saving, or the config folder is inaccessible. Retry after checking permissions. Details: $($_.Exception.Message)"
    }
}

function Read-ConfigFile {
    $stream = $null
    try {
        $stream = [IO.File]::Open($ConfigPath, [IO.FileMode]::Open,
            [IO.FileAccess]::Read, [IO.FileShare]::Read)
        $memory = New-Object IO.MemoryStream
        try {
            $stream.CopyTo($memory)
            $bytes = $memory.ToArray()
            $memory.Position = 0
            $reader = New-Object IO.StreamReader($memory, [Text.Encoding]::UTF8, $true)
            try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }
        } finally { $memory.Dispose() }
        return [pscustomobject]@{ Path = $ConfigPath; Exists = $true;
            Signature = [Convert]::ToBase64String($bytes); Text = $text }
    } catch [IO.FileNotFoundException] {
        return [pscustomobject]@{ Path = $ConfigPath; Exists = $false; Signature = ''; Text = '' }
    } catch {
        throw "Cannot read config '$ConfigPath'. No recovery was attempted. Details: $($_.Exception.Message)"
    } finally { if ($null -ne $stream) { $stream.Dispose() } }
}

function Write-ConfigTemporaryFile([string]$TemporaryPath, [byte[]]$Bytes) {
    $stream = [IO.File]::Open($TemporaryPath, [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write, [IO.FileShare]::None)
    try {
        $stream.Write($Bytes, 0, $Bytes.Length)
        $stream.Flush($true)
    } catch {
        $stream.Dispose()
        [IO.File]::Delete($TemporaryPath)  # Only the file this call created.
        throw
    } finally { $stream.Dispose() }
}

function Backup-ConfigFile([string]$BackupPath) {
    [IO.File]::Copy($ConfigPath, $BackupPath, $false)
}

function Publish-ConfigFile([string]$TemporaryPath, [bool]$Replacing) {
    if ($Replacing) {
        [IO.File]::Replace($TemporaryPath, $ConfigPath, [NullString]::Value)
    } else {
        [IO.File]::Move($TemporaryPath, $ConfigPath)
    }
}

function Assert-ConfigDepth($cfg) {
    # PS5.1 silently truncates deep JSON without the warning emitted by PS7.
    $pending = New-Object 'Collections.Generic.Stack[object]'
    $pending.Push([pscustomobject]@{ Value = $cfg; Depth = 0 })
    while ($pending.Count) {
        $entry = $pending.Pop()
        $value = $entry.Value
        $children = @()
        if ($value -is [Management.Automation.PSCustomObject]) {
            if ($entry.Depth -gt 100) { throw 'Config nesting exceeds the supported JSON depth of 100.' }
            foreach ($property in $value.PSObject.Properties) {
                $pending.Push([pscustomobject]@{ Value = $property.Value; Depth = ($entry.Depth + 1) })
            }
        } elseif ($value -is [Collections.IDictionary] -or $value -is [array]) {
            if ($entry.Depth -gt 100) { throw 'Config nesting exceeds the supported JSON depth of 100.' }
            if ($value -is [Collections.IDictionary]) { $children = @($value.Values) }
            else { $children = $value }
            foreach ($child in $children) {
                $pending.Push([pscustomobject]@{ Value = $child; Depth = ($entry.Depth + 1) })
            }
        }
    }
}

function Write-ConfigFile($cfg, $Previous, [string]$BackupKind = 'previous') {
    $temporary = Join-Path $ConfigDir ('config.' + [guid]::NewGuid().ToString('N') + '.tmp')
    $ownedTemporary = $false
    $backup = $null
    try {
        Assert-ConfigDepth $cfg
        $json = ConvertTo-Json -InputObject $cfg -Depth 100 -WarningAction Stop
        [void](ConvertFrom-ConfigText $json)
        $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($json + "`r`n")
        Write-ConfigTemporaryFile $temporary $bytes
        $ownedTemporary = $true
        if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($temporary)) -cne [Convert]::ToBase64String($bytes)) {
            throw 'Temporary config verification failed.'
        }
        if ($Previous.Exists) {
            $backup = Join-Path $ConfigDir ('config.' + $BackupKind + '-' + [guid]::NewGuid().ToString('N') + '.json')
            Backup-ConfigFile $backup
            if ([Convert]::ToBase64String([IO.File]::ReadAllBytes($backup)) -cne $Previous.Signature) {
                throw 'Config changed while creating its backup; reload before saving.'
            }
        }
        Publish-ConfigFile $temporary $Previous.Exists
        $script:ConfigSnapshot = [pscustomobject]@{ Path = $ConfigPath; Exists = $true;
            Signature = [Convert]::ToBase64String($bytes); Text = $json }
        return $backup
    } catch {
        throw "Cannot save config '$ConfigPath'. The previous file was not intentionally removed; any completed backup is retained. Details: $($_.Exception.Message)"
    } finally {
        if ($ownedTemporary -and [IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
}

function Save-Config($cfg) {
    Assert-ConfigShape $cfg
    Assert-OutputDirectory $cfg.OutputDir
    $lock = Open-ConfigLock
    try {
        $current = Read-ConfigFile
        if ($null -eq $script:ConfigSnapshot -or $script:ConfigSnapshot.Path -ne $ConfigPath) {
            if ($current.Exists) { throw 'Please load config before replacing an existing preference file.' }
        } elseif ($script:ConfigSnapshot.Exists -ne $current.Exists -or
            $script:ConfigSnapshot.Signature -cne $current.Signature) {
            throw 'Config changed since it was loaded/saved; reload before saving.'
        }
        [void](Write-ConfigFile $cfg $current)
    } finally { $lock.Dispose() }
}

function Load-Config {
    $lock = Open-ConfigLock
    try {
        $current = Read-ConfigFile
        $cfg = $null
        $invalidReason = $null
        if ($current.Exists) {
            try { $cfg = ConvertFrom-ConfigText $current.Text }
            catch { $invalidReason = $_.Exception.Message }
        }
        if (-not $current.Exists -or $null -ne $invalidReason) {
            try {
                $cfg = [pscustomobject]@{ OutputDir = (Get-DefaultOutputDir) }
                Assert-ConfigShape $cfg
                Assert-OutputDirectory $cfg.OutputDir
            } catch {
                throw "Cannot use the default Videos folder. Config was not replaced. Details: $($_.Exception.Message)"
            }
            $backup = Write-ConfigFile $cfg $current 'invalid'
            if ($null -ne $invalidReason) {
                Write-Host "Invalid config: $invalidReason Original bytes preserved at '$backup'. Using the default Videos folder '$($cfg.OutputDir)'." -ForegroundColor Yellow
            }
        } else {
            # Availability failures are operational errors, never schema recovery.
            Assert-OutputDirectory $cfg.OutputDir
            $script:ConfigSnapshot = $current
        }
        return $cfg
    } finally { $lock.Dispose() }
}

function Prompt-Path([string]$prompt, [switch]$Folder, [switch]$CreateIfMissing) {
    while ($true) {
        $p = Read-Host $prompt
        if ([string]::IsNullOrWhiteSpace($p)) { return $null }
        $p = $p.Trim().Trim('"')
        if ([string]::IsNullOrWhiteSpace($p)) { return $null }

        try {
            if ($Folder) {
                if ($CreateIfMissing -and -not (Test-Path -LiteralPath $p)) {
                    # Creation is reserved for an explicitly selected output folder.
                    [void][IO.Directory]::CreateDirectory($p)
                }
                if (Test-Path -LiteralPath $p -PathType Container) {
                    return (Resolve-Path -LiteralPath $p).Path
                }
            } else {
                if (Test-Path -LiteralPath $p -PathType Leaf) {
                    return (Resolve-Path -LiteralPath $p).Path
                }
            }
        } catch {
            Write-Host "Cannot access path '$p': $($_.Exception.Message)" -ForegroundColor Yellow
            continue
        }

        Write-Host "Invalid path. Try again." -ForegroundColor Yellow
    }
}

function Parse-MetadataFromName([string]$fileName) {
    $base = [IO.Path]::GetFileNameWithoutExtension($fileName)

    $patterns = @(
        '^(?<band>.+?)\s+(?<dd>\d{2})(?<mm>\d{2})(?<yyyy>\d{4})(?:\s*-\s*.*)?$',
        '^(?<band>.+?)\s+(?<dd>\d{2})[.\-](?<mm>\d{2})[.\-](?<yyyy>\d{4})(?:\s*-\s*.*)?$'
    )

    foreach ($rx in $patterns) {
        $m = [regex]::Match($base, $rx)
        if ($m.Success) {
            $band = $m.Groups['band'].Value.Trim()
            $dd   = $m.Groups['dd'].Value
            $mm   = $m.Groups['mm'].Value
            $yyyy = $m.Groups['yyyy'].Value
            $iso  = "{0}-{1}-{2}" -f $yyyy,$mm,$dd
            $hum  = "{0}.{1}.{2}" -f $dd,$mm,$yyyy
            return [pscustomobject]@{
                Band      = $band
                DateISO   = $iso
                DateHuman = $hum
                Title     = $base
            }
        }
    }

    # Fallback, find any 8-digit date anywhere (ddmmyyyy)
    $m2 = [regex]::Match($base, '(?<!\d)(?<dd>\d{2})(?<mm>\d{2})(?<yyyy>\d{4})(?!\d)')
    if ($m2.Success) {
        $idx  = $m2.Index
        $band = $base.Substring(0, $idx).Trim()
        $dd   = $m2.Groups['dd'].Value
        $mm   = $m2.Groups['mm'].Value
        $yyyy = $m2.Groups['yyyy'].Value
        $iso  = "{0}-{1}-{2}" -f $yyyy,$mm,$dd
        $hum  = "{0}.{1}.{2}" -f $dd,$mm,$yyyy
        return [pscustomobject]@{
            Band      = $band
            DateISO   = $iso
            DateHuman = $hum
            Title     = $base
        }
    }

    # No prompts, compress anyway, just without tags
    return [pscustomobject]@{
        Band      = ''
        DateISO   = ''
        DateHuman = ''
        Title     = $base
    }
}

function Get-ProbeProperty($Object, [string]$Name) {
    if ($null -ne $Object -and $Object -is [Management.Automation.PSCustomObject]) {
        $property = $Object.PSObject.Properties[$Name]
        if ($null -ne $property) { return ,$property.Value }
    }
    return $null
}

function ConvertTo-ProbeNumber($Value) {
    if ($null -eq $Value -or $Value -is [bool] -or
        ($Value -isnot [string] -and $Value -isnot [ValueType])) { return $null }
    $number = 0.0
    $text = [Convert]::ToString($Value, [Globalization.CultureInfo]::InvariantCulture)
    if ([double]::TryParse($text, [Globalization.NumberStyles]::Float,
        [Globalization.CultureInfo]::InvariantCulture, [ref]$number) -and
        -not [double]::IsNaN($number) -and -not [double]::IsInfinity($number)) { return $number }
    return $null
}

function ConvertTo-ProbeInteger($Value) {
    $number = ConvertTo-ProbeNumber $Value
    if ($null -ne $number -and $number -ge 0 -and $number -le [int]::MaxValue -and
        [Math]::Truncate($number) -eq $number) { return [int]$number }
    return $null
}

function ConvertTo-ProbeString($Value) {
    if ($Value -is [string] -and -not [string]::IsNullOrWhiteSpace($Value) -and
        $Value -notin @('N/A','unknown','unspecified')) { return $Value }
    return $null
}

function ConvertTo-ProbeRatio($Value, [string]$Separator = '/') {
    if ($Value -isnot [string]) { return $null }
    $parts = $Value -split [regex]::Escape($Separator)
    if ($parts.Count -ne 2) { return $null }
    $numerator = ConvertTo-ProbeInteger $parts[0]
    $denominator = ConvertTo-ProbeInteger $parts[1]
    if ($null -eq $numerator -or $null -eq $denominator -or $numerator -le 0 -or $denominator -le 0) { return $null }
    return [pscustomobject]@{ Raw = $Value; Numerator = $numerator; Denominator = $denominator;
        Value = ([double]$numerator / $denominator) }
}

function New-ProbeResult {
    [pscustomobject]@{ SchemaVersion = 1; Succeeded = $false; Stage = 'Json'; FailureKind = $null; Reason = $null;
        InputPath = $null; ResolvedInputPath = $null; Native = $null; Streams = @(); RealVideoIndices = @();
        PrimaryVideoIndex = $null; PrimaryVideo = $null; FormatName = $null; FormatTimecode = $null;
        DurationSeconds = $null; DurationState = 'Unknown'; DurationSource = $null; ProgressMode = 'Indeterminate';
        GeometryState = 'MetadataOnly'; DisplayGeometry = $null; Warnings = @(); Limitations = @() }
}

function ConvertFrom-ProbeJson([string]$Json) {
    $result = New-ProbeResult
    $kind = 'InvalidJson'
    try {
        # PS5.1 can unwrap a one-object root array. The root must be an object.
        if (-not $Json.TrimStart().StartsWith('{')) { throw 'Probe JSON root must be an object.' }
        $document = ConvertFrom-Json -InputObject $Json -ErrorAction Stop
        $kind = 'InvalidStructure'
        $rawStreams = Get-ProbeProperty $document 'streams'
        if ($rawStreams -isnot [array]) { throw 'Probe streams must be an array.' }
        $format = Get-ProbeProperty $document 'format'
        if ($null -ne $format -and $format -isnot [Management.Automation.PSCustomObject]) {
            throw 'Probe format must be an object when present.'
        }
        $result.FormatName = ConvertTo-ProbeString (Get-ProbeProperty $format 'format_name')
        $result.FormatTimecode = ConvertTo-ProbeString (Get-ProbeProperty (Get-ProbeProperty $format 'tags') 'timecode')
        if ($result.FormatName -and @($result.FormatName -split ',' | Where-Object { $_ -in @('hls','dash','concat') }).Count) {
            $kind = 'UnsupportedFormat'
            throw 'Playlist/manifest demuxers are not supported video inputs.'
        }
        $streams = New-Object 'Collections.Generic.List[object]'
        $indices = New-Object 'Collections.Generic.HashSet[int]'
        foreach ($raw in $rawStreams) {
            $kind = 'InvalidStructure'
            if ($raw -isnot [Management.Automation.PSCustomObject]) { throw 'Each probe stream must be an object.' }
            $index = ConvertTo-ProbeInteger (Get-ProbeProperty $raw 'index')
            $rawType = Get-ProbeProperty $raw 'codec_type'
            # FFprobe's explicit unknown stream type is still an identifiable omitted stream.
            $type = $(if ($rawType -is [string] -and $rawType -eq 'unknown') { 'unknown' } else { ConvertTo-ProbeString $rawType })
            if ($null -eq $index -or -not $indices.Add($index) -or $null -eq $type) {
                throw 'Every stream needs a unique nonnegative integer index and codec type.'
            }
            $flags = Get-ProbeProperty $raw 'disposition'
            if ($null -ne $flags -and $flags -isnot [Management.Automation.PSCustomObject]) {
                throw "Stream $index disposition must be an object."
            }
            $disposition = @{}
            if ($null -ne $flags) {
                foreach ($flag in $flags.PSObject.Properties) {
                    $value = ConvertTo-ProbeInteger $flag.Value
                    if ($null -eq $value -or $value -notin @(0,1)) { throw "Stream $index has invalid disposition '$($flag.Name)'." }
                    $disposition[$flag.Name] = $value
                }
            }
            $attached = $disposition.ContainsKey('attached_pic') -and $disposition['attached_pic'] -eq 1
            $codec = ConvertTo-ProbeString (Get-ProbeProperty $raw 'codec_name')
            $width = ConvertTo-ProbeInteger (Get-ProbeProperty $raw 'width')
            $height = ConvertTo-ProbeInteger (Get-ProbeProperty $raw 'height')
            if ($type -eq 'video' -and -not $attached -and
                ($null -eq $codec -or $null -eq $width -or $width -le 0 -or $null -eq $height -or $height -le 0)) {
                $kind = 'InvalidVideo'
                throw "Real video stream $index needs a codec and positive coded width/height."
            }
            $tags = Get-ProbeProperty $raw 'tags'
            $rotation = $null; $rotationSource = $null; $matrix = $null; $matrixCount = 0; $rotationInvalid = $false
            $sideData = Get-ProbeProperty $raw 'side_data_list'
            if ($null -ne $sideData -and $sideData -isnot [array]) { throw "Stream $index side_data_list must be an array." }
            $hdrTypes = @()
            foreach ($side in @($sideData)) {
                $sideType = ConvertTo-ProbeString (Get-ProbeProperty $side 'side_data_type')
                if ($sideType -in @('Mastering display metadata','Content light level metadata','DOVI configuration record',
                    'Dolby Vision RPU Data','Dolby Vision Metadata') -or $sideType -match '^HDR Dynamic Metadata ') {
                    $hdrTypes += $sideType
                }
                if ((Get-ProbeProperty $side 'side_data_type') -eq 'Display Matrix') {
                    $matrixCount++
                    if ($matrixCount -gt 1) { continue }
                    $rotation = ConvertTo-ProbeNumber (Get-ProbeProperty $side 'rotation')
                    $matrix = ConvertTo-ProbeString (Get-ProbeProperty $side 'displaymatrix')
                    $rotationInvalid = $null -eq $rotation
                    if ($null -ne $rotation) { $rotationSource = 'DisplayMatrix' }
                }
            }
            if ($matrixCount -eq 0) {
                $rawRotation = Get-ProbeProperty $tags 'rotate'
                $rotation = ConvertTo-ProbeNumber $rawRotation
                if ($matrixCount -eq 0 -and $null -ne $rawRotation -and $null -eq $rotation) { $rotationInvalid = $true }
                if ($null -ne $rotation) { $rotationSource = 'Tag' }
            }
            $sar = ConvertTo-ProbeRatio (Get-ProbeProperty $raw 'sample_aspect_ratio') ':'
            $dar = ConvertTo-ProbeRatio (Get-ProbeProperty $raw 'display_aspect_ratio') ':'
            $durationValue = Get-ProbeProperty $raw 'duration'
            $duration = ConvertTo-ProbeNumber $durationValue
            if ($null -ne $duration -and $duration -le 0) { $duration = $null }
            $channels = ConvertTo-ProbeInteger (Get-ProbeProperty $raw 'channels')
            $sampleRate = ConvertTo-ProbeInteger (Get-ProbeProperty $raw 'sample_rate')
            if ($null -ne $channels -and $channels -le 0) { $channels = $null }
            if ($null -ne $sampleRate -and $sampleRate -le 0) { $sampleRate = $null }
            $streams.Add([pscustomobject]@{
                Index = $index; CodecType = $type; CodecName = $codec;
                Disposition = [pscustomobject]@{ Default = ($disposition.ContainsKey('default') -and $disposition['default'] -eq 1);
                    AttachedPicture = $attached; Flags = $disposition };
                Width = $width; Height = $height; SampleAspectRatio = $(if ($null -ne $sar) { $sar.Raw } else { $null });
                DisplayAspectRatio = $(if ($null -ne $dar) { $dar.Raw } else { $null });
                RotationDegrees = $rotation; RotationSource = $rotationSource; DisplayMatrix = $matrix;
                DisplayMatrixCount = $matrixCount; RotationMetadataInvalid = $rotationInvalid;
                HdrMetadataTypes = @($hdrTypes | Select-Object -Unique);
                PixelFormat = (ConvertTo-ProbeString (Get-ProbeProperty $raw 'pix_fmt'));
                ColourPrimaries = (ConvertTo-ProbeString (Get-ProbeProperty $raw 'color_primaries'));
                ColourTransfer = (ConvertTo-ProbeString (Get-ProbeProperty $raw 'color_transfer'));
                ColourMatrix = (ConvertTo-ProbeString (Get-ProbeProperty $raw 'color_space'));
                ColourRange = (ConvertTo-ProbeString (Get-ProbeProperty $raw 'color_range'));
                AverageFrameRate = (ConvertTo-ProbeRatio (Get-ProbeProperty $raw 'avg_frame_rate'));
                RealFrameRate = (ConvertTo-ProbeRatio (Get-ProbeProperty $raw 'r_frame_rate'));
                TimeBase = (ConvertTo-ProbeRatio (Get-ProbeProperty $raw 'time_base'));
                Channels = $channels; SampleRate = $sampleRate;
                FrameCount = (ConvertTo-ProbeInteger (Get-ProbeProperty $raw 'nb_frames'));
                CodecTag = (ConvertTo-ProbeString (Get-ProbeProperty $raw 'codec_tag_string'));
                Timecode = (ConvertTo-ProbeString (Get-ProbeProperty $tags 'timecode'));
                ChannelLayout = (ConvertTo-ProbeString (Get-ProbeProperty $raw 'channel_layout'));
                Language = (ConvertTo-ProbeString (Get-ProbeProperty $tags 'language'));
                DurationSeconds = $duration; DurationRaw = $durationValue
            })
        }
        $result.Streams = @($streams.ToArray() | Sort-Object Index)
        $videos = @($result.Streams | Where-Object { $_.CodecType -eq 'video' -and -not $_.Disposition.AttachedPicture })
        $result.RealVideoIndices = @($videos | ForEach-Object { $_.Index })
        if ($videos.Count -eq 0) { $kind = 'NoRealVideo'; throw 'Probe found no real video stream (attached artwork is excluded).' }
        $result.PrimaryVideo = $videos[0]
        $result.PrimaryVideoIndex = $videos[0].Index
        $formatDurationRaw = Get-ProbeProperty $format 'duration'
        $formatDuration = ConvertTo-ProbeNumber $formatDurationRaw
        if ($null -ne $formatDuration -and $formatDuration -gt 0) {
            $result.DurationSeconds = $formatDuration; $result.DurationSource = 'Format'
        } elseif ($null -ne $videos[0].DurationSeconds) {
            $result.DurationSeconds = $videos[0].DurationSeconds; $result.DurationSource = 'VideoStream'
        }
        if ($null -ne $result.DurationSeconds) {
            $result.DurationState = 'Known'; $result.ProgressMode = 'DurationAvailable'
        } else {
            $rawDurations = @($formatDurationRaw,$videos[0].DurationRaw)
            if (@($rawDurations | Where-Object { $null -ne $_ -and $_ -ne '' -and $_ -ne 'N/A' }).Count) { $result.DurationState = 'Invalid' }
            $result.Warnings += 'Source duration is unknown; progress is indeterminate; duration comparison is unavailable for validation.'
            $result.Limitations += 'Source/output duration comparison is unavailable without a known source duration.'
        }
        $result.Limitations += 'Probe geometry is raw metadata; the selected stream geometry plan is derived separately.'
        $result.Succeeded = $true; $result.Stage = 'Ready'
    } catch {
        $result.FailureKind = $kind; $result.Reason = $_.Exception.Message
        $result.Stage = $(if ($kind -eq 'InvalidJson') { 'Json' } else { 'Validation' })
    }
    return $result
}

function Get-MediaInspection([string]$FFprobe, [string]$InputPath,
    [ValidateRange(100,30000)][int]$TimeoutMilliseconds = 10000) {
    $result = New-ProbeResult
    $result.InputPath = $InputPath
    try {
        $source = Get-Item -LiteralPath $InputPath -Force -ErrorAction Stop
        if ($source.PSProvider.Name -ne 'FileSystem' -or $source.PSIsContainer -or $source.Extension -notin $VideoExts) {
            throw 'The probe input must be an existing supported local/UNC video file.'
        }
        $result.ResolvedInputPath = $source.FullName
    } catch {
        $result.Stage = 'Source'; $result.FailureKind = 'InvalidSource'; $result.Reason = $_.Exception.Message
        return $result
    }
    $native = Invoke-EnvironmentCall $FFprobe @('-v','error','-protocol_whitelist','file',
        '-show_streams','-show_format','-of','json','-i',$source.FullName) $TimeoutMilliseconds -ReturnFailure -Utf8Output
    if (-not $native.Succeeded) {
        $result.Stage = 'Probe'; $result.Native = $native; $result.Reason = $native.Error
        $result.FailureKind = $(if ($native.TimedOut) { 'Timeout' } elseif ($null -eq $native.ExitCode) { 'NativeStart' } else { 'NativeExit' })
        return $result
    }
    $result = ConvertFrom-ProbeJson $native.StdOut
    $result.InputPath = $InputPath; $result.ResolvedInputPath = $source.FullName; $result.Native = $native
    return $result
}

function Get-DisplayMatrixGeometry($Video) {
    # FFprobe row order: a,b,u / c,d,v / x,y,w. Affine values are 16.16; u,v,w are 2.30.
    $row = '[ \t]+(?<v>[+-]?\d+)[ \t]+(?<v>[+-]?\d+)[ \t]+(?<v>[+-]?\d+)[ \t]*'
    $pattern = '\A\s*00000000:' + $row + '\r?\n[ \t]*00000001:' + $row + '\r?\n[ \t]*00000002:' + $row + '\s*\z'
    $match = [regex]::Match([string]$Video.DisplayMatrix,$pattern)
    if (-not $match.Success) { throw 'Unsupported display matrix: expected three complete FFprobe integer rows.' }
    $values = @($match.Groups['v'].Captures | ForEach-Object {
        $value = 0
        if (-not [int]::TryParse($_.Value,[Globalization.NumberStyles]::Integer,
            [Globalization.CultureInfo]::InvariantCulture,[ref]$value)) { throw 'Unsupported display matrix: integer overflow.' }
        $value
    })
    $a,$b,$u,$c,$d,$v,$x,$y,$w = $values
    $diagonal = $b -eq 0 -and $c -eq 0 -and [Math]::Abs([long]$a) -eq 65536 -and [Math]::Abs([long]$d) -eq 65536
    $swapped = $a -eq 0 -and $d -eq 0 -and [Math]::Abs([long]$b) -eq 65536 -and [Math]::Abs([long]$c) -eq 65536
    if ($u -ne 0 -or $v -ne 0 -or $w -ne 1073741824 -or (-not $diagonal -and -not $swapped)) {
        throw 'Unsupported display matrix: only canonical quarter turns and axis reflections without scale, skew or perspective are supported.'
    }
    $rebaseX = -[Math]::Min(0.0,[long]$a*$Video.Width) - [Math]::Min(0.0,[long]$c*$Video.Height)
    $rebaseY = -[Math]::Min(0.0,[long]$b*$Video.Width) - [Math]::Min(0.0,[long]$d*$Video.Height)
    if (($x -ne 0 -or $y -ne 0) -and ($x -ne $rebaseX -or $y -ne $rebaseY)) {
        throw 'Unsupported display matrix: arbitrary canvas translation is outside the no-crop policy.'
    }
    $angle = $(if ($a -gt 0) { 0 } elseif ($a -lt 0) { 180 } elseif ($b -gt 0) { 270 } else { 90 })
    [pscustomobject]@{ RotationDegrees=$angle; IsIdentity=($a -eq 65536 -and $d -eq 65536 -and $b -eq 0 -and $c -eq 0 -and $x -eq 0 -and $y -eq 0) }
}

function Get-VideoGeometryPlan($Video) {
    if ((Get-ProbeProperty $Video 'RotationMetadataInvalid') -eq $true) { throw 'Unsupported geometry: supplied rotation metadata is invalid.' }
    $rotation = $(if ($null -eq $Video.RotationDegrees) { 0.0 } else { $Video.RotationDegrees })
    # Accept only exact quarter turns. Arbitrary rotation can clip the frame in FFmpeg's default canvas.
    if (($rotation % 90) -ne 0) { throw 'Unsupported geometry: rotation must be a multiple of 90 degrees for the no-crop policy.' }
    $rotation = (($rotation % 360) + 360) % 360
    $swap = ($rotation % 180) -eq 90
    $matrixIdentity = $true
    $matrixCount = Get-ProbeProperty $Video 'DisplayMatrixCount'
    if ($matrixCount -gt 0 -or $null -ne $Video.DisplayMatrix) {
        if ($matrixCount -gt 1) { throw 'Unsupported geometry: multiple display matrices are ambiguous.' }
        $matrix = Get-DisplayMatrixGeometry $Video
        if ($matrix.RotationDegrees -ne $rotation) { throw 'Unsupported geometry: display matrix and reported rotation disagree.' }
        $matrixIdentity = $matrix.IsIdentity
    }
    $width = $(if ($swap) { $Video.Height } else { $Video.Width })
    $height = $(if ($swap) { $Video.Width } else { $Video.Height })
    $targetHeight = [int](2*[Math]::Floor([Math]::Min($height,1080)/2.0))
    $targetWidth = [int][Math]::Min(2*[Math]::Floor($width/2.0),
        2*[Math]::Round($width*$targetHeight/[double]$height/2.0,[MidpointRounding]::AwayFromZero))
    if ($targetWidth -lt 2 -or $targetHeight -lt 2) { throw 'Unsupported geometry: even dimensions of at least 2x2 require enlargement.' }
    $warnings = @(); $expectedDar = $null; $expectedSar = $null
    $sar = ConvertTo-ProbeRatio $Video.SampleAspectRatio ':'
    $dar = ConvertTo-ProbeRatio $Video.DisplayAspectRatio ':'
    if ($null -ne $sar) {
        $codedDar = $Video.Width/[double]$Video.Height*$sar.Value
        if ($null -ne $dar -and [Math]::Abs($dar.Value/$codedDar-1) -gt 0.001) { throw 'Unsupported geometry: coded DAR and SAR disagree by more than 0.1 percent.' }
        $orientedSar = $(if ($swap) { 1.0/$sar.Value } else { $sar.Value })
        $expectedDar = $width/[double]$height*$orientedSar
        $expectedSar = $expectedDar*$targetHeight/$targetWidth
    } else { $warnings += 'Source pixel aspect is unknown; display aspect preservation cannot be established from metadata.' }
    $filter = $(if ($targetWidth -ne $width -or $targetHeight -ne $height) { "scale=${targetWidth}:${targetHeight}" } else { $null })
    # Default autorotation precedes this scale. Scale adjusts SAR to preserve DAR; do not force square pixels.
    [pscustomobject]@{ RotationDegrees=$rotation; MatrixIsIdentity=$matrixIdentity; OrientedWidth=$width; OrientedHeight=$height;
        TargetWidth=$targetWidth; TargetHeight=$targetHeight; Filter=$filter; ExpectedDisplayAspectRatio=$expectedDar;
        ExpectedSampleAspectRatio=$expectedSar; AspectRelativeTolerance=0.001; Warnings=$warnings }
}

function Get-VideoColourPlan($Video) {
    # Bit depth and BT2020 gamut alone are not evidence of HDR.
    $transfer = ConvertTo-ProbeString (Get-ProbeProperty $Video 'ColourTransfer')
    $primaries = ConvertTo-ProbeString (Get-ProbeProperty $Video 'ColourPrimaries')
    $matrix = ConvertTo-ProbeString (Get-ProbeProperty $Video 'ColourMatrix')
    $range = ConvertTo-ProbeString (Get-ProbeProperty $Video 'ColourRange')
    $pixels = ConvertTo-ProbeString (Get-ProbeProperty $Video 'PixelFormat')
    $rawHdrTypes = Get-ProbeProperty $Video 'HdrMetadataTypes'
    $hdrTypes = @($rawHdrTypes | Where-Object { $_ })
    $plan = [pscustomobject]@{ Supported=$true; State='SDR'; Reason=$null; OutputPixelFormat='yuv420p';
        Primaries=$null; Transfer=$null; Matrix=$null; Range=$null; ConvertFullRange=$false; Arguments=@(); Warnings=@() }
    if ($transfer -in @('smpte2084','arib-std-b67') -or $hdrTypes.Count) {
        $evidence = @($transfer) + $hdrTypes
        $plan.Supported=$false; $plan.State='UnsupportedHDR'
        $plan.Reason='Unsupported HDR (' + (($evidence | Where-Object { $_ }) -join ', ') +
            '): no validated HDR conversion is available. Convert a copy separately to SDR with a reviewed tone-mapping workflow, then retry; the source is unchanged.'
        return $plan
    }
    if ($pixels -and $pixels -match '^yuvj' -and $range -eq 'tv') {
        $plan.Supported=$false; $plan.State='UnsupportedColour'
        $plan.Reason='Unsupported colour: full-range pixel format contradicts limited-range metadata. Export a copy with corrected colour metadata separately, then retry.'
        return $plan
    }
    if ($transfer -in @('linear','log100','log316','log','log_sqrt','vlog','smpte428') -or
        $matrix -in @('gbr','rgb','bt2020c','ictcp','chroma-derived-c','chroma-derived-nc','smpte2085') -or
        ($pixels -and $pixels -match '^(gbr|rgb|bgr|rgba|bgra|argb|abgr|xyz)')) {
        $plan.Supported=$false; $plan.State='UnsupportedColour'
        $plan.Reason='Unsupported colour transform: RGB, linear/log or specialized matrix conversion is untested. Export a conventional YUV SDR copy with known colour metadata separately, then retry; the source is unchanged.'
        return $plan
    }
    $knownPrimaries=@('bt709','bt470m','bt470bg','smpte170m','smpte240m','film','bt2020','smpte431','smpte432','jedec-p22')
    $knownTransfers=@('bt709','bt470m','bt470bg','gamma22','gamma28','smpte170m','smpte240m',
        'iec61966-2-4','bt1361e','iec61966-2-1','bt2020-10','bt2020-12')
    $knownMatrices=@('bt709','fcc','bt470bg','smpte170m','smpte240m','bt2020nc')
    if ($primaries -in $knownPrimaries) { $plan.Primaries=$primaries }
    if ($transfer -in $knownTransfers) {
        $plan.Transfer=$transfer
        if ($transfer -eq 'gamma22') { $plan.Transfer='bt470m' }
        elseif ($transfer -eq 'gamma28') { $plan.Transfer='bt470bg' }
    }
    if ($matrix -in $knownMatrices) { $plan.Matrix=$matrix }
    if ($range -in @('tv','pc')) { $plan.Range='tv'; $plan.ConvertFullRange=$range -eq 'pc' }
    elseif ($pixels -and $pixels -match '^yuvj') { $plan.Range='tv'; $plan.ConvertFullRange=$true }
    if ($null -eq $plan.Primaries -or $null -eq $plan.Transfer -or $null -eq $plan.Matrix -or $null -eq $plan.Range) {
        $plan.State='Ambiguous'
        $plan.Warnings += 'Colour metadata is ambiguous or incomplete; HDR absence cannot be established. Encoding uses the SDR compatibility path without assigning missing Rec709 tags; colour fidelity is unverified.'
    }
    if ($primaries -eq 'bt2020' -or $matrix -eq 'bt2020nc') {
        $plan.Warnings += 'Source uses wide gamut colour; retained tags do not convert it to Rec709 or establish universal player compatibility.'
    }
    if ($plan.ConvertFullRange) { $plan.Warnings += 'Full-range SDR samples are rescaled to limited range for 8-bit yuv420p compatibility; this is not HDR tone mapping.' }
    if ($pixels -and $pixels -ne 'yuv420p') { $plan.Warnings += 'SDR compatibility output is 8-bit 4:2:0; source bit depth/chroma are not preserved.' }
    $plan.Arguments=@('-pix_fmt:v:0','yuv420p')
    foreach ($pair in @(@('-color_primaries:v:0',$plan.Primaries),@('-color_trc:v:0',$plan.Transfer),
        @('-colorspace:v:0',$plan.Matrix),@('-color_range:v:0',$plan.Range))) {
        if ($null -ne $pair[1]) { $plan.Arguments += $pair }
    }
    return $plan
}

function Assert-VideoColourSupported($Colour) {
    if (-not $Colour.Supported) {
        $failure=New-Object InvalidOperationException($Colour.Reason)
        $failure.Data['WvcStage']='Colour'
        throw $failure
    }
}

function Test-OutputColour($Video, $SourceVideo) {
    $sourceColour=Get-VideoColourPlan $SourceVideo
    Assert-VideoColourSupported $sourceColour
    $outputColour=Get-VideoColourPlan $Video
    Assert-VideoColourSupported $outputColour
    if ($Video.PixelFormat -ne 'yuv420p') { throw 'Output pixel format must be the intended 8-bit yuv420p SDR compatibility format.' }
    foreach ($pair in @(@('ColourPrimaries',$sourceColour.Primaries),@('ColourTransfer',$sourceColour.Transfer),
        @('ColourMatrix',$sourceColour.Matrix),@('ColourRange',$sourceColour.Range))) {
        # H.264 may omit a limited-range VUI when all other colour fields are unknown.
        if ($pair[0] -eq 'ColourRange' -and $null -eq $Video.ColourRange -and $sourceColour.Range -eq 'tv' -and
            $null -eq $sourceColour.Primaries -and $null -eq $sourceColour.Transfer -and $null -eq $sourceColour.Matrix -and
            $null -eq $outputColour.Primaries -and $null -eq $outputColour.Transfer -and $null -eq $outputColour.Matrix) {
            $sourceColour.Warnings += 'Output range signalling is unavailable; conventional yuv420p decoding uses limited range, but this tag could not be confirmed.'
            continue
        }
        if ($null -ne $pair[1] -and (Get-ProbeProperty $Video $pair[0]) -ne $pair[1]) { throw ('Output did not retain the planned SDR ' + $pair[0] + '.') }
    }
    if ($outputColour.ConvertFullRange) { throw 'Output colour range must not be full range for this compatibility path.' }
    return $sourceColour.Warnings
}

function Get-StreamPlan($Inspection) {
    if (-not $Inspection.Succeeded -or $null -eq $Inspection.PrimaryVideo -or
        $null -eq $Inspection.PrimaryVideoIndex) { throw 'A stream plan requires a successful real-video inspection.' }
    # The normalizer already selected the first real video. Carry that same object.
    $video = $Inspection.PrimaryVideo
    $audioStreams = @($Inspection.Streams | Where-Object { $_.CodecType -eq 'audio' } | Sort-Object Index)
    $defaults = @($audioStreams | Where-Object { $_.Disposition.Default })
    $audio = $null; $audioSelection = 'None'
    if ($defaults.Count -eq 1) { $audio = $defaults[0]; $audioSelection = 'UniqueDefault' }
    elseif ($audioStreams.Count) { $audio = $audioStreams[0]; $audioSelection = 'FirstByIndex' }
    $audioIndex = $(if ($null -ne $audio) { $audio.Index } else { $null })
    $maps = @('-map',('0:' + $Inspection.PrimaryVideoIndex))
    if ($null -ne $audio) { $maps += @('-map',('0:' + $audioIndex)) }
    $omitted = @($Inspection.Streams | Where-Object {
        $_.Index -ne $Inspection.PrimaryVideoIndex -and ($null -eq $audioIndex -or $_.Index -ne $audioIndex)
    } | Sort-Object Index | ForEach-Object {
        $reason = if ($_.Disposition.AttachedPicture) { 'AttachedPicture' }
            elseif ($_.CodecType -eq 'video') { 'AlternateVideo' }
            elseif ($_.CodecType -eq 'audio') { 'AlternateAudio' } else { 'UnsupportedType' }
        [pscustomobject]@{ Index = $_.Index; CodecType = $_.CodecType; CodecName = $_.CodecName; Reason = $reason }
    })
    $reasons = @{ AttachedPicture = 'attached artwork'; AlternateVideo = 'alternate video';
        AlternateAudio = 'alternate audio'; UnsupportedType = 'not included in this output' }
    $colour = Get-VideoColourPlan $video
    Assert-VideoColourSupported $colour
    $geometry = Get-VideoGeometryPlan $video
    return [pscustomobject]@{ SchemaVersion = 1; Colour = $colour; Video = $video; VideoIndex = $Inspection.PrimaryVideoIndex; Geometry = $geometry;
        VideoSelection = 'FirstRealByIndex'; Audio = $audio; AudioIndex = $audioIndex;
        AudioSelection = $audioSelection; MapArguments = $maps; OmittedStreams = $omitted;
        Warnings = @($omitted | ForEach-Object { "Omitting stream $($_.Index) ($($_.CodecType)): $($reasons[$_.Reason])." }) }
}

function Write-StreamPlan($Plan) {
    Write-Host ("Video stream: {0} ({1}, {2}x{3}; first real video by index)." -f
        $Plan.VideoIndex,$Plan.Video.CodecName,$Plan.Video.Width,$Plan.Video.Height)
    $geometry = Get-VideoGeometryPlan $Plan.Video
    Write-Host ("Output geometry: {0}x{1}; height cap 1080, no crop/upscale, default autorotation." -f $geometry.TargetWidth,$geometry.TargetHeight)
    foreach ($warning in $geometry.Warnings) { Write-Host $warning -ForegroundColor Yellow }
    $colour = Get-VideoColourPlan $Plan.Video
    Assert-VideoColourSupported $colour
    Write-Host ('Colour output: 8-bit yuv420p SDR compatibility; no HDR tone mapping/preservation.')
    foreach ($warning in $colour.Warnings) { Write-Host $warning -ForegroundColor Yellow }
    if ($null -eq $Plan.Audio) {
        Write-Host 'Audio stream: none (silent input).'
    } else {
        $audio = $Plan.Audio
        $channels = $(if ($null -ne $audio.Channels) { [string]$audio.Channels } else { 'unknown' })
        $layout = $(if ($audio.ChannelLayout) { $audio.ChannelLayout } else { 'unknown' })
        $rate = $(if ($null -ne $audio.SampleRate) { [string]$audio.SampleRate } else { 'unknown' })
        $language = $(if ($audio.Language) { $audio.Language } else { 'unknown' })
        $flags = @($audio.Disposition.Flags.Keys | Sort-Object | Where-Object { $audio.Disposition.Flags[$_] -eq 1 }) -join ','
        if (-not $flags) { $flags = 'none' }
        $selection = $(if ($Plan.AudioSelection -eq 'UniqueDefault') { 'unique default audio' } else { 'first audio by index' })
        Write-Host ("Audio stream: {0} ({1} channels; layout {2}; sample rate {3}; language {4}; {5}; dispositions {6})." -f
            $Plan.AudioIndex,$channels,$layout,$rate,$language,$selection,$flags)
    }
    foreach ($warning in $Plan.Warnings) { Write-Host $warning -ForegroundColor Yellow }
}

function Next-CompressedPath([string]$targetPath) {
    # Creates: "name (compressed).mp4", then "name (compressed 2).mp4", etc.
    $dir  = Split-Path -Parent $targetPath
    $base = [IO.Path]::GetFileNameWithoutExtension($targetPath)
    $ext  = [IO.Path]::GetExtension($targetPath)

    $candidate = Join-Path $dir ("{0} (compressed){1}" -f $base,$ext)
    if (-not (Test-Path -LiteralPath $candidate)) { return $candidate }

    $i = 2
    while ($true) {
        $candidate = Join-Path $dir ("{0} (compressed {1}){2}" -f $base,$i,$ext)
        if (-not (Test-Path -LiteralPath $candidate)) { return $candidate }
        $i++
    }
}

function Get-InputReparsePoint([string]$p) {
    # Inspect ancestors too: a normal child beneath a junction still crosses it.
    $item = Get-Item -LiteralPath $p -Force -ErrorAction Stop
    while ($null -ne $item) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { return $item.FullName }
        $parent = if ($item -is [IO.FileInfo]) { $item.Directory } else { $item.Parent }
        if ($null -eq $parent) { break }
        $item = Get-Item -LiteralPath $parent.FullName -Force -ErrorAction Stop
    }
    return $null
}

function Get-ReservedOutputJobDirectory($Item) {
    $directory = if ($Item -is [IO.FileInfo]) { $Item.Directory } else { $Item }
    while ($null -ne $directory) {
        if ($directory.Name -match '^\.wvc-job-[0-9a-f]{32}$') { return $directory.FullName }
        $directory = $directory.Parent
    }
    return $null
}

function Get-OutputJobWarnings([string]$OutputDirectory) {
    try {
        foreach ($directory in @(Get-ChildItem -LiteralPath $OutputDirectory -Directory -Force -ErrorAction Stop)) {
            if ($directory.Name -match '^\.wvc-job-[0-9a-f]{32}$') {
                "Reserved WinVidCompress job directory present (active or unverified leftovers; not recovered or deleted): $($directory.FullName)"
            }
        }
    } catch [Management.Automation.PipelineStoppedException] { throw }
    catch { "Could not inspect reserved output-job directories: $($_.Exception.Message)" }
}

function Get-InputScan([string]$p) {
    $files = New-Object 'Collections.Generic.List[string]'
    $errors = New-Object 'Collections.Generic.List[object]'
    $warnings = New-Object 'Collections.Generic.List[string]'
    $normalized = $null
    $pending = New-Object 'Collections.Generic.Stack[string]'
    $visited = New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    try {
        if ([string]::IsNullOrWhiteSpace($p)) { throw 'Input path is blank.' }
        $resolved = Resolve-Path -LiteralPath $p -ErrorAction Stop
        if ($resolved.Provider.Name -ne 'FileSystem') { throw 'Only filesystem inputs are supported.' }
        $root = Get-Item -LiteralPath $resolved.ProviderPath -Force -ErrorAction Stop
        if ($root -isnot [IO.FileInfo] -and $root -isnot [IO.DirectoryInfo]) {
            throw 'Input is not a filesystem file or directory.'
        }
        $normalized = $root.FullName
        $pending.Push($normalized)
    } catch {
        $errors.Add([pscustomobject]@{ Path = $p; Kind = 'InvalidInput'; Message = $_.Exception.Message })
    }

    while ($pending.Count) {
        $current = $pending.Pop()
        try {
            $reparse = Get-InputReparsePoint $current
            if ($reparse) {
                $errors.Add([pscustomobject]@{ Path = $current; Kind = 'ReparsePointSkipped';
                    Message = "Reparse points are not scanned: $reparse" })
                continue
            }
            $item = Get-Item -LiteralPath $current -Force -ErrorAction Stop
            $reservedJob = Get-ReservedOutputJobDirectory $item
            if ($reservedJob) {
                $warnings.Add("Reserved WinVidCompress job directory excluded (active or unverified leftovers): $reservedJob")
                continue
            }
        } catch {
            $errors.Add([pscustomobject]@{ Path = $current; Kind = 'InputReadFailed'; Message = $_.Exception.Message })
            continue
        }
        if ($item -is [IO.DirectoryInfo]) {
            if (-not $visited.Add($item.FullName)) {
                $errors.Add([pscustomobject]@{ Path = $current; Kind = 'RepeatedDirectory';
                    Message = 'Directory was already scanned; repeated traversal refused.' })
                continue
            }
            $enumerationErrors = @()
            try {
                # Capture nonterminating provider errors while retaining readable siblings.
                # No -Recurse: every child is checked before any descent or read-open.
                $children = @(Get-ChildItem -LiteralPath $current -ErrorAction SilentlyContinue -ErrorVariable enumerationErrors)
            } catch {
                $errors.Add([pscustomobject]@{ Path = $current; Kind = 'DirectoryReadFailed'; Message = $_.Exception.Message })
                continue
            }
            foreach ($failure in $enumerationErrors) {
                $failedPath = if ($failure.TargetObject -is [string] -and $failure.TargetObject) {
                    $failure.TargetObject
                } else { $current }
                $errors.Add([pscustomobject]@{ Path = $failedPath; Kind = 'DirectoryReadFailed'; Message = $failure.Exception.Message })
            }
            foreach ($child in $children) {
                if ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) {
                    $errors.Add([pscustomobject]@{ Path = $child.FullName; Kind = 'ReparsePointSkipped';
                        Message = 'Reparse points are not scanned.' })
                } elseif ($child -is [IO.DirectoryInfo] -or
                    ($child -is [IO.FileInfo] -and $VideoExts -contains $child.Extension)) {
                    $pending.Push($child.FullName)
                }
            }
        } elseif ($item -is [IO.FileInfo]) {
            if ($VideoExts -notcontains $item.Extension) {
                $errors.Add([pscustomobject]@{ Path = $current; Kind = 'UnsupportedExtension';
                    Message = "Unsupported input extension: $($item.Extension)" })
                continue
            }
            try {
                # Access preflight only, not media validation. Never read or modify bytes.
                $stream = [IO.File]::Open($item.FullName, [IO.FileMode]::Open, [IO.FileAccess]::Read,
                    ([IO.FileShare]::ReadWrite -bor [IO.FileShare]::Delete))
                $stream.Dispose()
                $files.Add($item.FullName)
            } catch {
                $errors.Add([pscustomobject]@{ Path = $current; Kind = 'FileReadFailed'; Message = $_.Exception.Message })
            }
        }
    }
    return [pscustomobject]@{ InputPath = $p; NormalizedPath = $normalized;
        Files = $files.ToArray(); Errors = $errors.ToArray(); Warnings = $warnings.ToArray(); Succeeded = ($errors.Count -eq 0) }
}

function Collect-InputFiles([string]$p) {
    # Compatibility file stream. Callers needing diagnostics use Get-InputScan.
    return (Get-InputScan $p).Files
}

function Get-QueuePathKey([string]$fullPath) {
    # Provider normalization also supports long paths on Windows PowerShell 5.1.
    $key = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($fullPath)
    # Ordinary extended drive/UNC spellings are aliases, not different sources.
    # Keep special extended literals (e.g. trailing dots/spaces) distinct.
    $ordinary = $null
    if ($key.StartsWith('\\?\UNC\', [StringComparison]::OrdinalIgnoreCase)) {
        $ordinary = '\\' + $key.Substring(8)
    } elseif ($key -match '^\\\\\?\\[A-Za-z]:\\') {
        $ordinary = $key.Substring(4)
    }
    if ($ordinary -and $ordinary -notmatch '[. ](?:\\|$)' -and $ordinary -notmatch '/') {
        $key = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ordinary)
    }
    return $key
}

function Get-InputQueue([string[]]$paths) {
    $scans = New-Object 'Collections.Generic.List[object]'
    $sources = New-Object 'Collections.Generic.Dictionary[string,string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach ($p in $paths) {
        $scan = Get-InputScan $p
        $scans.Add($scan)
        foreach ($file in $scan.Files) {
            $key = Get-QueuePathKey $file
            if (-not $sources.ContainsKey($key)) {
                $sources.Add($key, $file)
            } elseif ([StringComparer]::Ordinal.Compare($file, $sources[$key]) -lt 0) {
                # Stable spelling even when aliases arrive in a different order.
                $sources[$key] = $file
            }
        }
    }
    $keys = [string[]]@($sources.Keys)
    [array]::Sort($keys, [StringComparer]::OrdinalIgnoreCase)
    $files = @($keys | ForEach-Object { $sources[$_] })
    # Reserved GUID job directories are excluded by the scanner. Never infer ownership from
    # OutputDir, extension or a compressed/partial suffix; keep ambiguous files.
    return [pscustomobject]@{ Files = $files; Scans = $scans.ToArray() }
}

function Get-EncodeArguments([string]$InputPath, [string]$OutputPath, $StreamPlan, [int]$CRF, $Metadata) {
    # Pure token construction: paths and metadata never become shell expressions.
    $tokens = @('-hide_banner','-nostdin','-stats','-n','-i',$InputPath)
    $tokens += $StreamPlan.MapArguments
    $geometry = Get-VideoGeometryPlan $StreamPlan.Video
    $colour = Get-VideoColourPlan $StreamPlan.Video
    Assert-VideoColourSupported $colour
    $filter = $geometry.Filter
    if ($colour.ConvertFullRange) {
        if ($null -eq $filter) { $filter='scale=iw:ih' }
        $filter += ':in_range=pc:out_range=tv'
    }
    if ($null -ne $filter) { $tokens += @('-vf',$filter) }
    $tokens += @('-c:v','libx264','-preset','veryfast','-crf',"$CRF")
    $tokens += $colour.Arguments
    if ($null -ne $StreamPlan.Audio) { $tokens += @('-c:a','aac','-b:a','160k') }
    $tokens += @('-movflags','+faststart')
    if ($null -ne $Metadata) {
        if ($Metadata.Title) { $tokens += @('-metadata',"title=$($Metadata.Title)") }
        if ($Metadata.Band) { $tokens += @('-metadata',"artist=$($Metadata.Band)") }
        if ($Metadata.DateISO) { $tokens += @('-metadata',"date=$($Metadata.DateISO)") }
        if ($Metadata.DateHuman -and $Metadata.Band) {
            $tokens += @('-metadata',"comment=Interview date $($Metadata.DateHuman); Band: $($Metadata.Band)")
        }
    }
    $tokens += $OutputPath
    return $tokens
}

function Invoke-EncodeProcess([string]$Executable, [string[]]$Arguments,
    [ValidateRange(100,30000)][int]$DrainTimeoutMilliseconds = 10000,
    [ValidateRange(4096,1048576)][int]$CaptureLimitCharacters = 1048576) {
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $Executable
    # ArgumentList is unavailable on .NET Framework. Use the tested Windows CRT quoting.
    $start.Arguments = (@($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' ')
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.StandardOutputEncoding = New-Object Text.UTF8Encoding($false)
    $start.StandardErrorEncoding = New-Object Text.UTF8Encoding($false)
    $start.EnvironmentVariables.Remove('FFREPORT')
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $start
    $started = $false
    $exitCode = $null
    $failureKind = $null
    $errorText = $null
    $streams = @()
    $readers = @()
    $inputWriter = $null
    $clock = [Diagnostics.Stopwatch]::StartNew()
    $exitClock = $null
    try {
        [void]$process.Start()
        $started = $true
        $inputWriter = $process.StandardInput
        $readers = @($process.StandardOutput,$process.StandardError)
        foreach ($reader in $readers) {
            $buffer = New-Object char[] 4096
            $streams += @{ Reader=$reader; Buffer=$buffer; Text=(New-Object Text.StringBuilder);
                Task=$reader.ReadAsync($buffer,0,$buffer.Length); Closed=$false; Characters=[long]0; Truncated=$false }
        }
        $inputWriter.Close()
        # Tasks do IO only. Console output and all PowerShell run on this runspace.
        while ($true) {
            foreach ($stream in $streams) {
                if (-not $stream.Closed -and $stream.Task.IsCompleted) {
                    $count = $stream.Task.GetAwaiter().GetResult()
                    if ($count -eq 0) { $stream.Closed = $true; continue }
                    $chunk = [string]::new($stream.Buffer,0,$count)
                    $stream.Characters += $count
                    [void]$stream.Text.Append($chunk)
                    if ($stream.Text.Length -gt $CaptureLimitCharacters) {
                        [void]$stream.Text.Remove(0,$stream.Text.Length-$CaptureLimitCharacters)
                        $stream.Truncated = $true
                    }
                    Write-Host $chunk -NoNewline
                    $stream.Task = $stream.Reader.ReadAsync($stream.Buffer,0,$stream.Buffer.Length)
                }
            }
            if ($process.HasExited) {
                if ($null -eq $exitClock) {
                    $exitCode = $process.ExitCode
                    $exitClock = [Diagnostics.Stopwatch]::StartNew()
                }
                if ($streams[0].Closed -and $streams[1].Closed) { break }
                if ($exitClock.ElapsedMilliseconds -ge $DrainTimeoutMilliseconds) {
                    $failureKind = 'PipeDrainTimeout'
                    $errorText = "Timed out draining encoder pipes after $DrainTimeoutMilliseconds ms."
                    break
                }
                Start-Sleep -Milliseconds 10
            } else {
                # No total encoding deadline; short waits allow pipeline interruption.
                [void]$process.WaitForExit(10)
            }
        }
        if ($null -eq $failureKind -and $exitCode -ne 0) {
            $failureKind = 'NonZeroExit'
            $errorText = "FFmpeg exit code: $exitCode"
        }
    } catch [Management.Automation.PipelineStoppedException] {
        throw
    } catch {
        $failureKind = if ($started) { 'ProcessFailed' } else { 'StartFailed' }
        $errorText = $_.Exception.Message
        if ($started -and $process.HasExited) { $exitCode = $process.ExitCode }
    } finally {
        try {
            if ($started -and -not $process.HasExited) {
                try {
                    $process.Kill()
                    if (-not $process.WaitForExit(2000)) { throw 'Owned encoder did not exit after termination.' }
                } catch {
                    # Exit can race Kill(). Only failure to stop a live child is fatal.
                    if (-not $process.HasExited) {
                        $abort = New-Object InvalidOperationException ('Could not stop the owned encoder: ' + $_.Exception.Message)
                        $abort.Data['WvcAbortBatch'] = $true
                        throw $abort
                    }
                }
            }
        } finally {
            try {
                # .NET Framework Process.Dispose does not close these readers.
                foreach ($resource in (@($inputWriter) + $readers)) {
                    if ($null -ne $resource) {
                        try { $resource.Dispose() } catch {
                            # Continue closing the other pipe; preserve any earlier failure.
                            if ($null -eq $failureKind) {
                                $failureKind = 'ResourceCleanupFailed'
                                $errorText = $_.Exception.Message
                            }
                        }
                    }
                }
            } finally {
                $process.Dispose()
                $clock.Stop()
                foreach ($stream in $streams) {
                    # Closing an inherited pipe can fault its pending read. Observe
                    # that task without an unbounded wait or replacing the failure.
                    try {
                        if ($stream.Task.Wait(100)) { [void]$stream.Task.GetAwaiter().GetResult() }
                    } catch { } # Disposal-related read faults are expected here.
                }
            }
        }
    }
    $outputText = ''; $diagnosticText = ''
    $outputCount = [long]0; $diagnosticCount = [long]0
    $outputTruncated = $false; $diagnosticTruncated = $false
    if ($streams.Count -eq 2) {
        $outputText = $streams[0].Text.ToString(); $diagnosticText = $streams[1].Text.ToString()
        $outputCount = $streams[0].Characters; $diagnosticCount = $streams[1].Characters
        $outputTruncated = $streams[0].Truncated; $diagnosticTruncated = $streams[1].Truncated
    }
    return [pscustomobject]@{ SchemaVersion=1; Started=$started;
        Succeeded=($started -and $null -eq $failureKind -and $exitCode -eq 0); ExitCode=$exitCode;
        FailureKind=$failureKind; Error=$errorText; StdOut=$outputText; StdErr=$diagnosticText;
        StdOutCharacters=$outputCount; StdErrCharacters=$diagnosticCount;
        StdOutTruncated=$outputTruncated; StdErrTruncated=$diagnosticTruncated;
        ElapsedSeconds=$clock.Elapsed.TotalSeconds }
}

function New-OutputJob([string]$SourcePath, [string]$OutputDirectory, [string]$NominalPath,
    [string]$CandidatePath, [ValidatePattern('^[0-9a-f]{32}$')][string]$JobId = ([guid]::NewGuid().ToString('N'))) {
    $root = [IO.Path]::GetFullPath((Get-Item -LiteralPath $OutputDirectory -Force -ErrorAction Stop).FullName)
    if ($root.Length -gt [IO.Path]::GetPathRoot($root).Length) { $root = $root.TrimEnd('\','/') }
    $directory = Join-Path $root ('.wvc-job-' + $JobId)
    if (Test-Path -LiteralPath $directory) { throw 'Reserved job directory already exists; refusing adoption.' }
    if (Get-InputReparsePoint $root) { throw 'Output job paths cannot cross reparse points.' }
    [void][IO.Directory]::CreateDirectory($directory)
    $reservation = $null
    try {
        if ((Get-Item -LiteralPath $directory -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw 'Reserved job directory became a reparse point.'
        }
        if (@(Get-ChildItem -LiteralPath $directory -Force -ErrorAction Stop).Count) {
            throw 'Reserved job directory is not empty; refusing adoption.'
        }
        $reservationPath = Join-Path $directory 'active.owner'
        # The independent reservation is exclusive. DeleteOnClose removes that
        # opened file by handle, not a possibly substituted media pathname.
        $reservation = New-Object IO.FileStream $reservationPath,([IO.FileMode]::CreateNew),
            ([IO.FileAccess]::ReadWrite),([IO.FileShare]::None),4096,([IO.FileOptions]::DeleteOnClose)
        $job = [pscustomobject]@{ SchemaVersion=1; JobId=$JobId; Root=$root; SourcePath=$SourcePath;
            NominalPath=[IO.Path]::GetFullPath($NominalPath); CandidatePath=[IO.Path]::GetFullPath($CandidatePath);
            JobDirectory=$directory; TempPath=(Join-Path $directory 'encode.partial.mp4');
            ReservationPath=$reservationPath; Reservation=$reservation }
        $record = [pscustomobject]@{SchemaVersion=1;JobId=$JobId;SourcePath=$SourcePath;
            NominalPath=$job.NominalPath;TemporaryPath=$job.TempPath;State='Reserved'}
        $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes(($record | ConvertTo-Json -Compress))
        $reservation.Write($bytes,0,$bytes.Length)
        $reservation.Flush()
        [void](Assert-OutputJob $job -BeforeEncode)
        return $job
    } catch [Management.Automation.PipelineStoppedException] {
        if ($null -ne $reservation) { try { $reservation.Dispose() } catch { } }
        throw
    } catch {
        if ($null -ne $reservation) { try { $reservation.Dispose() } catch { } }
        # Never recursively remove or adopt an uncertain allocation.
        throw "Output allocation refused; unverified directory retained: $directory. $($_.Exception.Message)"
    }
}

function Assert-OutputJob($Job, [switch]$BeforeEncode, [switch]$ForPublication) {
    if ($Job.SchemaVersion -ne 1 -or $Job.JobId -cnotmatch '^[0-9a-f]{32}$' -or
        $null -eq $Job.Reservation -or -not $Job.Reservation.CanWrite) { throw 'Invalid or closed output-job ownership.' }
    $root = [IO.Path]::GetFullPath($Job.Root)
    $expectedDirectory = Join-Path $root ('.wvc-job-' + $Job.JobId)
    $expectedTemp = Join-Path $expectedDirectory 'encode.partial.mp4'
    $expectedReservation = Join-Path $expectedDirectory 'active.owner'
    foreach ($pair in @(@($Job.JobDirectory,$expectedDirectory),@($Job.TempPath,$expectedTemp),
        @($Job.ReservationPath,$expectedReservation),@($Job.Reservation.Name,$expectedReservation))) {
        if (-not [StringComparer]::OrdinalIgnoreCase.Equals([IO.Path]::GetFullPath($pair[0]),$pair[1])) {
            throw 'Output-job path/provenance mismatch; no path mutation allowed.'
        }
    }
    foreach ($final in @($Job.NominalPath,$Job.CandidatePath)) {
        if (-not [StringComparer]::OrdinalIgnoreCase.Equals([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($final)),$root)) {
            throw 'Final output escaped its destination directory.'
        }
    }
    if (Get-InputReparsePoint $expectedDirectory) { throw 'Output job crossed a reparse point.' }
    if ($BeforeEncode -or $ForPublication) {
        $unexpected = @(Get-ChildItem -LiteralPath $expectedDirectory -Force -ErrorAction Stop |
            Where-Object { $_.Name -notin @('active.owner','encode.partial.mp4') })
        if ($unexpected.Count) { throw 'Unexpected job artifacts; temporary authorship is unverified.' }
    }
    if (Test-Path -LiteralPath $expectedTemp) {
        $item = Get-Item -LiteralPath $expectedTemp -Force -ErrorAction Stop
        if ($BeforeEncode) { throw 'Temporary path already exists; refusing overwrite or ownership claim.' }
        if ($item -isnot [IO.FileInfo] -or ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
            throw 'Temporary output is not a regular non-reparse file.'
        }
    }
}

function Move-OutputFileNoClobber([string]$Source, [string]$Destination) {
    # Two-argument File.Move refuses any existing destination on both runtimes.
    [IO.File]::Move($Source,$Destination)
}

function Publish-OutputJob($Job, [ValidateSet('rename','skip')][string]$Policy) {
    [void](Assert-OutputJob $Job -ForPublication)
    if (-not (Test-Path -LiteralPath $Job.TempPath -PathType Leaf)) { throw 'Encoder produced no temporary output.' }
    $candidate = $Job.CandidatePath
    for ($attempt=0; $attempt -lt 64; $attempt++) {
        if (-not [StringComparer]::OrdinalIgnoreCase.Equals([IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($candidate)),$Job.Root)) {
            throw 'Promotion candidate escaped the output directory.'
        }
        if ([StringComparer]::OrdinalIgnoreCase.Equals((Get-QueuePathKey $candidate),(Get-QueuePathKey $Job.SourcePath))) {
            throw 'Promotion candidate must differ from the source.'
        }
        try {
            [void](Assert-OutputJob $Job -ForPublication)
            Move-OutputFileNoClobber $Job.TempPath $candidate
            return [pscustomobject]@{Published=$true;Skipped=$false;FinalPath=$candidate;Reason=$null}
        } catch {
            $nativeError = $_.Exception.GetBaseException()
            $code = $nativeError.HResult -band 65535
            # Do not turn permission/sharing/disk/source errors into rename loops.
            if ($nativeError -isnot [IO.IOException] -or $code -notin @(80,183) -or
                -not (Test-Path -LiteralPath $candidate)) { throw }
            if ($Policy -eq 'skip') {
                return [pscustomobject]@{Published=$false;Skipped=$true;FinalPath=$candidate;Reason='Final appeared during encoding.'}
            }
            $candidate = Next-CompressedPath $Job.NominalPath
        }
    }
    throw 'Final-name collision retry limit reached; partial retained.'
}

function Close-OutputJob($Job, [bool]$Published, [string]$Stage, [string]$Reason, [switch]$EncoderMayStillRun) {
    $warning = $null
    try {
        [void](Assert-OutputJob $Job)
        if ($EncoderMayStillRun -or @(Get-ChildItem -LiteralPath $Job.JobDirectory -Force -ErrorAction Stop |
            Where-Object { $_.Name -ne 'active.owner' }).Count) {
            # Media is never deleted by path. Failed, replaced or still-written
            # partials are retained; a reservation alone cannot prove authorship.
            $recordPath = Join-Path $Job.JobDirectory 'retained.json'
            $record = [pscustomobject]@{SchemaVersion=1;JobId=$Job.JobId;SourcePath=$Job.SourcePath;
                TemporaryPath=$Job.TempPath;NominalPath=$Job.NominalPath;Stage=$Stage;Reason=$Reason;
                State='RetainedUnverified';Published=$Published;EncoderMayStillRun=[bool]$EncoderMayStillRun}
            $file = [IO.File]::Open($recordPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
            try {
                $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes(($record | ConvertTo-Json -Depth 4))
                $file.Write($bytes,0,$bytes.Length)
            } finally { $file.Dispose() }
            $warning = "Retained unverified partial/job artifacts: $($Job.TempPath) (job $($Job.JobId))."
        }
    } catch {
        $warning = "Retained job artifacts at $($Job.JobDirectory); cleanup/record refused for job $($Job.JobId): $($_.Exception.Message)"
    } finally {
        # Release only our open reservation. Preserve existing cancellation/fatal exceptions.
        try { $Job.Reservation.Dispose() } catch { $warning = 'Output-job reservation cleanup failed: ' + $_.Exception.Message }
    }
    if ($null -eq $warning) {
        try {
            if (Get-InputReparsePoint $Job.JobDirectory) { throw 'Job directory became a reparse point.' }
            [IO.Directory]::Delete($Job.JobDirectory,$false) # Empty only; never recursive.
        } catch { $warning = "Retained job directory: $($Job.JobDirectory). $($_.Exception.Message)" }
    }
    return [pscustomobject]@{Warning=$warning}
}

function Get-OutputDurationTolerance($Plan) {
    $frames = 0.0; $audioPadding = 0.0
    if ($null -ne $Plan.Video.AverageFrameRate) { $frames = 2.0 / $Plan.Video.AverageFrameRate.Value }
    if ($null -ne $Plan.Audio -and $null -ne $Plan.Audio.SampleRate) { $audioPadding = 2048.0 / $Plan.Audio.SampleRate }
    return [Math]::Min(2.0,[Math]::Max(0.25,$frames + $audioPadding))
}

function Test-OutputStructure($Output, $Source, $Plan) {
    if (-not $Output.Succeeded) { throw "Output probe failed [$($Output.FailureKind)]: $($Output.Reason)" }
    if ('mp4' -notin @($Output.FormatName -split ',')) { throw 'Output probe did not identify the MP4 container family.' }
    $videos = @($Output.Streams | Where-Object CodecType -eq 'video')
    $audios = @($Output.Streams | Where-Object CodecType -eq 'audio')
    $audioCount = [int]($null -ne $Plan.Audio)
    if ($videos.Count -ne 1 -or $audios.Count -ne $audioCount -or
        $videos[0].Disposition.AttachedPicture -or $videos[0].CodecName -ne 'h264') {
        throw 'Output needs exactly one real H.264 video and only the selected AAC audio, without extra streams.'
    }
    $video = $videos[0]
    $warnings = New-Object 'Collections.Generic.List[string]'
    foreach ($warning in @(Test-OutputColour $video $Plan.Video)) { $warnings.Add($warning) }
    $extra = @($Output.Streams | Where-Object { $_.CodecType -notin @('video','audio') })
    if ($extra.Count) {
        $timecode = if ($null -ne $Source.FormatTimecode) { $Source.FormatTimecode } else { $Plan.Video.Timecode }
        if ($extra.Count -ne 1 -or $extra[0].CodecType -ne 'data' -or $extra[0].CodecTag -ne 'tmcd' -or
            $null -eq $timecode -or $video.Timecode -ne $timecode -or $extra[0].Timecode -ne $timecode) {
            throw 'Unexpected output streams; only a generated tmcd track matching retained video timecode is allowed.'
        }
        $warnings.Add('MP4 includes a generated timecode track matching retained source metadata; it is excluded from decode checks.')
    }
    if ($video.FrameCount -eq 0) { throw 'Output video explicitly reports zero frames.' }
    if ($null -eq $video.FrameCount) { $warnings.Add('Output frame count is unavailable; structural validation does not establish decoded frame integrity.') }
    $geometry = Get-VideoGeometryPlan $Plan.Video
    if ($video.Width -ne $geometry.TargetWidth -or $video.Height -ne $geometry.TargetHeight) { throw 'Output dimensions do not match the exact even, oriented height-cap plan.' }
    $outputGeometry = Get-VideoGeometryPlan $video
    if ($outputGeometry.RotationDegrees -ne 0 -or -not $outputGeometry.MatrixIsIdentity) { throw 'Output retains a display transform after autorotation.' }
    $outputSar = ConvertTo-ProbeRatio $video.SampleAspectRatio ':'
    if ($null -ne $geometry.ExpectedDisplayAspectRatio -and $null -ne $outputSar) {
        $outputDar = $video.Width/[double]$video.Height*$outputSar.Value
        if ([Math]::Abs($outputDar/$geometry.ExpectedDisplayAspectRatio-1) -gt $geometry.AspectRelativeTolerance) { throw 'Output display aspect differs from the oriented source by more than 0.1 percent.' }
    } else { $warnings.Add('Display aspect comparison is unavailable because source or output SAR is unknown; structural dimensions do not establish visual orientation or integrity.') }
    if ($audioCount) {
        $audio = $audios[0]
        if ($audio.CodecName -ne 'aac' -or $null -eq $audio.Channels -or $null -eq $audio.SampleRate) {
            throw 'Selected output audio needs AAC and positive channels/sample rate.'
        }
        if ($null -ne $Plan.Audio.Channels -and $audio.Channels -ne $Plan.Audio.Channels) { throw 'Output audio channel count changed.' }
    }
    $tolerance = Get-OutputDurationTolerance $Plan
    $checks = New-Object 'Collections.Generic.List[object]'
    $videoDuration = $video.DurationSeconds
    if ($null -eq $videoDuration -and $null -ne $video.DurationRaw -and $video.DurationRaw -notin @('N/A','unknown','unspecified')) {
        throw 'Output video supplied an invalid duration; it cannot use the container fallback.'
    }
    if ($null -eq $videoDuration -and $Output.Streams.Count -eq 1) {
        $videoDuration = $Output.DurationSeconds
        $warnings.Add('Output video duration uses the sole-video container fallback.')
    }
    if ($null -eq $videoDuration) { throw 'Output video duration is unavailable; retained audio cannot stand in for video.' }
    if ($audioCount -and $null -eq $audios[0].DurationSeconds) { throw 'Output audio duration is unavailable.' }
    $videoReference = $Plan.Video.DurationSeconds
    if ($null -eq $videoReference -and $Source.Streams.Count -eq 1) {
        $videoReference = $Source.DurationSeconds
        if ($null -ne $videoReference) { $warnings.Add('Source video duration uses the sole-video container fallback; independent stream duration is unavailable.') }
    }
    $references = @([pscustomobject]@{Name='Video';Expected=$videoReference;Actual=$videoDuration})
    if ($audioCount) { $references += [pscustomobject]@{Name='Audio';Expected=$Plan.Audio.DurationSeconds;Actual=$audios[0].DurationSeconds} }
    if ($Source.Streams.Count -eq (1+$audioCount) -and $Source.DurationSource -eq 'Format' -and $null -ne $Source.DurationSeconds) {
        $known = @($references | Where-Object { $null -ne $_.Expected })
        $longest = ($known | Measure-Object Expected -Maximum).Maximum
        if ($known.Count -ne $references.Count -or [Math]::Abs($Source.DurationSeconds - $longest) -gt $tolerance) {
            $warnings.Add('Source container duration disagrees with selected stream durations; aggregate comparison is unavailable because timestamp/edit offsets may be rebased.')
        } elseif ($Output.DurationSource -ne 'Format') {
            $warnings.Add('Output container duration is unavailable; a stream fallback cannot satisfy the aggregate comparison.')
        } else { $references += [pscustomobject]@{Name='RetainedContainer';Expected=$Source.DurationSeconds;Actual=$Output.DurationSeconds} }
    }
    foreach ($reference in $references) {
        if ($null -eq $reference.Expected) {
            $warnings.Add("Source $($reference.Name.ToLowerInvariant()) duration is unknown; that duration comparison is unavailable.")
            continue
        }
        if ($null -eq $reference.Actual) { throw "Output $($reference.Name) duration is unavailable for its known reference." }
        $shortLimit = 0.1*$reference.Expected
        if ($reference.Actual -ge $reference.Expected) { $shortLimit = [Math]::Max(0.05,$shortLimit) }
        $allowance = [Math]::Min($tolerance,$shortLimit)
        if ($reference.Expected -lt 0.5) { $warnings.Add('Short duration allows up to 50ms of timestamp padding; shortening remains limited to 10 percent and metadata cannot prove frame integrity.') }
        $difference = [Math]::Abs($reference.Actual - $reference.Expected)
        $checks.Add([pscustomobject]@{Stream=$reference.Name;ExpectedSeconds=$reference.Expected;ActualSeconds=$reference.Actual;ToleranceSeconds=$allowance})
        if ($difference -gt ($allowance + 0.000001)) { throw "Output $($reference.Name) duration differs by $difference seconds (tolerance $allowance)." }
    }
    return [pscustomobject]@{DurationChecks=$checks.ToArray();Warnings=$warnings.ToArray()}
}

function Get-OutputValidation([string]$FFprobe, $Job, $Source, $Plan,
    [ValidateRange(100,30000)][int]$TimeoutMilliseconds = 10000) {
    $result = [pscustomobject]@{SchemaVersion=1;Succeeded=$false;JobId=$Job.JobId;SourcePath=$Job.SourcePath;
        TemporaryPath=$Job.TempPath;Stage='Validation';FailureKind='File';Reason=$null;Inspection=$null;DurationChecks=@();Warnings=@()}
    $file = $null
    try {
        [void](Assert-OutputJob $Job -ForPublication)
        # Hold read sharing during structural inspection; no writer/deleter can
        # modify this open file. Close it before the no-clobber publication move.
        $file = [IO.File]::Open($Job.TempPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        if ($file.Length -lt 16) { throw 'Temporary output is empty or too short for an MP4 ftyp header.' }
        $header = New-Object byte[] 16
        if ($file.Read($header,0,16) -ne 16) { throw 'Temporary output header is unreadable.' }
        $boxLength = [long]$header[0]*16777216 + [long]$header[1]*65536 + [long]$header[2]*256 + $header[3]
        $type = [Text.Encoding]::ASCII.GetString($header,4,4)
        $brand = [Text.Encoding]::ASCII.GetString($header,8,4)
        if ($type -cne 'ftyp' -or $boxLength -lt 16 -or $boxLength -gt $file.Length -or $brand -cnotmatch '^(iso[m1-9]|mp4[12]|avc1)$') {
            throw 'Temporary output lacks an expected MP4 ftyp/brand (QuickTime/3GP are not MP4 output).'
        }
        $result.FailureKind = 'Probe'
        $result.Inspection = Get-MediaInspection $FFprobe $Job.TempPath $TimeoutMilliseconds
        if (-not $result.Inspection.Succeeded) { throw "Output probe failed [$($result.Inspection.FailureKind)]: $($result.Inspection.Reason)" }
        $result.FailureKind = 'Structure'
        $structure = Test-OutputStructure $result.Inspection $Source $Plan
        [void](Assert-OutputJob $Job -ForPublication)
        $result.DurationChecks = $structure.DurationChecks; $result.Warnings = $structure.Warnings
        $result.Succeeded = $true; $result.FailureKind = $null
    } catch [Management.Automation.PipelineStoppedException] { throw }
    catch {
        $result.Reason = "Job $($Job.JobId); source $($Job.SourcePath); temporary $($Job.TempPath): $($_.Exception.Message)"
    } finally { if ($null -ne $file) { $file.Dispose() } }
    return $result
}

function Invoke-OutputDecodeCheck([string]$FFmpeg, $Job, $Validation) {
    [void](Assert-OutputJob $Job -ForPublication)
    if (-not $Validation.Succeeded -or $Validation.JobId -ne $Job.JobId -or
        $Validation.TemporaryPath -ne $Job.TempPath -or $Validation.SourcePath -ne $Job.SourcePath) {
        throw 'A full decode check requires successful structural validation for this output job.'
    }
    $arguments = @('-hide_banner','-nostdin','-v','error','-xerror','-abort_on','empty_output_stream','-err_detect','explode','-protocol_whitelist','file','-i',$Job.TempPath)
    foreach ($stream in @($Validation.Inspection.Streams | Where-Object { $_.CodecType -in @('video','audio') })) { $arguments += @('-map',('0:'+ $stream.Index)) }
    $arguments += @('-f','null','NUL')
    $file = [IO.File]::Open($Job.TempPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
    try { $native = Invoke-EncodeProcess $FFmpeg $arguments }
    finally { $file.Dispose() }
    return [pscustomobject]@{SchemaVersion=1;Succeeded=$native.Succeeded;JobId=$Job.JobId;SourcePath=$Job.SourcePath;
        TemporaryPath=$Job.TempPath;Native=$native;Reason=$(if ($native.Succeeded) {$null} else {"Job $($Job.JobId); source $($Job.SourcePath): decode check failed [$($native.FailureKind)]: $($native.Error)"})}
}

function New-JobResult([string]$SourcePath, [int]$CRF) {
    return [pscustomobject]@{ SchemaVersion=1; JobId=([guid]::NewGuid().ToString('N'));
        SourcePath=$SourcePath; OutputPath=$null; CandidatePath=$null; TemporaryPath=$null;
        RetainedPath=$null; Outcome='Unstarted'; Stage='Queued'; Reason='Not started.';
        SelectedStreams=$null; Settings=[pscustomobject]@{VideoCodec='libx264';Preset='veryfast';CRF=$CRF;
            PixelFormat='yuv420p';ColourPolicy='SDRCompatibility';AudioCodec='aac';AudioBitrate='160k';Container='mp4';FastStart=$true;HeightCap=1080;Applied=$false};
        ElapsedSeconds=0.0; InputBytes=$null; OutputBytes=$null; SizeChangeBytes=$null;
        SizeChangePercent=$null; AbortBatch=$false; CancellationRequested=$false; LogPath=$null;
        Diagnostics=[pscustomobject]@{Probe=$null;Encode=$null;Validation=$null;Warnings=@()} }
}

function Get-JobFileLength([string]$FilePath) {
    # Accounting is advisory; failure to read size cannot undo a published final.
    try { return (Get-Item -LiteralPath $FilePath -Force -ErrorAction Stop).Length }
    catch {
        if ($_.Exception -is [System.Management.Automation.PipelineStoppedException] -or
            $_.Exception -is [System.OperationCanceledException]) { throw }
        return $null
    }
}

function Get-BatchResult([object[]]$Jobs, [object[]]$Scans, [switch]$Requested,
    [switch]$StartupFailed, [switch]$Cancelled, [string]$Reason) {
    $records=@($Jobs | Where-Object { $null -ne $_ })
    $scanRecords=@($Scans | Where-Object { $null -ne $_ })
    $scanErrors=@($scanRecords | ForEach-Object { $_.Errors })
    $counts=[pscustomobject]@{Found=$records.Count;Done=0;Skipped=0;Failed=0;Cancelled=0;Unstarted=0;
        Scanned=@($scanRecords | Where-Object Succeeded).Count;ScanErrors=$scanErrors.Count}
    foreach ($job in $records) {
        switch ($job.Outcome) {
            'Completed' { $counts.Done++ }
            'Skipped' { $counts.Skipped++ }
            'Failed' { $counts.Failed++ }
            'Cancelled' { $counts.Cancelled++ }
            'Unstarted' { $counts.Unstarted++ }
            default { throw 'Unknown job outcome; counters cannot reconcile.' }
        }
    }
    $code=0
    if ($Cancelled -or $counts.Cancelled -or @($records | Where-Object CancellationRequested).Count) { $code=3 }
    elseif ($StartupFailed -or ($Requested -and -not $records.Count)) { $code=2 }
    elseif ($counts.Failed -or $counts.ScanErrors -or $counts.Unstarted) { $code=1 }
    return [pscustomobject]@{SchemaVersion=1;ExitCode=$code;Requested=[bool]$Requested;Cancelled=($code -eq 3);
        StartupFailed=[bool]$StartupFailed;Reason=$Reason;Warnings=@();Jobs=$records;Scans=$scanRecords;
        ScanErrors=$scanErrors;Counters=$counts}
}

function Compress-One($ffmpeg, $ffprobe, [string]$inPath, [string]$outDir, [int]$crf, [ref]$counters) {
    # The optional legacy reference is updated from this record only. Batch dispatch
    # consumes returned records and never uses it as an outcome authority.
    $result=New-JobResult $inPath $crf
    $clock=[Diagnostics.Stopwatch]::StartNew()
    $result.Outcome='Failed'
    $outputJob = $null
    $published = $false
    $skipped = $false
    $encoderMayStillRun = $false
    $stage = 'Prepare'
    $reason = 'Interrupted or unfinished job.'
    try {
        if (-not (Test-Path -LiteralPath $inPath -PathType Leaf)) {
            $reason='Source file is missing.'
            Write-Host "Missing: $inPath" -ForegroundColor Red
            return $result
        }

        if (-not (Test-Path -LiteralPath $outDir -PathType Container)) {
            $reason='Output folder is missing.'
            Write-Host "Output folder missing: $outDir" -ForegroundColor Red
            return $result
        }

        $result.InputBytes=Get-JobFileLength $inPath

        $meta = Parse-MetadataFromName ([IO.Path]::GetFileName($inPath))
        $base = [IO.Path]::GetFileNameWithoutExtension($inPath)

        $nominal = Join-Path $outDir ($base + '.mp4')
        $out = $nominal
        $result.CandidatePath=$out

        $sourceKey = Get-QueuePathKey $inPath
        if ([StringComparer]::OrdinalIgnoreCase.Equals($sourceKey, (Get-QueuePathKey $out)) -or
            (Test-Path -LiteralPath $out)) {
            if ($CollisionMode -eq 'skip') {
                $skipped = $true
                $result.Outcome='Skipped'
                $reason='Existing output or source/output collision; skip policy.'
                Write-Host "Skipping (exists): $out" -ForegroundColor DarkYellow
                return $result
            } else {
                $out = Next-CompressedPath $out
            }
        }

        if ([StringComparer]::OrdinalIgnoreCase.Equals($sourceKey, (Get-QueuePathKey $out))) {
            throw 'Output path must differ from the input path.'
        }

        $result.CandidatePath=$out
        $stage='Probe'
        $inspection = Get-MediaInspection $ffprobe $inPath
        $result.Diagnostics.Probe=$inspection
        if ($null -ne $inspection.Native -and $inspection.Native.StdErr) {
            Write-Host ("Probe diagnostics: " + $inspection.Native.StdErr.Trim()) -ForegroundColor Yellow
        }
        if (-not $inspection.Succeeded) {
            throw "Probe failed [$($inspection.FailureKind)] at $($inspection.Stage): $($inspection.Reason)"
        }
        foreach ($warning in $inspection.Warnings) { Write-Host $warning -ForegroundColor Yellow }
        $streamPlan = Get-StreamPlan $inspection
        $result.SelectedStreams=[pscustomobject]@{Video=$streamPlan.Video.Index;
            Audio=$(if ($null -ne $streamPlan.Audio) { $streamPlan.Audio.Index } else { $null })}
        if ($null -eq $streamPlan.Audio) { $result.Settings.AudioCodec=$null; $result.Settings.AudioBitrate=$null }
        $result.Diagnostics.Warnings += $streamPlan.Colour.Warnings
        Write-StreamPlan $streamPlan
        $stage = 'Allocate'
        $outputJob = New-OutputJob $inPath $outDir $nominal $out
        $result.JobId=$outputJob.JobId
        $result.TemporaryPath=$outputJob.TempPath
        [void](Assert-OutputJob $outputJob -BeforeEncode)
        $encodeArguments = @(Get-EncodeArguments $inPath $outputJob.TempPath $streamPlan $crf $meta)

        Write-Host "`n>>> Compressing:" -ForegroundColor Cyan
        Write-Host $inPath
        Write-Host "    -> $out"

        $stage = 'Encode'
        $native = Invoke-EncodeProcess $ffmpeg $encodeArguments
        $result.Settings.Applied=if ($null -ne $native.PSObject.Properties['Started']) { [bool]$native.Started } else { [bool]$native.Succeeded }
        $result.Diagnostics.Encode=$native
        if ($native.StdOutTruncated -or $native.StdErrTruncated) {
            Write-Host 'Captured encoder diagnostics retain only the last 1048576 characters per stream; console output was streamed.' -ForegroundColor Yellow
        }
        if (-not $native.Succeeded) { throw "Encoder failed [$($native.FailureKind)]: $($native.Error)" }
        $stage = 'Validation'
        $validation = Get-OutputValidation $ffprobe $outputJob $inspection $streamPlan
        $result.Diagnostics.Validation=$validation
        if ($null -ne $validation.Inspection -and $null -ne $validation.Inspection.Native -and $validation.Inspection.Native.StdErr) {
            Write-Host ("Output probe diagnostics: " + $validation.Inspection.Native.StdErr.Trim()) -ForegroundColor Yellow
        }
        if (-not $validation.Succeeded) { throw "Output validation failed [$($validation.FailureKind)]: $($validation.Reason)" }
        foreach ($warning in $validation.Warnings) { Write-Host $warning -ForegroundColor Yellow }
        $stage = 'Promote'
        $publication = Publish-OutputJob $outputJob $CollisionMode
        $published = $publication.Published
        if ($published) {
            $result.Outcome='Completed'
            $result.OutputPath=$publication.FinalPath
            $stage='Complete'
            $reason = 'Published.'
            if ($publication.FinalPath -ne $out) { Write-Host ("Published as: " + $publication.FinalPath) -ForegroundColor Cyan }
            Write-Host "Done." -ForegroundColor Green
        } else {
            $reason = $publication.Reason
            $skipped = $true
            $result.Outcome='Skipped'
            $result.CandidatePath=$publication.FinalPath
            Write-Host ("Skipping final collision: " + $publication.FinalPath) -ForegroundColor DarkYellow
        }
    } catch {
        $reason = $_.Exception.Message
        # Classify the actual exception explicitly on both supported hosts. A
        # reporting interruption cannot undo a durable publication or valid skip.
        if ($_.Exception -is [System.Management.Automation.PipelineStoppedException]) {
            $stage='Interrupted'; $reason='Pipeline interrupted; partial retained if present.'
            $result.CancellationRequested=$true
            if (-not $published -and -not $skipped) { $result.Outcome='Cancelled' }
            $_.Exception.Data['WvcJobResult']=$result
            throw
        }
        if ($_.Exception.Data.Contains('WvcAbortBatch')) {
            $encoderMayStillRun = $true
            $result.AbortBatch=$true
            $_.Exception.Data['WvcJobResult']=$result
            throw
        }
        if ($_.Exception.Data.Contains('WvcStage')) { $stage=[string]$_.Exception.Data['WvcStage'] }
        if ($_.Exception -is [System.OperationCanceledException]) {
            $stage='Interrupted'; $result.CancellationRequested=$true
            if (-not $published -and -not $skipped) { $result.Outcome='Cancelled' }
        } elseif ($published -or $skipped) {
            try { Write-Host ("Recorded job outcome; console reporting failed: " + $reason) -ForegroundColor Yellow } catch { }
        } else {
            Write-Host "Failed [$stage]: $inPath" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor DarkRed
        }
    } finally {
        if ($null -ne $outputJob) {
            $cleanup = Close-OutputJob $outputJob $published $stage $reason -EncoderMayStillRun:$encoderMayStillRun
            if ($cleanup.Warning) {
                $result.RetainedPath=$outputJob.JobDirectory
                $result.Diagnostics.Warnings+=@($cleanup.Warning)
                try { Write-Host $cleanup.Warning -ForegroundColor Yellow } catch {
                    # Console diagnostics cannot replace interruption/fatal cleanup.
                    try { [Console]::Error.WriteLine($cleanup.Warning) } catch { }
                }
            }
        }
        $clock.Stop()
        $result.ElapsedSeconds=$clock.Elapsed.TotalSeconds
        $result.Stage=$stage
        $result.Reason=$reason
        if ($published) {
            try { $result.OutputBytes=Get-JobFileLength $result.OutputPath }
            catch {
                if ($_.Exception -is [System.Management.Automation.PipelineStoppedException]) {
                    $result.CancellationRequested=$true; $_.Exception.Data['WvcJobResult']=$result; throw
                }
                if ($_.Exception -is [System.OperationCanceledException]) {
                    $result.CancellationRequested=$true; $result.Diagnostics.Warnings+=@('Output size accounting cancelled after publication.')
                } else { $result.Diagnostics.Warnings+=@('Output size accounting failed: '+$_.Exception.Message) }
            }
            if ($null -ne $result.InputBytes -and $null -ne $result.OutputBytes) {
                $result.SizeChangeBytes=$result.OutputBytes-$result.InputBytes
                if ($result.InputBytes -gt 0) { $result.SizeChangePercent=100.0*$result.SizeChangeBytes/$result.InputBytes }
            }
        }
        if ($null -ne $counters -and $null -ne $counters.Value) {
            switch ($result.Outcome) {
                'Completed' { $counters.Value.Done++ }
                'Skipped' { $counters.Value.Skipped++ }
                'Failed' { $counters.Value.Failed++ }
            }
        }
    }
    return $result
}

function Process-Paths([string[]]$paths, $ffmpeg, $ffprobe, $cfg) {
    # Recheck at every requested batch, including after a menu preference change.
    try {
        [void](Get-OutputEnvironment $cfg.OutputDir)
        foreach ($warning in @(Get-OutputJobWarnings $cfg.OutputDir)) { Write-Host $warning -ForegroundColor Yellow }
        # Freeze all selections before any encoder can create new candidates.
        $queue=Get-InputQueue $paths
    }
    catch {
        if ($_.Exception -is [System.Management.Automation.PipelineStoppedException]) { throw }
        if ($_.Exception -is [System.OperationCanceledException]) {
            return (Get-BatchResult @() @() -Requested -Cancelled -Reason $_.Exception.Message)
        }
        Write-Host $_.Exception.Message -ForegroundColor Red
        return (Get-BatchResult @() @() -Requested -StartupFailed -Reason $_.Exception.Message)
    }
    $jobs=New-Object 'Collections.Generic.List[object]'
    foreach ($scan in $queue.Scans) {
        if ($null -ne $scan.PSObject.Properties['Warnings']) {
            foreach ($warning in $scan.Warnings) { Write-Host $warning -ForegroundColor Yellow }
        }
        $targets = @($scan.Files)
        foreach ($failure in $scan.Errors) {
            Write-Host ("Scan error [{0}]: {1}`n    {2}" -f $failure.Kind,$failure.Path,$failure.Message) -ForegroundColor Yellow
        }
        if ($targets.Count -eq 0) {
            if ($scan.Succeeded) { Write-Host "No videos found: $($scan.InputPath)" -ForegroundColor Yellow }
        }
    }
    $stopScheduling=$false
    foreach ($f in $queue.Files) {
        if ($stopScheduling) {
            $job=New-JobResult $f $DefaultCRF
            $job.Reason='Batch ended before this job started.'
        } else {
            try {
                $job=Compress-One $ffmpeg $ffprobe $f $cfg.OutputDir $DefaultCRF
            } catch {
                if ($_.Exception -is [System.Management.Automation.PipelineStoppedException]) { throw }
                $job=$_.Exception.Data['WvcJobResult']
                if ($null -eq $job) {
                    $job=New-JobResult $f $DefaultCRF
                    $job.Outcome='Failed'; $job.Stage='Dispatch'; $job.Reason=$_.Exception.Message; $job.AbortBatch=$true
                }
                $stopScheduling=$true
            }
            if ($null -eq $job -or $job -is [array] -or
                (Get-ProbeProperty $job 'SchemaVersion') -ne 1 -or
                (Get-ProbeProperty $job 'SourcePath') -cne $f -or
                (Get-ProbeProperty $job 'Outcome') -notin @('Completed','Skipped','Failed','Cancelled','Unstarted')) {
                $job=New-JobResult $f $DefaultCRF
                $job.Outcome='Failed'; $job.Stage='Dispatch'; $job.Reason='Compressor did not return one matching job record.'; $job.AbortBatch=$true
            }
            if ($job.Outcome -eq 'Cancelled' -or $job.CancellationRequested -or $job.AbortBatch) { $stopScheduling=$true }
        }
        $jobs.Add($job)
    }

    $batch=Get-BatchResult $jobs.ToArray() $queue.Scans -Requested
    $counters=$batch.Counters

    try {
        Write-Host "`n========== Summary ==========" -ForegroundColor Cyan
        Write-Host ("Found:   {0}" -f $counters.Found)
        Write-Host ("Done:    {0}" -f $counters.Done)
        Write-Host ("Skipped: {0}" -f $counters.Skipped)
        Write-Host ("Failed:  {0}" -f $counters.Failed)
        Write-Host ("Cancelled: {0}" -f $counters.Cancelled)
        Write-Host ("Unstarted: {0}" -f $counters.Unstarted)
        Write-Host ("Scanned: {0}" -f $counters.Scanned)
        Write-Host ("Scan errors: {0}" -f $counters.ScanErrors)
    } catch {
        if ($_.Exception -is [System.Management.Automation.PipelineStoppedException]) { throw }
        if ($_.Exception -is [System.OperationCanceledException]) {
            $batch.Cancelled=$true; $batch.ExitCode=3; $batch.Warnings+=@('Summary reporting cancelled.')
        } else { $batch.Warnings+=@('Summary reporting failed: '+$_.Exception.Message) }
    }
    return $batch
}

function Get-SessionResult([object[]]$Batches) {
    $runs=@($Batches | Where-Object { $null -ne $_ })
    $jobs=@($runs | ForEach-Object { $_.Jobs })
    $scans=@($runs | ForEach-Object { $_.Scans })
    $result=Get-BatchResult $jobs $scans -Requested:($runs.Count -gt 0) -Reason 'Menu closed.'
    # Preserve an earlier empty/invalid requested batch even after a successful one.
    foreach ($batch in $runs) { if ($batch.ExitCode -gt $result.ExitCode) { $result.ExitCode=$batch.ExitCode } }
    $result.Cancelled=($result.ExitCode -eq 3)
    $result.StartupFailed=@($runs | Where-Object StartupFailed).Count -gt 0
    $result.Warnings=@($runs | ForEach-Object { $_.Warnings })
    $result | Add-Member -NotePropertyName Batches -NotePropertyValue $runs
    return $result
}

# --- TUI ---
function Run-TUI($ffmpeg, $ffprobe, $cfg) {
    $batches=New-Object 'Collections.Generic.List[object]'
    try {
    while ($true) {
        Write-Host ""
        Write-Host "========== WinVidCompress =========="
        Write-Host "Output folder: $($cfg.OutputDir)"
        Write-Host ""
        Write-Host "1) Set output folder"
        Write-Host "2) Compress ONE file"
        Write-Host "3) Compress ALL videos in a folder (recursive)"
        Write-Host "4) Quit"

        $c = Read-Host "Choose [1-4]"
        switch ($c) {
            '1' {
                $p = Prompt-Path "Enter output folder path (blank to cancel)" -Folder -CreateIfMissing
                if ($p) {
                    $candidate = $cfg.PSObject.Copy()
                    $candidate.OutputDir = $p
                    try {
                        [void](Get-OutputEnvironment $candidate.OutputDir)
                        Save-Config $candidate
                        $cfg.OutputDir = $p
                    } catch {
                        if ($_.Exception -is [System.Management.Automation.PipelineStoppedException] -or
                            $_.Exception -is [System.OperationCanceledException]) { throw }
                        Write-Host "Output preference was not changed: $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
            }
            '2' {
                $f = Prompt-Path "Paste a source FILE path"
                if ($f) {
                    $batch=Process-Paths @($f) $ffmpeg $ffprobe $cfg
                    if ($null -ne $batch) { $batches.Add($batch) }
                    if ($null -ne $batch -and ($batch.ExitCode -eq 3 -or @($batch.Jobs | Where-Object AbortBatch).Count)) { return (Get-SessionResult $batches.ToArray()) }
                }
            }
            '3' {
                $d = Prompt-Path "Paste a source FOLDER path" -Folder
                if ($d) {
                    $batch=Process-Paths @($d) $ffmpeg $ffprobe $cfg
                    if ($null -ne $batch) { $batches.Add($batch) }
                    if ($null -ne $batch -and ($batch.ExitCode -eq 3 -or @($batch.Jobs | Where-Object AbortBatch).Count)) { return (Get-SessionResult $batches.ToArray()) }
                }
            }
            '4' { return (Get-SessionResult $batches.ToArray()) }
            Default { }
        }
    }
    } catch {
        if ($_.Exception -is [System.Management.Automation.PipelineStoppedException]) { throw }
        $cancelled=$_.Exception -is [System.OperationCanceledException]
        $batches.Add((Get-BatchResult @() @() -Cancelled:$cancelled -StartupFailed:(-not $cancelled) -Reason $_.Exception.Message))
        return (Get-SessionResult $batches.ToArray())
    }
}

function Invoke-WinVidCompress([string[]]$Paths, [switch]$CheckEnvironment,
    [switch]$Unattended, [switch]$ExplicitRequest) {
    $stage='Startup'
    $inputPaths=@($Paths | Where-Object { $null -ne $_ })
    try {
        if (-not $CheckEnvironment -and ($Unattended -or $ExplicitRequest) -and -not $inputPaths.Count) {
            throw 'No input paths supplied for the requested batch.'
        }
        $ffmpeg=Ensure-Tool 'ffmpeg.exe'
        $ffprobe=Ensure-Tool 'ffprobe.exe'
        $tools=Get-ToolEnvironment $ffmpeg $ffprobe
        if ($CheckEnvironment) {
            $cfg=Get-EnvironmentConfig
            $output=Get-OutputEnvironment $cfg.OutputDir
            Write-EnvironmentReport $tools $output
            return (Get-BatchResult @() @() -Reason 'Environment check completed.')
        }
        $cfg=Load-Config
        $output=Get-OutputEnvironment $cfg.OutputDir
        Write-EnvironmentReport $tools $output
        if ($inputPaths.Count -gt 0) { return (Process-Paths $inputPaths $ffmpeg $ffprobe $cfg) }
        $stage='Menu'
        return (Run-TUI $ffmpeg $ffprobe $cfg)
    } catch {
        if ($_.Exception -is [System.Management.Automation.PipelineStoppedException]) { throw }
        if ($_.Exception -is [System.OperationCanceledException]) {
            return (Get-BatchResult @() @() -Cancelled -Reason $_.Exception.Message)
        }
        $reason=$_.Exception.Message
        try { [Console]::Error.WriteLine("WinVidCompress [$stage]: $reason") } catch { }
        return (Get-BatchResult @() @() -StartupFailed -Reason $reason)
    }
}

# Dot-sourcing loads helpers/defaults without application startup or caller exit.
if ($MyInvocation.InvocationName -eq '.') { return }

# --- Main ---
if ($KeepOpen -and $Unattended) {
    [Console]::Error.WriteLine('WinVidCompress: -KeepOpen and -Unattended cannot be combined. Put -Unattended first when using the BAT launcher.')
    exit 2
}
$run=Invoke-WinVidCompress -Paths $Path -CheckEnvironment:$CheckEnvironment -Unattended:$Unattended -ExplicitRequest:($PSBoundParameters.ContainsKey('Path'))
$global:LASTEXITCODE=$run.ExitCode
if (-not $KeepOpen) { exit $run.ExitCode }
