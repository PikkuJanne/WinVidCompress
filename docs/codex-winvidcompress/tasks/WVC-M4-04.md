# WVC-M4-04 — Add Windows CI and targeted static analysis

## Read first

Dependencies: WVC-M4-03. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../TESTING.md, ../SECURITY_AND_RELEASE.md.

## Scope

- `.github/workflows/**`
- `PSScriptAnalyzerSettings.psd1`
- `tests/**`
- `tools/test*.ps1`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Run unit/targeted integration tests on Windows PowerShell 5.1 and a supported stable PowerShell 7 version.
2. Pin action revisions and test-tool/dependency versions with provenance/integrity checks appropriate to distribution.
3. Use minimum token permissions and no secrets for untrusted PRs; do not use privileged pull_request_target for checkout/test execution.
4. Analyze changed code; use narrow documented suppressions instead of a wholesale style rewrite.

## Acceptance

- **WVC-M4-04-A01** (targeted): Failing tests and static-analysis policy failures fail the workflow.
- **WVC-M4-04-A02** (targeted): CI reports host/FFmpeg versions and preserves sanitized results as artifacts.
- **WVC-M4-04-A03** (targeted): No automatic merge, tag, GitHub release or deployment is introduced.
- **WVC-M4-04-A04** (manual): Real workflow runs on the pushed feature commit are inspected; queued/missing runs are not called passed.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
