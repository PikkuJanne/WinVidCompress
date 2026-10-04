# WVC-M1-03 — Make configuration validation and recovery safe

## Read first

Dependencies: WVC-M0-03. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../CONFIG_AND_DISCOVERY.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Config*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Validate JSON root type, property presence, scalar types and output directory semantics before property access.
2. Retain backward compatibility with the existing OutputDir-only JSON file.
3. Distinguish malformed config from unavailable external/UNC destinations; never silently rewrite a temporary failure to Videos.
4. Write through an owned temporary file, preserve a previous valid copy, and use replace/no-clobber semantics as appropriate.

## Acceptance

- **WVC-M1-03-A01** (targeted): Missing file, empty file, invalid JSON, null, {}, [], numeric root and wrong OutputDir types all have explicit tested outcomes.
- **WVC-M1-03-A02** (targeted): Offline output drive, permission denial and existing file-as-directory do not silently redirect or overwrite saved preferences.
- **WVC-M1-03-A03** (targeted): A failed save does not destroy the last valid config; tests isolate APPDATA.
- **WVC-M1-03-A04** (targeted): Unknown compatible keys survive load/save or a documented migration; no unnecessary schema reset occurs.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
