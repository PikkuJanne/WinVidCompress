# WVC-M2-03 — Isolate command construction and native process execution

## Read first

Dependencies: WVC-M2-02, WVC-M1-02. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../PROCESS_AND_CLI.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Arguments*`
- `tests/integration/*Process*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Build FFmpeg arguments as tokens in a pure helper, then use a small execution adapter.
2. Preserve correct quoting across Windows PowerShell 5.1 and PowerShell 7; do not assume ProcessStartInfo.ArgumentList exists in .NET Framework.
3. Drain stderr and progress stdout without deadlocks; keep native stderr distinct from PowerShell error policy.
4. Prevent child input from consuming menu/interactive input and avoid leaking callbacks/process resources.

## Acceptance

- **WVC-M2-03-A01** (targeted): Default encoder tokens and exact input/output/metadata token values have unit assertions.
- **WVC-M2-03-A02** (manual): Native argument round trips preserve supported filenames and metadata on both target shells.
- **WVC-M2-03-A03** (targeted): Large stderr output cannot deadlock the process; nonzero exit is always recognized.
- **WVC-M2-03-A04** (targeted): The adapter returns a structured process result and does not evaluate source paths as shell code.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
