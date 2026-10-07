# Physical Ctrl+C acceptance - 2026-10-07

**WVC-M3-06 A01 passed; task verified.** The owner replied **“All PASS”** after the fresh PS51, PS7 and BAT-unattended retry instructions. Each saved observation has all seven checks passing. With the previously accepted BAT-menu and BAT-drop observations, all five supported launch modes now have passing physical Ctrl+C evidence.

| Route | Automatic PASS / FAIL | Application / session exit | First-job elapsed | Job outcomes |
|---|---|---|---|---|
| PS51 | 7 / 0 | 3 / 3 | 1.7817635 s | Cancelled, Unstarted |
| PS7 | 7 / 0 | 3 / 3 | 2.501606 s | Cancelled, Unstarted |
| BAT-unattended | 7 / 0 | 3 / 3 | 1.4798311 s | Cancelled, Unstarted |
| BAT-menu (retained) | 7 / 0 | 3 / 3 | See initial evidence | Cancelled, Unstarted |
| BAT-drop (retained) | 7 / 0 | 3 / 3 | See initial evidence | Cancelled, Unstarted |

Fresh retry: **21 PASS / 0 FAIL / 0 skipped / 0 NotRun**. Selected successful five-route evidence: **35 PASS / 0 FAIL**, combining two observation sets rather than claiming a new five-route run. The [initial evidence](MANUAL-2026-10-07.md) remains an unchanged historical snapshot: 26 PASS / 9 FAIL, including the three expired first attempts. No old report or failed row was overwritten or regraded.

Each retry started only a.mov, cancelled it, and left b.mov unstarted. All nine source/existing-final sentinels remain unchanged; no cancelled partial was published. Logs and counters agree: Found 2, Failed 0, Cancelled 1, Unstarted 1, application/session exit 3. The owned encoder acknowledged private graceful q and exited **0**, with Requested/GracefulAttempted/ExitedDuringGrace true and Forced false. Native exit 0 is distinct from the application cancellation result. Outer verifier exits were not recorded.

Observed clean application commit `e3d1536bf1408ad52048717bc3e62b50c7c13936`; app SHA256 `36ab3b93c4adad963c8141f33744f11c6deb8abd188a9bd913d56d2087648679`, BAT `0d97c046847d7002e78b23d91c4caca3498c88b9c932ae84158da9e4db51ba3f`. Copied application/launcher, wrappers and synthetic fixture hashes match the retained policy. Hosts: Windows PowerShell 5.1.26100.9444 Desktop and PowerShell 7.6.5 Core. Explorer opened each owned route folder, the owner ran its Check-*.bat, pressed physical Ctrl+C during first Encoding, and answered PASS. Exact projected rows, timestamps, commands and retained report hashes are in [JSON](MANUAL-CANCEL-2026-10-07.json). Raw media/config/logs/private paths and fixtures remain local/ignored.

Acceptance covers controlled physical Ctrl+C using synthetic encoders/probes. Retained A02-A04 evidence separately covers actual FFmpeg private-pipe shutdown, unrelated-process isolation, file safety and logs/queue consistency. Console-close, Ctrl+Break, hard crash, power loss and detached descendants remain outside this manual criterion. Broader playback/representative/network/durability/release/default-quality gates are unchanged. Historical clean Full 1814/0/0/8 at 93eecb1 remains unchanged; no unrelated suite rerun for these documentation-only changes.

TASKS/STATUS/NEXT/matrix now agree: **24 verified / 0 implemented / 8 todo; 96 passed / 32 not_run**. No further repetition is needed for this Ctrl+C criterion. Feature `codex/wvc-manual-acceptance` was clean and synchronized at parent `529ff1508537195c209a5fcaef342a63aab884e0` before editing. Final handoff commit/live fetch/push equality and actual PR/CI state are reported externally after push. Exact next task: **WVC-M4-03 - Stress concurrency, crash recovery and filesystem edge cases**.
