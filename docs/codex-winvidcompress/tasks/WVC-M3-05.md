# WVC-M3-05 — Add machine progress and privacy-aware persistent logs

## Read first

Dependencies: WVC-M2-06, WVC-M3-04. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../PROCESS_AND_CLI.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Progress*`
- `tests/unit/*Log*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Parse FFmpeg -progress key/value records, keeping stderr diagnostics separate.
2. Show file index/total and elapsed/approximate remaining time; unknown duration gets indeterminate progress.
3. Record encoding, finalizing, validating and completed states accurately.
4. Write bounded session text/JSON results locally with schema version, and add a redacted diagnostic export.

## Acceptance

- **WVC-M3-05-A01** (targeted): Partial progress records, N/A values, locale differences and end markers are tested.
- **WVC-M3-05-A02** (targeted): No job is reported fully complete before validation and final promotion.
- **WVC-M3-05-A03** (targeted): Logs capture version/parameters/errors and useful job identity; normal console operation does not become a wall of raw logs.
- **WVC-M3-05-A04** (targeted): Sharing/export redacts personal roots/filenames as configured; no automatic telemetry or upload is added.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
