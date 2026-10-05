# Next session

Exact next task: **WVC-M2-02 - Select and map the same real video and intended audio**. M2-01 is verified/A01-A04 passed. One bounded task; retain completed config/launcher/path/environment acceptance.

## Current state and preflight

- Root D:/projects/WinVidCompress-main; feature/upstream `codex/wvc-m2-01-probe` / `origin/codex/wvc-m2-01-probe`; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git.
- Owner merged PR9; inspected base `118d5f1534a82d06b6fc534a6c5e03237d45faff` retains prior feature/reviewed baseline. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/10); implementation CI 0 checks/0 statuses/0 workflow runs. Keep draft/no merge.
- Clean tested implementation `8efa0b82224fd1793715b2f7369697c71b73fb87`. Prior clean live local/fetch/push equality at `2026-10-05T17:30:34.704492+00:00` describes that implementation. Final handoff SHA is reported externally; independently verify live state.

Read AGENTS/INDEX/STATUS/GIT_SYNC, M2-02 entry/brief, MEDIA_PIPELINE and relevant PROCESS_AND_CLI/OUTPUT_SAFETY/TESTING sections. Inspect root/upstream/HEAD/dirty ownership, operations/conflicts/hooks, effective URLs and live refs. Fetch --no-tags and reconcile ancestry; run tools/codex-winvidcompress/check_repo_sync.py against the real root. Preserve unmerged feature work. One writer; no resets/stash/force/main pushes or silent discard.

## Next task boundary

M2-01's Get-MediaInspection/ConvertFrom-ProbeJson returns all normalized Streams, RealVideoIndices, PrimaryVideoIndex/PrimaryVideo (first real video by absolute index), coded metadata and nullable duration. One UTF-8 -show_streams/-show_format JSON call uses the small bounded helper. Attached pictures are excluded; source/probe/schema/no-real-video failure blocks encoding. Native status/diagnostics remain available. Unknown duration is allowed with indeterminate warning/validation limitation.

M2-02 must carry the chosen real video's absolute index through inspection/scaling and explicit -map; select unique default audio or first audio, permit silence and disclose omitted alternatives without channel/FPS/default-quality drift. Current encoder still auto-selects streams. Prove inspected/encoded indices match in synthetic multi-video/artwork/multi-audio/silent cases. DisplayGeometry remains null/MetadataOnly; rotation/SAR transforms belong to M3-01. M2-03 owns the encoder native adapter; later tasks own transaction/validation/source-change/manifests. Do not silently combine tasks.

Probe file whitelist and playlist response rejection do not guarantee an offline encoder or exclude UNC access. Direct-process cleanup is bounded; filesystem/network/process creation lack total deadlines; detached descendants are not tracked. Prior config/queue/collision safeguards remain; path freeze is not immutable content identity. Preserve defaults/menu/flat/sequential behavior and owner-approved D005 launcher routes.

## Tested checkpoint and handoff

Clean 8efa0b8 on PS5.1.26100.9444/PS7.6.5, each Focused123/0/0/0, Quick275/0/0/0, Targeted291/0/4/0, exit0. Existing pins at `Join-Path $env:TEMP 'wvc-m0-02-dev-modules'`; no downloads. Forty-four Probe regressions and eight entry recorder cases. Actual FFmpeg/FFprobe absent PATH/adjacent; four media skips per Targeted host. No real-media/Full/new manual/Explorer/CI pass. [Exact evidence](evidence/WVC-M2-01.json), [session](evidence/WVC-M2-01-session.md). Raw diagnostics remain ignored .test-results/m201. No M2-01 task blocker/new owner action.

End the thread with intentional evidence/status/next/session commit/push, clean live fetch/push equality, exact SHAs, PR/CI/tests/omissions and the next bounded task. Final synchronization must be external to its own commit.
