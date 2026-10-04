# Product contract

## Preserve by default

The tool remains a Windows 11 local PowerShell application driving external FFmpeg/FFprobe. Preserve `.ps1`/`.bat` entry points, the simple text menu, direct CLI use, drag/drop of files/folders, sequential recursive batches, a remembered output directory, filename-derived interview tags and non-blocking metadata parsing.

Keep H.264/libx264, preset veryfast, CRF 22, AAC 160 kbps, MP4 with +faststart. Keep no crop/no upscaling, a height-cap rather than an unapproved 1920x1080 box, no arbitrary forced frame rate, and no silent stereo downmix. Flat layout and safe collision renaming remain defaults. A rerun is not implicitly a request for resume; resume and stronger identity checks are opt-in.

Source videos and pre-existing outputs are immutable inputs to the tool. Never delete a source to save space, encode over it, replace an existing result with a partial, or auto-lower quality to make a file smaller. A compressed copy is not a lossless archival master.

## Intended hardening

Correct broken control flow, unsafe path handling and inconsistent config recovery. Make queue contents deterministic; ensure the inspected stream is the encoded stream; use owned temp files and no-clobber promotion; validate success rather than trusting exit zero alone. New CLI switches do not add prompts to the default workflow.

Unattended invocations must not prompt or linger in an interactive shell. Preserve interactive window-readability intentionally, with a documented distinction from unattended operation. Unsupported/corrupt inputs should produce a clear failed job, not hang the whole batch.

## Deliberately out of scope

No upload website, server-side FFmpeg, processing accounts, cloud queue, GUI framework rewrite, GPU/HEVC/AV1 mode expansion, parallel encoder orchestration, auto-updater, automatic tone-mapping or silent FFmpeg installation. Python helper scripts in this handoff are developer-only; no Python dependency may be added to the distributed video tool.

## Definitions

`Found` means the deterministic unique eligible queue count, not the raw number of duplicate selections. Scan errors are separately counted. `Done` means encoding succeeded, structural validation passed, and no-clobber final promotion succeeded. An intentional valid skip is not a failed encode. `Cancelled` and `Failed` remain distinguishable. An unknown input duration is not zero. `Synced` refers to one named clean local branch matching the live GitHub branch at a recorded check, not an assurance that main has been merged or a website deployed.
