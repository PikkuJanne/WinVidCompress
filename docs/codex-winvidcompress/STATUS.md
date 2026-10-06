# Current programme status

Updated: 2026-10-06. Repository: PikkuJanne/WinVidCompress.

**WVC-M2-06 is implemented; A01-A03 passed, A04 manual observation pending.** Tasks/criteria: 13 verified/2 implemented/17 todo; 57 passed/2 skipped/69 not_run. TASKS.json is authoritative. M2-02 remains implemented with A01/A03 skipped pending actual output confirmation. No milestone/release acceptance.

## Behavior and boundaries

Job/batch/session records now drive reconciled counters and separate scan errors, preserve diagnostic/owned-artifact identity, and retain completed jobs across later menu/report failures. Direct PS1 batches and first-switch BAT -Unattended return 0/1/2/3 application outcomes; default BAT remains usable with a retained prompt. Dot-sourced helpers never exit callers. Completion still requires native success, structural validation and no-clobber promotion. Published/skipped outcomes survive later reporting cancellation; unstarted jobs remain explicit.

PS1/BAT/menu/sequential batches/default libx264/veryfast/CRF22/AAC160k/faststart/no-upscale coded-height/maps/filename metadata and safe retention remain. Physical Ctrl+C/console-close/graceful/tree behavior, persistent logs/manifests, geometry/colour, UNC/atomicity/power loss and hostile substitution remain unaccepted. Structural checks do not prove full visual/audio integrity. Prior D005 observations and limits are retained.

## Verification

Clean final checkpoint `14f719e9b9fa5920ee6d710cf0563bfa107c0444`: application `c0498affa86cf0d585b0ef09197f1c0070012a3f` plus bounded suite allowance and reporting-fixture alias correction. Actual Windows 11/PS5.1.26100.9444/PS7.6.5, existing Pester 5.7.1 / analyzer 1.24.0. Each host Quick 460/0/4/0 and Targeted 476/0/8/0 (pass/fail/skip/not_run), exit0. All final Quick/Targeted/Full runs tested 14f719e. Full both hosts 932/0/12/8, exit2/Incomplete; eight NotRun rows remain. No overlapping test runs. FFmpeg/FFprobe absent; no downloads. Native fixtures are synthetic sentinels, not media. A04 actual Explorer observation is pending despite passed automated exit/menu continuation checks. No Full/CI/manual/milestone/release pass. [Evidence](evidence/WVC-M2-06.md), [exact commands](evidence/WVC-M2-06.json), [session](evidence/WVC-M2-06-session.md). Read-only review found no remaining material code blocker.

## Git and next task

Feature/upstream `codex/wvc-m2-06-results` / `origin/codex/wvc-m2-06-results`; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR15; fetched main `216e797948ba234238e1ba4d4bb6397fffe80a67` retains prior feature/baseline with empty content difference. New feature preserves that state. Draft PR creation pending until the final handoff push; actual PR state will be reported externally. Implementation CI 0 checks/0 statuses/0 workflows, no CI pass. Clean implementation live equality at `2026-10-06T05:21:41.585660+00:00`; final handoff SHA/live equality reported externally after its commit.

Exact next task: **WVC-M3-01 - Harden resizing and rotation without a new resolution preset**. Retain pending M2-06 A04, M2-02 media skips and Full manual/future rows. No new implementation/approval blocker. Stop after this handoff.
