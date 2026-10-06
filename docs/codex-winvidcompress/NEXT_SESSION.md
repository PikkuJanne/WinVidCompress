# Next session

Exact next **WVC-M3-04 - Report savings and benchmark rather than guess**. M3-03 verified/A01-A04 passed, no owner approval gate. M3-02 D006 colour approval and M3-01/M2-02 verification remain. M2-06 actual Explorer observation and physical cancellation/Full gates remain pending. One bounded task per thread.

## Current state and preflight

Feature/upstream codex/wvc-m3-03-metadata/origin/codex/wvc-m3-03-metadata; sole origin https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR18 at main c576bef; this feature began from inspected merged main, with reviewed baseline/history retained and no content discarded. Implementation/tested `b955d11b649410745b8de917392401045d4e033d`. Previous clean live equality at 2026-10-06T14:40:20.495057+00:00 on both endpoints. Draft [PR19](https://github.com/PikkuJanne/WinVidCompress/pull/19) open; CI 0 checks/0 statuses/0 runs/no pass. Final documentation SHA/live proof is reported externally after commit. Independently verify current live state before edits.

Read AGENTS/INDEX/STATUS/GIT_SYNC plus the selected task entry/brief and relevant specs/testing. Inspect branch/HEAD/dirty ownership, operations/conflicts/hooks, all effective URLs/upstream/live refs; fetch --no-tags and reconcile. Use check_repo_sync.py read-only. One checkout writer; no reset/stash/force/main push/discard. A final commit cannot contain its own SHA.

## Metadata policy and next implementation

M3-03 counts bounded supported ASCII date candidates across compact/dotted/dashed formats; matching separators and invariant Gregorian validation are required. Multiple candidates (including invalid/repeated), invalid dates, blank band and unsupported patterns omit the entire derived tuple, keep full title, warn and continue compression. The existing whitespace-delimited compact fallback warns that a valid number can be unrelated; filenames cannot establish meaning. Unicode/punctuation remain argument data.

Existing single-input FFmpeg global/selected-stream inheritance remains. Filename title always overrides; a valid artist/date/comment tuple overrides source equivalents. On failure source equivalents can remain. Other compatible/private tags may survive; output is not metadata sanitization. Native MP4 cases verify exact Finnish/German/CJK/Cyrillic/punctuation tags, override/failure inheritance, copyright/audio language, absent source interview tags and unchanged source/final sentinels. Arbitrary mdta-key omission is only one observed case; rerun at the future packaged baseline. Full integrity/player display are not established by tag read-back.

M3-04 adds honest per-job/batch reduction/growth/unknown accounting, no fixed savings promise and a reproducible benchmark runner/report. Read its exact brief and BENCHMARKS; existing result byte/elapsed fields are already present. Use disposable synthetic or explicitly approved representative copies; keep private clips/paths local. Timings and visual/audio judgments must be measured/owner-recorded. Do not change CRF/preset/codec/audio bitrate or default quality without owner approval. No later milestone work implied.

## Tested checkpoint and tools

Clean Quick PS5.1 639/0/0/0 and Targeted PS5.1 659/0/0/0/PS7 659/0/0/0 at `b955d11b649410745b8de917392401045d4e033d`, all exit 0. Targeted includes Quick; no separate PS7 Quick or new Full/manual/Explorer run. Initial native MOV fixture language failure is retained; MP4 source-language precondition and passing gates supersede it without product-language policy changes. [Exact commands/evidence](evidence/WVC-M3-03.json).

Actual Windows 11 Pro 10.0.26300 UBR9457/26H2; PS5.1.26100.9444/PS7.6.5; Pester5.7.1/analyzer1.24.0; existing FFmpeg/FFprobe 2026-10-04-git-a35c879992 essentials. Verify tools next host; only process-local test PATH prepend, no downloads/system changes. No overlapping tests/private media. End with intentional task/evidence/status/next/session commit/push, clean live refs, exact SHAs/tests/omissions/PR/CI and next task. No inferred Full/CI/milestone/release pass.
