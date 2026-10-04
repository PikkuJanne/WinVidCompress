# Current programme status

Updated: 2026-10-04. Repository: `PikkuJanne/WinVidCompress`.

M0-01/M0-02/M0-03 are verified for their bounded criteria. **WVC-M1-01 is implemented with A01-A03 passed; A04 actual Explorer observation remains not_run.** The remaining 28 tasks are todo; 113 criteria remain not_run. TASKS.json is the authority. No milestone/release or owner acceptance is claimed.

## Repository and reconciliation

- Root `D:/projects/WinVidCompress-main`; branch `codex/wvc-m1-01-menu-paths`, upstream `origin/codex/wvc-m1-01-menu-paths`.
- Origin fetch/push: `https://github.com/PikkuJanne/WinVidCompress.git`, one destination each.
- Initial checkout clean at M0-03 handoff `2a103b6ff4274208be6ac70bcbdb8f0a8ecf123d`, matching both live endpoints; no unknown changes, operations/conflicts or active hooks.
- Owner merged PR #3 before this session. Fetch found main `e8b54d1fdd03bdd3e0135c67c38335788a6f8112`, a descendant with the identical tree. Created this task branch from that inspected main. No reset/stash/clean/history rewrite.
- Implementation/tested commit `6337b73d41cf65b9f12cb412800bc3d68780693c`. Quit returns to its caller. Source selection validates an existing literal path; only explicit output selection can create a directory. Access/creation errors display the actual diagnostic and allow retry/cancel.
- Four-option workflow, defaults/quality, source processing and BAT bytes retained. PS1 existing encoding/CRLF preserved by bounded ASCII edits; help documents BAT's retained PowerShell prompt.

## Actual evidence

[Evidence](evidence/WVC-M1-01.md), [exact JSON commands/results](evidence/WVC-M1-01.json), [session](evidence/WVC-M1-01-session.md). Prior [M0-03 harness evidence](evidence/WVC-M0-03.md) remains historical.

Windows 11 Pro 10.0.26300; separately tested PS5.1.26100.9444 Desktop and PS7.6.5 Core. Pester 5.7.1/analyzer 1.24.0 reused externally; no dependency download.

| Clean implementation run | Passed | Failed | Skipped | NotRun | Exit |
|---|---:|---:|---:|---:|---:|
| Quick, each host | 79 | 0 | 0 | 4 | 0 |
| Targeted, each host | 93 | 0 | 4 | 4 | 0 |
| Full, both hosts | 168 | 8 | 4 | 8 | 1 |

Quick includes 75 Pester checks and four static/schema gates. Twenty focused menu/path checks cover caller survival, real menu/prompt selection, missing-source preservation, explicit output creation, cancellation, literal bracket/Finnish/German/CJK paths, existing-file/neighbor sentinels and permission/creation diagnostics. The repaired obsolete AST-only Quit probe was replaced with normal menu coverage.

Targeted adds six native PS1/BAT batch/menu cases and eight copied/hashed synthetic JSON fixtures. BAT's scripted menu case executes a split output marker after Quit, proving its retained shell survives without accepting echoed input. Scripted stdin is not actual Explorer/manual acceptance.

Full's eight failures are four remaining baseline assertions per host: wrong-shaped valid JSON/config recovery, empty-folder FullName, single-video folder Count, explicit single-file Count. These remain M1-03/M1-04 work. Full is failed, not verified application/release acceptance. Four media recipes skip because FFmpeg/FFprobe are absent; eight broader manual/future records remain NotRun.

## Pending criterion and continuity

M1-01-A04 requires actual human Explorer double-click/menu/Quit observation. Native desktop control is disabled here. An isolated manual fixture is prepared, and the user was asked to observe it; no response/result recorded yet. Its wrapper isolates APPDATA/PATH before calling byte-identical PS1/BAT copies with startup-only dependency sentinels. Preparation/native stdin does not pass A04. Real media, Explorer argv/drag-drop, playback, cancellation, UNC/long-path and benchmarks remain untested.

Draft [PR #4](https://github.com/PikkuJanne/WinVidCompress/pull/4) open against main. No workflow runs or PR checks at the tested implementation; no CI pass.

Previous verified sync: `6337b73d41cf65b9f12cb412800bc3d68780693c` at `2026-10-04T17:27:56.672063+00:00`; local/live fetch/live push heads equal, clean, matching upstream, no operations/conflicts. This only describes that implementation checkpoint. Final handoff push/check is pending when committed and reported externally afterwards, without a self-SHA loop.

Exact next action: **complete WVC-M1-01-A04** with the actual Explorer observation. Next bounded coding task: **WVC-M1-02 — Harden the .bat launcher using measured argument round trips**. No automated implementation blocker; manual evidence is pending. This agent made no main push/merge, release/deployment/settings/secrets or quality change.
