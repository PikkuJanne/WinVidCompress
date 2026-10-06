# Next session

Exact next **WVC-M3-03 - Validate interview metadata dates and preserve text**. M3-02 verified/A01-A04 passed, including owner four-pair colour PASS/SDR-default approval (D006). M3-01/M2-02 verified; M2-06 actual Explorer observation and physical cancellation/full gates remain pending. One bounded task per thread.

## Current state and preflight

Feature/upstream codex/wvc-m3-02-colour/origin/codex/wvc-m3-02-colour; sole origin https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR17 main 0f44b6a; histories/baseline retained with no content difference. Application 2cc40cd50664c4f674c103f5caa4527ff84b880f, final helper 03f6bbb98efbf028191a3ec08934fd700e8447f2, identical application bytes. Previous clean live equality at 2026-10-06T14:17:53.984133+00:00. Draft PR18 open; actual CI 0 checks/statuses/workflow runs, no pass. Final documentation SHA/live proof reported externally after commit. Independently verify current live state before edits.

Read AGENTS/INDEX/STATUS/GIT_SYNC plus the selected task entry/brief and relevant specs/testing. Inspect branch/HEAD/dirty ownership, operations/conflicts/hooks, all effective URLs/upstream/live refs; fetch --no-tags and reconcile. Use check_repo_sync.py read-only. One checkout writer; no reset/stash/force/main push/discard. A final commit cannot contain its own SHA.

## Retained colour evidence and next implementation

Four SOURCE/OUTPUT pairs (8/10-bit BT709 bars, limited/full-range 10-bit ramps) were prepared from clean 03f6bbb with matching application hash. Owner viewed the sheet and answered PASS — acceptable match; approve SDR default on 2026-10-06. D006 records the tested SDR-default approval. Retained ignored report .test-results/m302/colour-review.json contains private local kit paths/provenance; public evidence contains only hashes/sample facts. No repeat is needed for unchanged application bytes. This closes A04; broader playback/display calibration/HDR-conversion and other manual gates remain separate.

M3-02 derives colour anew from the same selected Video for reporting/encode/validation, independent of depth. Known HDR/surfaced metadata and explicit RGB/linear/log/V-log/specialized matrices fail at Colour before allocation. Conventional YUV SDR outputs 8-bit yuv420p, retains known tags and actually rescales full range to limited. Ambiguous fields warn; no invented missing Rec709 or tone mapper. Unknown range VUI can be warned only for otherwise wholly untagged input/output; tagged SDR must match. Stream-level inspection and synthetic stills do not establish full integrity or calibrated playback.

M3-03 covers existing filename date formats/calendar validity/fallback ambiguity/blank band, compression on parsing failure, Unicode metadata and tag precedence/read-back. Read its exact brief/MEDIA_PIPELINE before changing Parse-MetadataFromName. Preserve libx264/veryfast/CRF22/AAC160k/faststart, exact geometry/no crop/upscale, flat output/no-clobber, result outcomes and existing entry points. No later milestone work implied.

## Tested checkpoint and tools

Quick PS 5.1 at 2cc40cd: 588/0/0/0; Targeted PS 5.1 and PS 7 at 03f6bbb: each 608/0/0/0, exit 0, clean trees. Targeted includes Quick; no separate PS 7 Quick or new Full run. Earlier Targeted 2cc40cd had 605 passes/3 entry-recorder failures; those were fixed, isolated eight entry routes passed, and history is retained. Historical Full remains incomplete for eight NotRun rows. [Exact evidence](evidence/WVC-M3-02.json).

Actual Windows 11 Pro 10.0.26300 UBR9457/26H2; PS 5.1.26100.9444/PS 7.6.5; Pester 5.7.1/analyzer 1.24.0; existing FFmpeg/FFprobe 2026-10-04-git-a35c879992 essentials, process-only test PATH prepend from owner-provided external folder. Verify tools again on next host; no dependency downloads/system changes. No overlapping tests or private media. End each task with intentional evidence/status/next/session commit/push, clean live refs, exact SHAs/tests/omissions/PR/CI and next task. No inferred Full/CI/milestone/release pass.
