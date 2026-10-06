# WVC-M2-06 evidence - 2026-10-06

**Implemented; A01-A03 passed. A04 manual observation remains not_run.** 13 verified/2 implemented/17 todo; 57 passed/2 skipped/69 not_run. [Exact commands, host versions, report hashes and omissions](WVC-M2-06.json).

## Result and exit behavior

Compress-One returns one schema 1 record with source/output/temporary/retained identity, outcome/stage/reason, selected streams/settings, timing/nullable signed size changes and probe/encode/validation diagnostics. Batch/session counters derive from returned records; scan errors remain separate. Unstarted remainder is explicit after cancellation/fatal dispatch. Successful publication and valid skips remain durable outcomes even if subsequent reporting/accounting is cancelled; a separate cancellation signal stops scheduling. A later menu prompt failure/cancellation retains earlier batches/jobs and their reasons.

Application exits: 0 success including valid intentional skips; 1 job/scan/unfinished failure; 2 startup/config/invalid/empty requested batch; 3 observed application cancellation with precedence. Quit/blank selection before a batch returns 0. Pure Invoke-WinVidCompress and dot-sourcing never exit the caller; executable entry owns exit. Default BAT retains -NoExit and adds -KeepOpen; first -Unattended returns the actual process code without menu/pause. KeepOpen plus Unattended is refused. Existing D005 variable-shaped-percent limitations remain documented. Host parse/binding and physical Ctrl+C are outside this application exit contract.

## Clean checks

Clean final checkpoint `14f719e9b9fa5920ee6d710cf0563bfa107c0444`: application `c0498affa86cf0d585b0ef09197f1c0070012a3f` plus bounded suite allowance and reporting-fixture alias correction. Actual Windows 11/PS5.1.26100.9444/PS7.6.5, existing Pester 5.7.1 / analyzer 1.24.0. Each host Quick 460/0/4/0 and Targeted 476/0/8/0 (pass/fail/skip/not_run), exit0. All final Quick/Targeted/Full runs tested 14f719e. Full both hosts 932/0/12/8, exit2/Incomplete; eight NotRun rows remain. No overlapping test runs. FFmpeg/FFprobe absent; no downloads. Native fixtures are synthetic sentinels, not media.

| Run | pass/fail/skip/not_run | Exit / status |
|---|---|---|
| quick51-final-fixed | 460/0/4/0 | 0 / PassedWithOmissions |
| quick7-final-fixed | 460/0/4/0 | 0 / PassedWithOmissions |
| targeted51-final | 476/0/8/0 | 0 / PassedWithOmissions |
| targeted7-final | 476/0/8/0 | 0 / PassedWithOmissions |
| full-both-final | 932/0/12/8 | 2 / Incomplete |

Unit results reconcile counters with separate scans and preserve exact failure/cancellation classification, source/final sentinels, diagnostic retention and caller survival. Native exit suite actually invokes current-host PS1 and PS5.1 BAT for success/mixed failure/startup/empty/no-input/scan partial failures, with no stdin/pause. All-skip and controlled cancellation 3 execute real entry helpers in a worker. Scripted default BAT menu/Quit/prompt continuation passes, but does not establish actual Explorer observation. Shared characterization/environment/queue/launcher fixtures were minimally adapted to returned records and executable exits; malformed raw -File evidence now fails its grade rather than indexing past the array.

Dirty regression-first and diagnostic runs are retained as development observations, not clean acceptance. Ordered PS5.1 unit/Quick runs exposed actual RuntimeException/InvalidOperationException entering a typed cancellation catch; explicit fully qualified actual-type checks fixed the failures. Underlying engine/session cause remains unproven. A comma-separated -Hosts token failed native -File binding before any test; corrected commands are the clean runs above. Read-only review found no remaining material code/source/publication blocker.

## Manual and limitations

A04 is incomplete: the owner was asked to double-click the isolated Check-Menu.bat, choose 4 and observe the usable prompt. No PASS/FAIL/UNSURE reply at handoff. Kit hashes/base dirty tree are in JSON; no private temporary path in Git. Earlier D005 owner evidence is retained, not reused as proof of this changed menu. Real media remains skipped, Full manual/future rows open, controlled cancellation is not physical Ctrl+C/console-close/tree acceptance. Structural checks do not prove full visual/audio integrity. Logs/manifests remain later work; LogPath null. Default profile, geometry, maps, filenames and owned no-clobber retention boundaries remain.

## Git and handoff

Feature/upstream `codex/wvc-m2-06-results` / `origin/codex/wvc-m2-06-results`; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR15; fetched main `216e797948ba234238e1ba4d4bb6397fffe80a67` retains prior feature/baseline with empty content difference. New feature preserves that state. Draft PR creation pending until the final handoff push; actual PR state will be reported externally. Implementation CI 0 checks/0 statuses/0 workflows, no CI pass. Clean implementation live equality at `2026-10-06T05:21:41.585660+00:00`; final handoff SHA/live equality reported externally after its commit.

Exact next task: **WVC-M3-01 - Harden resizing and rotation without a new resolution preset**. Carry pending A04 and earlier M2-02 native-media skips. No new code/approval blocker; geometry/default policy changes require the existing owner approval rules. Final handoff commit/push/live equality pending within this record.
