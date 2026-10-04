# WVC-M1-02 — Harden the .bat launcher using measured argument round trips

## Read first

Dependencies: WVC-M0-03. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../PROCESS_AND_CLI.md, ../TESTING.md.

## Scope

- `WinVidCompress.bat`
- `WinVidCompress.ps1`
- `tests/launcher/**`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Remove unnecessary delayed expansion and avoid multi-stage command reconstruction.
2. Use a dedicated test argument-recorder to observe the exact argv entering PowerShell; do not execute payload-like filenames.
3. Preserve double-click, one-file, folder and multiple-selection invocation on Windows PowerShell 5.1.
4. Document Windows command-line length and shell-specific limits instead of promising unlimited drops.

## Acceptance

- **WVC-M1-02-A01** (manual): Arguments containing spaces, !, &, parentheses, apostrophes, [], %, Finnish/German characters and non-Latin names arrive unchanged in supported launch paths.
- **WVC-M1-02-A02** (manual): Test literal %PATH% and !NAME! filename segments with matching environment variables set; no environment substitution or command execution occurs.
- **WVC-M1-02-A03** (targeted): No Invoke-Expression, dynamically constructed cmd /c pipeline or broad execution-policy changes are introduced.
- **WVC-M1-02-A04** (manual): Missing .ps1 and inaccessible dependencies result in actionable launcher errors.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
