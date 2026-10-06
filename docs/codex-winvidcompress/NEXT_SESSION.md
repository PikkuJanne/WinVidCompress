# Next session

Exact next **WVC-M3-02 - Define SDR compatibility and reject untested HDR conversions**. M3-01 verified A01-A04, including owner visual PASS. M2-02 now verified after existing installed-tool output checks. M2-06 remains implemented with actual Explorer menu/Quit/prompt observation pending. One bounded task; preserve historical evidence and pending physical/manual gates.

## Current state and preflight

Feature/upstream `codex/wvc-m3-01-geometry` / `origin/codex/wvc-m3-01-geometry`; sole origin https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR16 into main 3ce6f66; prior feature/historical baseline retained with empty content difference. Application `7e09068d63799dbfe9b2a83b62bb4c003f61a134`, final test-helper checkpoint `02a07baff854d647c82e5758c21a66a00fa66dd6`. Clean implementation live equality at 2026-10-06T13:38:56.437975+00:00; documentation handoff SHA/live proof and actual draft PR reported externally after its commit. Implementation CI 0 checks/0 statuses/0 workflow runs, no CI pass.

Read AGENTS/INDEX/STATUS/GIT_SYNC, M3-02 entry/brief and MEDIA_PIPELINE/DECISIONS/TESTING. Inspect actual branch/HEAD/dirty ownership, operations/conflicts/hooks and effective URLs/live refs; fetch --no-tags/reconcile, then read-only check_repo_sync.py. One checkout writer; preserve unknown changes. No reset/stash/force/main push/discard. Independently verify live state; final handoff SHA cannot be stored in its own commit.

## Next implementation and retained boundaries

M3-02 defines tested SDR yuv420p compatibility, recognizes PQ/HLG through metadata rather than bit depth, returns actionable unsupported HDR without untested tone mapping and warns on ambiguous colour. Read exact acceptance/approval gate; do not relabel HDR as SDR or alter default quality by intuition. M3-01 source metadata normalization remains raw; selected-stream Geometry derives separately, and encoding/validation recompute from the same Video object. Default autorotation once; exact even oriented height cap; SAR retained for aspect; unsupported matrices rejected before allocation; residual output transforms rejected. Colour/pixel-format compatibility is still unaccepted.

Existing source/final no-clobber/owned retention, records and 0/1/2/3 outcomes remain. M2-06 actual Explorer observation and physical Ctrl+C/console-close remain pending. Persistent logs/manifests/progress/packaging, UNC/power-loss/hostile substitution remain later work.

## Tested checkpoint and tools

Quick PS 5.1 537/0/0/0 at 7e09068 and PS 7 537/0/0/0 at 02a07ba; Targeted PS 5.1 557/0/0/0, PS 7 557/0/0/0 at 02a07ba, all exit 0. Full both hosts 1090/0/0/8 at 02a07ba, exit 2/Incomplete for eight NotRun rows. Actual Windows 11 Pro 10.0.26300 UBR9457/26H2, PS 5.1.26100.9444/PS 7.6.5, Pester 5.7.1/analyzer 1.24.0. FFmpeg/FFprobe 2026-10-04-git-a35c879992 essentials build verified in owner-provided C:\ffmpeg\bin; inherited/registered PATH did not expose them to this task, so tests prepended that folder only in-process. Verify tools/path again on the next host; do not download dependencies or change system settings. Native 13 geometry/two timing cases and previous stream/silent checks passed; owner viewed six geometry pairs and answered PASS. Retained manual geometry kit provenance is in ignored local report; public evidence omits private paths. Prior M2-06 local Explorer kit remains pending. No need to repeat already recorded M3-01 owner observation for unchanged application bytes.

End task with intentional evidence/status/next/session commit/push, live clean refs, exact SHAs/tests/omissions/PR/CI and next task. No Full/CI/milestone/release pass inferred.
