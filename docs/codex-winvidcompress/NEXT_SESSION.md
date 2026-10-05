# Next session

Exact next safe task: **WVC-M2-03 - Isolate command construction and native process execution**. M2-02 is implemented, A02/A04 passed/A01/A03 skipped. Do not silently mark actual output confirmation passed. INDEX allows later work against demonstrated implemented dependencies. One bounded task.

## Current state and preflight

- Root D:/projects/WinVidCompress-main; feature/upstream `codex/wvc-m2-02-streams` / `origin/codex/wvc-m2-02-streams`; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git.
- Owner merged PR10; inspected base `aac681a0f8873792dc46e9ba599801d4ff11f9b4` retains prior feature/reviewed baseline. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/11); implementation CI 0 checks/0 statuses/0 workflow runs. Keep draft/no merge.
- Clean tested implementation `ed3a91676c350d6718741d30b7b9f4127286f528`. Prior live local/fetch/push equality at `2026-10-05T17:55:31.725417+00:00` describes that implementation. Final handoff SHA is reported externally; independently verify live state.

Read AGENTS/INDEX/STATUS/GIT_SYNC, M2-03 entry/brief, PROCESS_AND_CLI, relevant MEDIA_PIPELINE/OUTPUT_SAFETY/TESTING sections and M2-02 evidence. Inspect root/upstream/HEAD/dirty ownership, operations/conflicts/hooks, effective URLs and live refs; fetch --no-tags/reconcile ancestry; run tools/codex-winvidcompress/check_repo_sync.py. One writer; preserve unmerged work. No reset/stash/force/main push or silent discard.

## Next task and pending checks

M2-03 extracts pure FFmpeg command construction and a small native execution adapter. Preserve exact stream-plan maps, defaults, input/output/metadata tokens and literal argv on PS5.1/PS7. Drain diagnostics/progress without deadlock, retain native exit/status/stderr, isolate native input and clean owned callbacks/process resources. Follow its actual manual acceptance scope; recorder tests cannot replace Explorer checks. Do not combine transaction/progress/geometry/manifest tasks silently.

M2-02 Get-StreamPlan carries the inspection's existing PrimaryVideo object/index, unique-default-or-first audio, exact MapArguments, nullable metadata, every omitted index/type/reason and plain console warnings. Height cap reads that same Video.Height. No audio means no map/AAC options. Default quality remains; no -ac/-ar/-r. Explicit unknown codec_type is identifiable; malformed arrays fail. Mapped-stream metadata/dispositions rely on FFmpeg defaults, with no clearing override.

Pending real-media confirmation: supply already-installed FFmpeg/FFprobe applications on PATH and rerun both stream unit/integration suites on both hosts. Two integration cases reuse synthetic multi-stream/silent recipes, with a larger later video, then inspect output geometry/audio/channels/language/default disposition. Record tool versions/exact tested SHA/output evidence before changing A01/A03 to passed and M2-02 to verified. No automatic downloads; native tools remain absent. The encoder still uses the older call operator until M2-03, so test failures there may expose its documented adapter boundary.

DisplayGeometry is null/MetadataOnly until M3-01. Probe file whitelist does not guarantee offline encoder behavior/avoid UNC. Filesystem/network/process creation lack total deadlines; cleanup tracks direct owned processes only. Prior config/queue/collision/D005 safeguards remain, with content identity/owned media-temp/promotion/validation/manifests still later.

## Tested checkpoint and handoff

Clean ed3a916, PS5.1.26100.9444/PS7.6.5 each Focused 105/0/2/0, Quick 288/0/2/0, Targeted 304/0/6/0, all exit0. Existing pins at `Join-Path $env:TEMP 'wvc-m0-02-dev-modules'`; no downloads. Thirteen Stream regressions and eight Targeted entry cases. Two output checks skipped in all scopes; four additional Targeted media skips. Whole Pester child has120-second bound after one observed60-second PS7 Targeted timeout; per-fixture deadlines remain separate. APPDATA/FFREPORT/output isolation; raw logs/reports and failed pre-repair owned diagnostics remain local/ignored. No new Full/manual/Explorer/media/CI pass. [Evidence](evidence/WVC-M2-02.json), [session](evidence/WVC-M2-02-session.md).

End each task with intentional evidence/status/next/session commit/push, clean live refs, exact SHAs, tests/skips/PR/CI/pending checks and next task. Report final sync externally to its own commit.
