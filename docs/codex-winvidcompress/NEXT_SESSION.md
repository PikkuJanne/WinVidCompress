# Next session

Exact next task: **WVC-M1-06 - Add dependency and output-environment diagnostics**. M1-05 is verified/A01-A04 passed. Do not repeat completed path/config/launcher manual acceptance or implement the rest of M1 silently.

## Current state

- Root D:/projects/WinVidCompress-main; feature/upstream `codex/wvc-m1-05-queue` / `origin/codex/wvc-m1-05-queue`; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git.
- Owner merged PR7; current feature starts from inspected main `8081fd5275aa8aa56ebe41b2002881dd1c69e70c` with previous feature work retained. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/8); implementation has zero CI/check/status/workflow runs. Keep draft/no merge.
- Clean tested implementation `e5b2c86acdad84d33500fc8b5d37fe538271215d`. Previous live clean local/fetch/push equality at 2026-10-05T16:42:19.730864+00:00 describes that implementation. Final handoff SHA is reported externally; independently verify live state.

Read AGENTS/INDEX/STATUS/GIT_SYNC, M1-06 entry/brief and targeted process/environment/security specs. Inspect checkout/upstream/HEAD/dirty ownership, operations/conflicts/hooks, effective URLs and live refs. Fetch --no-tags, inspect ancestry and run tools/codex-winvidcompress/check_repo_sync.py against the real root. One writer; preserve unknown changes. Retain feature work if this PR is not merged; inspect fetched main ancestry if owner merged.

## Verified behavior and boundaries

Get-InputQueue returns Files[] and original Scans[] after all discovery completes. Ordinal ignore-case keys deduplicate overlapping/repeated selections and normal/extended drive/UNC aliases; provider normalization preserves PS5.1 long keys. Ordinal sorting plus stable alias spelling is deterministic. Found counts unique queued sources; scan completeness/errors remain selection-level. Every diagnostic precedes encoding. Equal/nested destinations retain MP4/compressed/partial originals; source/output equality explicitly renames/skips/refuses unsafe identity before probe/native invocation. Preserve defaults, flat output and FFmpeg -n.

Queue freezing concerns paths, not byte stability/file IDs. Hard links, 8.3 and mapped-drive/UNC aliases remain separate identity concerns. Current application has no trusted ownership artifacts; do not introduce filename/output-directory exclusions. Proven artifact exclusions accompany M2-04 temp/M3-07 manifest protocols. Source size/mtime change detection, validation and transactional promotion remain outstanding later safety work. Reparse concurrent-replacement and remote SMB/media limits remain documented.

M1-03 config transactions and owner-approved M1-02 D005 routes remain verified. M1-04 actual owner path observation is passed within its recorded local/localhost-UNC boundary; do not ask for a repeat. Broader Explorer batch/playback/release gates are incomplete. Follow TESTING.md Human check design if future platform-sensitive scope needs a new observation.

## Tested checkpoint and handoff

On clean e5b2c86, each Windows host PS5.1.26100.9444 / PS7.6.5: Focused69/0/0/0, Quick200/0/0/0, Targeted214/0/4/0 exit0. Existing pinned modules: `Join-Path $env:TEMP 'wvc-m0-02-dev-modules'`; no download. Run broad gates serially. Four Targeted media fixtures per host lack FFmpeg/FFprobe. Twenty-two queue regressions use synthetic sentinels/CreateNew recorders, real sharing denial/hard links, source/final hashes and injected long-path keys. These are not new Explorer or media validation results.

[Exact evidence](evidence/WVC-M1-05.json), [session](evidence/WVC-M1-05-session.md). Raw reports/stdout stay local under ignored .test-results/m105; passing Pester/harness roots are cleaned. No M1-05 blocker/new owner action; broader milestone/release gates remain.

End the next thread with intentional evidence/status/next/session commit/push, clean live fetch/push equality, exact SHAs, PR/CI/tests/omissions and next bounded task. M1-06 preserves PATH-before-adjacent precedence unless owner authorizes a change; inspect real installed tools, bounded capability/version calls and destination diagnostics without downloads/elevation/config fallback.
