# WVC-M1-01 — Repair menu exit and separate source/output folder selection

## Read first

Dependencies: WVC-M0-03. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../PRODUCT_CONTRACT.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Menu*`
- `tests/unit/*Path*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Replace switch-only Quit handling with a function return or correctly labelled outer-loop exit.
2. Separate existing-source validation from explicitly requested output directory creation.
3. Keep blank-to-cancel and the four-option workflow; report permission errors clearly.

## Acceptance

- **WVC-M1-01-A01** (targeted): Choosing 4 exits the menu function without redisplaying it or terminating a caller runspace.
- **WVC-M1-01-A02** (targeted): A missing source directory remains missing after selection; only a selected output path can be created.
- **WVC-M1-01-A03** (targeted): Blank input cancels; literal brackets and Unicode paths are not expanded as wildcards.
- **WVC-M1-01-A04** (manual): Double-click launch reaches the menu and Quit leaves the console in its documented state.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
