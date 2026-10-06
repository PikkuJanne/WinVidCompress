# Current programme status

Updated: 2026-10-06. Repository: PikkuJanne/WinVidCompress.

**WVC-M3-03 verified; A01-A04 passed on both actual Windows PowerShell hosts.** Tasks 17 verified/1 implemented/14 todo; criteria 71 passed/0 skipped/57 not_run. TASKS.json is authoritative. M3-02 owner colour review/default approval D006 and M3-01/M2-02 verification remain. M2-06 remains implemented with A04 actual Explorer observation pending. No milestone/release acceptance.

## Behavior and boundaries

Filename dates now use invariant Gregorian validation. Multiple supported date tokens (including repeated/invalid tokens), impossible dates, blank bands and unsupported patterns omit the derived artist/date/comment tuple, retain title, warn and keep compression running. The retained compact fallback discloses that a valid unlabelled number can be unrelated. Unicode/punctuation remain literal argument data. Filename title and a valid interview tuple override source fields; failure inherits compatible source equivalents. Other compatible source tags can remain; this is not private-metadata sanitization. [Policy](MEDIA_PIPELINE.md#filename-metadata).

PS1/BAT/menu/sequential batches/maps/filename metadata/libx264/veryfast/CRF22/AAC160k/faststart, exact even oriented height cap/no crop/upscale, colour policy and owned no-clobber publication/results remain. Tag read-back/structural probes do not establish player display or full integrity. Physical cancellation, persistent logs/manifests, UNC/durability/hostile substitution, packaging and broader manual gates remain later work.

## Verification

Implementation/tested `b955d11b649410745b8de917392401045d4e033d`; clean Quick PS5.1 639/0/0/0; clean Targeted PS5.1 659/0/0/0 and PS7 659/0/0/0, all exit 0. Targeted includes Quick. 43 focused units and eight native metadata cases cover invariant dates, exact Unicode tag read-back, override/inheritance, parse-failure compression and source/final sentinels. Initial fixture language failure is retained, corrected and superseded. No separate PS7 Quick or new Full/Explorer/manual run. Historical Full remains incomplete with eight NotRun rows.

Actual Windows 11 Pro 10.0.26300 UBR9457/26H2; PS5.1.26100.9444/PS7.6.5; Pester5.7.1/analyzer1.24.0; existing FFmpeg/FFprobe 2026-10-04-git-a35c879992 essentials with process-only PATH prepend. Installed-build metadata claims require packaging-baseline revalidation. No downloads/private media/overlapping tests or fabricated CI/manual results. [Evidence](evidence/WVC-M3-03.md), [commands](evidence/WVC-M3-03.json), [session](evidence/WVC-M3-03-session.md).

## Git and next task

Feature/upstream codex/wvc-m3-03-metadata/origin/codex/wvc-m3-03-metadata; sole origin https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR18 into main c576bef; new branch began there with all baseline/history retained. Previous clean implementation live equality at 2026-10-06T14:40:20.495057+00:00: `b955d11b649410745b8de917392401045d4e033d` on both endpoints. Draft [PR19](https://github.com/PikkuJanne/WinVidCompress/pull/19) open; actual CI 0 checks/0 statuses/0 runs, no pass. Final handoff push/live proof is reported externally after its commit.

Exact next **WVC-M3-04 - Report savings and benchmark rather than guess**. Retain M2-06 A04/physical/manual/Full gates; no automated task blocker. Stop after this handoff.
