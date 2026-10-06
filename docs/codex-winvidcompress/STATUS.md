# Current programme status

Updated: 2026-10-06. Repository: PikkuJanne/WinVidCompress.

**WVC-M4-01 verified; A01-A04 passed on PS5.1 and PS7.** TASKS.json is authoritative: 20 verified/3 implemented/9 todo; criteria 89 passed/39 not_run. Prior M3-06 physical Ctrl+C A01, M3-04 playback A04 and M2-06 actual Explorer A04 remain pending. No milestone/release acceptance.

Per-run OutputDir/CollisionMode and read-only WhatIf preserve defaults < config < options without implicit persistence. Preview starts no native tools and creates no config/output/jobs/logs/manifests. It estimates current queue destinations; media validity and writability remain unchecked. Preview rejects doctor/manifest controls before startup. Doctor permits OutputDir and retains its temporary write check. No-option menu/config recovery and default profile retained. [CLI policy](PROCESS_AND_CLI.md#optional-cli).

Clean tested implementation `2932907cf417ca179f25a149618e7e45760c637e`, app SHA256 `93da2284e07c66e17f437064aa6170417e01452f01d6a46f1276b7a93c1c612c`: both-host Full 1702/0/0/8, exit2 solely historical manual/future rows; per-host Pester PS5.1 839; PS7 839. Pre-cold-fix PS7 task slice 56 passed/0 failed/0 skipped/0 NotRun; earlier evolving PS5.1 Quick 838 passed/0 failed/0 skipped/0 NotRun. All 61 current task cases passed on both supported hosts; cold-fix units 30/0 per host preceded Full. Earlier clean Full timed out on PS7 at 300 seconds; suite-only bound now 420 seconds. [Acceptance](evidence/WVC-M4-01.md), [exact commands/failures/limits](evidence/WVC-M4-01.json), [session](evidence/WVC-M4-01-session.md).

Actual Windows11 Pro10.0.26300/UBR9457/26H2, PS5.1.26100.9444/PS7.6.5, pinned Pester5.7.1/analyzer1.24.0 and already installed FFmpeg/FFprobe2026-10-04 essentials. Synthetic isolated fixtures only. No quality change/private media/download/elevation/system policy/new runtime. Structural checks do not prove full visual/audio integrity; earlier physical/manual and network/power-loss/hostile-user gates remain explicit.

Feature/upstream codex/wvc-m4-01-preview/origin/codex/wvc-m4-01-preview; sole origin https://github.com/PikkuJanne/WinVidCompress.git. Owner-merged PR23/main `e9d175168712a0eb646121a024ac8cda87572da1` reconciled before branching. Previous clean live local/fetch/push equality at 2026-10-06T17:49:37.794672+00:00 matched `2932907cf417ca179f25a149618e7e45760c637e`. [Draft PR24](https://github.com/PikkuJanne/WinVidCompress/pull/24) open; implementation CI0 checks/0 workflow runs, no pass. Final handoff SHA/live sync and current PR/CI reported externally after push.

Exact next **WVC-M4-02 - Add opt-in relative subfolder preservation**. Stop after this handoff.
