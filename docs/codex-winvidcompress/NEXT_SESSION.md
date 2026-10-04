# Next session

Next task: **WVC-M0-02 — Characterize existing behaviour and add the smallest test seam**.

Use installed NEXT_THREAD_PROMPT.md for the next thread. Do not reuse the import prompt or reapply the external bundle.

## Start from actual current state

- Root: `D:/projects/WinVidCompress-main`; branch: `codex/wvc-m0-01-handoff`; upstream: `origin/codex/wvc-m0-01-handoff`.
- Verified repository and effective fetch/push origin: `PikkuJanne/WinVidCompress`, `https://github.com/PikkuJanne/WinVidCompress.git`.
- Imported/tested checkpoint: `7fce9895d5e14554b78d82958c1ed7917a4b20ac`. Previously verified clean live-ref equality at `2026-10-04T15:35:55.240343+00:00` applies only to that commit. Final evidence handoff SHA is reported externally after commit/push; inspect current HEAD independently.
- Draft PR [#1](https://github.com/PikkuJanne/WinVidCompress/pull/1) remains open against main. No CI runs/checks were present at the import checkpoint.
- The original open folder had no Git metadata. All seven existing files exactly matched live main `5bab7fc698d153128babe3421ce19c0ca3012cc5` before Git tracking was restored in place without altering the working files. This matches the historical review; BASELINE.json is informational.

Read root/parent AGENTS.md, STATUS.md, GIT_SYNC.md, TASKS.json, evidence/WVC-M0-01.md and the WVC-M0-02 task brief. Before editing, inspect status, operations/conflicts, URLs, branch/upstream and HEAD; fetch origin with `git fetch --no-tags origin`; then run `python tools/codex-winvidcompress/check_repo_sync.py --repo "D:/projects/WinVidCompress-main"`. Preserve unknown changes/divergence; reconcile before proceeding. Do not reimport handoff templates over their live state.

## Exact bounded next action

After live-state verification, characterize current argument construction, naming and metadata using mocks/synthetic inputs; introduce only the smallest helper-loading seam that avoids tool discovery, config writes and TUI startup. Keep the normal PS1/BAT entry flow and libx264 / veryfast / CRF 22 / AAC 160k / MP4 +faststart defaults. Reproduce known menu/config/enumeration defects as known defects, without treating broken behavior as desired.

Read PRODUCT_CONTRACT.md, TESTING.md and AUDIT.md for that task. Scope: WinVidCompress.ps1 and tests/**. Isolate APPDATA/output roots; record Windows PowerShell 5.1 and PowerShell 7 characterization results separately.

## Existing evidence and limitations

WVC-M0-01: 62 handoff payload additions, all hashes matched; seven original files unchanged; helper suite 47 passed/1 symlink-creation skip; tracker valid with 32 tasks/128 criteria/23 mappings. Only M0-01 is verified; the other 31 tasks remain todo/not_run. No application improvement is claimed.

Available developer tools: Python 3.14.7, Git 2.56.0.windows.1, GitHub CLI 2.97.0 with authorized repository access, PowerShell 7.6.5 and Windows PowerShell 5.1.26100.9444 (version queries only). FFmpeg/FFprobe not found on PATH or in the repository at this checkpoint; verify requirements instead of silently installing dependencies. No application/Explorer/media tests ran. The helper suite's Windows symlink test remains skipped.

No handoff blocker or owner decision is pending. Final handoff push/check must be confirmed from current live state. Stop after WVC-M0-02; update evidence/continuity, commit intended changes, push this feature branch, verify live fetch/push SHA equality and clean worktree externally, and update the existing draft PR. Owner approval remains necessary for main merges/pushes, default-quality changes, tags/releases, settings/secrets, dependency bundling/signing or website deployment.
