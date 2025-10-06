# WinVidCompress — One-preset video compressor for Win11 (PowerShell + FFmpeg)
Minimal, no-frills video compressor I use to archive my band interview videos with consistent settings and basic metadata. It’s a personal, purpose-built tool, I don’t expect most people to need this. It trades options for speed and repeatability.

**Synopsis**
One compression profile (like HandBrake “Very Fast 1080p”):
H.264 (libx264) -preset veryfast, -crf 22; AAC 160 kbps; MP4 with +faststart.
No cropping; only downscales if source height > 1080 (never upscales).
Filename-driven metadata (artist/date/title/comment) for interview archiving.
Drag & drop workflow: I drop a single video onto the .bat and find the result in Videos.

**Requirements**
Windows 11
PowerShell (Windows PowerShell is fine)
FFmpeg + FFprobe in PATH or placed next to the script
(any recent static build is fine)

**Installation**
Download a recent static FFmpeg build for Windows (includes ffmpeg.exe and ffprobe.exe).
Put both exes either in PATH or in the same folder as this repo’s script.
Place these files together (e.g., in Downloads):
WinVidCompress.ps1
WinVidCompress.bat (wrapper for double-click + drag-and-drop)
On first run the tool creates %APPDATA%\WinVidCompress\config.json and sets the OutputDir to your Videos folder.

Usage
1. My everyday flow (drag & drop onto .bat)
Drag a single video file onto WinVidCompress.bat.
The compressed .mp4 appears in %USERPROFILE%\Videos.
Window stays open so you can see progress/logs.
2. TUI (double-click)
Double-click WinVidCompress.bat to open the TUI:
Set output folder (persists in config)
Compress ONE file (paste a path)
Compress ALL videos in a folder (recursive)
3. Command line
#One file
.\WinVidCompress.ps1 "D:\Interviews\Band Name 29092025 - CamA.mov"
#Whole folder (recursive)
.\WinVidCompress.ps1 "D:\Interviews\ToArchive"

**Filename → Metadata**
The script tries to parse band and date from the filename (base name). Supported patterns (with or without trailing “ - …”):
Band Name ddmmyyyy
Band Name dd.mm.yyyy
Band Name dd-mm-yyyy
Tags written:
artist = Band Name
date = YYYY-MM-DD
title = base filename
comment = Interview date dd.mm.yyyy; Band: <name>
If parsing fails, the file still compresses (no prompts).

**Output location**
Default: Windows Videos folder (e.g., C:\Users\<you>\Videos).
You can change it in the TUI (Option 1).
The setting is stored in %APPDATA%\WinVidCompress\config.json.

**Batch wrapper (included)**
WinVidCompress.bat (drag-and-drop + double-click):

@echo off
setlocal EnableExtensions EnableDelayedExpansion
set "SCRIPT=%~dp0WinVidCompress.ps1"
:: Double-click = TUI
if "%~1"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%"
  goto :eof
)
:: Drag & drop (handles typical cases)
set "ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%SCRIPT%" !ARGS!
Note: Windows CMD treats %…% as env vars. This wrapper handles typical cases; if you still hit edge cases, use the TUI or rename the file.

**Technical details**
Video: -c:v libx264 -preset veryfast -crf 22
Audio: -c:a aac -b:a 160k
Container: -movflags +faststart
Scaling: -vf scale=-2:1080 only if source height > 1080
Invokes FFmpeg via PowerShell call operator (&) to keep quoting correct.

**Tweaks (optional):**
Smaller files → increase CRF to 23–24 (lower quality).
H.265/HEVC (slower, smaller) → swap libx264 to libx265 and use CRF ~27.

**Troubleshooting**
“ffmpeg not found” → put ffmpeg.exe and ffprobe.exe next to the script or add them to PATH.
TUI appears when dragging a file → the argument didn’t reach the script cleanly; try again, or open the TUI and choose option 2/3.
Reset output folder → delete %APPDATA%\WinVidCompress\config.json and rerun (defaults to Videos).

**Intent & License**
This is a personal tool for a very specific workflow (archiving my video interviews with bands). It’s provided as-is, without warranty. Use at your own risk.
If you want to reuse or adapt it, feel free, just be mindful it intentionally avoids features to keep my workflow fast and predictable.