# WinVidCompress — One-preset video compressor for Win11 (PowerShell + FFmpeg)
Minimal, no-frills video compressor I use to archive my band interview videos with consistent settings and basic metadata. It’s a personal, purpose-built tool, I don’t expect most people to need this. It trades options for speed and repeatability.

**Synopsis**
One compression profile (like HandBrake “Very Fast 1080p”):
H.264 (libx264) -preset veryfast, -crf 22; AAC 160 kbps; MP4 with +faststart.
No cropping; only downscales if source height > 1080 (never upscales).
Filename-driven metadata (artist/date/title/comment) for interview archiving.
Drag & drop workflow: I drop video files or folders onto the .bat and find the result in Videos.
Supports simple batch processing:
- Dropping a single file compresses that file
- Dropping a folder compresses all videos inside (recursive)
- Dropping multiple files or folders queues everything and processes sequentially

Completed jobs report original/output bytes, reduction or growth, source duration and measured elapsed time. Batch size totals include only completed jobs with a positive known original size and known output size; unavailable sizes and other outcomes are counted separately. Results vary; valid output can be larger. CRF does not set an output size. Developer measurements and optional experiments are described in [the benchmark guide](docs/benchmarks/README.md); the production profile remains unchanged.

**Requirements**
Windows 11
PowerShell (Windows PowerShell is fine)
FFmpeg + FFprobe in PATH or placed next to the script
(must include libx264, AAC, MP4/faststart, scale and FFprobe CSV/JSON support)

**Installation**
Download a recent static FFmpeg build for Windows (includes ffmpeg.exe and ffprobe.exe).
Put both exes either in PATH or in the same folder as this repo’s script.
Place these files together (e.g., in Downloads):
WinVidCompress.ps1
WinVidCompress.bat (wrapper for double-click + drag-and-drop)
On a normal first run the tool creates %APPDATA%\WinVidCompress\config.json and sets the OutputDir to your Videos folder. Preview and per-run overrides leave an absent preference file absent.

**Usage**
1. My everyday flow (drag & drop onto .bat)
Drag a single video file (or a folder) onto WinVidCompress.bat.
The compressed .mp4 appears in %USERPROFILE%\Videos.
Window stays open so you can see progress/logs.

Paths containing `%NAME%` segments, such as `literal %PATH%.mov`, are unsupported for BAT drag/drop because Windows shell expansion can change them. This applies to folder names too; keep the BAT/script installation path free of these segments. Double-click the BAT and paste the literal source path in menu option 2/3, or invoke the PS1 from PowerShell with single quotes:

```powershell
.\WinVidCompress.ps1 'D:\Interviews\literal %PATH% !NAME!.mov'
```
1. TUI (double-click)
Double-click WinVidCompress.bat to open the TUI:
Set output folder (persists in config)
Compress ONE file (paste a path)
Compress ALL videos in a folder (recursive)
1. Command line
#One file
.\WinVidCompress.ps1 "D:\Interviews\Band Name 29092025 - CamA.mov"
#Whole folder (recursive)
.\WinVidCompress.ps1 "D:\Interviews\ToArchive"

For unattended use, run the PS1 with `-Unattended`, or put that switch first in the BAT command. These routes never open the menu or pause after completion:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\WinVidCompress.ps1 -Unattended 'D:\Interviews\ToArchive'
```

```bat
WinVidCompress.bat -Unattended "D:\Interviews\ToArchive"
```

Direct PS1 batches also return the application exit code. Codes are **0** completed with no failures (including valid collision skips), **1** job/scan failure, **2** startup/configuration/invalid or empty requested batch, and **3** observed application cancellation, which takes precedence. Cancelling a menu selection or choosing Quit before a batch returns 0. The default BAT adds `-KeepOpen` and retains its PowerShell prompt; its eventual shell exit is separate from the batch result. `-KeepOpen` and `-Unattended` cannot be combined. Physical Ctrl+C/console-close handling remains unverified; PowerShell engine parse/binding errors can have their own exit code.

Per-run `-OutputDir` selects an existing absolute output directory, and `-CollisionMode rename|skip` controls ordinary collisions. Defaults apply first, then saved config, then supplied options. Neither option saves preferences. Config may contain an optional `CollisionMode`; omission means `rename`. Unknown config fields are preserved. With per-run controls, invalid config fails without recovery; an unavailable saved output can be replaced by a valid `-OutputDir` for that run. The four-item menu and normal config recovery remain available when no per-run controls are supplied.

```powershell
.\WinVidCompress.ps1 -Unattended -OutputDir 'D:\Output' -CollisionMode skip 'D:\Interviews'
.\WinVidCompress.ps1 -Unattended -WhatIf -OutputDir 'D:\Output' 'D:\Interviews'
Get-Help .\WinVidCompress.ps1 -Full
```

`-WhatIf` reads preferences and the input/output directories to print estimated encode/skip destinations. It creates no config, backups, directories, jobs, logs or manifests and starts no native tools. Media validity, destination writability and concurrent name changes are unchecked. Empty/invalid selection returns 2; a partly failed scan with planned files returns 1. Preview and per-run conversion controls require explicit inputs. Preview cannot combine with `-CheckEnvironment` or manifest controls; preview the same inputs without those flags. The doctor accepts `-OutputDir` and retains its disclosed temporary write check. Resume retries always use safe rename around old outputs. CRF remains 22 and has no public switch. A relative filename beginning with a dash needs a `.\` prefix or an absolute path.

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
Dates must be real Gregorian calendar dates; leap years are checked independently of Windows language settings. Multiple date tokens (even repeated or invalid ones), blank band names and invalid dates omit filename-derived artist/date/comment and print a warning. The base filename still supplies the title, and compression continues without prompts.

The legacy compact-date fallback, such as `Band Name 29092025 CamA`, accepts one whitespace-delimited, calendar-valid eight-digit token and warns that an unlabelled number may be unrelated to an interview. Longer numbers and tokens embedded in letters are ignored. Dotted/dashed dates use matching separators and the patterns above.

Metadata precedence: the filename title overrides the source title; a valid band/date pair also overrides source artist/date/comment. Otherwise those source fields can remain. Other compatible global and selected-stream source tags follow FFmpeg's standard single-input copying and MP4 support, including copyright and audio language where supported. Outputs can contain source metadata beyond the four generated fields; compression does not sanitize private metadata. Arbitrary source tags are not guaranteed to survive.

**Output location**
Default: Windows Videos folder (e.g., C:\Users\<you>\Videos).
You can change it in the TUI (Option 1).
The setting is stored in %APPDATA%\WinVidCompress\config.json.
If an output file already exists, the script auto-renames the new file using a "(compressed)" suffix.

**Technical details**
Video: -c:v libx264 -preset veryfast -crf 22
Audio: -c:a aac -b:a 160k
Container: -movflags +faststart
Scaling: -vf scale=-2:1080 only if source height > 1080
Invokes FFmpeg through the owned native process adapter with literal argument tokens and Windows quoting.

Stream selection: first real video by index, excluding cover artwork; unique default audio when present, otherwise first audio by index. Silent video stays silent. The console lists selected streams, audio channels and omitted alternatives/subtitles/data/attachments. Explicit maps keep scaling tied to the inspected video; no channel-count or frame-rate override is added.

**Tweaks (optional):**
Smaller files → increase CRF to 23–24 (lower quality).
H.265/HEVC (slower, smaller) → swap libx264 to libx265 and use CRF ~27.

**Troubleshooting**
Run `.\WinVidCompress.ps1 -CheckEnvironment` from PowerShell to report the exact executable paths, versions/build details, required capabilities, output access and available capacity. Applications found in PATH take precedence over copies next to the script; aliases/functions are refused. Each native check has a 10-second timeout, including pipe draining. The tool does not download or replace dependencies, edit PATH or request elevation.

The diagnostic command never converts media or saves/repairs configuration. It uses the saved destination (Videos if no config exists), creates a unique temporary file in that existing directory to test writing, and removes it on close. It creates no config, backups or output folders. Invalid configuration, offline destinations and write denials fail clearly. Normal startup, output selection and each batch also check destination access. Free space is advisory and output size is not guaranteed; permissions and capacity can change after the check. UNC/mount-point capacity may be unknown.

“ffmpeg not found” → put ffmpeg.exe and ffprobe.exe next to the script or add them to PATH.
TUI appears when dragging a file → the argument didn’t reach the script cleanly; try again, or open the TUI and choose option 2/3.
Reset output folder → delete %APPDATA%\WinVidCompress\config.json and rerun (defaults to Videos).

**Intent & License**
This is a personal tool for a very specific workflow (archiving my video interviews with bands). It’s provided as-is, without warranty. Use at your own risk.
If you want to reuse or adapt it, feel free, just be mindful it intentionally avoids features to keep my workflow fast and predictable.
