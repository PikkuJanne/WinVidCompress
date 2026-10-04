# WVC-M0-02 evidence — baseline characterization and helper loading

Recorded 2026-10-04. Acceptance A01 through A04 passed for this bounded task. Implementation/tested commit: `a1e22e4a1f6eec9ca56e0e58e8d624155f627342`. Exact commands/host outcomes: [JSON](WVC-M0-02.json). [Session](WVC-M0-02-session.md).

## Changes and reconciliation

Initial feature checkout was clean at `4e4d241b1d0e4eae1482bee9076e7b147dc15887`, matching live endpoints. Origin identity, upstream, conflicts/operations and hooks were inspected; no active project hooks or unexpected guidance existed. Fetch revealed owner-merged PR #1, main `778f5678d115cfefe863b9e7cb7f1d1cf4520dee`, a descendant with an identical tree. Created `codex/wvc-m0-02-characterization` from current main; no unknown work discarded/reset/stashed/cleaned or history rewritten.

Only application edit: comment and `if ($MyInvocation.InvocationName -eq '.') { return }` before Main. Dot-source loads helpers/defaults without Ensure-Tool, Load-Config or TUI startup. Normal invocation retains existing statements/functions. BAT/README/license/assets have no diff from inspected main. Defaults remain libx264 / veryfast / CRF 22 / AAC 160k / MP4 +faststart.

Tests capture exact default argument ordering, filename metadata, height-cap/no-upscale construction, collision suffixes/sentinel hashes, valid isolated config and recursive enumeration. Encoder/probe doubles avoid encoding. A lower-level discovery tripwire protects the first include if the seam regresses. Real TUI is never executed: dispatch is mocked and Quit reproduced using the real extracted switch in a bounded synthetic loop.

Native smoke runs actual -File on both hosts and original BAT with a working two-video folder, fixture APPDATA/config/output/PATH, generated native recorder and controlled stdin for -NoExit. Captured paths, Done=2/Failed=0, absent media output and unchanged source hashes are checked. Fixture binaries/config remain outside Git. Cleanup checks absolute containment and owned directory names; timeout stops only the owned process tree, retaining fixtures on termination failure.

Scope expansion is only required tracker/evidence/continuity records. Full tiered harness, persistent setup/encoding policy and real generated media remain M0-03.

## Results

Host: Windows 11 Pro 10.0.26300. Pester 5.7.1 and analyzer 1.24.0 explicitly prepared in an external temporary developer directory; checked against [Pester package](https://www.powershellgallery.com/packages/Pester/5.7.1) and [analyzer release](https://github.com/PowerShell/PSScriptAnalyzer/releases/tag/1.24.0). Package hashes/exact commands are in JSON. No persistent policy change or application dependency installation occurred.

| Run | Host | Passed | Failed | Skipped | Excluded/not_run | Exit |
|---|---|---:|---:|---:|---:|---:|
| Positive characterization | Windows PowerShell 5.1.26100.9444 Desktop | 22 | 0 | 0 | 5 | 0 |
| Positive characterization | PowerShell 7.6.5 Core | 22 | 0 | 0 | 5 | 0 |
| Separate KnownDefect | Windows PowerShell 5.1.26100.9444 Desktop | 0 | 5 | 0 | 22 | 1 |
| Separate KnownDefect | PowerShell 7.6.5 Core | 0 | 5 | 0 | 22 | 1 |
| Native entry smoke | Actual -File 5.1, -File 7, original BAT | 3 | 0 | 0 | 0 | 0 |

Five desired assertions fail on both hosts: Quit repeats the outer loop; `{}` config throws missing OutputDir; empty folder throws missing FullName; single-video folder and explicit single file throw missing Count. These are baseline failures for M1-01/M1-03/M1-04, not passed tests or desired behavior. Explicit single-file failure also occurred in an initial native entry attempt; the working folder route was verified separately.

Quick on tested commit: parse/load pass on both hosts; analyzer 1.24.0 under PS7 reports zero error-severity diagnostics across application and three test PS1 files. Legacy warning/style debt remains. `python -B tools/codex-winvidcompress/validate_tracker.py --repo .` passes (32 tasks/128 criteria/23 mappings). `git -c core.whitespace=cr-at-eol diff --check` passes with original CRLF preserved. Staged checks/intended-file review passed.

Early exploratory Pester execution was policy-blocked, not a demonstrated pre-seam failure. Final commands use process-local Bypass as the existing launcher does. An early config defect test lacked a fixture directory; corrected before the tested commit, after which the actual OutputDir exception reproduced. Exploratory outcomes are separate from final evidence.

## Acceptance and limits

- A01: fixture isolation, no config creation on include, discovery tripwire, mocked startup and owned native smoke roots. No actual TUI or real APPDATA/Videos test access.
- A02: exact ordered argument assertion retains every default; height-cap and metadata pass on both hosts.
- A03: actual direct/original launcher flow passes for the existing working two-video-folder route. No-argument dispatch mocked; explicit single-file Count defect separately recorded.
- A04: both real Windows shells launched separately; version/result/exit summaries reviewed independently. This is platform characterization, not Explorer/owner approval.

FFmpeg/FFprobe remain absent on PATH/adjacent. No real encoding, structural validation, full visual/audio integrity, playback, Explorer/drag-drop, interactive menu, comprehensive special-character native argv, benchmark or full milestone run claimed. Recorders do not establish future encoder safety. Manual Explorer acceptance remains outstanding. No private videos/config/raw logs/secrets or executables are committed.

Draft [PR #2](https://github.com/PikkuJanne/WinVidCompress/pull/2): open against main; implementation head matches above. Zero GitHub check/workflow runs at that commit; no CI pass. Implementation push/live sync passed at `2026-10-04T15:51:43.173257+00:00`, local/live fetch/live push equal tested SHA, matching upstream, clean/no operations.

Final handoff push/check is pending when committed. Report final SHA/live equality externally to avoid self-SHA. No agent main push/merge, quality change, release/settings change or deployment. Next **WVC-M0-03 — Establish the regression harness and generated fixtures**; no blocker to that bounded developer task.
