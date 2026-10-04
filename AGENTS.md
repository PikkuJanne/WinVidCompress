# WinVidCompress: instructions for coding agents

## Product boundaries
Improve the existing local Windows PowerShell + FFmpeg tool in small reviewable changes. Keep `WinVidCompress.ps1` and `WinVidCompress.bat` as the user entry points. Preserve the simple menu, drag/drop, sequential batches and filename-based interview metadata. Do not introduce a web service, cloud processing, GUI rewrite or new runtime language/framework.

Default contract: libx264, `veryfast`, CRF 22, AAC 160k, MP4 `+faststart`, no crop/no upscale, documented height-cap policy, flat output and safe rename collisions. Do not change default quality settings based on intuition. Existing real source files, current owner instructions and verified repository state outrank this historical plan.

## Read and execute one task
Read `docs/codex-winvidcompress/INDEX.md`, `STATUS.md`, `NEXT_SESSION.md`, and the relevant `TASKS.json` entry/task brief. One task per thread is the default. Small tasks, not whole milestones, are context units. Split an oversized task explicitly; do not silently delete acceptance requirements. Avoid re-reading the entire bundle when a targeted brief suffices.

## Git synchronization is required
Follow `docs/codex-winvidcompress/GIT_SYNC.md`. Inspect current checkout, branch, dirty state, in-progress operations, origin fetch/push URLs and live branch state before editing. Fetch and reconcile current code with the reviewed baseline; do not reset to the baseline. Preserve unknown changes and stop if ownership is unclear.

Use a `codex/wvc-*` feature branch. Commit only intentional files, push meaningful tested checkpoints and every session handoff, and verify current local HEAD equals the actual GitHub feature-branch ref. A cached origin ref, successful commit or merely queued push is not proof of synchronization. Treat the remote as the cross-machine continuity authority; do not discard local work to match it. No concurrent writers to this same checkout/branch.

Never force-push, reset --hard, clean, silently stash, delete branches or rewrite history to resolve a mismatch. Do not push to main/master, merge PRs, create/publish tags/releases, alter repository settings/secrets, deploy a website or change default compression quality without explicit owner approval. Feature-branch pushes and draft PR updates for this agreed work are permitted within the runtime's actual permissions.

## Safety and tests
Never overwrite or delete source videos or existing final outputs. Work with short synthetic fixtures or explicitly approved copies in isolated directories; isolate APPDATA and output roots in tests. No private media, config, paths, logs or secrets in GitHub. No automatic uploads, telemetry, elevation, system policy changes or dependency downloads as part of normal compression.

Keep source/metadata values as arguments, not shell expressions. Check native process exit codes; preserve stderr diagnostics. Use owned temporary outputs, structural validation and no-clobber promotion. Do not claim structural validation proves full visual/audio integrity.

Maintain Windows PowerShell 5.1 compatibility and test a supported PowerShell 7. Avoid 7-only .NET/process APIs without a tested fallback. Keep refactoring proportional; allow minimal pure helper boundaries and a testable entry-point guard. Do not disable strict mode to hide errors or rewrite all formatting just to satisfy a linter.

Use the test tiers in `TESTING.md`: quick + targeted per task, full at risk/milestone gates, actual Windows Explorer manual checks before acceptance. Record exact commands, host versions, tested commits, pass/fail/skip counts and limitations. Never invent results or mark a skipped Windows test passed from Linux mocks.

## End of every thread
Update the task/acceptance evidence, STATUS, NEXT_SESSION and a session record. Commit and push the handoff, then run the read-only live sync check. Report the actual local/remote SHAs, branch, tests, CI/PR state, blockers and exact next task. Do not try to embed a commit's own SHA in that same commit; use the previous implementation SHA for test evidence and report final synchronization externally after the final commit.
