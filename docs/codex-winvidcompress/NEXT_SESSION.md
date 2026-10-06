# Next session

Exact next task: **WVC-M2-06 - Define job results, counters and script exit codes**. M2-05 is verified A01-A04. M2-02 remains implemented A02/A04 passed and A01/A03 skipped without actual output confirmation. One bounded task; preserve pending checks.

## Current state and preflight

- Root D:/projects/WinVidCompress-main; feature/upstream `codex/wvc-m2-05-validation` / `origin/codex/wvc-m2-05-validation`; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git.
- Owner merged PR13; initial inspected main `a23a917a4881d45c9c061a150f83ef865570cf66` includes prior feature/historical baseline. Owner subsequently merged PR14 at aba01e3; fetched current main `f2897dcab0dfffd8d6b80f4f0452b57aeb5b5cd9` has identical content to that checkpoint. Feature c8a3ed0 preserves the correction; the followup draft carries it and this handoff. [Open draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/15); implementation CI 0 checks/0 statuses/0 workflows. No CI pass/merge inferred.
- Clean tested implementation `c8a3ed074e87b8be5e51eb42a3d19c532a8a7ee5`; live equality at `2026-10-06T04:00:09.499705+00:00` describes that checkpoint. Final handoff SHA reported externally; independently inspect current live state.

Read AGENTS/INDEX/STATUS/GIT_SYNC, M2-06 entry/brief and PROCESS_AND_CLI.md/TESTING.md. Inspect root/upstream/HEAD/dirty ownership, operations/conflicts/hooks, URLs/live refs; fetch --no-tags/reconcile ancestry and run check_repo_sync.py. One writer; preserve unknown changes. No reset/stash/force/main push/discard.

## Next implementation and retained boundaries

M2-06 returns job results, reconciles counters plus separate scan errors, and defines exact process exits: 0 completed/no failures, 1 partial/job failure, 2 startup/invalid request/no eligible input, 3 cancellation with precedence. Valid skips are non-errors; distinguish explicit empty batch from menu cancellation. Separate interactive persistence from unattended real exit. Preserve helper dot-sourcing without exiting caller. Its A04 requires actual Windows manual exit/interactive evidence; use honest observations, retain D005 launcher limits and prior owner evidence.

M2-05 currently leaves Compress-One counter-based; validation precedes Publish-OutputJob, and Done increments only after both pass. Invalid output retains job/source/temp/stage/reason and never acquires a final. The helper returns native diagnostics and normal conversion displays probe stderr; retained.json does not persist that stderr. Do not weaken this boundary when introducing result records. Get-OutputValidation holds read sharing, checks FTYP/normalized probe/streams/geometry/duration and returns structured validation. Get-OutputDurationTolerance/Test-OutputStructure are pure seams. Explicit Invoke-OutputDecodeCheck requires matching successful validation and never runs automatically; see OUTPUT_SAFETY.md for timing/fallback/timecode policy and limitations.

M2-04 still reserves an exclusive GUID job independently of initially absent -n temp. File.Move never replaces a final; collision retry/skip and conservative retention remain. Media is never deleted by path; only owned reservation/empty directory cleanup. Fatal termination retains even empty jobs. Reserved jobs are excluded from discovery and read-only warned about. Full Ctrl+C/console-close/graceful/tree handling stays M3-06; manifests/UNC durability/hostile same-user substitution remain open. No default quality/maps/filename metadata/geometry/colour change.

## Tested checkpoint and handoff

Both actual hosts on clean `c8a3ed074e87b8be5e51eb42a3d19c532a8a7ee5`: Focused 243/0/4/0, Quick 405/0/4/0, Targeted 421/0/8/0. Focused/Quick/Targeted exit0; Earlier Full on clean aba01e3: 407/0/8/8, exit2/Incomplete with zero executed failures, seven manual and one future row NotRun. Existing pins at `Join-Path $env:TEMP 'wvc-m0-02-dev-modules'`. 66 unit/eight actual native validation cases per host; entry/concurrent fixtures also pass through validation with synthetic FTYP/JSON, not media. Four Focused/Quick and eight Targeted/Full media skips; no tools downloaded. New real SDR A/V/silent encode/probe/full-decode and existing M2-02 output cases require already-installed FFmpeg/FFprobe on PATH. Record actual versions/commit/output evidence when supplied; do not convert skips to passes by inspection. No Full/new Explorer/playback/cancellation/CI/release claim. [Evidence](evidence/WVC-M2-05.json), [session](evidence/WVC-M2-05-session.md).

End each task with intentional evidence/status/next/session commit/push, live clean refs, exact SHAs/tests/skips/PR/CI and exact next task. Report final sync externally to its own commit.
