# WVC-M2-02 evidence - 2026-10-05

**Implemented; A02/A04 passed, A01/A03 skipped pending actual FFmpeg output confirmation.** Clean implementation `ed3a91676c350d6718741d30b7b9f4127286f528` on Windows11 Pro10.0.26300 UBR9457 (26H2), PS5.1.26100.9444 Desktop/PS7.6.5 Core. Existing Pester5.7.1/analyzer1.24.0 reused without downloads. [Exact commands/results/report hashes](WVC-M2-02.json).

Each host, serial: Focused 105/0/2/0, Quick 288/0/2/0, Targeted 304/0/6/0 (passed/failed/skipped/NotRun), all exit0. Quick/Targeted independently record exact SHA/Dirty=false. Thirteen Stream cases use actual Windows native argument recorders, in-memory plans and console assertions. Two installed-tool output tests remain skipped in Focused/Quick/Targeted; Targeted also skips four existing media fixtures. FFmpeg/FFprobe are absent from PATH/adjacent. No actual encode/output/channel/metadata identity or silent completion is claimed; no new Full/manual/Explorer/milestone/release pass.

## Behavior and acceptance

Get-StreamPlan carries the inspection's existing first-real-video object/index into height selection and exact absolute -map tokens. Artwork is excluded. Audio selects the unique default or otherwise the lowest index, including multiple-default ambiguity. Silence has no audio map/options. The plan and console retain selected channels/layout/rate/language/disposition facts and list every omitted index/type/reason. Optional metadata stays unknown. Explicit unknown codec_type stays identifiable; malformed type arrays still fail. libx264/veryfast/CRF22, selected AAC160k and faststart remain; no channel/rate/FPS override or synthetic audio.

- A01 (skipped): Native recorder passes exact inspected VideoIndex-to-map and height coupling with shuffled/noncontiguous multi-video indices. Actual encoded output confirmation is skipped without FFmpeg/FFprobe; recorder argv does not prove produced-media identity.
- A02 (passed): Oversized attached artwork is excluded from the selected real-video index, height cap and native encoder maps; omission is explicit. Actual probe/encoder recorders on both hosts.
- A03 (skipped): Silent native recorder dispatch has only the video map and no audio options; unique/no/multiple-default audio policy and omitted alternatives are visible. Actual silent encode/output-no-audio confirmation is skipped without FFmpeg/FFprobe.
- A04 (passed): The same in-memory plan and console report include selected video/audio indices, coded geometry, known/unknown channels/layout/rate/language/dispositions, and every omitted index/type/reason including artwork, alternate video/audio, subtitle/data/attachment/unknown. No persistent job-report subsystem is introduced.

Mapped-stream metadata/dispositions use FFmpeg defaults; actual muxer read-back remains open. Encoder native execution remains the prior adapter until M2-03. Rotation/SAR transforms remain M3-01; output safety/validation/progress/source-change/manifest requirements remain later. Console reporting is in-memory/per-job, with no new persistent reporting/CLI subsystem.

## Git and review

One root writer; subagent review read-only. Minimal scope additions update existing normalizer/mocks/assertions and behavior docs. A pre-repair PS7 Targeted run exceeded the former 60-second full-Pester-child bound; the tier runner now permits a bounded 120 seconds, retaining separate fixture deadlines. That failed run/owned diagnostics stay local. APPDATA is isolated before include; real-media tests clear/restore FFREPORT and use owned roots. Passing Pester/harness roots are cleaned; raw logs/reports/binaries stay ignored .test-results/m202/temp. Source/existing-final hashes and output inventory remain unchanged in recorder cases. Legacy PS1 UTF-8 without BOM/CRLF retained; no private media/config/dependencies staged.

Implementation pushed on `codex/wvc-m2-02-streams`; clean live local/fetch/push equality verified at `2026-10-05T17:55:31.725417+00:00`. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/11); implementation CI 0 checks/0 statuses/0 workflow runs. No CI pass inferred. Final handoff commit/push equality remains pending inside this record and is reported externally after commit.

Pending: supply already-installed native tools on PATH and run both stream unit/integration suites on both hosts; record versions/tested SHA/output read-back before marking A01/A03 passed or task verified. Exact next safe task: **WVC-M2-03 - Isolate command construction and native process execution**. Usable implemented behavior satisfies its dependency under INDEX; skipped confirmation remains open. Stop after this task.
