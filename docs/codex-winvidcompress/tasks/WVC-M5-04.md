# WVC-M5-04 — Prepare website product metadata and genuine demonstration content

## Read first

Dependencies: WVC-M5-03. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../WEBSITE_HANDOFF.md.

## Scope

- `website-content/**`
- `docs/releases/**`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Create static product metadata and copy describing the local application and verified release candidate.
2. Populate version/download/checksum fields from released artifacts only; before release keep them null/draft.
3. Prepare real screenshot instructions/captures and labelled measured examples using synthetic or approved media.
4. Do not build upload forms, accounts, server-side FFmpeg, a new web framework or telemetry.

## Acceptance

- **WVC-M5-04-A01** (targeted): Website data has a schema/version and distinguishes draft candidates from published downloads.
- **WVC-M5-04-A02** (targeted): No fabricated download URL, checksum, testimonial or compression measurement is published.
- **WVC-M5-04-A03** (targeted): Screenshots show the actual tool and contain no personal paths or footage without permission.
- **WVC-M5-04-A04** (targeted): Website content is prepared locally only; no deployment is performed.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.

## Approval gate

Public website deployment and connecting release download URLs require owner approval and an actual release.
