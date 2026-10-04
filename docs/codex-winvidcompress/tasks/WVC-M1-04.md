# WVC-M1-04 — Normalize file discovery and expose scan failures

## Read first

Dependencies: WVC-M1-01. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../CONFIG_AND_DISCOVERY.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Discovery*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Materialize zero/one/many enumeration results consistently; preserve literal path handling.
2. Normalize existing filesystem paths; reject unsupported non-filesystem inputs.
3. Report unreadable paths and inaccessible subfolders separately from empty folders.
4. Choose and document a safe reparse-point/junction traversal policy with cycle protection.

## Acceptance

- **WVC-M1-04-A01** (targeted): Empty directory, one file, many files and mixed supported/unsupported extensions work under strict mode.
- **WVC-M1-04-A02** (targeted): Unreadable or missing requested inputs produce explicit records and do not count as successful scans.
- **WVC-M1-04-A03** (targeted): Reparse points cannot cause recursive loops or accidental broad scans.
- **WVC-M1-04-A04** (manual): UNC, non-ASCII and longer paths are tested on Windows and limitations recorded.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
