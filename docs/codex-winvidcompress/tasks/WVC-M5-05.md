# WVC-M5-05 — Reconstruct from GitHub and present a release candidate for approval

## Read first

Dependencies: WVC-M5-04. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../GIT_SYNC.md, ../SECURITY_AND_RELEASE.md, ../ACCEPTANCE_MATRIX.md.

## Scope

- `docs/codex-winvidcompress/**`
- `docs/releases/**`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Clone the pushed feature branch into a new disposable directory on the active workstation; reconstruct using only tracked code and documented dependencies.
2. Build and inspect the package, run clean-extraction smoke tests, and verify hashes.
3. Reconcile all 23 improvement IDs against task acceptance evidence; document gated optional decisions rather than silently omitting them.
4. Present exact implementation/head/remote SHAs, test outcomes, limitations and the candidate artifact paths. Stop before merging, tagging, release publication or site deployment.

## Acceptance

- **WVC-M5-05-A01** (manual): A clean clone of the live GitHub branch reproduces the tested candidate without hidden files from the developer checkout.
- **WVC-M5-05-A02** (targeted): All required tasks/acceptance IDs have real evidence; skipped/manual pending items remain visible.
- **WVC-M5-05-A03** (targeted): Local HEAD equals the live GitHub feature ref and worktree is clean at handoff.
- **WVC-M5-05-A04** (manual): Owner explicitly accepts the candidate before publication; approval records cite their actual decision.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.

## Approval gate

Merge to default branch, tags, GitHub release publication and website deployment are separate explicit owner approvals.
