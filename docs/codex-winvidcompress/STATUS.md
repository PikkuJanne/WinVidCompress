# Current programme status

Updated:2026-10-07. Repository:PikkuJanne/WinVidCompress.

**M2-06 and M3-04 now verified after scoped owner manual observations; M4-02 remains verified.** TASKS.json authoritative:23 verified/1 implemented/8 todo; criteria95 passed/33 not_run. Physical cancellation M3-06 A01 remains partial:BAT-menu/drop each7/7; PS51/PS7/BAT-unattended each4/7 after the first recorder120-second watchdog, so timely first-job Ctrl+C needs only3 fresh retries. All human PASS observations and9 failing exercise rows preserved. [Manual evidence](evidence/MANUAL-2026-10-07.md), [exact artifacts/projections](evidence/MANUAL-2026-10-07.json), [session](evidence/MANUAL-2026-10-07-session.md).

Owner PASS covers actual Explorer menu/Quit and usable1+1=2 prompt, and the current eight-second moving-pattern/steady-tone source/default repeat1 playback. Two-repeat default timings are measured. Face/text/speech synchronization, representative media, experimental playback and broad player/HDR/network/durability/release gates remain unobserved. No quality change/approval. Physical Ctrl+C uses synthetic recorders; installed FFmpeg private-pipe shutdown has separate retained native evidence.

Latest clean automated Full at implementation `93eecb15ee9ba33cdc8428aaeeb2c4435bc4fb91`:1814/0/0/8, exit2 solely historical manual/future rows; per-host Pester895, including56 layout cases per host. Historical raw reports/counts unchanged; no long unrelated suite rerun for documentation. Observed manual commit `7bfe67453c6515a85ac4c8eac09e0de577fe8280`, app SHA256 `36ab3b93c4adad963c8141f33744f11c6deb8abd188a9bd913d56d2087648679`. [Layout acceptance](evidence/WVC-M4-02.md).

`-PreserveSubfolders` stays per-run, explicit-input, disjoint-root and flat-manifest-only; flat/default quality remains unchanged. Existing validated descendants and no-clobber jobs remain. Fresh isolated three-route retry extends only owned recorder/wrapper timer to600seconds; native timer survival/private-q exit0 check passed. Owner retry observations not_run. Kits/raw diagnostics retained locally; no private media/download/system policy/new application runtime.

Feature `codex/wvc-manual-acceptance` from owner-merged PR25/main `e3d1536bf1408ad52048717bc3e62b50c7c13936`; sole origin https://github.com/PikkuJanne/WinVidCompress.git. Observed7bfe674 and merged main have identical app/BAT content. Previous clean live equality at `2026-10-07T12:46:52.279681+00:00` was on codex/wvc-m4-02-layout7bfe674; final new-branch SHA/live PR/CI reported externally after push.

Immediate manual action:only PS51/PS7/BAT-unattended retry, one at a time, Ctrl+C within10seconds of FIRST Encoding progress. Exact next task **WVC-M4-03 - Stress concurrency, crash recovery and filesystem edge cases**. No milestone/release acceptance.
