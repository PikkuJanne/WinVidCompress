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
    C) Direct PowerShell
        - Run:  .\WinVidCompress.ps1  "D:\Interviews\Band 29092025 - CamA.mov"
        - Or:   .\WinVidCompress.ps1  "D:\Interviews\FolderWithVideos"

NOTES
    - Paths, spaces, and special characters are handled correctly when using the provided .bat.
    - If you ever want smaller files, change $DefaultCRF from 22 to 23–24.
    - If config becomes invalid or is deleted, OutputDir resets to your Videos folder automatically.
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

$DefaultCRF = 22
$VideoExts  = @('.mp4','.mov','.mkv','.m4v','.avi','.mpg','.mpeg','.mts','.m2ts','.wmv')

# Collision behavior when output file already exists:
# "skip": do nothing
# "rename": create " (compressed)" / " (compressed 2)" suffix
$CollisionMode = 'rename'

# --- Helpers ---
function Ensure-Tool([string]$exe) {
    $cmd = Get-Command $exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $local = Join-Path (Split-Path -Parent $PSCommandPath) $exe
    if (Test-Path -LiteralPath $local) { return $local }

    throw "$exe not found. Put it in PATH or next to this script."
}

function Save-Config($cfg) {
    if (-not (Test-Path -LiteralPath $ConfigDir)) {
        [void][IO.Directory]::CreateDirectory($ConfigDir)
    }
    $cfg | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $ConfigPath
}

function Load-Config {
    if (-not (Test-Path -LiteralPath $ConfigDir)) {
        [void][IO.Directory]::CreateDirectory($ConfigDir)
    }

    $videos = [Environment]::GetFolderPath('MyVideos')  # e.g. C:\Users\<you>\Videos

    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        $cfg = [pscustomobject]@{ OutputDir = $videos }
        Save-Config $cfg
        return $cfg
    }

    try {
        $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    } catch {
        $cfg = [pscustomobject]@{ OutputDir = $videos }
        Save-Config $cfg
        return $cfg
    }

    if (-not $cfg.OutputDir -or -not (Test-Path -LiteralPath $cfg.OutputDir)) {
        $cfg.OutputDir = $videos
        Save-Config $cfg
    }

    return $cfg
}

function Prompt-Path([string]$prompt, [switch]$Folder) {
    while ($true) {
        $p = Read-Host $prompt
        if ([string]::IsNullOrWhiteSpace($p)) { return $null }
        $p = $p.Trim().Trim('"')

        if ($Folder) {
            if (-not (Test-Path -LiteralPath $p)) {
                # Create if missing, for user-selected output folder
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

function Collect-InputFiles([string]$p) {
    if (-not (Test-Path -LiteralPath $p)) { return @() }

    if (Test-Path -LiteralPath $p -PathType Leaf) {
        return ,(Resolve-Path -LiteralPath $p).Path
    }

    # Folder: recursive
    $files = Get-ChildItem -LiteralPath $p -Recurse -File -ErrorAction SilentlyContinue |
        Where-Object { $VideoExts -contains $_.Extension.ToLower() }

    return $files.FullName
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

        if (Test-Path -LiteralPath $out) {
            if ($CollisionMode -eq 'skip') {
                Write-Host "Skipping (exists): $out" -ForegroundColor DarkYellow
                $counters.Value.Skipped++
                return
            } else {
                $out = Next-CompressedPath $out
            }
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
    $counters = [pscustomobject]@{ Found = 0; Done = 0; Skipped = 0; Failed = 0 }

    foreach ($p in $paths) {
        $targets = Collect-InputFiles $p
        if (-not $targets -or $targets.Count -eq 0) {
            Write-Host "No videos found: $p" -ForegroundColor Yellow
            continue
        }

        $counters.Found += $targets.Count

        foreach ($f in $targets) {
            Compress-One $ffmpeg $ffprobe $f $cfg.OutputDir $DefaultCRF ([ref]$counters)
        }
    }

    Write-Host "`n========== Summary ==========" -ForegroundColor Cyan
    Write-Host ("Found:   {0}" -f $counters.Found)
    Write-Host ("Done:    {0}" -f $counters.Done)
    Write-Host ("Skipped: {0}" -f $counters.Skipped)
    Write-Host ("Failed:  {0}" -f $counters.Failed)
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
                $p = Prompt-Path "Enter output folder path (blank to cancel)" -Folder
                if ($p) {
                    $cfg.OutputDir = $p
                    Save-Config $cfg
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
            '4' { break }
            Default { }
        }
    }
}

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