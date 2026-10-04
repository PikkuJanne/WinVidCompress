# Current programme status

Updated: 2026-10-04. Repository: `PikkuJanne/WinVidCompress`.

`WVC-M0-01` is verified at import checkpoint `7fce9895d5e14554b78d82958c1ed7917a4b20ac`. This thread only installs and verifies the developer handoff; no application improvement has been implemented. The other 31 tasks remain `todo`, with their 124 acceptance criteria `not_run`. TASKS.json is the task-status authority.

## Actual repository and reconciliation

- Actual root: `D:/projects/WinVidCompress-main`.
- Active branch: `codex/wvc-m0-01-handoff`; upstream: `origin/codex/wvc-m0-01-handoff`.
- Origin fetch and push URLs: `https://github.com/PikkuJanne/WinVidCompress.git` (one effective URL for each direction).
- The initial folder had seven source/documentation/asset files and no `.git` metadata. No root or parent AGENTS.md was present. Git-dependent import was held until repository identity and file ownership were established.
- All seven local Git blob hashes exactly matched live GitHub main `5bab7fc698d153128babe3421ce19c0ca3012cc5`; no unknown files existed. Live main equals the historical review anchor; no newer source work or existing feature branch/PR required reconciliation.
- Git metadata was restored in place from fetched live history using `git init`, remote/fetch, creation of the previously absent feature ref, and index-only `git read-tree`. No checkout of working files, stash, reset, clean, force-push, or history replacement occurred. Before import, the feature branch was clean, with no conflicts/operations and no upstream; the first authorized push established the matching upstream.
- The external installer was inspected, previewed without changing worktree inventory or hashes, then applied with `--apply --expected-head 5bab7fc698d153128babe3421ce19c0ca3012cc5`. It added 62 missing handoff files; all payload hashes matched. AGENTS.md was new, so no owner guidance was overwritten. BASELINE.json remains an unchanged historical snapshot.
- The compressor, launcher, README, license, and all three assets remain byte-identical to live main. Existing libx264 / veryfast / CRF 22 / AAC 160k / MP4 +faststart defaults remain intact.

## Evidence and limitations

Evidence: [WVC-M0-01.md](evidence/WVC-M0-01.md), [WVC-M0-01.json](evidence/WVC-M0-01.json).

Windows 11 Pro build 26300; PowerShell 7.6.5; Python 3.14.7; Git 2.56.0.windows.1; GitHub CLI 2.97.0. Git/Python/GitHub CLI were already available; no software was installed. Windows PowerShell 5.1.26100.9444 and PowerShell 7.6.5 are available (version queries only); application compatibility was not exercised. FFmpeg/FFprobe were not found on PATH or in this root.

Developer-helper suite: 48 tests, 47 passed, 1 skipped, exit 0. The destination symlink-escape test was skipped because Windows symlink creation was unavailable. This differs from the external bundle's historical Linux helper run of 48 passes. Bundle/tool checks do not establish application behavior. Installed tracker validation passes: 32 tasks, 128 criteria, all 23 reviewed improvements mapped. No application, media, Explorer, benchmark, or Windows PowerShell 5.1 compatibility tests ran in this task.

Draft PR: [#1](https://github.com/PikkuJanne/WinVidCompress/pull/1), open against main. At the tested import checkpoint, GitHub reported no workflow runs or check runs; no CI pass is claimed.

Previous verified synchronization: `7fce9895d5e14554b78d82958c1ed7917a4b20ac`, checked at `2026-10-04T15:35:55.240343+00:00`; local HEAD equals live fetch and push feature refs, worktree clean, no operation/conflict state. This is a point-in-time result for that checkpoint only.

The final evidence handoff commit's push/check is pending when this file is committed. Verify that final SHA externally after the final push and again at the next session; never treat the prior checkpoint as proof for a later commit. No merge, default-branch push, release, dependency bundling/signing, settings/secrets change, or website deployment was authorized/performed.

Next task: **WVC-M0-02 — Characterize existing behaviour and add the smallest test seam**. No blocker was found for this handoff; symlink coverage remains an explicit helper-test limitation.
