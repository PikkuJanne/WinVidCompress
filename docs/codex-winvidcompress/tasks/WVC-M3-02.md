# WVC-M3-02 — Define SDR compatibility and reject untested HDR conversions

## Read first

Dependencies: WVC-M3-01. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../MEDIA_PIPELINE.md, ../DECISIONS.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Colour*`
- `tests/integration/*Colour*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Detect HDR from colour metadata and transfer characteristics, not bit depth alone.
2. Implement and test a conventional 8-bit yuv420p SDR compatibility path for supported SDR inputs.
3. Use an actionable unsupported result for known HDR not covered by a validated conversion path; no automatic tone mapper in this scope.
4. Warn on ambiguous colour metadata, preserve known SDR colour information where appropriate, and never relabel HDR as SDR.

## Acceptance

- **WVC-M3-02-A01** (targeted): 10-bit SDR is not incorrectly classified as HDR solely by depth.
- **WVC-M3-02-A02** (targeted): PQ/HLG test metadata is recognized and untested HDR does not silently encode as ordinary SDR.
- **WVC-M3-02-A03** (targeted): SDR outputs have the intended tested pixel format and do not claim HDR preservation.
- **WVC-M3-02-A04** (manual): Colour-sensitive sample review is recorded before promoting changed defaults.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.

## Approval gate

New tone-mapping path or change to accepted output-quality defaults requires owner approval.
