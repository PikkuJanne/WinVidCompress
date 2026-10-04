# WVC-M5-03 — Preserve licensing and review distribution security

## Read first

Dependencies: WVC-M5-02. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../SECURITY_AND_RELEASE.md.

## Scope

- `LICENSE`
- `README.md`
- `SECURITY.md`
- `THIRD_PARTY_NOTICES.md`
- `docs/releases/**`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Preserve the existing Unlicense for project code; do not relabel FFmpeg binaries.
2. Keep the initial package tool-only with trusted dependency instructions and clear build-specific FFmpeg licensing references.
3. Document privacy-aware bug reports, no elevation requirement, and responsible security reporting without inventing contact channels.
4. Record code-signing and bundled-FFmpeg distribution as approval-gated follow-on decisions, not completed features.

## Acceptance

- **WVC-M5-03-A01** (targeted): Original license remains intact unless the owner explicitly authorizes a change.
- **WVC-M5-03-A02** (targeted): No FFmpeg binary is silently included under the project license.
- **WVC-M5-03-A03** (targeted): Release materials avoid claims of certification, guaranteed safety or signed binaries unless demonstrated.
- **WVC-M5-03-A04** (targeted): No embedded credentials, secret-looking values, private absolute paths or unintended telemetry are found in the candidate.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.

## Approval gate

Bundled dependencies, signing setup, license changes or external account/settings changes require explicit owner approval.
