# Next session

Exact next task: **WVC-M2-01 - Expand FFprobe into normalized JSON media inspection**. M1-06 is verified/A01-A04 passed. Do not repeat completed path/config/launcher manual acceptance or implement all M2 silently.

## Current state

- Root D:/projects/WinVidCompress-main; feature/upstream `codex/wvc-m1-06-environment` / `origin/codex/wvc-m1-06-environment`; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git.
- Owner merged PR8; inspected main `a8272ef15097141b18a79960404b827f270cc889` contains prior feature history. Open [draft PR](https://github.com/PikkuJanne/WinVidCompress/pull/9); implementation has zero CI/check/status/workflow runs. Keep draft/no merge.
- Clean tested implementation `a91bfa6b2d35839e3296570843beeeb34a81f2ef`. Previous clean live local/fetch/push equality at `2026-10-05T17:07:35.638654+00:00` describes that implementation. Final handoff SHA is reported externally; independently verify live state.

Read AGENTS/INDEX/STATUS/GIT_SYNC, M2-01 entry/brief, MEDIA_PIPELINE and relevant PROCESS_AND_CLI/OUTPUT_SAFETY/TESTING sections. Inspect checkout/upstream/HEAD/dirty ownership, operations/conflicts/hooks, effective URLs and live refs. Fetch --no-tags, inspect ancestry and run tools/codex-winvidcompress/check_repo_sync.py against the real root. One writer; preserve unknown changes. Retain feature work if PR is unmerged; inspect fetched main ancestry if owner merged.

## Verified behavior and boundaries

M1-06 resolves actual PATH-before-adjacent applications and refuses aliases/functions. Get-ToolEnvironment runs seven native checks with 10-second process/pipe limits and bounded failure cleanup; exact version/build and libx264/AAC/MP4-faststart/scale/CSV-JSON probe capability responses are required. Invoke-EnvironmentCall uses tested PS5.1-compatible argv quoting, concurrent streams, exits/stderr and removes child FFREPORT. It terminates only its directly started process; filesystem/network resolution/process creation remain outside total startup deadlines.

`-CheckEnvironment` reads config without save/default creation/recovery/locks and never converts. Its disclosed owned one-byte temporary destination write is removed on close; no config/backups/folders created. Startup, menu candidate save and every batch check output writing. Saved/active preferences survive inaccessible/write-denied destinations. Current capacity is advisory and can be unknown on UNC/reparse/mount-point paths; size/access stability is not guaranteed.

M1-05 complete deterministic unique path queue/pre-encode diagnostics/source-output nonidentity guard remain. Candidate freeze does not establish immutable bytes/file IDs; hard-link/8.3/mapped-drive aliases can remain separate. No trusted current ownership artifacts; do not exclude ambiguous MP4/compressed/partial/original destination files. Source-change detection, transactional media-temp/promotion, structural validation and manifests remain future tasks. Defaults/flat output/-n remain. Existing D005 actual owner launcher/path observations stay passed; broader Explorer/SMB/playback/release gates remain.

## Tested checkpoint and handoff

On clean a91bfa6, each real Windows host PS5.1.26100.9444/PS7.6.5: Focused112/0/0/0, Quick231/0/0/0, Targeted247/0/4/0 exit0, serial. Existing pins at `Join-Path $env:TEMP 'wvc-m0-02-dev-modules'`; no downloads. Thirty-one Environment native/ACL regressions and eight real entry cases use synthetic recorders. Actual FFmpeg/FFprobe absent from PATH/adjacent; four media skips per Targeted host. Real capability/media support remains unverified; no repeated manual/Full check.

[Exact evidence](evidence/WVC-M1-06.json), [session](evidence/WVC-M1-06-session.md). Raw diagnostics stay local under ignored .test-results/m106; passing harness/Pester roots cleaned. No M1-06 blocker/new owner action. M2-01 replaces current unbounded/silent-stderr height-only Get-VideoHeight with bounded normalized JSON media inspection; reuse the small native helper proportionately and preserve diagnostic timeout/argv/file safety. Do not confuse program-version capability output with real input-media inspection.

End the next thread with intentional evidence/status/next/session commit/push, clean live fetch/push equality, exact SHAs, PR/CI/tests/omissions and next bounded task. No merge/default-branch push/tag/release/settings/deployment/default-quality action without explicit approval.
