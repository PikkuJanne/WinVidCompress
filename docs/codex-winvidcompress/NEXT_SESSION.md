# Next session

Exact next **WVC-M3-05 - Add machine progress and privacy-aware persistent logs**. WVC-M3-04 implemented/A01-A03 passed; A04 owner playback observation pending. No default quality approval requested or inferred. M3-01/M3-02/M2-02 already verified; SDR-default approval D006 recorded. M2-06 actual Explorer observation, physical cancellation and historical Full gates remain. One bounded task per thread.

## Preflight and checkpoint

Feature/upstream `codex/wvc-m3-04-benchmarks`/origin/codex/wvc-m3-04-benchmarks, sole origin https://github.com/PikkuJanne/WinVidCompress.git. Owner-merged PR19/main 301ec13 was inspected; feature retains baseline/history. Implementation/tested `60e12b3b80307833cc7dee24c62eaa2c8f094ed4`. Previous clean live equality at 2026-10-06T15:17:13.247272+00:00 matched it on both endpoints. Draft [PR20](https://github.com/PikkuJanne/WinVidCompress/pull/20) open; CI0/no pass. Final documentation SHA/live proof reported externally after commit. Independently inspect/fetch/verify current state before editing; no reset/stash/force/discard/concurrent writer.

Read AGENTS/INDEX/STATUS/GIT_SYNC plus selected task/TASKS/specs/testing. Inspect branch/HEAD/dirty ownership/operations/conflicts/hooks, effective URLs/upstream/live refs; fetch --no-tags and reconcile. Use read-only check_repo_sync.py.

## Accounting and benchmark handoff

Legacy SizeChangeBytes/Percent remain output-minus-input; new SavingsPercent is its inverse. Completed pairs with positive known input and known nonnegative output drive weighted batch totals; unavailable/zero input and other outcomes are disclosed. Duration sums only known completed source durations; elapsed sums attempted job times and excludes queue/summary overhead. Publication survives later accounting/reporting cancellation. Larger valid output is retained; no fixed savings promise.

tools/benchmark.ps1 defaults to short synthetic FFV1/PCM pattern/tone and three repeats, with isolated APPDATA and ignored retained outputs/raw diagnostics. Approved copies are duplicated under opaque names and hashed. Preset-only/CRF-only candidates are experiments; actual path-placeholder tokens/settings/tool/host/source hashes and stage spreads are recorded. Faststart is inside encode/mux time, not separately measured. Existing empty duration-list aggregation guard keeps unavailable-comparison warnings. The committed [measured synthetic example](../benchmarks/2026-10-06-synthetic-windows.json) has six actual runs, every playback field NotRun; representative interview quality/default approval is not established. [Guide/template](../benchmarks/README.md). Owner review was requested; no reply recorded at handoff. Keep private clips/paths/tags/logs out of Git.

## Verification and next implementation

Clean Quick PS5.1 665/0/0/0; Targeted PS5.1/PS7 each 685/0/0/0 at `46d6070c2bd2ac60e200dcd2f1c34faf0c565b9a` for PS5.1 and `60e12b3b80307833cc7dee24c62eaa2c8f094ed4` for PS7 (identical application bytes), all exit0. Targeted includes Quick; no separate PS7 Quick/new Full/Explorer/manual run. [Exact commands/failures/hashes](evidence/WVC-M3-04.json). Actual Windows 11 Pro 10.0.26300 UBR9457/26H2, PS5.1.26100.9444/PS7.6.5, Pester5.7.1/analyzer1.24.0, existing FFmpeg/FFprobe 2026-10-04-git-a35c879992 essentials. Verify tools next host; process-local PATH only, no downloads/system changes. Native compatibility applies to installed build; packaging revalidation remains.

M3-05 adds parsed machine progress and privacy-aware local persistent logs: read its brief/PROCESS_AND_CLI, preserve completion-after-validation/publication, tolerate N/A/partial/locale values, bound diagnostics and redact sharing without telemetry. Do not silently expand into cancellation/resume/CLI milestones. Finish with intentional evidence/status/next/session commit/push, clean live equality and actual PR/CI/tests/omissions. Stop after that task.
