# Next session

Exact next task: **WVC-M2-04 - Implement owned temporary output and no-clobber promotion**. M2-03 is verified A01-A04. M2-02 remains implemented A02/A04 passed, A01/A03 skipped without real output confirmation. INDEX allows usable implemented dependencies; retain all pending media checks. One bounded task.

## Current state and preflight

- Root D:/projects/WinVidCompress-main; feature/upstream `codex/wvc-m2-03-process` / `origin/codex/wvc-m2-03-process`; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git.
- Owner merged PR11; inspected main `2be234cf79eba6c413e6a13c624d929bab7f688a` retains prior feature and historical reviewed baseline. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/12); implementation CI 0 checks/0 statuses/0 workflow runs. No CI pass or merge.
- Clean tested implementation `c2e714589afc8bcc910ae9ea8e6aad0fc5ace218`; prior live equality at `2026-10-05T18:24:44.059808+00:00` describes that SHA. Final handoff SHA is reported externally; independently inspect current live state.

Read AGENTS/INDEX/STATUS/GIT_SYNC, M2-04 entry/brief and OUTPUT_SAFETY/TESTING boundaries. Inspect root/upstream/HEAD/dirty ownership, operations/conflicts/hooks, effective URLs/live refs; fetch --no-tags/reconcile ancestry; run tools/codex-winvidcompress/check_repo_sync.py. One writer; preserve unknown changes. No reset/stash/force/main push/discard.

## Next implementation and pending confirmation

M2-04 owns unique same-volume temporary MP4 paths, FFmpeg no-overwrite, no-clobber final promotion with safe collision retry, and own-only failure cleanup/interruption reporting. Do not reserve the exact temp with an empty file then invoke -n. Preserve source/final sentinels, flat output and collision policy. Add meaningful failure/race/promote regressions under both hosts. Keep full structural validation/progress/cancellation tasks separate.

M2-03 provides pure `Get-EncodeArguments` and structured `Invoke-EncodeProcess`, preserving profile/maps/metadata/height policy plus -nostdin. Actual argv uses CRT quoting under PS5.1/PS7; both UTF-8 streams drain/display concurrently, closed stdin, no total encode deadline, bounded post-exit drains, separate diagnostic tails with explicit truncation and guarded resources. Owned-process cleanup failure is tagged WvcAbortBatch and rethrown by Compress-One; preserve this when adding temporary-output cleanup. Pipeline interruption propagates. Direct child only; full Ctrl+C/console-close/tree/graceful cancellation remains M3-06. Done is still native-success until safe publication/validation mature.

M2-02 reuses the inspected first-real-video object/index and unique-default-or-first audio, exact maps and omission reports. Silent sources get no audio map/options; no -ac/-ar/-r drift. Selected metadata relies on FFmpeg mapping defaults. Already-installed FFmpeg/FFprobe on PATH are needed to rerun stream unit/integration suites on both hosts and record binary versions/tested SHA/output read-back before A01/A03/task verification. No downloads. Geometry remains MetadataOnly until M3-01; probe file whitelist does not guarantee offline encoding/avoid UNC.

## Tested checkpoint and handoff

Both actual hosts, clean c2e7145: Focused 122/0/2/0, Quick 305/0/2/0, Targeted 321/0/6/0, ManualArgv 3/0/0/0, all exit0. Existing pins at `Join-Path $env:TEMP 'wvc-m0-02-dev-modules'`. A02 explicit agent-executed native argv inspection passed three exact token/source-hash cases per host; no new owner/Explorer observation required. Eight Targeted entry cases pass. Two real-output tests skipped in all automated scopes plus four Targeted fixture skips. APPDATA/FFREPORT/owned roots are isolated; binaries/raw logs remain local/ignored. No new Full/Explorer/media/CI/milestone/release claim. [Evidence](evidence/WVC-M2-03.json), [session](evidence/WVC-M2-03-session.md).

End each task with intentional evidence/status/next/session commit/push, clean live refs, exact SHAs, tests/skips/PR/CI/pending checks and exact next task. Report final sync externally to its own commit.
