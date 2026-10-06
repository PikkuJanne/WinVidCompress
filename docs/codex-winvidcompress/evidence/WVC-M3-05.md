# WVC-M3-05 evidence

2026-10-06. **A01-A04 passed; task verified on both actual Windows PowerShell hosts.** No milestone/release or physical-cancellation acceptance.

Initial implementation/Quick: `0c53f73c374d68eb275c48370c5aae659038f67e`. Final implementation/tested: `371ff2f8a17a97dca2053228f8075d33b24a4897`. Application SHA256 `ee17172f2071b764b2565fe301f27e55695f420fb0a33d737272bb9c4f9bc064`. Actual Windows 11 Pro 10.0.26300 UBR9457/26H2; PowerShell 5.1.26100.9444/7.6.5; Pester 5.7.1/analyzer 1.24.0; existing FFmpeg/FFprobe 2026-10-04-git-a35c879992 essentials. Exact commands, report hashes, failures and build hashes are in [JSON](WVC-M3-05.json).

| Gate | Commit | Passed/failed/skipped/not-run | Exit |
|---|---|---|---|
| Quick PS5.1 | 0c53f73 | 704/0/0/0 | 0 |
| Final Targeted PS5.1 | 371ff2f | 725/0/0/0 | 0 |
| Final Targeted PS7 | 371ff2f | 725/0/0/0 | 0 |

Every final gate used a clean tree. Targeted includes Quick; no separate PS7 Quick or new Full/manual run. Forty new regressions: 26 progress units, 12 log units and two native progress cases, plus upgraded entry-route assertions.

| Acceptance | Observed coverage |
|---|---|
| A01 | Every character split, CRLF/unterminated end, invariant cultures, N/A/negative/nonfinite/overflow/invalid values, timestamp priority, bounded malformed recovery, monotonic position, unknown duration; actual chunked Windows recorder/concurrent stderr and installed FFmpeg progress. |
| A02 | End/native exit never makes Completed/100. Validation and no-clobber publication precede completion; validation/promotion failures and collision skips stay below 100 with unchanged source hashes/owned retention. Display cancellation preserves published outcome and cancellation signal. |
| A03 | Actual version/application hash/settings/tokens/job IDs/stage/error tails, incremental outcomes, JSON/text limits/truncation and real exclusive write/quota/lock failures with visible warning-only policy. Managed stdout/stderr does not flood the console; failure prints useful bounded stderr. Actual direct PS1 on both hosts/BAT checks compare persistent records with two published sentinels/source hashes. Doctor creates no logs. |
| A04 | Default local export strips structured/argument paths, Unicode filenames/stems/generated metadata and unknown diagnostic/build text while preserving IDs/enums/settings/native failure kind/exit. Selected detail, extra roots and filename options tested. CreateNew prevents export/original-report clobbering. Source adds no upload/telemetry/network/export-on-start mechanism. |

Initial focused 23/9 then 28/4 failures exposed integer Math.Min/Max overload rounding, nested token arrays and unsuitable recursive/session mock setup; repaired. Peer review caught short-stem replacement corrupting IDs/settings, spaced build path leakage, display cleanup swallowing cancellation and hidden actionable stderr; fixed with regressions. Final focused quota/progress/native PS5.1 run passed 50/0/0/0.

Initial Targeted PS5.1 721/3/0/0 at 0c53f73 failed direct PS1 both-host/BAT batch smoke because those fixtures required suppressed raw recorder stdout. Actual batches completed/published two files per route. Recorder argv now goes to an owned Base64 file; original source/temp/final/sentinel/hash assertions remain, with log-agreement and raw-output/doctor-no-log assertions added. Both standalone entry reruns passed 8/0/0/0. Final gates supersede the failed run, which remains recorded.

Only root wrote this checkout; peer design/final/entry reviews were read-only. Scope expansion is minimal existing encoder/entry fixtures and docs required by managed stdout/session logging. PS1/BAT/menu/sequential batches/default profile/maps/geometry/colour/metadata/publication retain the contract. BAT and native timeout/deadline policy are unchanged.

Private logs stay local under isolated APPDATA in tests. Each report caps at 1 MiB; 128-session admission uses an exclusive quota lock, without automatic deletion. Failures warn without relabeling valid output or changing batch exit. Default sharing omits arbitrary diagnostic/tag text; explicitly retaining metadata requires review. Logs can be partial after pipeline/console/crash interruption. Finalizing is the native end/exit boundary, not separately measured faststart. Structural checks do not prove full media integrity.

Draft [PR21](https://github.com/PikkuJanne/WinVidCompress/pull/21) is open. Actual final implementation has zero checks/statuses/workflow runs, combined pending; no CI pass. Prior clean live proof at 2026-10-06T15:48:48.631578+00:00 matched 371ff2f on local/fetch/push. Final handoff commit/push/live equality is reported externally after commit; no self-SHA loop.

M2-06 Explorer A04, M3-04 owner playback A04, physical cancellation and historical Full gates remain. Exact next **WVC-M3-06 - Cancel safely and terminate only this job’s child process**. Stop after this task.
