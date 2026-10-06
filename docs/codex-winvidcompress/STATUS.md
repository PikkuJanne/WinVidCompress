# Current programme status

Updated: 2026-10-06. Repository: PikkuJanne/WinVidCompress.

**WVC-M3-01 is verified; A01-A04 passed, including owner geometry observation.** Tasks 15 verified/1 implemented/16 todo; criteria 63 passed/0 skipped/65 not_run. TASKS.json is authoritative. Existing real-media checks also close M2-02 A01/A03; that task is verified. M2-06 remains implemented with A04 actual Explorer menu/prompt observation pending. No milestone/release acceptance.

## Behavior and boundaries

Selected-stream geometry now caps vertical raster height after one default autorotation, rounds dimensions to even without enlargement/crop, preserves known display aspect through SAR and validates exact output dimensions/residual transforms. No 1920 width bound, square-pixel conversion, quality/audio/FPS change. Unsupported malformed/noncanonical/arbitrary display transforms fail before allocation. PS1/BAT/menu/sequential batches/maps/filename metadata/owned no-clobber publication and records remain. Colour compatibility, physical cancellation, persistent logs/manifests, UNC/durability/hostile substitution and packaging remain later work. Structural checks do not prove full visual/audio integrity.

## Verification

Application `7e09068d63799dbfe9b2a83b62bb4c003f61a134`, final test-helper checkpoint `02a07baff854d647c82e5758c21a66a00fa66dd6`, same application bytes. Quick PS 5.1 537/0/0/0 at 7e09068 and PS 7 537/0/0/0 at 02a07ba; Targeted PS 5.1 557/0/0/0, PS 7 557/0/0/0 at 02a07ba, all exit 0. Full both hosts 1090/0/0/8 at 02a07ba, exit 2/Incomplete for eight NotRun rows. Actual Windows 11 Pro 10.0.26300 UBR9457/26H2, PS 5.1.26100.9444/PS 7.6.5, Pester 5.7.1/analyzer 1.24.0. Existing FFmpeg/FFprobe 2026-10-04-git-a35c879992 essentials build, process-only PATH prepend. Native geometry/pixel/SAR/source-final safety and HFR/VFR checks passed; owner PASS for all six visual pairs. No overlapping tests, downloads/private media or fabricated manual/CI results. [Evidence](evidence/WVC-M3-01.md), [exact commands](evidence/WVC-M3-01.json), [session](evidence/WVC-M3-01-session.md). Full remains incomplete for eight unrelated manual/future rows.

## Git and next task

Feature/upstream `codex/wvc-m3-01-geometry` / `origin/codex/wvc-m3-01-geometry`; sole origin https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR16 into main 3ce6f66; prior feature/historical baseline retained with empty content difference. Clean implementation live equality at 2026-10-06T13:38:56.437975+00:00. CI 0 checks/0 statuses/0 workflow runs, no CI pass. Draft creation and final handoff SHA/live equality reported externally after the documentation push.

Exact next **WVC-M3-02 - Define SDR compatibility and reject untested HDR conversions**. Retain M2-06 A04 and Full manual/future rows. No current task blocker. Stop after this handoff.
