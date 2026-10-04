# WVC-M3-06 — Cancel safely and terminate only this job’s child process

## Read first

Dependencies: WVC-M3-05. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../OUTPUT_SAFETY.md, ../PROCESS_AND_CLI.md.

## Scope

- `WinVidCompress.ps1`
- `tests/integration/*Cancel*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Implement controlled cancellation for the active child, then prevent the next job from starting.
2. Attempt a bounded graceful stop followed by termination only of the owned child/process tree as supported.
3. Always release callbacks/resources and update job status; leave crash-only artifacts distinguishable by provenance.
4. Do not use taskkill /IM ffmpeg.exe or global process-name termination.

## Acceptance

- **WVC-M3-06-A01** (manual): Ctrl+C in each supported Windows launch mode stops the current batch and does not start the next file.
- **WVC-M3-06-A02** (targeted): Another unrelated FFmpeg process is not terminated.
- **WVC-M3-06-A03** (targeted): Source/existing final files are unchanged; no cancelled partial is promoted.
- **WVC-M3-06-A04** (targeted): Cancellation exit status, logs and queue summary agree.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
