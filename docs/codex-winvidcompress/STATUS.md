# Current programme status

Updated: 2026-10-06. Repository: PikkuJanne/WinVidCompress.

**WVC-M3-02 is verified; A01-A04 passed, including owner colour review/SDR-default approval (D006).** Tasks 16 verified/1 implemented/15 todo; criteria 67 passed/0 skipped/61 not_run. TASKS.json is authoritative. M3-01 and M2-02 remain verified. M2-06 remains implemented with A04 actual Explorer observation pending. No milestone/release acceptance.

## Behavior and boundaries

Selected-stream colour planning rejects PQ/HLG/surfaced HDR metadata and explicit untested RGB/linear/log/V-log/specialized transforms before allocation. Supported YUV SDR requests 8-bit yuv420p, retains known tags and rescales full-range samples to limited range. Ambiguity/wide gamut/reduced bit depth or chroma are disclosed; missing Rec709 tags are not invented. Output validation checks format/planned tags, with only an otherwise untagged limited-range-signalling warning exception. No HDR tone mapping/preservation or general colour management claim. Owner A04 review approved the tested SDR default; D006 records its scope.

PS1/BAT/menu/sequential batches/maps/filename metadata/libx264/veryfast/CRF22/AAC160k/faststart and exact even oriented height cap/no crop/upscale remain. Owned no-clobber publication and job/batch records remain. Structural probes/rendered stills do not prove full visual/audio integrity; stream-level colour metadata cannot establish every per-frame change. Physical cancellation, persistent logs/manifests, UNC/durability/hostile substitution and packaging remain later work.

## Verification

Application `2cc40cd50664c4f674c103f5caa4527ff84b880f`; final test-helper checkpoint `03f6bbb98efbf028191a3ec08934fd700e8447f2`, same application bytes. Clean Quick PS 5.1 588/0/0/0 at 2cc40cd; clean Targeted PS 5.1 and PS 7 each 608/0/0/0 at 03f6bbb, all exit 0. Targeted includes Quick. Native thirteen colour cases cover depth/chroma/range/tag/pixel/chroma checks, HDR refusal and source/final sentinels; 38 focused unit cases. A first Targeted 605/3 failure caused by an incomplete entry recorder is retained, fixed and superseded by actual passing gates. No separate PS 7 Quick or new Full run claimed. Historical Full remains incomplete for eight NotRun rows.

Actual Windows 11 Pro 10.0.26300 UBR9457/26H2, PS 5.1.26100.9444/PS 7.6.5, Pester 5.7.1/analyzer 1.24.0; installed FFmpeg/FFprobe 2026-10-04-git-a35c879992 essentials with process-only PATH prepend. Four-pair synthetic still kit prepared clean 03f6bbb; owner answered PASS — acceptable match; approve SDR default. No overlapping tests/downloads/private media or fabricated manual/CI results. [Evidence](evidence/WVC-M3-02.md), [exact commands](evidence/WVC-M3-02.json), [session](evidence/WVC-M3-02-session.md).

## Git and next task

Feature/upstream codex/wvc-m3-02-colour/origin/codex/wvc-m3-02-colour; sole origin https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR17 into main 0f44b6a, retained preceding feature/history with empty content difference. Previous clean implementation sync at 2026-10-06T14:17:53.984133+00:00 at 03f6bbb matched both live endpoints. Draft [PR18](https://github.com/PikkuJanne/WinVidCompress/pull/18) open. CI 0 checks/0 statuses/0 workflow runs; no CI pass. Final handoff push/live proof reported externally after its commit.

Exact next **WVC-M3-03 - Validate interview metadata dates and preserve text**. Retain M2-06 A04 and physical/manual/full gates. No automated task blocker. Stop after this handoff.
