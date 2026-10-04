# Next session

Exact remaining action: **WVC-M1-01-A04 — actual Windows Explorer double-click/menu/Quit observation**. M1-01 code and automated A01-A03 are implemented/passed; do not mark verified without the manual result.

Next bounded coding task after that acceptance record: **WVC-M1-02 — Harden the .bat launcher using measured argument round trips**. Do not silently implement the rest of M1.

## Start from actual state

- Root `D:/projects/WinVidCompress-main`; branch `codex/wvc-m1-01-menu-paths`; upstream `origin/codex/wvc-m1-01-menu-paths`.
- Origin has one fetch/push destination `https://github.com/PikkuJanne/WinVidCompress.git`.
- Tested implementation `6337b73d41cf65b9f12cb412800bc3d68780693c`; prior clean live equality at `2026-10-04T17:27:56.672063+00:00` describes only that checkpoint. Final handoff SHA is externally reported after push; verify independently.
- Draft [PR #4](https://github.com/PikkuJanne/WinVidCompress/pull/4) open against main; no workflow/check runs at implementation checkpoint.
- Owner merged PR #3 before this session. Inspected main `e8b54d1fdd03bdd3e0135c67c38335788a6f8112` has the same tree as M0-03's final feature; M1-01 branch starts from it.

Read AGENTS/INDEX/STATUS/GIT_SYNC/TASKS, M1-01 evidence for the remaining manual check, then the M1-02 brief/PROCESS_AND_CLI/TESTING for launcher work. Inspect status/branch/upstream/HEAD, operations/conflicts/hooks, effective URLs and live state. Run `git fetch --no-tags origin` then `python -B tools/codex-winvidcompress/check_repo_sync.py --repo "D:/projects/WinVidCompress-main"`.

Preserve unknown changes. If PR #4 merged, start launcher work from inspected current main; otherwise retain M1-01 ancestry in the next codex/wvc-* branch. Never rely on cached refs or reset to the historical baseline. One writer only.

## Remaining actual manual check

The prior user was asked asynchronously to observe a prepared isolated fixture; no manual result has been recorded. Native desktop control is disabled in this session. If a response arrives, record the actual observer/date/result and tested copy hashes, then update M1-01-A04/status/evidence without claiming broader media/argv acceptance.

If a fresh fixture is needed, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/unit/New-MenuManualFixture.ps1
```

This outputs an owned temp root and Check-Menu.bat. In Explorer double-click that wrapper, select 4 once, confirm the menu disappears and a usable PowerShell prompt remains, then type exit. The wrapper only isolates APPDATA/PATH/PSModulePath and calls the unchanged original BAT/actual PS1 copies. Native sentinels satisfy startup lookup and fail if accidentally invoked; do not compress with them. Preparation or scripted stdin is not manual execution. Keep paths/config/exes/tokens/raw logs outside Git. After closing the owned console, clean only its returned Owner with TestSupport's Remove-WvcTestRoot.

A01-A03 cover real bounded menu behavior and literal path helper behavior on both hosts; A04 requires the actual observation. No permission decision is needed to run this isolated check.

## Subsequent launcher scope

M1-02 should measure actual argv through a dedicated recorder, remove unnecessary delayed expansion/multi-stage argument reconstruction, and preserve double-click/one-file/folder/multiple selection on PS5.1. Test spaces, !, &, parentheses, apostrophes, [], %, Finnish/German/non-Latin, literal %PATH%/!NAME! with matching variables. Do not execute payload-like names or promise unlimited Windows command lines. Missing PS1/dependencies must produce actionable errors. Several criteria require actual Windows Explorer observation.

Use the existing tier runner with nested tests automatically discovered. New PS1 stays ASCII or UTF-8 BOM; BAT CRLF. External temporary Pester 5.7.1/analyzer 1.24.0 modules may not persist; no automatic download in application/runners.

## Tested outcomes and limits

Clean implementation: each host Quick 79 passed/0 failed/0 skipped/4 NotRun, exit 0; Targeted 93 passed/0 failed/4 skipped/4 NotRun, exit 0. Full both hosts 168 passed/8 known failures/4 skipped/8 NotRun, exit 1. Counts include 75 Pester checks plus static/native/JSON cases. Twenty menu/path regressions pass per host; six native batch/menu entries pass. BAT's surviving caller is verified through a split output marker after scripted Quit.

Remaining Full failures: config shape and empty/single enumeration defects (M1-03/M1-04). Four media recipes skip because FFmpeg/FFprobe are absent. No real encoding/probe/playback, actual Explorer/manual, comprehensive special-character drag/drop, cancellation/UNC/long-path/benchmark pass is claimed. Compression defaults and BAT bytes retained.

End with task/evidence/status/next/session updates, intentional feature commits/push, live fetch/push equality/clean check and draft PR status. Main push/merge, release/tags/settings/secrets/deployment or quality changes need explicit owner approval.
