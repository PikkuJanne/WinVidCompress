# Current programme status

Updated: 2026-10-05. Repository: PikkuJanne/WinVidCompress.

**WVC-M1-05 is verified; A01-A04 passed.** M0-01/M0-02/M0-03/M1-01/M1-02/M1-03/M1-04/M1-05 are verified; 24 tasks remain todo. Criteria: 32 passed, 96 not_run. TASKS.json is authoritative. No milestone/release acceptance.

## Behavior and supported boundary

All selections are scanned before the first encode; a deterministic ordinal case-insensitive queue deduplicates overlapping/repeated normalized paths and ordinary extended aliases. Found counts unique sources. Selection-level Scanned/Scan errors and all partial-failure diagnostics remain visible before sequential encoding. Originals in equal/nested destinations and compressed/partial filenames remain eligible. Input/output equality uses rename/skip and an explicit nonidentity guard; compression defaults, flat output and FFmpeg -n remain.

Freeze covers candidate paths, not source bytes or file IDs. Hard links/8.3/mapped-drive-versus-UNC aliases can remain separate jobs. There is no current trusted ownership manifest/owned media-temp protocol; actual proven-ownership exclusions, source-change detection, temporary transactions, validation and promotion remain later work. Reparse discovery keeps its documented stable-filesystem race boundary.

M1-03 config safety, M1-02 owner-approved D005 launcher routes and M1-04 actual owner path observations remain verified. No completed manual check was repeated. Broader Explorer multi-drop/remote SMB/media/milestone/release acceptance remains incomplete.

## Verification

Clean implementation `e5b2c86acdad84d33500fc8b5d37fe538271215d`, Windows 11 Pro 10.0.26300 UBR9457 (26H2), PS 5.1.26100.9444 Desktop/PS 7.6.5 Core. Existing Pester 5.7.1/analyzer 1.24.0 reused. Each host: Focused 69/0/0/0, Quick 200/0/0/0, Targeted 214/0/4/0 (passed/failed/skipped/NotRun), exit 0, serial runs. Twenty-two queue regressions include actual dispatch with CreateNew file-writing encoder recorders and unchanged source/final hashes. Four media skips per Targeted run lack FFmpeg/FFprobe. No real-media success or new manual/Full result is claimed.

Read-only review caught a draft PS5.1 long-key regression; provider normalization and a supported-host regression fixed it before the clean tested commit. Final review found no material issue. [Evidence](evidence/WVC-M1-05.md), [exact commands/results](evidence/WVC-M1-05.json), [session](evidence/WVC-M1-05-session.md). Raw reports/logs remain under ignored .test-results/m105; Pester/owned harness fixture roots are cleaned on passing runs.

## Git and next task

Feature/upstream `codex/wvc-m1-05-queue` / `origin/codex/wvc-m1-05-queue` at D:/projects/WinVidCompress-main; sole origin fetch/push URL https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR7; inspected main `8081fd5275aa8aa56ebe41b2002881dd1c69e70c` contains previous feature history and has the same tree. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/8); zero implementation-head CI/status/workflow checks/runs, no CI pass.

Previous clean live local/fetch/push equality at 2026-10-05T16:42:19.730864+00:00 describes implementation `e5b2c86acdad84d33500fc8b5d37fe538271215d`. Final handoff documentation commit/push equality is pending here and reported externally; no self-SHA loop.

Exact next: **WVC-M1-06 - Add dependency and output-environment diagnostics**. No M1-05 task blocker or new owner approval remains. Stop after this handoff.
