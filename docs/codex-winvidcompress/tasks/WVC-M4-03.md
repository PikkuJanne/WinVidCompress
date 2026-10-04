# WVC-M4-03 — Stress concurrency, crash recovery and filesystem edge cases

## Read first

Dependencies: WVC-M4-02. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../OUTPUT_SAFETY.md, ../ACCEPTANCE_MATRIX.md.

## Scope

- `WinVidCompress.ps1`
- `tests/integration/*Safety*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Exercise two independent tool instances targeting the same name and config simultaneously.
2. Inject errors at temp creation, encode exit, probe, promotion and manifest/config persistence boundaries.
3. Verify stale-artifact discovery uses ownership proof and never blanket deletes.
4. Check unavailable drives/UNC and long-path limitations in disposable Windows test roots.

## Acceptance

- **WVC-M4-03-A01** (targeted): Existing sentinels retain their hashes through each injected failure.
- **WVC-M4-03-A02** (targeted): Final-name races resolve as safe rename/skip/failure, never overwrite.
- **WVC-M4-03-A03** (targeted): Crash artifacts remain identifiable; reporting them cannot mutate unrelated files.
- **WVC-M4-03-A04** (manual): Windows-specific filesystem cases have actual results or explicit release-blocking limitations.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
