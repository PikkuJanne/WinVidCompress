# WVC-M1-03 configuration evidence

Recorded 2026-10-05. All A01-A04 passed; task verified. No config-specific manual criterion or owner gate applies. Broader milestone/release acceptance remains outstanding. [Exact commands/results](WVC-M1-03.json), [session](WVC-M1-03-session.md), draft [PR #6](https://github.com/PikkuJanne/WinVidCompress/pull/6).

Clean tested implementation: `4582ce187ee7b3179785bc29b7e61352c8e7cb76`, from inspected main `2f6f4eed33bf8458f520b90da4b0f24efdd7ec32`. Windows 11 Pro 10.0.26300 UBR9457, Windows PowerShell 5.1.26100.9444 Desktop and PowerShell 7.6.5 Core. Existing pinned Pester5.7.1/PSScriptAnalyzer1.24.0 reused; no dependency download.

| Scope | Passed | Failed | Skipped | NotRun | Exit |
|---|---:|---:|---:|---:|---:|
| Focused config, each host | 47 | 0 | 0 | 0 | 0 |
| Quick, each host | 154 | 0 | 0 | 3 | 0 |
| Targeted, each host | 168 | 0 | 4 | 3 | 0 |
| Full, both hosts | 318 | 6 | 4 | 8 | 1 |

Full's six failures are exactly empty/single-folder/explicit-single-file discovery regressions for M1-04 on each host. Four media fixtures skip because FFmpeg/FFprobe are unavailable; eight broader manual/future checks remain NotRun. Quick/Targeted leave only the three discovery defects NotRun. Neither a structural fixture check nor a native argument recorder establishes full media integrity.

Initial overlapping PS7 Quick/Targeted attempts failed at the harness timeout: respectively 4/1/0/0 and 18/1/4/0 (pass/fail/skip/NotRun), exit1. Quick's process-tree termination raced an already exited PID. After all relevant runs ended, no active processes referencing the failed owned fixture roots remained. Serial Quick/Targeted reruns passed on the same clean commit. Concurrency is an observed circumstance, not a measured diagnosis; the original failed reports remain in the local archive and JSON evidence.

## Acceptance mapping

| Criterion | Observed evidence |
|---|---|
| A01 | Isolated first-run OutputDir-only creation; 20 cases cover empty/invalid JSON, null, {}, [], singleton-object array, numeric/string/bool roots, null/number/bool/array/object/blank OutputDir and invalid relative/provider/URL/wildcard syntax. Recovery preserves exact original bytes and prints its reason/backup. |
| A02 | Simulated unavailable drive and UNC share plus simulated access denial; real Windows listing ACL denial with finally restoration; real file-as-directory sentinel. Saved bytes stay exact and defaults are not consulted. |
| A03 | Isolated APPDATA/output per case; real config read/replace sharing failures, real exclusive-lock contention and no-clobber temp/backup collisions; simulated temp-write/backup/promotion faults, racing first-run file, stale and case-sensitive snapshot checks. Config/source sentinels survive; owned temps are cleaned. Failed menu save retains the active preference. |
| A04 | Legacy valid load stays byte-unchanged. Unknown nested object/array/null/bool/numeric/Unicode keys and timestamp strings survive compatible saves with exact previous-copy backup. Excessive nesting is refused before PS5.1 truncation; older PS7 date-format normalization is documented. |

## Implementation and limits

Raw root syntax is checked before ConvertFrom-Json can unwrap arrays; property presence/type and absolute Windows path syntax are checked before strict property access. Schema recovery is separate from config-read and saved-destination availability failures. First-run/recovery defaults require a nonempty, absolute, accessible known Videos folder; no arbitrary fallback is chosen.

Saves hold an exclusive persistent sidecar lock, compare an exact loaded byte snapshot, write/flush/verify an owned sibling CreateNew temp, preserve a unique no-clobber previous/invalid copy, then File.Replace or no-clobber File.Move. PS5.1 needs `[NullString]::Value` for File.Replace's null backup parameter. Backups are retained and not automatically pruned; lock deletion is avoided because it can race another instance. Menu preference changes commit to disk before modifying the active config.

The participating-instance lock and stale check cannot guarantee races with external editors that ignore the lock. Network filesystems/crashes/power loss were not exercised; local Windows primitive checks do not establish identical remote atomicity/durability. Output listing checks create no output file and cannot prove every future write will succeed. JSON object/array depth above100 is refused. DateKind String is used where supported; older PS7 hosts may normalize ISO timestamp formatting through normal DateTime parsing. Tested PS5.1/PS7.6.5 preserve the tested timestamp exactly.

The only test scope expansion is graduating the existing M1-03 characterization from KnownDefect into normal coverage; specification/developer/tracker/handoff docs accompany the implementation. BAT and encoder/quality/default media settings are unchanged. WhatIf/CheckEnvironment remain later CLI work. Actual Explorer/UNC/media/playback/manual acceptance remains a broader gate; this config task's acceptance method is Pester plus filesystem fault injection.

## Artifacts and synchronization

Nine reports and nine stdout logs were copied to ignored `.test-results/m103-4582ce1` with SHA256 equality verified. Five owned diagnostic roots (49 files) were archived with file hashes checked, then cleaned after ownership/temp-containment/reparse/process checks. Raw paths, environment values, generated native fixtures and diagnostics stay outside Git. Only sanitized commands/counts/case IDs are committed.

Implementation pushed on `codex/wvc-m1-03-config`; live local/fetch/push equality and clean state checked at `2026-10-05T15:08:48.811892+00:00` for `4582ce187ee7b3179785bc29b7e61352c8e7cb76`. PR #6 is draft/open; zero check/workflow runs at that checkpoint, no CI pass. Final documentation handoff push/check is pending at commit time and reported externally after commit, avoiding a self-SHA loop. Exact next task: **WVC-M1-04**.
