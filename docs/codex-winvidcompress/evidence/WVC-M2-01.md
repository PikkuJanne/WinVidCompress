# WVC-M2-01 evidence - 2026-10-05

**Verified; A01-A04 passed.** Clean implementation `8efa0b82224fd1793715b2f7369697c71b73fb87` on Windows 11 Pro 10.0.26300 UBR9457 (26H2), PS5.1.26100.9444 Desktop/PS7.6.5 Core. Existing Pester5.7.1/analyzer1.24.0 reused without downloads. [Exact commands/results/report hashes](WVC-M2-01.json).

Each host, serial runs: Focused123/0/0/0, Quick275/0/0/0, Targeted291/0/4/0 (passed/failed/skipped/NotRun), all exit0. Quick/Targeted independently record exact SHA and Dirty=false. Forty-four Probe cases use real Windows synthetic native processes and existing JSON fixtures. Eight Targeted entry cases exercise actual PS1/BAT/menu/doctor routes with recorders. Four installed-tool media skips per host lack FFmpeg/FFprobe; no real FFmpeg/media or new Full/manual/Explorer/milestone/release result.

## Behavior and acceptance

One bounded UTF-8 JSON call per inspected input replaces silent-stderr height-only probing. Literal file selection, retained stdout/stderr/exit, structured failure and invariant normalization preserve optional metadata as null. All stream indices/types/dispositions, coded geometry/rotation/SAR/DAR, pixel/colour/frame rates/time base, audio details and nullable duration are represented. Artwork is excluded from first-real-video candidates. Compression refuses probe/schema/no-real-video failures; unknown duration is allowed with an indeterminate-progress warning and explicit unavailable duration-comparison limitation.

- A01: Actual Windows native exit 23 with stderr, missing executable and 300-ms hang/owned-process cleanup return structured failure; malformed JSON/root/schema, duplicate indices and required codec/coded geometry fail. Native and JSON failures do not dispatch encoding.
- A02: Audio-only, attached artwork only and empty streams refuse encoding; real candidate excludes artwork and is ordered by absolute stream index. Source/existing-final hashes and output inventory remain unchanged.
- A03: Valid video with no duration proceeds through the encoder recorder; DurationSeconds remains null, Unknown state/Indeterminate progress and explicit unavailable duration-comparison warning/limitation. Invalid finite/nonfinite/zero/negative/localized duration stays nullable; valid stream fallback is retained.
- A04: fi-FI/de-DE/en-US parse invariant dot-decimal numbers and rational metadata; extra unknown fields tolerated. UTF-8 native non-ASCII metadata and shell-looking literal source argv survive both hosts.

The probe allows file protocol and rejects playlist demuxer responses; UNC file access and the earlier encoder prevent an absolute offline guarantee. Explicit encoder mapping remains M2-02. Display geometry remains null/MetadataOnly with rotation/SAR transforms deferred to M3-01. Process creation/filesystem/network calls have no total deadline; owned-process cleanup does not track detached descendants. Output transaction/validation/progress/source-change/manifest requirements remain later work. Defaults, flat outputs and sequential processing remain unchanged.

## Git and review

One writer; subagent review was read-only. Minimal scope additions update the existing helper options, characterization/queue mocks and entry JSON responder. UTF-8 review concern has a passing native regression; no remaining material blocker. APPDATA/output/process fixtures are isolated, source/final hashes remain intact and passing roots are cleaned. Raw reports/logs stay ignored under .test-results/m201. No private media, dependencies or logs were staged; legacy PS1 encoding/CRLF retained.

Implementation pushed on `codex/wvc-m2-01-probe`; clean live local/fetch/push equality verified at `2026-10-05T17:30:34.704492+00:00`. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/10); implementation CI 0 checks/0 statuses/0 workflow runs. No CI pass inferred. Final handoff commit/push synchronization remains pending inside this record and is reported externally after commit.

Exact next: **WVC-M2-02 - Select and map the same real video and intended audio**. No task blocker/new owner approval; broader milestone/release gates remain. Stop after this task.
