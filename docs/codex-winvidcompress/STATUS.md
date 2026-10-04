# Current programme status

Updated: 2026-10-04. Repository: `PikkuJanne/WinVidCompress`.

`WVC-M0-01` and `WVC-M0-02` are verified for their bounded acceptance criteria. M0-02 implementation/tested commit: `a1e22e4a1f6eec9ca56e0e58e8d624155f627342`. The remaining 30 tasks are `todo`, with 120 acceptance criteria `not_run`. TASKS.json is the status authority. No milestone/release or owner acceptance is claimed.

## Actual repository and reconciliation

- Root: `D:/projects/WinVidCompress-main`.
- Branch: `codex/wvc-m0-02-characterization`; upstream: `origin/codex/wvc-m0-02-characterization`.
- Effective origin fetch/push: `https://github.com/PikkuJanne/WinVidCompress.git`, one destination each.
- Initial checkout: clean M0-01 feature HEAD `4e4d241b1d0e4eae1482bee9076e7b147dc15887`, matching both live endpoints, no operations/conflicts.
- Fetch revealed the owner's merge of PR #1. Main is `778f5678d115cfefe863b9e7cb7f1d1cf4520dee`, a descendant with an identical tree. PR #1 is merged, rather than still draft as the prior handoff recorded.
- Created this task branch from inspected current main. Historical BASELINE.json was compared, never used as a reset target. No unknown changes were present; no stash/reset/clean/history rewrite occurred.
- Application edit: three lines before Main permit dot-source helper loading without startup. Existing functions/default quality/normal entry flow and the original BAT remain. README/license/assets are unchanged.

## Evidence and limitations

Evidence: [WVC-M0-02.md](evidence/WVC-M0-02.md), [JSON](evidence/WVC-M0-02.json), [session](evidence/WVC-M0-02-session.md).

Windows 11 Pro 10.0.26300. Separately tested Windows PowerShell 5.1.26100.9444 Desktop and PowerShell 7.6.5 Core. Pester 5.7.1 and PSScriptAnalyzer 1.24.0 were prepared only in an external temporary developer directory; neither is an application dependency.

- Positive characterization on each host: 22 passed, 0 failed, 0 skipped, 5 excluded/not_run; exit 0.
- Separate KnownDefect run on each host: 0 passed, 5 failed, 0 skipped, 22 excluded/not_run; exit 1. Desired assertions fail for Quit repeating, missing OutputDir in valid JSON, empty-folder FullName access, single-video-folder Count access and explicit single-file Count access. These remain defects for M1-01/M1-03/M1-04, not endorsed behavior.
- Native entry smoke: 3 passed/0 failed/0 skipped, exit 0. Actual PS1 -File on both hosts and unchanged BAT process a two-video synthetic folder with native recorders; captured paths/counters and source hashes checked. Recorder produces no media.
- Quick: parse/load checks pass on both hosts; analyzer error-severity scan returns zero diagnostics across four PS1 files; tracker valid with 32 tasks/128 criteria/23 mappings; CRLF-aware whitespace passes.
- Tests isolate APPDATA/output/source roots. Real TUI, user configuration and user Videos are not exercised. Collision sentinels remain unchanged under mocks.

FFmpeg/FFprobe remain unavailable on PATH/adjacent. No real encoding, media validation/playback, Explorer drag/drop, interactive menu, comprehensive native special-character argv or benchmark result is claimed. Manual Explorer/release acceptance remains outstanding. Full harness/setup/fixture/encoding policy belongs to M0-03.

Draft PR: [#2](https://github.com/PikkuJanne/WinVidCompress/pull/2), open against main. At the implementation checkpoint GitHub reports zero workflow runs/check runs and an empty PR checks list; no CI pass is claimed.

Previous verified sync: `a1e22e4a1f6eec9ca56e0e58e8d624155f627342` at `2026-10-04T15:51:43.173257+00:00`; local HEAD equals live fetch/push feature refs, matching upstream, clean worktree, no operations/conflicts. This applies only to that checkpoint.

Final evidence handoff push/check is pending when this file is committed. Report final SHA equality externally after commit/push; independently verify at the next session. This agent performed no main push/merge, release, settings/secrets change, website deployment or quality change.

Next: **WVC-M0-03 — Establish the regression harness and generated fixtures**. No blocker to that bounded developer task; known application defects and untested media/manual paths remain explicit.
