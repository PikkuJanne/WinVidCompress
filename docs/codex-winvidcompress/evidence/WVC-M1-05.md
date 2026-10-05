# WVC-M1-05 evidence - 2026-10-05

WVC-M1-05 is verified; A01-A04 passed on the supported Windows hosts. This is bounded queue acceptance, not milestone/release acceptance. Tested clean implementation: `e5b2c86acdad84d33500fc8b5d37fe538271215d`; base: `8081fd5275aa8aa56ebe41b2002881dd1c69e70c`.

All selections now finish discovery before encoding. The queue deduplicates normalized Windows path aliases with ordinal ignore-case comparison, chooses a stable invocation spelling and sorts once. Found counts unique sources; complete selection and scan-error counts remain independent. Each diagnostic is printed before encoding. Input/output equality explicitly applies rename/skip and refuses an identical renamed path before probing/native invocation. Sequential processing, flat output, source/final preservation, `-n` and compression defaults remain.

| Criterion | Actual evidence on both hosts |
|---|---|
| A01 | File+parent, parent+child and repeated selections; case/relative/dot/PSDrive/provider/extended aliases; selection/culture-independent order; stable alias spelling; injected long-path keys. Real hard links are separate documented identities. |
| A02 | Every scan completes before first encoder call; newly created output/partial paths cannot join. File-writing CreateNew encoder recorders run actual Process-Paths with equal/nested destinations and overlapping roots. |
| A03 | Existing destination MP4s, `(compressed)` and `.partial` originals stay eligible; source and existing-output hashes are unchanged. |
| A04 | Ordinary/extended source-output equality triggers safe suffix despite a raced existence check; skip policy works; an identical renamed output fails before probe/encode. Missing/partial read failures remain visible before readable siblings encode once. |

Windows 11 Pro 10.0.26300 UBR9457 (26H2); PS 5.1.26100.9444 Desktop and PS 7.6.5 Core. Existing Pester 5.7.1 and analyzer 1.24.0 modules reused; no dependency download. Six clean-commit runs were serial; all exits0:

| Scope | PS5.1 passed/failed/skipped/NotRun | PS7 passed/failed/skipped/NotRun |
|---|---|---|
| Focused queue+discovery+characterization | 69/0/0/0 | 69/0/0/0 |
| Quick | 200/0/0/0 | 200/0/0/0 |
| Targeted | 214/0/4/0 | 214/0/4/0 |

The 22 queue regressions use isolated APPDATA/TestDrive, synthetic sentinels and encoder recorders. Real read-sharing denial and hard links are exercised. Exact commands, hosts, counts, artifact hashes and limitations: [JSON](WVC-M1-05.json). Raw JSON/stdout stay under ignored `.test-results/m105`; no private paths/config/logs/media are committed.

Regression-first draft on unchanged base: 3 pass/12 fail, expected exit 1; implementation resolved the defects. One draft host-message substring assertion was repaired. Read-only review identified a PS5.1 `.NET GetFullPath` long-path regression before the implementation commit; provider normalization and a supported-host long-key regression fixed it. Final review found no material issue.

Freeze means a candidate-path snapshot, not immutable media or file-ID identity. Hard links/8.3/mapped-drive-versus-UNC aliases may still produce separate jobs. Current code has no proven owned media artifacts to exclude; ambiguous existing files remain eligible. Actual trusted ownership exclusions belong with M2-04/M3-07. Size/mtime change detection, temporary transactions, structural validation and race-safe promotion remain later work. Injected long and synthetic UNC keys do not claim new Windows IO/manual evidence; prior M1-04 IO/manual evidence remains scoped to that task.

Four media fixture skips per Targeted host lack FFmpeg/FFprobe; recorder success is not real-media/playback validation. No new Explorer/manual/Full run or owner approval was required by these four targeted criteria. Broader Explorer, milestone and release gates remain incomplete.

Feature `codex/wvc-m1-05-queue`; implementation checkpoint was pushed with an explicit refspec and clean live fetch/push equality at 2026-10-05T16:42:19.730864+00:00. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/8); implementation has zero check/status/workflow runs, so no CI pass. Final documentation commit/push/live equality is pending in this committed record and reported externally after that commit. Exact next: **WVC-M1-06 - Add dependency and output-environment diagnostics**.
