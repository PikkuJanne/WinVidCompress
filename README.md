# WinVidCompress

A local Windows 11 PowerShell + FFmpeg tool for making smaller viewing copies of interview videos. Drop files or folders onto `WinVidCompress.bat`, or use its four-item menu. Batches run sequentially. Keep your originals: H.264/AAC copies are lossy and are not archival masters.

The fixed profile is **libx264, veryfast, CRF 22; AAC 160k; MP4 +faststart**. There is no crop or upscale. The **oriented height** is capped at 1080, with even dimensions for encoder compatibility; width is not capped at 1920. This is the tool's own profile, with no claim of equivalence to another application's preset. Results vary; a valid output can be larger than its source.

## Download and extract

1. Open the [repository](https://github.com/PikkuJanne/WinVidCompress), select the branch or commit you intend to use, then choose **Code > Download ZIP**. A source ZIP is a development snapshot; this guide does not advertise a new packaged release.
2. Use **Extract All** into a folder you can read and write. Run from the extracted folder, not inside the ZIP. Keep `WinVidCompress.ps1` and `WinVidCompress.bat` together; retain `README.md`, `docs/user` and `LICENSE` for reference. Avoid `%NAME%` segments anywhere in the installation path.
3. Obtain Windows `ffmpeg.exe` and `ffprobe.exe` from a Windows build provider linked by the [FFmpeg download page](https://ffmpeg.org/download.html). Follow that provider's integrity checks and keep the build updated. Choose a build with libx264, AAC, MP4/faststart, scale and FFprobe JSON/CSV support. FFmpeg is a separate dependency with [build-dependent licensing](https://ffmpeg.org/legal.html).
4. The simplest setup is to copy both executables from that build's `bin` folder next to the two scripts. Alternatively, use an existing PATH installation. **PATH takes precedence** over adjacent executables; the diagnostic step below shows which copies will run. WinVidCompress does not install or update them.

Use Windows PowerShell **5.1**, already used by the BAT launcher, or a supported stable **PowerShell 7** for direct PS1 commands. Recorded Windows tests include 5.1.26100.9444 and 7.6.6. Python, Git, Pester and an administrator account are not application requirements.

## Check setup and make a first copy

Open PowerShell in the extracted folder. Create a separate, existing output folder, for example `D:\Output`, and substitute your actual paths below. Use a short disposable or approved source copy for the first run.

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\WinVidCompress.ps1 -CheckEnvironment -OutputDir 'D:\Output'
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\WinVidCompress.ps1 -Unattended -WhatIf -OutputDir 'D:\Output' 'D:\Sources'
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\WinVidCompress.ps1 -Unattended -OutputDir 'D:\Output' 'D:\Sources'
```

For PowerShell 7 use `pwsh.exe` in place of `powershell.exe`. `-ExecutionPolicy Bypass` here applies to the new process only, as it does in the BAT launcher. It does not change the saved machine/user policy. Respect organizational policy; see [blocked script troubleshooting](docs/user/TROUBLESHOOTING.md#script-or-dependency-is-blocked).

The **doctor** (`-CheckEnvironment`) reports exact dependency paths, versions, capabilities and output access. It creates and removes an owned temporary write-test file in the existing destination, but creates no output folders, preferences or backups. Capacity is advisory. The **preview** (`-WhatIf`) prints estimated destinations without native tools, writes, logs or config recovery; it does not prove media validity or writability. These two commands are separate.

The conversion prints stream selection, progress, per-job outcomes and a summary. A `Done` result means encoding, structural checks and final publication succeeded. Play the copy to check picture, orientation, speech/sync and detail before relying on it. Structural validation does not establish full visual/audio integrity. These per-run `-OutputDir` commands leave a missing preference file absent.

## Everyday use

Double-click `WinVidCompress.bat` to open the menu:

1. Set output folder and save it.
2. Compress one file by pasting its literal path.
3. Compress videos in a folder recursively.
4. Quit to the retained PowerShell prompt; type `exit` to close the window.

Ordinary first startup creates `%APPDATA%\WinVidCompress\config.json` with the Windows **Videos known folder**, which may be redirected and is not necessarily `%USERPROFILE%\Videos`. It must be available. Subsequent runs use the saved output directory. Option 1 can create a folder you explicitly choose. CLI `-OutputDir` requires an existing directory and applies only to that run.

Drag one file, one folder or several files/folders onto the BAT to queue them. Folders are recursive; eligible paths are deduplicated and sorted before encoding. Keep output separate from input so later folder runs do not pick up previous compressed copies. The default output is **flat**: `Band 29092025.mov` becomes `Band 29092025.mp4` directly in the output folder. Occupied names get ` (compressed)`, then ` (compressed 2)`, etc. Sources and existing finals are never replaced. A normal rerun makes another safely named copy; it does not automatically resume.

Supported extension candidates are `.mp4`, `.mov`, `.mkv`, `.m4v`, `.avi`, `.mpg`, `.mpeg`, `.mts`, `.m2ts` and `.wmv`. Actual codecs, geometry and colour must pass inspection; an extension alone does not guarantee support. Linked/reparse-point inputs are reported as scan errors rather than traversed.

**BAT path limits:** `%NAME%` segments such as `%PATH%` are unsupported in source and installation paths. Use menu option 2/3 or direct PS1 with single-quoted literal paths. An outer CMD with delayed expansion can also change `!NAME!`. In CMD/BAT omit a quoted folder's trailing backslash; for a drive root use `D:\.` or paste `D:\` in the menu. CMD's 8191-character command-line limit includes all expanded paths/quotes; drop a folder or use smaller selections for a large batch.

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\WinVidCompress.ps1 -Unattended -OutputDir 'D:\Output' 'D:\Sources\literal %PATH% !NAME!.mov'
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-Help .\WinVidCompress.ps1 -Full"
```

For a CMD/BAT unattended call, put the switch **first**:

```bat
WinVidCompress.bat -Unattended -OutputDir "D:\Output" "D:\Sources"
```

Unattended runs open no menu and do not pause. Direct PS1 batches return the application exit code. Default BAT runs retain a prompt; the batch result is in `$LASTEXITCODE`, separate from the later shell exit. `-KeepOpen` is for that wrapper and cannot combine with `-Unattended`.

| Code | Application result |
| --- | --- |
| 0 | No failures, including valid collision skips; menu Quit/selection cancellation before a batch |
| 1 | Job or scan failure |
| 2 | Startup/configuration error, invalid options, invalid or empty requested batch |
| 3 | Observed application cancellation; takes precedence |

Use Ctrl+C to cancel a running job. Completed finals remain; interrupted jobs may retain diagnostics/partials. Physical Ctrl+C has owner-observed passing evidence in five supported launch modes. Console close, Ctrl+Break, crashes and power loss have broader unverified limits. PowerShell parse/binding errors can produce shell-specific exit codes.

## Media, metadata and optional controls

The tool encodes the first real video stream by index, excluding cover art, and one audio stream: the unique default, otherwise the first by index. Silent input stays silent. Other video/audio streams, subtitles, source data and attachments are omitted and listed. No frame-rate or channel-count override is added. Output is 8-bit `yuv420p` SDR compatibility; detected HDR is refused and no tone mapping is provided. Ambiguous colour metadata warns and does not establish colour fidelity or absence of HDR.

The base filename supplies the title. A valid `Band Name ddmmyyyy`, `Band Name dd.mm.yyyy` or `Band Name dd-mm-yyyy`, optionally followed by ` - ...`, also supplies artist, calendar date and an interview comment. Bad/ambiguous dates warn without blocking conversion. Compatible source tags can remain; compression **does not sanitize private metadata**.

See the [option and media reference](docs/user/REFERENCE.md) for `-CollisionMode`, `-PreserveSubfolders`, validated opt-in manifest/resume, exact geometry/colour policies and metadata precedence. See [troubleshooting](docs/user/TROUBLESHOOTING.md) for config recovery, offline drives, failed probes, larger outputs and cancellation. [Verification and support limits](docs/user/VERIFICATION.md) link each capability to completed acceptance evidence and distinguish local test extraction from release/package acceptance. Developer measurements are in the [benchmark guide](docs/benchmarks/README.md); the production quality profile remains unchanged.

## Privacy and license

Compression runs on your machine. There are no application uploads, telemetry, accounts or automatic dependency downloads. Explicit UNC inputs/outputs can access network shares. Config, local logs, manifests and outputs can contain private paths, filenames and metadata; review them before sharing any diagnostic report. Logs are under `%APPDATA%\WinVidCompress\logs`; old logs are not deleted automatically.

Project code uses the [Unlicense](LICENSE), without warranty. External FFmpeg binaries retain their own licensing. Keep originals and review the results for your intended use.
