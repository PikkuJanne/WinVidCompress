# WVC-M4-05 — Complete the real Windows workflow acceptance matrix

## Read first

Dependencies: WVC-M4-04. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../ACCEPTANCE_MATRIX.md, ../TESTING.md.

## Scope

- `tests/**`
- `docs/codex-winvidcompress/evidence/**`
- `docs/codex-winvidcompress/STATUS.md`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Run the full automated matrix on exact implementation commits, then perform genuine Explorer drag/drop tests.
2. Exercise new-user and upgraded-config workflows on the active owner workstation with synthetic media.
3. Use copies of selected real interviews only with owner consent for visual/audio review.
4. Record remaining limitations with severity and release impact instead of weakening test expectations.

## Acceptance

- **WVC-M4-05-A01** (targeted): All required automated gates pass or are explicitly blocked with reproducible evidence.
- **WVC-M4-05-A02** (manual): Single file, folder, multiple selections, menu, paths with special characters and cancellation are checked from Windows Explorer.
- **WVC-M4-05-A03** (manual): Representative outputs play with expected orientation, duration, audio and metadata.
- **WVC-M4-05-A04** (targeted): No implementation is marked accepted solely from Linux or mocked tests.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.

## Approval gate

Owner supplies/approves real-media review and confirms manual acceptance.
