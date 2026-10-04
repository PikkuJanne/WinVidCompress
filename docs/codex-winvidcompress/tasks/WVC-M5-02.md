# WVC-M5-02 — Build deterministic tool-only release packages and checksums

## Read first

Dependencies: WVC-M5-01. Read AGENTS.md, STATUS.md, NEXT_SESSION.md, this brief and the matching TASKS.json entry. Task status lives only in TASKS.json.

Specifications: ../SECURITY_AND_RELEASE.md.

## Scope

- `tools/package*.ps1`
- `CHANGELOG.md`
- `VERSION*`
- `docs/releases/**`

Existing source files are authoritative. Paths for future tests/helpers are intended scope, not claims those files already exist. Allow the minimal shared helper change needed for this task and document any scope expansion.

## Implementation

1. Choose a version consistent with existing tags after checking GitHub; no version is pre-declared by this bundle.
2. Package using an allowlist: application entry points, actually needed assets, README/help/license/notices.
3. Record version/source commit/tested dependencies; generate SHA-256 checksums from final ZIP bytes.
4. Normalize ZIP ordering/timestamps where supported; test deterministic contents and repeatability before claiming bit-identical builds.

## Acceptance

- **WVC-M5-02-A01** (targeted): Package excludes private config, logs, videos, development fixture output, .git and credentials.
- **WVC-M5-02-A02** (targeted): Two builds from the same inputs have identical file manifests; byte reproducibility is measured and limitations recorded.
- **WVC-M5-02-A03** (targeted): Checksums verify final artifacts and source commit provenance is accurate.
- **WVC-M5-02-A04** (targeted): Packaging creates local candidate artifacts only, no tags/releases/uploads.

## Completion and handoff

Add the focused regression first where practical. Run quick plus relevant targeted tests, inspect the diff for source/file-safety regressions, and record exact commands/results. Do not repeat long unrelated suites at every small change.

Commit only intended implementation/test files. Record tested commit(s), evidence, any real CI result, and next task in the handoff files. Commit the handoff, push the feature branch, then verify local HEAD against live fetch and push endpoints. Keep the worktree clean. A push failure means unsynchronized; do not conceal it behind a completion label.

Final response: task/outcome, changed files, test evidence, current branch/local HEAD/live remote HEAD, PR/CI state, blockers/approvals and the exact next task. Stop after this task unless the owner explicitly requests another ready task in the same thread.
