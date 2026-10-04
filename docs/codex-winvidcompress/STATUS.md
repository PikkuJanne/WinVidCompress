# Current programme status

Updated: 2026-10-04. Repository: `PikkuJanne/WinVidCompress`.

`WVC-M0-01`, `WVC-M0-02` and `WVC-M0-03` are verified for their bounded acceptance criteria. The remaining 29 tasks are `todo`, with 116 acceptance criteria `not_run`. TASKS.json is the status authority. No milestone/release or owner acceptance is claimed.

## Actual repository and reconciliation

- Root: `D:/projects/WinVidCompress-main`.
- Branch: `codex/wvc-m0-03-harness`; upstream: `origin/codex/wvc-m0-03-harness`.
- Effective origin fetch/push: `https://github.com/PikkuJanne/WinVidCompress.git`, one destination each.
- Initial checkout: clean M0-02 feature HEAD `cef0fa39262a47f04634b0a90106a89536dccddd`, matching both live endpoints, no operations/conflicts or unknown changes.
- Fetch revealed the owner's merge of PR #2. Main `d1b28add3cd72375ff15ac6a3c625e4de619c8c8` is a descendant with an identical tree. PR #2 is merged, rather than still draft as the prior handoff recorded.
- Created this task branch from that inspected main. Historical BASELINE.json was compared, never used as a reset target. No stash/reset/clean/history rewrite occurred.
- M0-03 implementation checkpoints: `7d37d0ef80238d9482fec4976dc377487f7b4818` and final tested `dffc714ba3f6269f12e8e88056f49bae345ead68`. Application PS1/BAT, original README/license/assets and default quality are unchanged in this task.

## Evidence and limitations

Evidence: [WVC-M0-03.md](evidence/WVC-M0-03.md), [JSON](evidence/WVC-M0-03.json), [session](evidence/WVC-M0-03-session.md). Earlier [M0-02 evidence](evidence/WVC-M0-02.md) remains the application characterization baseline.

Windows 11 Pro 10.0.26300. Separately tested Windows PowerShell 5.1.26100.9444 Desktop and PowerShell 7.6.5 Core. Developer pins are Pester 5.7.1 and PSScriptAnalyzer 1.24.0; reused external temporary modules, with no dependency download in M0-03 or application runtime dependency added.

Final exact-commit outcomes:

| Run | Passed | Failed | Skipped | NotRun | Exit |
|---|---:|---:|---:|---:|---:|
| Quick, each PS5.1/PS7 host | 59 | 0 | 0 | 5 | 0 |
| Targeted, each PS5.1/PS7 host | 70 | 0 | 4 | 5 | 0 |
| Full, both required hosts | 125 | 10 | 4 | 8 | 1 |
| Manual checklist, unexecuted | 0 | 0 | 0 | 7 | 2 |
| Explicit absent required PS7, Quick | 4 | 0 | 1 | 0 | 2 |
| PS5.1 supplied as PS7, Targeted | 14 | 0 | 6 | 0 | 2 |

Quick's passing count combines 55 individual Pester checks and four static/schema gates. Targeted adds three native recorder entry cases and eight copied/hashed synthetic probe JSON cases. Four one-second synthetic media recipes are implemented but skipped because FFmpeg/FFprobe are unavailable. Actual generation/probing and visual/audio integrity have not been verified.

Full's ten failures are the same five baseline application assertions on each host: Quit repeats; `{}` configuration throws on OutputDir; empty-folder FullName throws; single-video folder and explicit single-file Count throw. These remain for M1-01/M1-03/M1-04. Full is a failed gate, not application/release verification. Seven actual manual checks and future media/CLI/safety/packaging coverage remain NotRun.

Mixed pass/fail/skip child execution, all-skipped suites, invalid/count-mismatched/duplicate child reports, missing/mislabelled hosts, native argument quoting, owned cleanup and fixture failure paths have regression coverage on both hosts. Repeating clean-commit PS7 Quick produced byte-identical reports. Nested tests are discovered automatically in stable path order. Tracker and CRLF-aware whitespace checks pass; no private media/config/paths/logs/executables are committed.

No actual Explorer drag/drop, double-click menu, real cancellation, playback/colour judgement, UNC/long-path or benchmark acceptance ran. The native recorder smoke exercises actual PS1/BAT processes with isolated two-file synthetic inputs and creates no media.

Draft [PR #3](https://github.com/PikkuJanne/WinVidCompress/pull/3) is open against main. GitHub reports zero workflow runs and an empty PR checks list at `dffc714ba3f6269f12e8e88056f49bae345ead68`; no CI pass is claimed.

Previous verified sync: `dffc714ba3f6269f12e8e88056f49bae345ead68` at `2026-10-04T17:09:49.610890+00:00`; local HEAD equals live fetch/push feature refs, matching upstream, clean worktree, no operations/conflicts. This applies only to that checkpoint.

Final evidence handoff push/check is pending when this file is committed. Report final SHA equality externally after commit/push; independently verify at the next session. This agent performed no main push/merge, release, settings/secrets change, deployment or quality change.

Next: **WVC-M1-01 — Repair menu exit and separate source/output folder selection**. No blocker to that bounded task; encoder/media/manual acceptance gaps remain explicit.
