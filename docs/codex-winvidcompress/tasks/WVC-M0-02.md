# WVC-M0-02 — Characterize existing behaviour and add the smallest test seam

## Read first

Dependencies: WVC-M0-01. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../PRODUCT_CONTRACT.md, ../TESTING.md, ../AUDIT.md.

## Scope

- `WinVidCompress.ps1`
- `tests/**`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Capture default argument construction, naming and metadata behaviour with mocks/synthetic inputs.
2. Allow pure helpers to be loaded without tool discovery, config writes or TUI startup. Keep the script entry point and normal invocation unchanged.
3. Reproduce the known menu, config and enumeration defects with focused tests. Mark baseline failures as known defects without asserting that broken behaviour is desired.
4. Avoid moving every function or adding an application framework.

## Acceptance

- **WVC-M0-02-A01** (targeted): Tests do not invoke the TUI, modify real APPDATA or touch user Videos.
- **WVC-M0-02-A02** (targeted): Default profile remains libx264 / veryfast / CRF 22 / AAC 160k / MP4 +faststart.
- **WVC-M0-02-A03** (targeted): Direct invocation and the original launcher still reach the existing application flow.
- **WVC-M0-02-A04** (manual): PowerShell 5.1 and PowerShell 7 characterization outcomes are recorded separately.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
