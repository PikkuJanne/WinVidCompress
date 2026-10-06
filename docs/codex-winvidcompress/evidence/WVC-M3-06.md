# WVC-M3-06 evidence

2026-10-06. **Implemented; A02-A04 passed; A01 physical Ctrl+C NOT RUN.** Exact commands, failures, report hashes, host/tool identity and scope are in [JSON](WVC-M3-06.json). No release acceptance.

## Implementation and source

Application/test commit `cc1e2a2f9e74d82d48142635783f18cdd38ca7d4`; manual-kit clarification `015f9872906448692f4e75c6a0d5a0719e130c99`. Current application SHA256 `1629646f11c4f7d5c10b3b4bafed43fc80ebdf4d0214ab84ff1ad305c3d7c1cb` matches both commits. Root was the sole writer; two agents gave read-only design/test/final reviews. Feature `codex/wvc-m3-06-cancellation` starts at inspected owner-merged PR21/main `5c9bcf96490fde3e542135c691360b9de1766906`, retaining reviewed baseline/history. [Draft PR22](https://github.com/PikkuJanne/WinVidCompress/pull/22) is open.

Batch owns/restores Ctrl+C input mode and polls on the PowerShell runspace without callbacks. Managed encoder receives fixed q/newline via private redirected stdin (`-stdin`), with 1500ms grace then owned Process.Kill/2000ms wait; concurrent bounded diagnostics and existing 10s post-exit drain remain. Raw/decode calls keep closed stdin. Request wins even after native exit 0, prevents unfinished publication/next dispatch and preserves durable Completed/Skipped outcomes. CancellationRequested/AbortBatch/native stop fields and session Cancelled are projected to local logs. Fatal stop failure retains provenance; no global name kill/console broadcast/media deletion. Default profile and unchanged BAT/entry points retained. [Policy and limits](../PROCESS_AND_CLI.md#cancellation).

## Gates

| Gate | Source | Passed / Failed / Skipped / NotRun | Exit |
|---|---|---|---|
| Intermediate Quick PS5.1 | dirty main-based working tree | 720 / 0 / 0 / 0 | 0 |
| Clean Full, both actual hosts | cc1e2a2 | 1458 / 0 / 0 / 8 | 2, Incomplete |
| Focused cancellation inside clean Full | cc1e2a2 | 16 / 0 / 0 / 0 per host | included above |
| Final manual-helper parse/analyzer/ASCII, PS5.1 | 015f987 | 6 / 0 / 0 / 0 | 0 |
| Clean five-route manual kit preparation | 015f987 | preparation only; observation NOT RUN | 0 |

Full includes Quick and Targeted scopes: 717 Pester passes per host plus 24 shared static/actual entry/native-fixture checks. Its eight historical manual/future rows are not passed; zero failed/skipped. Exact source clean and recorded. Actual Windows 11 Pro 10.0.26300 UBR9457/26H2, PS5.1.26100.9444/PS7.6.5; pinned Pester 5.7.1/analyzer 1.24.0 and existing FFmpeg/FFprobe 2026-10-04-git-a35c879992 essentials. No dependency download/system policy change/private media.

Sixteen new cases cover graceful exit 0 with retained stderr, ignore-q forced stop, request before start, retained owned partial/source+final hashes, unrelated actual FFmpeg PID/start identity survival, actual installed FFmpeg q acknowledgement, real worker code 3/log/summary agreement and one Cancelled/one Unstarted, requests before validation/publication and after completion/skip/summary, before first dispatch, context reset, fatal stop provenance and failing-setup cancellation precedence. Native markers/context seams are automated evidence, not physical Ctrl+C.

Initial focused7/0 passed. Expanded PS7 initially12/1 because test-scope skip mode was wrong and fixture children waited; those verified fixture-owned identities alone were stopped, the scope corrected and a test watchdog added. PS5.1 then13/1 three times on an overstrong task-state-based graceful-success field despite real q acknowledgement/exit 0; field narrowed to honest ExitedDuringGrace with separate native q assertion. Corrected focused PS5.1 14/0 and PS7 16/0 passed before final clean Full. All failures and exact commands retained in JSON; no failed assertion hidden or skip counted passed.

## Acceptance

- **A01 NOT RUN:** kit prepared from clean commits for PS51, PS7, BAT-unattended, BAT-menu and actual Explorer drop to an isolation wrapper. Instructions/verifier in [tests README](../../../tests/README.md). Seven automatic rows plus separate PASS/FAIL/UNSURE observation. Observer request has no result/observation artifacts. Synthetic launch/control-flow checks do not establish authentic-media quality. Default BAT's explicit `exit $LASTEXITCODE` transports code 3 and causes its expected error3/pause; press a key for verifier. Two plain synthetic names do not establish broad special-character argv acceptance.
- **A02 PASSED:** both-host clean Full native forced stop while a separately owned actual FFmpeg remained live with matching PID/start identity; cleanup stops only fixture-owned processes.
- **A03 PASSED:** both-host clean Full hashes/sentinels, owned retained partial/provenance/no flat promotion, prepublication checks and durable outcome preservation. Fatal-stop fault seam retains even empty job provenance and stops dispatch.
- **A04 PASSED:** real workers on both hosts return3 and reconcile console Cancelled1/Unstarted1, one encode start, JSONL Job/Result counters/native diagnostics/signals. Later completion/skip/summary/setup requests preserve records and cancellation precedence. Context reset supports subsequent batch.

## Synchronization and remaining gates

Previous clean live equality at 2026-10-06T16:23:27.858415+00:00: local/fetch/push `015f9872906448692f4e75c6a0d5a0719e130c99`. Sole verified origin https://github.com/PikkuJanne/WinVidCompress.git, matching upstream; no operations/conflicts/unknown changes. Final handoff commit/push verification pending at commit time and reported externally. Actual helper-commit CI 0 checks/0 workflow runs; no CI pass. PR remains draft.

Physical A01, prior M3-04 playback A04/M2-06 Explorer A04 and eight Full NotRun rows remain. Direct-child-only cleanup, unavailable/redirected console fallback, Ctrl+Break/console close/host interruption/crash, delayed probe/filesystem observation and warning-only log limits are explicit. Structural checks do not establish full A/V integrity. No main push/merge/release/default-quality change.

Exact next **WVC-M3-07 - Add validated batch retry/resume with a versioned manifest**. Its usable cancellation prerequisite has both-host automated evidence; pending physical gates remain explicit.
