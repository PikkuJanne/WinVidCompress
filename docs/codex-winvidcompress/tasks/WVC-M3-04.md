# WVC-M3-04 — Report savings and benchmark rather than guess

## Read first

Dependencies: WVC-M3-02, WVC-M2-06. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../BENCHMARKS.md.

## Scope

- `WinVidCompress.ps1`
- `tests/unit/*Summary*`
- `tools/benchmark*.ps1`
- `docs/benchmarks/**`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Add original/output bytes, percentage change, duration and elapsed time to each completed result and the batch summary.
2. Represent larger output honestly; do not auto-delete a valid result or lower CRF in repeated trials.
3. Add a reproducible benchmark runner/report template that records tool versions and exact settings.
4. Compare the current preset with optional experimental candidates on disposable representative copies only; retain defaults unless owner approves a measured change.

## Acceptance

- **WVC-M3-04-A01** (targeted): Reduction, growth, zero/unavailable size and cancelled jobs have correct arithmetic and labels.
- **WVC-M3-04-A02** (targeted): No fixed size-reduction percentage is promised in user-facing copy.
- **WVC-M3-04-A03** (targeted): Benchmark fixtures and reports record provenance; private clips and unredacted paths stay outside Git.
- **WVC-M3-04-A04** (manual): Timing and visual/audio judgments are measured/owner-recorded, not fabricated.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.

## Approval gate

Changing CRF, preset, codec, audio bitrate or other default quality/performance policy requires owner approval.
