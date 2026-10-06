# WVC-M3-03 evidence

2026-10-06. Implementation/tested commit `b955d11b649410745b8de917392401045d4e033d` on `codex/wvc-m3-03-metadata`. A01-A04 passed; no task approval gate. [Exact commands, reports and hashes](WVC-M3-03.json).

Invariant Gregorian validation retains the three filename formats and unchanged title. All supported bounded candidates are counted before selection; invalid/ambiguous/missing/unsupported dates or blank artist omit the entire derived interview tuple and report warnings without stopping compression. The retained compact fallback warns that valid numbers can be unrelated serials. Generated title and valid tuple override source equivalents; other compatible source tags follow the existing FFmpeg single-input policy. This does not sanitize private metadata. [Contract](../MEDIA_PIPELINE.md#filename-metadata), [FFmpeg copying/override reference](https://ffmpeg.org/ffmpeg.html#Advanced-options).

| Criterion | Actual evidence |
|---|---|
| A01 | 43 units: calendar/leap/century/year-zero/day/month/31-February, blank band, longer/embedded/unrelated/repeated/invalid-plus-valid tokens, matching separators and fi-FI/de-DE/en-US/ar-SA cultures. |
| A02 | Native exact UTF-8 Finnish/German and CJK/Cyrillic title/artist/comment/date plus literal shell-looking punctuation read back from validated MP4. |
| A03 | Native invalid-date/invalid-leap/ambiguous/blank-band/no-date cases complete encode/validation/no-clobber publication, with omission warnings and unchanged source/existing-final hashes. |
| A04 | Native source metadata asserted before encoding; valid tuple/title overrides, failure inheritance, absent-source interview-tag omission, copyright and selected audio language retention. Synthetic arbitrary mdta key omitted by this build's standard output muxer; not a privacy guarantee. |

Clean Quick PS5.1 **639/0/0/0**; clean Targeted PS5.1 **659/0/0/0** and PS7 **659/0/0/0**, all exit 0 at the implementation SHA. Counts are passed/failed/skipped/not_run. Targeted includes Quick. Actual Windows 11 Pro 10.0.26300 UBR9457/26H2; PS5.1.26100.9444/PS7.6.5; Pester5.7.1/analyzer1.24.0; existing FFmpeg/FFprobe 2026-10-04-git-a35c879992 essentials. Process-only PATH prepend; no downloads/production configuration/private media/overlapping tests.

Regression-first 1 passed/42 failed is retained. Development units then 43/0; first native 0/8 because MOV fixture did not store the expected audio language (source was unknown). MP4 fixture now verifies stored language before compression; focused native 8/0 and clean gates supersede that fixture failure. Application language policy was unchanged. Detailed logs/media remain ignored/local; public evidence contains sanitized facts/hashes.

Read-only review found no implementation/PS5.1 blocker. Application diff preserves PS1/BAT/menu/sequential processing, maps, geometry/colour, libx264/veryfast/CRF22/AAC160k/faststart and owned publication safety. Minimal scope expansion adds native metadata tests and policy documentation.

Previous implementation sync at 2026-10-06T14:40:20.495057+00:00: local/fetch/push all `b955d11b649410745b8de917392401045d4e033d`, clean. Draft [PR19](https://github.com/PikkuJanne/WinVidCompress/pull/19) open. Actual CI: 0 checks/0 statuses/0 workflow runs; no CI pass. Final handoff push/live proof must be reported externally after that commit.

No separate PS7 Quick or new Full/manual/Explorer result is claimed. Historical Full remains incomplete with eight NotRun rows; M2-06 A04 Explorer and physical cancellation remain pending. No packaged baseline exists; rerun native metadata checks at packaging. Tag/structural checks do not prove player display or full visual/audio integrity. Exact next **WVC-M3-04 - Report savings and benchmark rather than guess**.
