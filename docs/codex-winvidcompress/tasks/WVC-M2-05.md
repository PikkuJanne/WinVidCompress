# WVC-M2-05 — Validate output before marking it complete

## Read first

Dependencies: WVC-M2-04. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../OUTPUT_SAFETY.md, ../MEDIA_PIPELINE.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Validation*`
- `tests/integration/*Validation*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Probe the produced temp and require nonempty readable MP4 with expected video/audio structure.
2. Compare duration when known using a documented tolerance grounded in fixtures; allow timestamp/container differences without declaring every mismatch corrupt.
3. Add optional full decode validation for release testing rather than silently doubling every normal conversion.
4. Promote only after checks pass; describe ordinary validation as structural, not proof of perfect visual quality.

## Acceptance

- **WVC-M2-05-A01** (targeted): Exit 0 plus zero bytes, unreadable output, wrong streams or materially truncated duration is rejected.
- **WVC-M2-05-A02** (targeted): Silent-input and known/unknown-duration cases follow explicit policies.
- **WVC-M2-05-A03** (targeted): Only validated+promoted jobs increment Done.
- **WVC-M2-05-A04** (targeted): Validation errors carry source/job identity and do not overwrite existing outputs.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
