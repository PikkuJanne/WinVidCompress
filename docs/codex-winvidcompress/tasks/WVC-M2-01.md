# WVC-M2-01 — Expand FFprobe into normalized JSON media inspection

## Read first

Dependencies: WVC-M1-06. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../MEDIA_PIPELINE.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Probe*`
- `tests/fixtures/probe/**`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Replace height-only probing with one bounded structured inspection per input.
2. Parse stream indices/types/dispositions, geometry, rotation, SAR, pixel format, colour fields, audio details and duration where present.
3. Keep probe stderr and native exit status; reject malformed responses and no-real-video inputs.
4. Represent unknown/invalid duration explicitly without forcing an invented zero.

## Acceptance

- **WVC-M2-01-A01** (targeted): Probe exit failure, timeout, invalid JSON and missing required video fields yield structured failure.
- **WVC-M2-01-A02** (targeted): Audio-only input and attached artwork without real video do not start video compression.
- **WVC-M2-01-A03** (targeted): Valid video with absent duration proceeds with indeterminate progress and an explicit validation limitation.
- **WVC-M2-01-A04** (targeted): Probe output parsing is culture-independent and tolerates additional unknown fields.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
