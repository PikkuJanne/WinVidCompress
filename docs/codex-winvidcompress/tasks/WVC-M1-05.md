# WVC-M1-05 — Freeze and deduplicate the full batch before encoding

## Read first

Dependencies: WVC-M1-04. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../CONFIG_AND_DISCOVERY.md, ../OUTPUT_SAFETY.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Queue*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Collect all input selections into one deterministic queue before starting the first encode.
2. Deduplicate normalized paths with appropriate Windows comparison; document hard-link identity as a separate concern.
3. Exclude trusted generated outputs and owned temporary files, not every MP4 or every file in the output directory.
4. Handle source=destination, nested destination and overlapping input roots without losing original sources.

## Acceptance

- **WVC-M1-05-A01** (targeted): File+parent-folder, parent+child-folder and repeated selections encode a source once.
- **WVC-M1-05-A02** (targeted): Output files created during a run cannot become new inputs in the same run.
- **WVC-M1-05-A03** (targeted): Original MP4s in the destination or names containing (compressed) are not excluded solely by their name.
- **WVC-M1-05-A04** (targeted): New output is never the same normalized path as its input; discovery failures remain visible.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
