# Current programme status

Updated: 2026-10-06. Repository: PikkuJanne/WinVidCompress.

**WVC-M4-02 verified; A01-A04 passed on PS5.1 and PS7.** TASKS.json is authoritative:21 verified/3 implemented/8 todo; criteria93 passed/35 not_run. Prior M3-06 physical Ctrl+C A01, M3-04 playback A04 and M2-06 actual Explorer A04 remain pending. No milestone/release acceptance.

Per-run `-PreserveSubfolders` preserves relative source folders with deterministic multiple-root labels; flat remains the default. It requires explicit inputs and disjoint source/output roots, refuses doctor/manifest controls before startup, and does not persist configuration. Preview/logs show the chosen layout and collisions. Paths/components/containment/reparse points and existing roots revalidate before descendant creation; nested jobs retain existing no-clobber publication. [Layout policy](CONFIG_AND_DISCOVERY.md#implemented-relative-layout-wvc-m4-02).

Clean tested implementation `93eecb15ee9ba33cdc8428aaeeb2c4435bc4fb91`, app SHA256 `36ab3b93c4adad963c8141f33744f11c6deb8abd188a9bd913d56d2087648679`: both-host Full 1814/0/0/8, exit2 solely historical manual/future rows; per-host Pester PS5.1 895; PS7 895. All56 final task cases passed per host. Earlier dirty PS5.1 Quick896/0, corrected focused87/0 and earlier PS7 compatibility231/0. [Acceptance](evidence/WVC-M4-02.md), [exact commands/corrections/limits](evidence/WVC-M4-02.json), [session](evidence/WVC-M4-02-session.md).

Actual Windows11 Pro10.0.26300/UBR9457/26H2, PS5.1.26100.9444/PS7.6.5, pinned Pester5.7.1/analyzer1.24.0 and installed FFmpeg/FFprobe2026-10-04 essentials. Synthetic isolated fixtures only. No quality change/private media/download/elevation/system-policy/new runtime. Structural checks do not prove full visual/audio integrity. Prior physical/manual and network/power-loss/hostile-user gates remain explicit; UNC label units are not actual share acceptance.

Feature/upstream `codex/wvc-m4-02-layout`/`origin/codex/wvc-m4-02-layout`; sole origin https://github.com/PikkuJanne/WinVidCompress.git. Owner-merged PR24/main `4d46371f85bf5c82ee2e885fc613486c4b885391` reconciled before branching. Previous clean live local/fetch/push equality at `2026-10-06T18:52:16.878085+00:00` matched `93eecb15ee9ba33cdc8428aaeeb2c4435bc4fb91`. [Draft PR25](https://github.com/PikkuJanne/WinVidCompress/pull/25) open; implementation CI0 checks/0 workflow runs, no pass. Final handoff SHA/live sync and current PR/CI reported externally after push.

Exact next **WVC-M4-03 - Stress concurrency, crash recovery and filesystem edge cases**. Stop after this handoff.
