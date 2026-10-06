# Next session

Exact next **WVC-M3-06 - Cancel safely and terminate only this job’s child process**. M3-05 verified/A01-A04 passed on both actual Windows PowerShell hosts. M3-04 owner playback A04, M2-06 actual Explorer A04, physical cancellation and historical Full gates remain. Geometry/colour/streams and D006 already verified/approved. One bounded task per thread; no default quality approval inferred.

## Preflight and checkpoint

Feature/upstream codex/wvc-m3-05-progress-logs/origin/codex/wvc-m3-05-progress-logs; sole origin https://github.com/PikkuJanne/WinVidCompress.git. Owner-merged PR20/main 9fcffc4 inspected; prior feature/baseline history retained. Final implementation/tested 371ff2f8a17a97dca2053228f8075d33b24a4897. Previous clean live equality at 2026-10-06T15:48:48.631578+00:00 matched it on local/fetch/push. Draft [PR21](https://github.com/PikkuJanne/WinVidCompress/pull/21) open; CI0/no pass. Final handoff SHA/live proof reported externally after commit. Independently inspect/fetch/verify before editing with read-only check_repo_sync.py; no reset/stash/force/discard/concurrent writer.

Read AGENTS/INDEX/STATUS/GIT_SYNC, selected brief/TASKS and relevant output/process/testing specs. Inspect HEAD/dirty ownership/operations/conflicts/hooks/effective URLs/upstream/live refs; fetch --no-tags and reconcile. Keep source/final media untouched and tests isolated.

## Progress/log handoff

Get-EncodeArguments adds only -nostats/-progress pipe:1. Invoke-EncodeProcess takes an optional caller-runspace ProgressContext; raw developer/decode mode remains. Parser keeps four fields and at most 4096 unfinished characters, prefers microsecond fields then timestamps, tolerates N/A/locale/malformed values and holds percentage below100 until successful validation/publication. Finalizing reflects end/exit, not exact faststart start. Approximate ETA covers encode only. Display cleanup preserves existing cancellation signals and completed output.

Normal startup owns New-SessionLog/SessionLog; Process-Paths appends projected jobs before scheduling the next; completion appends session exit/counters. Schema1 JSONL/text live under APPDATA/WinVidCompress/logs. One MiB/file with paired truncation markers, 128-session admission serialized by quota.lock, no automatic deletion. Log warning-only policy preserves results/exits. Doctor and pre-session startup failures write no logs; standalone Compress-One keeps null LogPath. Raw private paths/tokens/tails stay local. Default explicit Export-WvcDiagnostic omits arbitrary diagnostic/tag text and preserves IDs/settings/native failure summaries; optional retained metadata requires review. [Policy/example](PROCESS_AND_CLI.md).

M3-06 must preserve bounded streams/owned direct-process cleanup and the no-clobber transaction while adding controlled/graceful cancellation, stop-scheduling and report/log agreement. Current pipeline/console/crash logs can be partial; physical Ctrl+C is unverified. Carry any new cancellation signals in projection without relabeling completed/skipped outcomes. Never terminate by global process name or overwrite/delete sources/finals. Follow its actual Windows manual brief; scripted OperationCanceledException seams do not prove physical Ctrl+C.

## Verification

Clean Quick PS5.1 at 0c53f73: 704/0/0/0. Clean final Targeted PS5.1/PS7 at 371ff2f: each725/0/0/0, all exit0; Targeted includes final Quick scope. Forty new unit/native regressions plus actual direct PS1 both-host/BAT argv/sentinel/session checks. Initial Targeted721/3 failed only obsolete raw recorder stdout expectations, retained/corrected; standalone entry8/0 twice and final gates pass. [Exact commands/reports/failures](evidence/WVC-M3-05.json).

Actual Windows 11 Pro 10.0.26300 UBR9457/26H2, PS5.1.26100.9444/PS7.6.5, Pester5.7.1/analyzer1.24.0, FFmpeg/FFprobe 2026-10-04-git-a35c879992 essentials. Verify next host; process-local PATH only, no downloads/system changes. No separate PS7 Quick/new Full/Explorer/playback/manual run; historical Full eight NotRun rows remain. Existing synthetic benchmark retains unfilled playback and does not establish representative interview quality. Structural checks do not prove full media integrity.

Finish one task with intentional code/test/evidence/status/next/session commits and push, actual test/CI/PR state, clean live local/fetch/push equality and explicit omitted/owner checks. Stop after that task.
