# Next session

Next: **WVC-M1-01 — Repair menu exit and separate source/output folder selection**.

Use installed NEXT_THREAD_PROMPT.md. Stop after that bounded task; do not reimport the bundle or implement all of M1.

## Start from actual state

- Root `D:/projects/WinVidCompress-main`; branch `codex/wvc-m0-03-harness`; upstream `origin/codex/wvc-m0-03-harness`.
- Verified effective origin fetch/push: `https://github.com/PikkuJanne/WinVidCompress.git`.
- Final implementation/tested checkpoint `dffc714ba3f6269f12e8e88056f49bae345ead68`; initial implementation `7d37d0ef80238d9482fec4976dc377487f7b4818`.
- Previous clean live-ref equality at `2026-10-04T17:09:49.610890+00:00` applies only to the implementation checkpoint. Final evidence handoff SHA is reported externally after push; inspect current HEAD independently.
- Draft [PR #3](https://github.com/PikkuJanne/WinVidCompress/pull/3) is open against main; no workflow/check runs existed at the final implementation checkpoint.
- Owner merged PR #2 before this session. Inspected main was `d1b28add3cd72375ff15ac6a3c625e4de619c8c8`, identical in tree to final M0-02 feature HEAD. This task branch began from that live main.

Read AGENTS.md, INDEX/STATUS, GIT_SYNC, TASKS.json, M1-01 brief and PRODUCT_CONTRACT; consult TESTING and M0-03 evidence/tests. Inspect branch/status/upstream/operations/conflicts/URLs and HEAD; run `git fetch --no-tags origin`, then `python -B tools/codex-winvidcompress/check_repo_sync.py --repo "D:/projects/WinVidCompress-main"`.

Preserve unknown changes and reconcile live main/feature histories. If PR #3 merged, start from inspected current main; otherwise retain M0-03 ancestry for the next `codex/wvc-*` branch. Do not discard the harness or rely solely on a cached remote ref. No concurrent writer may use the same checkout/branch.

## Exact bounded next action

Repair Quit with a function return or correct outer-loop exit; preserve the caller runspace. Separate validation of an existing source directory from creation of an explicitly selected output directory. Retain the four-option menu and blank-to-cancel behavior, use literal paths for brackets/Unicode, and report permission errors clearly.

Add focused tests under `tests/unit/*Menu*` and `tests/unit/*Path*`; nested `*.Tests.ps1` files are now automatically discovered. Move the repaired Quit assertion out of KnownDefect coverage. Do not silently repair the unrelated configuration/enumeration defects in this task.

Run Quick and relevant Targeted coverage on both real hosts using `tools/test.ps1`. `tests/README.md` documents pins, setup and report/exit semantics. Developer modules currently exist in an external temporary M0-02 directory; they may not persist. The runners do not download them. Use new report paths and fixture-local APPDATA/output/source roots.

M1-01-A04 requires an actual Windows double-click/menu/Quit check in the launcher's documented console state. Recorder/mocked coverage cannot pass that criterion. Record exact manual actions and actual outcome, or retain pending acceptance honestly.

## Outcomes and limits

Final clean M0-03 implementation: each real host Quick 59 passed/0 failed/0 skipped/5 NotRun, exit 0; Targeted 70 passed/0 failed/4 skipped/5 NotRun, exit 0. Full 125 passed/10 failed/4 skipped/8 NotRun, exit 1. Manual 7 NotRun, exit 2. Missing/wrong-version host probes return incomplete exit 2 without falsely claiming PS7 execution. Repeated PS7 Quick reports were byte-identical.

Full failures are five baseline assertions on each host: Quit repeats; `{}` config property access throws; empty-folder FullName throws; single-video folder and explicit single-file Count throw. The last four belong to M1-03/M1-04. Full remains failed until repaired; it is not a passing milestone/release gate.

FFmpeg/FFprobe were absent from PATH, adjacent files and inspected bundled dependency tree. Four one-second media recipes are implemented but real generation/probing is untested. Eight hand-authored synthetic probe JSON cases are available. No real media, Explorer, cancellation, playback/colour, UNC/long-path or benchmark pass is claimed.

Available: Windows 11 Pro build 26300, PS5.1.26100.9444, PS7.6.5, Pester 5.7.1, analyzer 1.24.0, Python 3.14.7, Git 2.56.0.windows.1, GitHub CLI 2.97.0. PS1/BAT/default quality remained unchanged in M0-03.

No owner decision blocks M1-01. End with task/evidence/STATUS/NEXT_SESSION/session updates, intentional commits, explicit feature push, live fetch/push equality and clean-state check, plus a draft PR. Main merges/pushes, tags/releases, settings/secrets, dependency bundling/signing, deployment and default-quality changes require explicit owner approval.
