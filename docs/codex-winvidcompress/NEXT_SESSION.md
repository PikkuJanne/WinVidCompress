# Next session

Exact next task: **WVC-M2-05 - Validate output before marking it complete**. M2-04 is verified A01-A04. M2-02 remains implemented A02/A04 passed, A01/A03 skipped without actual output confirmation. One bounded task; preserve pending checks.

## Current state and preflight

- Root D:/projects/WinVidCompress-main; feature/upstream `codex/wvc-m2-04-output` / `origin/codex/wvc-m2-04-output`; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git.
- Owner merged PR12; inspected main `e7e5bd600bea01e33fd6368dd203b395ed7d0b83` retains prior feature and historical reviewed baseline. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/13); implementation CI 0 checks/0 statuses/0 workflow runs. No CI pass/merge inferred.
- Clean tested implementation `731fa2fce26ad2fbc8b42b2ea2c54fbf8804015e`; point-in-time live equality at `2026-10-05T19:00:32.694633+00:00` describes that SHA. Final handoff SHA is reported externally; independently inspect current live state.

Read AGENTS/INDEX/STATUS/GIT_SYNC, M2-05 entry/brief and OUTPUT_SAFETY/MEDIA_PIPELINE/TESTING boundaries. Inspect root/upstream/HEAD/dirty ownership, operations/conflicts/hooks, effective URLs/live refs; fetch --no-tags/reconcile ancestry; run tools/codex-winvidcompress/check_repo_sync.py. One writer; preserve unknown changes. No reset/stash/force/main push/discard.

## Next implementation and retained boundaries

M2-05 probes the produced temporary media before promotion: require nonempty readable MP4 and expected video/audio structure, compare known duration with a documented fixture-grounded tolerance, disclose unknown-duration limits, and add optional full decode validation for release testing. Reject exit0 bad/empty/wrong/truncated output with source/job identity. Only validated+promoted jobs increment Done. Structural validation is not proof of perfect visual/audio integrity. Keep optional decode from silently doubling every normal encode; if scope is oversized, split explicitly without deleting acceptance.

M2-04 provides New/Assert/Publish/Close-OutputJob. FFmpeg temp remains initially absent under a reserved GUID directory, separate active.owner handle and -n. Two-argument File.Move does not replace final files; only destination-exists errors retry (bound64, original nominal basename) or skip. Media is never deleted by path. Retained.json is CreateNew; foreign records, extra artifacts, substituted paths/junctions and locked files are preserved/reported. Empty directory cleanup is non-recursive. WvcAbortBatch retains even an empty job; original interruption/fatal exceptions survive reporting. Do not weaken these boundaries when adding validation. Ordinary compressed/partial names remain eligible; exact reserved jobs are excluded and read-only output warnings disclose active/orphan jobs without automatic recovery.

Current Done requires native success plus publication, but no nonempty/container/stream/duration check yet. Shared characterization/Probe/Queue/Streams and entry recorders write synthetic invalid-media sentinels to model publication; migrate those mocks minimally for the new validation seam while keeping real-media coverage separate. Existing M2-03 argument/native diagnostics and defaults remain. Full Ctrl+C/console-close/tree/graceful handling stays M3-06; no durable crash ownership/manifests or UNC/hostile-user guarantee.

Already-installed FFmpeg/FFprobe on PATH are still needed for M2-02 A01/A03 output confirmation and real-media validation fixtures; preserve skips and record versions/SHA/output read-back when available. No downloads. Geometry/colour transform policy remains later; maps/defaults/filename metadata should not drift.

## Tested checkpoint and handoff

Both actual hosts: Focused/Quick clean6bed80c; Targeted/Full clean731fa2f: Focused 169/0/2/0, Quick 331/0/2/0, Targeted 347/0/6/0, Full 347/0/6/8. Focused/Quick/Targeted exit0, Full exit2/Incomplete with seven manual and one future coverage row NotRun, zero executed failures. Existing pins at `Join-Path $env:TEMP 'wvc-m0-02-dev-modules'`. 23 unit/three actual concurrent native collision cases per host and eight Targeted entry cases passed. Two real-output skips in Focused/Quick, six media skips in Targeted/Full. Recorders generate no valid media. APPDATA/FFREPORT/output roots isolated; raw diagnostics/binaries ignored. No Full/new Explorer/playback/cancellation/CI/milestone/release acceptance. [Evidence](evidence/WVC-M2-04.json), [session](evidence/WVC-M2-04-session.md).

End each task with intentional evidence/status/next/session commit/push, live clean refs, exact SHAs, tests/skips/PR/CI/pending checks and exact next task. Report final sync externally to its own commit.
