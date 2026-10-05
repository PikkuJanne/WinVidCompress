# Current programme status

Updated: 2026-10-05. Repository: `PikkuJanne/WinVidCompress`.

M0-01/M0-02/M0-03/M1-01 are verified for their bounded criteria. **The owner confirmed M1-01's actual Explorer A04 steps on 2026-10-05; all four criteria pass.** The remaining 28 tasks are todo; 112 criteria remain not_run. TASKS.json is the authority. No broader milestone/release acceptance is claimed.

## Repository and reconciliation

- Root `D:/projects/WinVidCompress-main`; branch `codex/wvc-m1-01-menu-paths`, upstream `origin/codex/wvc-m1-01-menu-paths`.
- Origin fetch/push: `https://github.com/PikkuJanne/WinVidCompress.git`, one destination each.
- Initial checkout clean at M0-03 handoff `2a103b6ff4274208be6ac70bcbdb8f0a8ecf123d`, matching both live endpoints; no unknown changes, operations/conflicts or active hooks.
- Owner merged PR #3 before this session. Fetch found main `e8b54d1fdd03bdd3e0135c67c38335788a6f8112`, a descendant with the identical tree. Created this task branch from that inspected main. No reset/stash/clean/history rewrite.
- Implementation/tested commit `6337b73d41cf65b9f12cb412800bc3d68780693c`. Quit returns to its caller. Source selection validates an existing literal path; only explicit output selection can create a directory. Access/creation errors display the actual diagnostic and allow retry/cancel.
- Four-option workflow, defaults/quality, source processing and BAT bytes retained. PS1 existing encoding/CRLF preserved by bounded ASCII edits; help documents BAT's retained PowerShell prompt.
- Confirmation follow-up began clean at `17a49c0cd9c8193b983b0acfc3bbcfeea3e03aae`; fetch revealed no newer main/feature change. Only documentation changes in this follow-up, with original automated results retained.

## Actual evidence

[Evidence](evidence/WVC-M1-01.md), [exact JSON commands/results](evidence/WVC-M1-01.json), [session](evidence/WVC-M1-01-session.md). Prior [M0-03 harness evidence](evidence/WVC-M0-03.md) remains historical.

Windows 11 Pro 10.0.26300; separately tested PS5.1.26100.9444 Desktop and PS7.6.5 Core. Pester 5.7.1/analyzer 1.24.0 reused externally; no dependency download.

| Clean implementation run, 2026-10-04 | Passed | Failed | Skipped | NotRun | Exit |
|---|---:|---:|---:|---:|---:|
| Quick, each host | 79 | 0 | 0 | 4 | 0 |
| Targeted, each host | 93 | 0 | 4 | 4 | 0 |
| Full, both hosts | 168 | 8 | 4 | 8 | 1 |

Quick includes 75 Pester checks and four static/schema gates. Twenty focused menu/path checks cover caller survival, real menu/prompt selection, missing-source preservation, explicit output creation, cancellation, literal bracket/Finnish/German/CJK paths, existing-file/neighbor sentinels and permission/creation diagnostics. The repaired obsolete AST-only Quit probe was replaced with normal menu coverage.

Targeted adds six native PS1/BAT batch/menu cases and eight copied/hashed synthetic JSON fixtures. BAT's scripted menu case executes a split output marker after Quit, proving its retained shell survives without accepting echoed input. Scripted stdin is not actual Explorer/manual acceptance.

Full's eight failures are four remaining baseline assertions per host: wrong-shaped valid JSON/config recovery, empty-folder FullName, single-video folder Count, explicit single-file Count. These remain M1-03/M1-04 work. Full is failed, not verified application/release acceptance. Four media recipes skip because FFmpeg/FFprobe are absent; eight broader manual/future records remain NotRun.

## Manual confirmation and continuity

On 2026-10-05 the owner quoted and confirmed the actual Explorer double-click Check-Menu.bat / enter 4 / usable PowerShell prompt / exit steps: A04 has 1 manual pass, 0 failed/skipped/NotRun. Prepared PS1/BAT hashes were rechecked against the tested implementation. The wrapper isolates APPDATA/PATH and uses startup-only dependency sentinels; the observation establishes menu/console behavior. Real media, Explorer argv/drag-drop, playback, cancellation, UNC/long-path and benchmarks remain untested.

Draft [PR #4](https://github.com/PikkuJanne/WinVidCompress/pull/4) open against main. No workflow runs or PR checks at the tested implementation; no CI pass.

Previous verified sync: `17a49c0cd9c8193b983b0acfc3bbcfeea3e03aae` at `2026-10-05T12:42:56.214979+00:00`; local/live fetch/live push heads equal, clean, matching upstream, no operations/conflicts. This describes the preceding documentation checkpoint. Final confirmation handoff push/check is pending when committed and reported externally afterwards, without a self-SHA loop.

Exact next task: **WVC-M1-02 — Harden the .bat launcher using measured argument round trips**. No M1-01 blocker/remaining criterion. This agent made no main push/merge, release/deployment/settings/secrets or quality change.
