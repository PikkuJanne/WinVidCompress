# Troubleshooting

Run the [README doctor command](../../README.md#check-setup-and-make-a-first-copy) first. Preserve originals, existing outputs and diagnostics while investigating. Retry using a short source copy and a separate existing local output folder.

## Script or dependency is blocked

Extract the ZIP before running, and keep PS1/BAT together. The BAT calls the system Windows PowerShell 5.1 with a process-only execution-policy bypass. The documented direct commands use the same temporary scope. Neither changes saved machine/user policy; [Microsoft documents policy precedence and process scope](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies).

If Windows or your organization blocks the files, inspect their source and ask your administrator about the applicable policy. Do not disable antivirus, SmartScreen or permanent execution-policy restrictions to run this tool. A downloaded-file warning is not proof of a trusted publisher or a signed release.

For missing/wrong dependencies, obtain both executables from a Windows build linked by [FFmpeg](https://ffmpeg.org/download.html), follow its integrity instructions, and place them beside the scripts. PATH copies still win; check the doctor's exact paths and versions. Functions/aliases masquerading as executables are refused. A timeout, capability failure or execute/read denial needs a working accessible build; WinVidCompress does not download replacements, edit PATH or elevate.

## Output drive unavailable, full or denied

Reconnect the saved drive/share and check that the directory exists and your account can list/write it. A valid saved preference is not silently redirected to Videos when its drive goes offline. Capacity is advisory; a successful write check cannot guarantee space/access throughout an encode. UNC capacity may be unknown, and remote/disconnecting shares have broader unverified support limits.

For a temporary alternative, create a separate local folder yourself, then use `-OutputDir` on the doctor and conversion commands. The override does not save the preference. To change the saved preference, restore access to the old destination, start the menu and use option 1; if that is impossible, use the backup/reset procedure below. `-PreserveSubfolders` requires disjoint roots and refuses reparse points/unsafe descendants.

## Invalid config, recovery or reset

The preference is `%APPDATA%\WinVidCompress\config.json`. It must be a JSON object with an absolute `OutputDir`; optional `CollisionMode` is `rename` or `skip`. Unknown fields survive normal saves. A minimal example is:

```json
{"OutputDir":"D:\\Output","CollisionMode":"rename"}
```

Ordinary startup preserves malformed bytes in `config.invalid-<GUID>.json`, then recovers to the Windows Videos known folder **only if that default is available**. A normal replacement save preserves previous bytes as `config.previous-<GUID>.json`. Read/backup/write failures stop rather than intentionally deleting the original. Doctor, preview and per-run output/collision/layout controls do not repair invalid config: resolve it first. A valid offline path is an availability error, not malformed-config recovery.

For a deliberate reset:

1. Close all WinVidCompress sessions. Copy `config.json` and any useful backup to a private location.
2. In Explorer open `%APPDATA%\WinVidCompress`. Rename `config.json` to a unique unused name such as `config.saved-20261007.json`; do not overwrite an older backup.
3. Start the BAT normally. If Videos is available it creates the default config. Use option 1 to choose your output folder. Check the displayed destination before converting.

To recover a previous config, close sessions, preserve the current file under another unique name, and **copy** the chosen backup to `config.json`; keep the backup. Confirm its destination is available and run doctor before conversion. If Videos itself is unavailable, a fresh per-run `-OutputDir` can run without creating a preference, or restore an available valid saved config. Do not rename a live lock or assume deleting `config.json.lock` solves contention: close the other session and reload. Concurrent/changed-config saves refuse stale data.

## Probe failure, no video or unsupported media

Read the job's failure stage and FFprobe stderr. The listed extensions are candidates, not guaranteed decoders. Audio-only/cover-art-only inputs, malformed probe results, inaccessible/corrupt sources, unsupported geometry and detected HDR fail clearly. Ordinary failed jobs continue; check `Failed` and scan errors even if other jobs completed.

Try the source copy in a trusted player and re-run doctor with the selected dependency build. If colour/geometry is refused, export a separate conventional SDR copy using a reviewed external workflow, then retry that copy. The tool does not tone-map HDR. Ambiguous-colour warnings require your own playback judgement; do not infer fidelity from the absence of an HDR error. Never repair or overwrite the original in place.

## Output is larger, has fewer streams or different detail

CRF controls quality, not a target size. Already efficient/small inputs can grow at the fixed profile. The summary reports actual bytes and growth/reduction for completed comparable jobs; unknown sizes and other outcomes are counted separately. It does not silently lower quality or discard a valid larger copy. Retain originals and decide whether a viewing copy is useful after playback. No CRF/codec quality option is exposed.

Only one video and one audio are selected, with no audio added to silent video. Alternatives, subtitles and attachments are omitted. Output is 8-bit 4:2:0 SDR compatibility, so bit depth/chroma detail may be reduced. The console's selected/omitted stream report and [media policy](REFERENCE.md#exact-media-policy) explain these choices. Filename metadata can override compatible source fields, and other private source tags may remain.

## Failed or cancelled jobs and retained partials

Use Ctrl+C during a job; allow cleanup to finish and read the summary. Completed finals are retained. Exit 3 means observed application cancellation; exit 1 means job/scan failure and exit 2 means startup/invalid or empty requested batch. Default BAT keeps its prompt; inspect `$LASTEXITCODE` before another command changes it, then type `exit`. Physical Ctrl+C is verified in recorded supported modes; console close/Ctrl+Break/crash/power-loss/detached-descendant behavior is not fully verified.

Failed/cancelled jobs may leave `.wvc-job-<GUID>` directories containing `encode.partial.mp4` and a `retained.json` record. Native stderr is also recorded in local session logs where available. These partials are not finished MP4s. Later runs warn and skip these reserved directories; they do not auto-recover, append or delete them. Keep diagnostic artifacts until the problem is understood. Manually remove only artifacts you have identified as belonging to your stopped job, after confirming no encoder is still running; do not touch source videos or existing final files.

A plain rerun makes fresh safely renamed outputs. For a batch with an existing manifest, use the [documented resume route](REFERENCE.md#output-safety-and-retry) with the original inputs/output/hash mode. Queue/root/schema/path mismatches or strong-to-fast downgrade refuse resume; a fast-to-strong upgrade retries all jobs. Changed readable source content/settings or an invalid completed output trigger a fresh safe retry instead of a completed skip. Exact PS1 bytes are fingerprinted, so a tool update (even help comments) can trigger retries. Preserve the manifest and old outputs; a fresh batch uses a new absent manifest path. Never edit identities to force a completed skip.

## Drag/drop, scan or preview surprises

Drop onto the BAT rather than the PS1. An unexpected menu suggests the selection did not reach the script; paste one literal path into menu option 2/3. Variable-shaped `%NAME%` paths require the menu/direct PS1 route. CMD delayed expansion, trailing backslashes and total command-line length have the [documented limits](../../README.md#everyday-use).

Linked/reparse directories are not traversed. A partly failed scan can process valid files and still return 1. `Found` is the unique eligible queue count. Keep output separate from sources: the frozen queue avoids newly created files during this run, but a later recursive run can pick up old finals. `-WhatIf` is a read-only estimate; it does not probe media or prove write permissions/concurrent names. Doctor intentionally uses a temporary write check.

## Logs and bug reports

Local logs live in `%APPDATA%\WinVidCompress\logs\<GUID>` as `session.txt` and `results.jsonl`. Warnings about their 1 MiB/file or 128-session quota do not invalidate compression. Review and remove old stopped-session logs manually if needed; the tool never prunes them. Config, logs, manifest, filenames, encode arguments and metadata can disclose private information.

Use the repository's available issue-reporting route for a non-sensitive bug report. Give the source commit/version if known, Windows/PowerShell and FFmpeg/FFprobe versions, failure stage/exit, and a minimal synthetic reproduction. Do not post raw personal paths, interview names/tags, private videos, config, logs or credentials.

For a reduced export from a stopped session, open a temporary process-scoped PowerShell session using the first command below, then run the next two inside it. Substitute actual private local paths; the destination must be absent. Type `exit` when finished:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass
. .\WinVidCompress.ps1
Export-WvcDiagnostic -SessionPath 'D:\PrivateDiagnostics\results.jsonl' -DestinationPath 'D:\PrivateDiagnostics\review-before-sharing.json'
```

Dot-sourcing loads helpers without compression/menu/config writes. Default redaction removes paths/names/metadata and free-form diagnostic text, so it may omit the original error. Review the exported JSON before voluntarily sharing it and add a sanitized explanation yourself. No upload happens automatically.
