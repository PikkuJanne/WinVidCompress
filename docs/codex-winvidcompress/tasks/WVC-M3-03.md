# WVC-M3-03 — Validate interview metadata dates and preserve text

## Read first

Dependencies: WVC-M0-03, WVC-M2-03. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../MEDIA_PIPELINE.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Metadata*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Use culture-independent calendar validation for existing ddmmyyyy, dd.mm.yyyy and dd-mm-yyyy patterns.
2. Define handling of fallback dates, ambiguous/multiple matches and blank band names.
3. Keep title and compression on parse failure; report omitted tags without inventing dates.
4. Define existing-tag precedence and verify MP4 tag read-back on the selected FFmpeg build.

## Acceptance

- **WVC-M3-03-A01** (targeted): Leap day, invalid month/day, 31 February, empty band and unrelated 8-digit numbers are tested.
- **WVC-M3-03-A02** (targeted): Finnish/German and non-Latin names round-trip as supported UTF-8 metadata.
- **WVC-M3-03-A03** (targeted): Failed date parsing never prevents an otherwise valid video from compressing.
- **WVC-M3-03-A04** (targeted): Source metadata and filename-derived overrides follow a documented deterministic policy.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
