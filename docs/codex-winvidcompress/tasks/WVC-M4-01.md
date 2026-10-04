# WVC-M4-01 — Expose optional CLI controls and a truly non-writing preview

## Read first

Dependencies: WVC-M3-07, WVC-M1-06. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../PROCESS_AND_CLI.md.

## Scope

- `WinVidCompress.ps1`
- `WinVidCompress.bat`
- `tests/unit/*Cli*`
- `tests/integration/*WhatIf*`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Add optional -OutputDir, -CollisionMode, -WhatIf and -CheckEnvironment without disrupting positional path arguments.
2. Use a defined precedence: built-in defaults < persisted config < per-run options; per-run options do not persist implicitly.
3. Implement read-only planning: no config creation, output directories, encoding, manifests or persistent logs under -WhatIf.
4. Provide real comment-based help and documented unattended usage; exact flag naming can be adjusted once and tracked.

## Acceptance

- **WVC-M4-01-A01** (targeted): No-option drag/drop/TUI behaviour retains the accepted defaults.
- **WVC-M4-01-A02** (targeted): WhatIf filesystem snapshots before/after show no application writes; process probes, when used, are read-only and documented.
- **WVC-M4-01-A03** (targeted): Invalid CRF/enum/path combinations fail before conversion; public options remain intentionally small.
- **WVC-M4-01-A04** (targeted): Get-Help examples execute correctly and automation never blocks on Read-Host.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
