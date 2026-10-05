# Current programme status

Updated: 2026-10-05. Repository: PikkuJanne/WinVidCompress.

**WVC-M1-02 is verified under owner-approved D005; A01-A04 passed.** M0-01/M0-02/M0-03/M1-01/M1-02 are verified; 27 tasks remain todo. Criteria: 20 passed, 108 not_run. TASKS.json is authoritative. No milestone/release acceptance.

## Behavior and supported boundary

BAT disables delayed expansion, forwards %* once to installed Windows PowerShell5.1 and retains NoExit/process-only Bypass. Startup failures show actionable diagnostics; selected dependency files are checked for readability before config creation. Default compression/media behavior remains unchanged.

D005 was explicitly approved by owner on 2026-10-05. Variable-shaped percent segments such as %PATH% anywhere in a BAT drop path use literal menu entry or direct PS1 from PowerShell instead. Ordinary percent and BAT !NAME! support remain required. Historical direct BAT percent substitution stays recorded; no reconstruction/system association/policy change or automatic rename.

## Verification

Owner confirmed “Completed both Explorer drops and the menu check”. Exact folder/ten-file native and bound records, real menu file/folder values with matching variables, and the automatic native PS1 subcheck agree. Five current/prepared hashes and eleven source sentinels match; no config write. Earlier zero/single/A03/A04 evidence retained. The direct subcheck is automatic within the human menu session; recorder selection/binding does not establish encoder/media integrity.

Clean tested implementation 67bb0e80b347817e3072fa7b23bdbafc892226cd, Windows11 Pro10.0.26300 UBR9457, PS5.1.26100.9444 Desktop/PS7.6.5 Core. Each host Quick106/0/0/4 and Targeted120/0/4/4 (passed/failed/skipped/NotRun), exit0. Pester5.7.1/analyzer1.24.0 reused. Four absent-media skips/four known config/enumeration NotRun; Full not rerun. Supported-fixture scripted smoke passes both. Completion follow-up is documentation-only, with schema/whitespace/privacy/data checks rather than a broad rerun.

[Evidence](evidence/WVC-M1-02.md), [exact JSON commands/results](evidence/WVC-M1-02.json), [session](evidence/WVC-M1-02-session.md). Twelve raw reports plus manifests archived locally under ignored .test-results with report-copy hashes verified. Both owned manual kits cleaned after no active fixture processes; historical synthetic read-deny ACL restored. No private paths/raw environment values uploaded.

## Git and next task

Feature/upstream codex/wvc-m1-02-launcher / origin/codex/wvc-m1-02-launcher at D:/projects/WinVidCompress-main; one origin fetch/push URL https://github.com/PikkuJanne/WinVidCompress.git. Draft [PR5](https://github.com/PikkuJanne/WinVidCompress/pull/5) remains open; zero CI/check/workflow runs, no CI pass.

Previous clean live equality at 2026-10-05T14:44:20.084546+00:00 describes documentation checkpoint 32e13889a4e60985fac03b67931c8bcb437aa198. Final documentation push/live equality pending when committed and reported externally; no self-SHA loop.

Exact next: **WVC-M1-03 — Make configuration validation and recovery safe**. Stop after this bounded handoff. No main push/merge, release/tag, policy/default-quality/deployment or settings/secrets action.
