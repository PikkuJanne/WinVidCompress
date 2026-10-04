# WVC-M0-01 evidence — actual local import and synchronization

Recorded 2026-10-04 by Codex for PikkuJanne/WinVidCompress. Acceptance: WVC-M0-01-A01 through A04. Machine-readable commands/results: [WVC-M0-01.json](WVC-M0-01.json).

Actual root: `D:/projects/WinVidCompress-main`; branch `codex/wvc-m0-01-handoff`; upstream `origin/codex/wvc-m0-01-handoff`; fetch/push origin `https://github.com/PikkuJanne/WinVidCompress.git`.

## Reconciliation and bounded changes

The original open folder lacked Git metadata. Existing/parent AGENTS.md was absent. Import was held while all seven local files were compared by raw Git blob hash with live GitHub main `5bab7fc698d153128babe3421ce19c0ca3012cc5`; inventories and every blob matched. No unknown/dirty source was discarded. No newer live source or prior feature branch/PR existed. The historical baseline was used for comparison only; BASELINE.json was preserved.

Git tracking was reconstructed in the same directory from fetched live history: initialize the absent metadata, add the verified origin, fetch without tags, create the previously absent feature ref at the observed fetched commit, populate only the index with `git read-tree`. No working-file checkout, stash, reset, clean, force-push or history replacement took place. Git metadata/commit identity are local configuration and are not part of the committed handoff additions.

The importer and every payload file were reviewed. Preview left all worktree file names and SHA-256 hashes unchanged. Apply was bound to observed full HEAD `5bab7fc698d153128babe3421ce19c0ca3012cc5` using `--apply --expected-head`; it added exactly 62 missing handoff files, all matching the external payload hashes. All seven original files were unchanged before and after import. New AGENTS.md overwrote no existing owner instructions. The raw payload started with 32 todo tasks and 128 not_run criteria. Only M0-01 progressed; no reviewed application improvement is implemented by this import.

Import implementation/tested checkpoint: `7fce9895d5e14554b78d82958c1ed7917a4b20ac`. The isolated suite exercised matching helper payload code in the external bundle; its results are not application tests. The final evidence/status additions are a subsequent handoff commit whose SHA must be verified externally after push.

## Checks and actual outcomes

Host: Windows 11 Pro 10.0.26300, PowerShell 7.6.5 Core, Python 3.14.7, Git 2.56.0.windows.1, GitHub CLI 2.97.0. Existing Python/Git/authenticated CLI were used; nothing was installed. Windows PowerShell 5.1.26100.9444 and PowerShell 7.6.5 are available (version queries only), but application compatibility was not tested. FFmpeg/FFprobe were not found on PATH or in the repository.

- Quick: complete local/live file inventory and raw blob comparison, 7/7 matched; no unknown files.
- Quick: importer preview, exit 0; 62 add actions, zero conflicts/issues, identical before/after worktree inventory/hashes.
- Quick: exact-HEAD apply, exit 0; 62/62 additions matched payload hashes, 7/7 originals unchanged.
- Targeted: `python -B -m unittest discover -s bundle-tests -v` in external BUNDLE_PATH, 48 tests in 79.077s, exit 0; 47 passed, 0 failed, 1 skipped. `test_25_destination_symlink_escape_is_refused` skipped because Windows symlink creation was unavailable. This differs from the bundle author's historical Linux 48/48 result; link-escape coverage is unverified on this host.
- Preservation checks passed: tests 16/17 refuse absent/stale expected HEAD; 19 preserves dirty work; 21 blocks all writes on AGENTS conflict; 22 preserves differing owner guidance explicitly; 24 refuses overwriting a changed tracker. These fixture tests cover refusal behavior; the real source tree contained no dirty source changes.
- Quick: external and installed `validate_tracker.py`, exit 0; 32 tasks, 128 criteria, all 23 improvements, no errors.
- Quick: staged diff contained only 62 authorized additions; `git diff --cached --check` exit 0. Original PS1/BAT/README/LICENSE/assets have no diff against live main, and their original hashes are in JSON.
- Manual/live: explicit feature push succeeded and established matching upstream. Read-only `check_repo_sync.py` exit 0 at `2026-10-04T15:35:55.240343+00:00`; local, live fetch and live push feature HEAD all `7fce9895d5e14554b78d82958c1ed7917a4b20ac`, worktree clean, no operations/conflicts.
- Manual/live: draft PR [#1](https://github.com/PikkuJanne/WinVidCompress/pull/1) created and attached; OPEN, draft, base main, head equals tested checkpoint. GitHub reported zero workflow runs/check runs for that checkpoint, with an empty PR checks list; CI was not run.

No application, media, Explorer, benchmark, or PowerShell 5.1 compatibility execution was performed. Existing PS1/BAT workflow and libx264 / veryfast / CRF 22 / AAC 160k / MP4 +faststart defaults are unchanged. No private media, config, raw logs or credentials were included.

## Acceptance and final handoff

A01 passed from real root/identity/clean-feature/source evidence. A02 passed from preserved unexpected initial state and isolated dirty/conflict refusal checks. A03 passed from actual non-mutating preview and scoped exact-HEAD import. A04 passed at the preceding real GitHub checkpoint recorded above. All evidence is specific to its tested tree/commit.

The final handoff commit's push verification is **pending when this record is committed**. Commit status/evidence/continuity, push the feature branch, run the checker against the actual root, and report final local/live fetch/live push SHA equality externally. Do not put this record's own SHA inside itself. If that final check fails, report unsynchronized/unknown and the exact pending action. Next session repeats live verification.

Next task: **WVC-M0-02 — Characterize existing behaviour and add the smallest test seam**. No handoff blocker is pending. Keep PR draft. Main merge/push, quality changes, tags/releases, repository settings/secrets, dependency bundling/signing and website deployment remain owner approval gates.
