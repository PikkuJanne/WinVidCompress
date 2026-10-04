# WVC-M3-01 — Harden resizing and rotation without a new resolution preset

## Read first

Dependencies: WVC-M2-06. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../MEDIA_PIPELINE.md, ../DECISIONS.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Geometry*`
- `tests/integration/*Geometry*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Use selected-stream display geometry and handle autorotation exactly once.
2. Retain a height-cap policy with no crop/no upscale; do not silently switch to a 1920x1080 bounding box.
3. Derive encoder-compatible even dimensions while preserving display aspect ratio within a documented rounding tolerance.
4. Document how odd-sized inputs and non-square pixels are treated; test the generated filter rather than copying an unverified expression.

## Acceptance

- **WVC-M3-01-A01** (targeted): Landscape, portrait, rotation 90/180/270, ultrawide, non-square SAR and odd dimensions have regression cases.
- **WVC-M3-01-A02** (targeted): Sub-1080 inputs are not enlarged; output orientation and aspect ratio match the source intent.
- **WVC-M3-01-A03** (targeted): High-frame-rate/VFR input does not acquire a forced FPS policy.
- **WVC-M3-01-A04** (manual): Owner views representative geometry samples before any materially changed default behaviour is accepted.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.

## Approval gate

Materially changing the height-cap/default geometry policy requires owner approval; bug fixes within the documented policy do not.
