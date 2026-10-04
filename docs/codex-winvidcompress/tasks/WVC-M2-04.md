# WVC-M2-04 — Implement owned temporary output and no-clobber promotion

## Read first

Dependencies: WVC-M2-03, WVC-M1-05. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../OUTPUT_SAFETY.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Output*`
- `tests/integration/*Collision*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Create unique same-volume temporary MP4 paths and record ownership per job; keep final filenames unavailable until successful promotion.
2. Keep FFmpeg refusal to overwrite a pre-existing temp path. Do not reserve the exact temp with an empty file then invoke -n against it.
3. Promote with a filesystem operation that refuses an existing final destination; re-resolve rename collisions safely.
4. Clean only proven owned temporary artifacts, with explicit interrupted-job reporting.

## Acceptance

- **WVC-M2-04-A01** (targeted): Existing source/final sentinel bytes are unchanged after success, failure and collision races.
- **WVC-M2-04-A02** (targeted): Two jobs targeting the same final base never clobber one another.
- **WVC-M2-04-A03** (targeted): Failed jobs leave no finished-looking final; cleanup never uses broad filename patterns.
- **WVC-M2-04-A04** (targeted): Promotion failure reports failure and retains/reports or safely removes only the owned partial according to policy.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
