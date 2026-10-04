# WVC-M4-02 — Add opt-in relative subfolder preservation

## Read first

Dependencies: WVC-M4-01. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../CONFIG_AND_DISCOVERY.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Layout*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Implement an opt-in preserve-subfolders layout, keeping flat output as the default.
2. Specify deterministic roots for multiple folder/file selections and repeated root names.
3. Guarantee destination containment; sanitize derived relative paths and reject traversal.
4. Make dry-run and logs display the chosen relative layout and collisions.

## Acceptance

- **WVC-M4-02-A01** (targeted): No flag produces the original flat layout.
- **WVC-M4-02-A02** (targeted): Two cameras with repeated clip names in different input folders produce deterministic separated outputs when enabled.
- **WVC-M4-02-A03** (targeted): Every planned output remains beneath the selected destination root.
- **WVC-M4-02-A04** (targeted): Input roots overlapping with destination do not cause self-reingestion.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
