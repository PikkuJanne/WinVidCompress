# Next session

Next bounded task: **WVC-M1-02 — Harden the .bat launcher using measured argument round trips**. WVC-M1-01 is verified: the owner confirmed actual Explorer A04 steps on 2026-10-05. Do not repeat the completed confirmation or silently implement the rest of M1.

## Start from actual state

- Root `D:/projects/WinVidCompress-main`; branch `codex/wvc-m1-01-menu-paths`; upstream `origin/codex/wvc-m1-01-menu-paths`.
- Origin has one fetch/push destination `https://github.com/PikkuJanne/WinVidCompress.git`.
- Tested implementation `6337b73d41cf65b9f12cb412800bc3d68780693c`; automated tests ran 2026-10-04. Documentation-only manual confirmation followed 2026-10-05, with no automated rerun.
- Previous clean live equality at `2026-10-05T12:42:56.214979+00:00` describes prior documentation HEAD `17a49c0cd9c8193b983b0acfc3bbcfeea3e03aae`. Final confirmation SHA is externally reported after push; verify independently.
- Draft [PR #4](https://github.com/PikkuJanne/WinVidCompress/pull/4) open against main; no workflow/check runs.
- Owner merged PR #3 before M1-01. Inspected main `e8b54d1fdd03bdd3e0135c67c38335788a6f8112` has the same tree as M0-03's final feature; M1-01 branch starts from it. Confirmation fetch found no newer main/feature change.

Read AGENTS/INDEX/STATUS/GIT_SYNC/TASKS, M1-02 brief/PROCESS_AND_CLI/TESTING, and targeted M1-01 launcher evidence. Inspect status/branch/upstream/HEAD, operations/conflicts/hooks, effective URLs and live state. Run `git fetch --no-tags origin` then `python -B tools/codex-winvidcompress/check_repo_sync.py --repo "D:/projects/WinVidCompress-main"`.

Preserve unknown changes. If PR #4 merged, start launcher work from inspected current main; otherwise retain M1-01 ancestry in the next codex/wvc-* branch. Never rely on cached refs or reset to the historical baseline. One writer only.

## Exact launcher scope

M1-02 should measure actual argv through a dedicated recorder, remove unnecessary delayed expansion/multi-stage argument reconstruction, and preserve double-click/one-file/folder/multiple selection on PS5.1. Test spaces, !, &, parentheses, apostrophes, [], %, Finnish/German/non-Latin, literal %PATH%/!NAME! with matching variables. Do not execute payload-like names or promise unlimited Windows command lines. Missing PS1/dependencies must produce actionable errors. Several criteria require actual Windows Explorer observation.

Use the existing tier runner with nested tests automatically discovered. New PS1 stays ASCII or UTF-8 BOM; BAT CRLF. External temporary Pester 5.7.1/analyzer 1.24.0 modules may not persist; no automatic download in application/runners.

M1-01's completed manual check used an isolated environment wrapper calling byte-identical PS1/BAT copies with startup-only native sentinels. Owner-confirmed Explorer launch, Quit returning to a usable PowerShell prompt, then exit passes only the menu/console criterion. Prepared hashes match tested commit `6337b73`. Broader special-character argv/drop/dependency checks still belong to M1-02; do not treat this as their evidence.

## Tested outcomes and limits

Clean implementation: each host Quick 79 passed/0 failed/0 skipped/4 NotRun, exit 0; Targeted 93 passed/0 failed/4 skipped/4 NotRun, exit 0. Full both hosts 168 passed/8 known failures/4 skipped/8 NotRun, exit 1. Counts include 75 Pester checks plus static/native/JSON cases. Twenty menu/path regressions pass per host; six native batch/menu entries pass. M1-01-A04 has one actual owner-confirmed manual pass dated 2026-10-05.

Remaining Full failures: config shape and empty/single enumeration defects (M1-03/M1-04). Four media recipes skip because FFmpeg/FFprobe were absent. No real encoding/probe/playback, comprehensive special-character drag/drop, cancellation/UNC/long-path/benchmark pass is claimed. Compression defaults and BAT bytes retained.

No M1-01 blocker remains. Stop after the bounded M1-02 slice, then record its actual criteria/tests/manual limitations and exact next task. End with task/evidence/status/next/session updates, intentional feature commits/push, live fetch/push equality/clean check and draft PR status. Main push/merge, release/tags/settings/secrets/deployment or quality changes need explicit owner approval.
