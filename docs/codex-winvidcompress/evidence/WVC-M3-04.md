# WVC-M3-04 evidence

2026-10-06. Application checkpoint `46d6070c2bd2ac60e200dcd2f1c34faf0c565b9a` plus harness-only checkpoint `60e12b3b80307833cc7dee24c62eaa2c8f094ed4`; implemented; A01-A03 passed, A04 owner playback observation pending. Default libx264/veryfast/CRF22/AAC160k/faststart and entry points remain.

Completed records carry original/output bytes, legacy signed output-minus-input deltas, positive saved percent for reductions (negative for growth), explicit size states, source duration, measured total/stage times and actual local encode tokens. Batch accounting weights comparable completed pairs by summed bytes; unknown/zero inputs and other outcomes are counted separately. Published completions remain included even if a later accounting/display cancellation makes exit3. Larger valid outputs are retained. No ratio is calculated from unknown/zero input size and no fixed savings promise exists.

| Gate/actual host | Passed / Failed / Skipped / NotRun | Exit |
|---|---|---|
| Quick 5.1.26100.9444 | 665 / 0 / 0 / 0 | 0 |
| Targeted 5.1.26100.9444 | 685 / 0 / 0 / 0 | 0 |
| Targeted 7.6.5 | 685 / 0 / 0 / 0 | 0 |

Quick/Targeted PS5.1 tested clean `46d6070c2bd2ac60e200dcd2f1c34faf0c565b9a`; final Targeted PS7 tested clean `60e12b3b80307833cc7dee24c62eaa2c8f094ed4`, which changes only the suite deadline/test-policy documentation. Application bytes are identical. Targeted includes Quick; no separate PS7 Quick claimed. Actual Windows 11 Pro 10.0.26300 UBR9457/26H2, PS5.1.26100.9444/PS7.6.5, pinned Pester5.7.1/analyzer1.24.0 and existing native tools. Exact per-run tested SHAs, commands, versions, hashes, cases and initial failures are in [JSON](WVC-M3-04.json).

26 new focused cases (18 summary/policy + 4 benchmark units + 4 native benchmark tests) cover reduction/growth/unchanged/zero/unknown/cancelled arithmetic, weighted exclusions, published-after-cancellation accounting, literal tokens, repeat spreads, real settings/times/provenance, private synthetic markers/paths, retained larger outputs, source hashes and refused-run hashes. Native tests exercise default, medium preset and CRF0 experiments. Static gates now include benchmark scripts. The FFV1/PCM fixture exposed an existing empty stream-duration aggregation error; the minimal Count guard restores existing unavailable-comparison warnings, with regression. No stream duration was invented or structural validation weakened.

Initial PS7 Targeted at 180 seconds timed out: 24 passed/1 harness failure, no Pester report. All 26 affected cases then passed separately on PS7. The suite deadline was raised to bounded 240 seconds; final gate supersedes the timeout without changing fixture limits. Initial summary regression 0/16, then 16/0; initial focused 25/1 was an over-broad privacy assertion matching explanatory text, corrected to exact synthetic secrets and then 26/0. Initial benchmark parser/missing-helper/empty-duration failures remain recorded locally and in JSON; clean final gates supersede them.

The committed [measured synthetic report](../../benchmarks/2026-10-06-synthetic-windows.json) is from six clean sequential runs (three each default/medium), two-second 320x240/24fps testsrc2 + 440Hz/48kHz sine, FFV1/PCM source, input 558507 bytes. It records tool/host/source/runner hashes, actual redacted command tokens and every measured repeat/spread. These are one-host warm-cache synthetic observations, not representative interview quality or a preset recommendation.

| Profile | Median output bytes | Median encode/mux seconds | Total seconds min / median / max |
|---|---|---|---|
| default | 114613 | 0.144010 | 0.349408 / 0.426331 / 0.609862 |
| preset-medium | 116990 | 0.181990 | 0.387218 / 0.391601 / 0.422342 |

Faststart relocation is inside encode/mux timing, not independently measured. Fixture selected-stream durations are unavailable despite known container duration; warning policy remains explicit. Structural validation does not establish full visual/audio integrity. Every playback judgment stays NotRun until actual owner evidence. No private representative copies were used; approved-copy native tests use generated synthetic files. All media/raw diagnostics remain ignored/local; only this inspected synthetic projection is committed. [Runner protocol/template](../../benchmarks/README.md).

Scope expansion: New tests/integration/BenchmarkSummary.Tests.ps1 native coverage outside the unit-only brief glob; minimal tools/test.ps1 static inclusion of benchmark scripts; README user accounting copy; exact local argument/stage measurements on existing result records; empty selected-source-duration aggregation guard found by real FFV1/PCM benchmark, with focused regression. Whole-suite Pester deadline raised from 180 to bounded 240 seconds after real PS7 timeout; individual fixture deadlines unchanged, tests/README updated. No process/output publication refactor or default quality change.

Task counts: 17 verified/2 implemented/13 todo; criteria 74 passed/0 skipped/54 not_run. M3-01/M3-02/M2-02 and SDR approval D006 already verified; corrected stale STATUS/NEXT_SESSION wording. M2-06 A04 Explorer, physical cancellation and historical eight Full NotRun rows remain. No new Full/manual/Explorer/default change/download/system change/automatic upload.

Feature `codex/wvc-m3-04-benchmarks`, sole origin https://github.com/PikkuJanne/WinVidCompress.git. Started from inspected owner-merged PR19/main 301ec13, retaining history/baseline. Previous clean live equality at 2026-10-06T15:17:13.247272+00:00 matched `60e12b3b80307833cc7dee24c62eaa2c8f094ed4` on both endpoints. Draft [PR20](https://github.com/PikkuJanne/WinVidCompress/pull/20), actual implementation CI 0 checks/0 statuses/0 runs, no pass. Final handoff push/live proof follows its commit and is reported externally. Exact next **WVC-M3-05 - Add machine progress and privacy-aware persistent logs**; retain A04 owner review.
