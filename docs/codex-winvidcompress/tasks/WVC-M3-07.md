# WVC-M3-07 — Add validated batch retry/resume with a versioned manifest

## Read first

Dependencies: WVC-M3-06, WVC-M1-05. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../OUTPUT_SAFETY.md, ../PROCESS_AND_CLI.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Manifest*`
- `tests/integration/*Resume*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Persist job identity, normalized source, size/mtime, settings fingerprint, output identity and state atomically.
2. Resume by rerunning unfinished jobs, never by appending encoded data to a partial MP4.
3. Skip a completed job only after checking source identity, settings and output validity; paths alone are insufficient.
4. Validate manifest schema/paths and reject traversal/foreign ownership; add an opt-in stronger source hash for stricter checks.

## Acceptance

- **WVC-M3-07-A01** (targeted): Changed source, changed CRF/settings, missing output, corrupt output and mismatched manifest all prevent a false completed skip.
- **WVC-M3-07-A02** (targeted): Interrupted batches can retry failed/unstarted jobs while keeping validated successful outputs.
- **WVC-M3-07-A03** (targeted): Default fast identity limitations are documented; opt-in hashing detects same-size/same-mtime content changes.
- **WVC-M3-07-A04** (targeted): Malformed/foreign manifests cannot cause deletion of files or execution outside the current local job scope.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
