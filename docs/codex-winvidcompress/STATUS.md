# Current programme status

Updated: 2026-10-06. Repository: PikkuJanne/WinVidCompress.

**WVC-M2-05 is verified, A01-A04 passed.** Tasks: 13 verified/1 implemented/18 todo. Criteria: 54 passed/2 skipped/72 not_run. TASKS.json is authoritative. M2-02 remains implemented with A01/A03 skipped pending actual output confirmation. No milestone/release acceptance.

## Behavior and boundaries

Done now requires native success, owned temporary MP4 structural validation and final no-clobber promotion. FTYP/probe/stream/geometry/duration checks reject bad output before publication. Selected A/V durations are checked independently with bounded, documented timing policy; unknown source references and unsafe/ambiguous aggregate comparisons are disclosed. Silent input stays silent. Matching generated source-timecode tracks are narrowly allowed. Optional full decode is an explicit developer helper, never automatic.

PS1/BAT/menu/sequential batches/default libx264/veryfast/CRF22/AAC160k/faststart/no-upscale coded-height policy/maps/filename metadata remain. Existing reservation/retention/no-clobber and M2-03 diagnostic/process safeguards remain. Structural metadata checks do not prove full visual/audio integrity; actual FFmpeg timing/decode compatibility, M3-01 transforms, full cancellation, durable manifests, UNC/atomicity/power-loss and hostile substitution remain unaccepted. D005 prior owner launcher observations are retained.

## Verification

Clean implementation `c8a3ed074e87b8be5e51eb42a3d19c532a8a7ee5`, Microsoft Windows 11 Pro 10.0.26300 UBR9457 (26H2), PS5.1.26100.9444/PS7.6.5, existing pins. Each host Focused 243/0/4/0, Quick 405/0/4/0, Targeted 421/0/8/0, serial. Focused/Quick/Targeted exit0; Earlier Full on clean aba01e3: 407/0/8/8, exit2/Incomplete with zero failures, seven manual and one future row NotRun. 66 new unit/eight actual native probe/argv cases per host plus existing entry/concurrent checks passed. Four Focused/Quick and eight Targeted/Full media skips without FFmpeg/FFprobe. Synthetic FTYP/JSON/sentinel fixtures are not valid media. No Full/new Explorer/playback/cancellation/CI/release pass. [Evidence](evidence/WVC-M2-05.md), [exact commands](evidence/WVC-M2-05.json), [session](evidence/WVC-M2-05-session.md). Raw artifacts ignored .test-results/m205; read-only review found no remaining material blocker.

## Git and next task

Feature/upstream `codex/wvc-m2-05-validation` / `origin/codex/wvc-m2-05-validation`; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR13; initial inspected main `a23a917a4881d45c9c061a150f83ef865570cf66` retains prior work/baseline. During verification owner merged PR14 at aba01e3; fetched current main `f2897dcab0dfffd8d6b80f4f0452b57aeb5b5cd9` has identical content to that initial implementation. The corrected feature is preserved with a followup draft. [Open draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/15); implementation CI 0 checks/0 statuses/0 workflows. Clean implementation live equality at `2026-10-06T04:00:09.499705+00:00`. Final handoff SHA/live equality reported externally after commit.

Exact next task: **WVC-M2-06 - Define job results, counters and script exit codes**. Retain M2-02 media skips and Full manual/future rows. No new code/approval blocker. Stop after this handoff.
