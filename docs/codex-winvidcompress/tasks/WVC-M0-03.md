# WVC-M0-03 — Establish the regression harness and generated fixtures

## Read first

Dependencies: WVC-M0-02. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../TESTING.md, ../ACCEPTANCE_MATRIX.md.

## Scope

- `tests/**`
- `tools/test*.ps1`
- `PSScriptAnalyzerSettings.psd1`
- `.gitignore`
- `.gitattributes`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Pin and document compatible Pester/PSScriptAnalyzer versions in the developer setup after checking official releases.
2. Create quick, targeted, full and manual test entry points with deterministic result reports.
3. Generate short synthetic video/audio fixtures in isolated temporary directories; use probe-JSON fixtures for expensive cases.
4. Define line-ending/encoding policy for .bat and PowerShell 5.1 Unicode without wholesale formatting churn.

## Acceptance

- **WVC-M0-03-A01** (targeted): Harness reports real pass/fail/skip counts and returns nonzero on failing automated tests.
- **WVC-M0-03-A02** (targeted): Missing FFmpeg or an unavailable host is recorded as skipped/not tested, never passed.
- **WVC-M0-03-A03** (targeted): No private footage, downloaded executables, secrets or real user config enters Git.
- **WVC-M0-03-A04** (targeted): A fixture inventory maps each generated file to commands, capabilities, cleanup owner and expected streams.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
