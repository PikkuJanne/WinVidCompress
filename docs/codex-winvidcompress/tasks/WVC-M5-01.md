# WVC-M5-01 — Write onboarding, help and troubleshooting for actual behaviour

## Read first

Dependencies: WVC-M4-05. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../PRODUCT_CONTRACT.md, ../SECURITY_AND_RELEASE.md.

## Scope

- `README.md`
- `WinVidCompress.ps1`
- `docs/user/**`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Document download/extract, dependency setup, doctor, first run, output naming and collision behaviour.
2. Describe exact preset settings, supported media, stream omissions, HDR limits and local-only privacy boundaries.
3. Remove unsupported blanket quoting/HandBrake-equivalence claims; do not market lossy copies as lossless archival masters.
4. Document resetting/recovering config without encouraging antivirus or permanent policy weakening.

## Acceptance

- **WVC-M5-01-A01** (targeted): A new user can follow instructions using a clean extracted package.
- **WVC-M5-01-A02** (targeted): README and Get-Help agree with implemented options and tested shells.
- **WVC-M5-01-A03** (targeted): Troubleshooting covers unavailable output drive, invalid config, probe failure, larger output and failed/cancelled jobs.
- **WVC-M5-01-A04** (targeted): All claimed capabilities point to completed acceptance records or explicit limitations.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
