# WVC-M0-01 — Reconcile the real checkout and install this handoff

## Read first

Dependencies: none. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../GIT_SYNC.md, ../BASELINE.json.

## Scope

- `AGENTS.md`
- `docs/codex-winvidcompress/**`
- `tools/codex-winvidcompress/**`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Read existing repository and parent instructions; inspect root, branch, worktree, remotes, upstream and operation state.
2. Fetch origin and compare the reviewed commit with current main and the active feature branch. Record changes; never reset to the review snapshot.
3. Use a clean codex/wvc-* branch. Preview the external importer, bind apply to the inspected HEAD, then review all added files.
4. Reconcile any existing AGENTS.md without replacing it; initialize STATUS.md, NEXT_SESSION.md and the first session record.
5. Commit the handoff only, push the feature branch, check live matching refs, and open or update one draft PR when tooling is available.

## Acceptance

- **WVC-M0-01-A01** (quick): Correct repository identity, unchanged application files, clean feature branch and actual local path are recorded.
- **WVC-M0-01-A02** (quick): A dirty/conflicting or unexpected checkout is preserved and explicitly blocked, not auto-stashed, cleaned or reset.
- **WVC-M0-01-A03** (quick): Importer preview creates no files; apply adds only missing approved handoff files.
- **WVC-M0-01-A04** (manual): A real GitHub branch SHA equals local HEAD after push; otherwise synchronization is marked unverified/failed.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
