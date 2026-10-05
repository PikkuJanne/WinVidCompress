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
    - No new output subfolders are created by default; files land directly in OutputDir.

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
    $cmd = Get-Command $exe -CommandType Application -ErrorAction SilentlyContinue
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
    return $candidate
}

function Get-DefaultOutputDir {
    [Environment]::GetFolderPath('MyVideos')
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

function Get-VideoHeight($ffprobe, [string]$inPath) {
    $out = & $ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 -- $inPath 2>$null
    $out = ($out | Out-String).Trim()
    $h = 0
    if ([int]::TryParse($out, [ref]$h)) { return $h }
    return $null
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

function Get-InputScan([string]$p) {
    $files = New-Object 'Collections.Generic.List[string]'
    $errors = New-Object 'Collections.Generic.List[object]'
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
        Files = $files.ToArray(); Errors = $errors.ToArray(); Succeeded = ($errors.Count -eq 0) }
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
    # No ownership manifest/temp protocol exists yet. Never infer ownership from
    # OutputDir, extension or a compressed/partial suffix; keep ambiguous files.
    return [pscustomobject]@{ Files = $files; Scans = $scans.ToArray() }
}

function Compress-One($ffmpeg, $ffprobe, [string]$inPath, [string]$outDir, [int]$crf, [ref]$counters) {
    try {
        if (-not (Test-Path -LiteralPath $inPath -PathType Leaf)) {
            Write-Host "Missing: $inPath" -ForegroundColor Red
            $counters.Value.Failed++
            return
        }

        if (-not (Test-Path -LiteralPath $outDir -PathType Container)) {
            Write-Host "Output folder missing: $outDir" -ForegroundColor Red
            $counters.Value.Failed++
            return
        }

        $meta = Parse-MetadataFromName ([IO.Path]::GetFileName($inPath))
        $base = [IO.Path]::GetFileNameWithoutExtension($inPath)

        $out = Join-Path $outDir ($base + '.mp4')

        $sourceKey = Get-QueuePathKey $inPath
        if ([StringComparer]::OrdinalIgnoreCase.Equals($sourceKey, (Get-QueuePathKey $out)) -or
            (Test-Path -LiteralPath $out)) {
            if ($CollisionMode -eq 'skip') {
                Write-Host "Skipping (exists): $out" -ForegroundColor DarkYellow
                $counters.Value.Skipped++
                return
            } else {
                $out = Next-CompressedPath $out
            }
        }

        if ([StringComparer]::OrdinalIgnoreCase.Equals($sourceKey, (Get-QueuePathKey $out))) {
            throw 'Output path must differ from the input path.'
        }

        $h = Get-VideoHeight $ffprobe $inPath

        $args = @(
            '-hide_banner',
            '-stats',
            '-n',                      # never overwrite
            '-i', $inPath
        )

        if ($h -and $h -gt 1080) {
            $args += @('-vf','scale=-2:1080')
        }

        $args += @(
            '-c:v','libx264','-preset','veryfast','-crf',"$crf",
            '-c:a','aac','-b:a','160k',
            '-movflags','+faststart'
        )

        if ($meta.Title) { $args += @('-metadata',"title=$($meta.Title)") }
        if ($meta.Band)  { $args += @('-metadata',"artist=$($meta.Band)") }
        if ($meta.DateISO) { $args += @('-metadata',"date=$($meta.DateISO)") }
        if ($meta.DateHuman -and $meta.Band) {
            $args += @('-metadata',"comment=Interview date $($meta.DateHuman); Band: $($meta.Band)")
        }

        $args += $out

        Write-Host "`n>>> Compressing:" -ForegroundColor Cyan
        Write-Host $inPath
        Write-Host "    -> $out"

        & $ffmpeg @args
        $ec = $LASTEXITCODE

        if ($ec -eq 0) {
            Write-Host "Done." -ForegroundColor Green
            $counters.Value.Done++
        } else {
            Write-Host "FFmpeg exit code: $ec" -ForegroundColor Red
            $counters.Value.Failed++
        }
    } catch {
        Write-Host "Failed: $inPath" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor DarkRed
        $counters.Value.Failed++
    }
}

function Process-Paths([string[]]$paths, $ffmpeg, $ffprobe, $cfg) {
    $counters = [pscustomobject]@{ Found = 0; Done = 0; Skipped = 0; Failed = 0; Scanned = 0; ScanErrors = 0 }

    # Complete every selection before an encoder can create any new input candidates.
    $queue = Get-InputQueue $paths
    foreach ($scan in $queue.Scans) {
        $targets = @($scan.Files)
        if ($scan.Succeeded) { $counters.Scanned++ }
        $counters.ScanErrors += $scan.Errors.Count
        foreach ($failure in $scan.Errors) {
            Write-Host ("Scan error [{0}]: {1}`n    {2}" -f $failure.Kind,$failure.Path,$failure.Message) -ForegroundColor Yellow
        }
        if ($targets.Count -eq 0) {
            if ($scan.Succeeded) { Write-Host "No videos found: $($scan.InputPath)" -ForegroundColor Yellow }
        }
    }
    $counters.Found = $queue.Files.Count
    foreach ($f in $queue.Files) {
        Compress-One $ffmpeg $ffprobe $f $cfg.OutputDir $DefaultCRF ([ref]$counters)
    }

    Write-Host "`n========== Summary ==========" -ForegroundColor Cyan
    Write-Host ("Found:   {0}" -f $counters.Found)
    Write-Host ("Done:    {0}" -f $counters.Done)
    Write-Host ("Skipped: {0}" -f $counters.Skipped)
    Write-Host ("Failed:  {0}" -f $counters.Failed)
    Write-Host ("Scanned: {0}" -f $counters.Scanned)
    Write-Host ("Scan errors: {0}" -f $counters.ScanErrors)
}

# --- TUI ---
function Run-TUI($ffmpeg, $ffprobe, $cfg) {
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
                        Save-Config $candidate
                        $cfg.OutputDir = $p
                    } catch {
                        Write-Host "Output preference was not changed: $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                }
            }
            '2' {
                $f = Prompt-Path "Paste a source FILE path"
                if ($f) {
                    Process-Paths @($f) $ffmpeg $ffprobe $cfg
                }
            }
            '3' {
                $d = Prompt-Path "Paste a source FOLDER path" -Folder
                if ($d) {
                    Process-Paths @($d) $ffmpeg $ffprobe $cfg
                }
            }
            '4' { return }
            Default { }
        }
    }
}

# Dot-sourcing loads helpers/defaults without application startup.
if ($MyInvocation.InvocationName -eq '.') { return }

# --- Main ---
$ffmpeg  = Ensure-Tool 'ffmpeg.exe'
$ffprobe = Ensure-Tool 'ffprobe.exe'
$cfg     = Load-Config

# If args were provided, queue and process immediately.
if ($Path -and $Path.Count -gt 0) {
    Process-Paths $Path $ffmpeg $ffprobe $cfg
} else {
    Run-TUI $ffmpeg $ffprobe $cfg
}
