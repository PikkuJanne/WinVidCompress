# WVC-M1-06 — Add dependency and output-environment diagnostics

## Read first

Dependencies: WVC-M0-03, WVC-M1-03. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../PROCESS_AND_CLI.md, ../SECURITY_AND_RELEASE.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Environment*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Resolve actual applications for ffmpeg.exe and ffprobe.exe with explicit paths and documented precedence.
2. Preserve current PATH-before-adjacent precedence unless a documented owner-approved change is required.
3. Record versions/build details and verify libx264, AAC and needed probe/muxer capabilities using bounded calls.
4. Validate destination availability/writability and report capacity concerns without a false size guarantee.

## Acceptance

- **WVC-M1-06-A01** (targeted): Missing, non-executable, wrong tool and unsupported encoder cases fail before processing.
- **WVC-M1-06-A02** (targeted): Doctor output shows exactly which binaries would run, without downloading or replacing them.
- **WVC-M1-06-A03** (targeted): Capability checks time out and fail clearly; no elevated rights or system PATH edits are required.
- **WVC-M1-06-A04** (targeted): Unwritable/offline destinations are diagnosed without changing saved preferences.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
