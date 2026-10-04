# WVC-M2-02 — Select and map the same real video and intended audio

## Read first

Dependencies: WVC-M2-01. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../MEDIA_PIPELINE.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Stream*`
- `tests/integration/*Streams*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Select a real video stream once and carry its absolute index into probing, scaling and -map construction.
2. Use first real video by stream index for the documented first-video policy; exclude attached pictures.
3. Select default-disposition audio when unique, otherwise the first audio; document/warn omitted alternatives.
4. Keep audio optional and subtitles/data/attachments intentionally out of scope; do not silently change channel count or frame rate.

## Acceptance

- **WVC-M2-02-A01** (targeted): A multi-video fixture proves the inspected and encoded indices are identical.
- **WVC-M2-02-A02** (targeted): Cover artwork is not mistaken for the primary video.
- **WVC-M2-02-A03** (targeted): Silent video completes without inventing an audio stream; multi-audio omission is visible.
- **WVC-M2-02-A04** (targeted): Selected video, audio, channels and any discarded stream types are present in the job plan/report.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
