# Current programme status

Updated: 2026-10-05. Repository: PikkuJanne/WinVidCompress.

**WVC-M1-04 is implemented; A01-A03 passed, A04 human Windows observation pending.** M0-01/M0-02/M0-03/M1-01/M1-02/M1-03 are verified;25 tasks remain todo. Criteria:27 passed,101 not_run. TASKS.json is authoritative. No milestone/release acceptance.

## Behavior and supported boundary

Discovery now returns literal normalized filesystem selections, Files/Errors arrays and completeness. Explicit supported files receive read-access preflight; missing/provider/extension/access errors are visible. Readable siblings survive incomplete subtree scans. Summary separates complete Scanned selections and Scan errors from encode counters; inaccessible scans are not reported as empty.

Traversal is nonrecursive with an explicit stack, reparse/ancestor exclusions and case-insensitive visited-directory guard. Path checks have a concurrent-replacement race; stable-filesystem policy is documented. Full queue snapshot/deduplication remains M1-05. The existing compression defaults, simple menu/launcher and sequential processing are preserved.

Verified M1-03 config transactions and M1-02 owner-approved D005 launcher boundary remain in force. Variable-shaped BAT percent segments use literal menu/direct PS1 routes. Discovery does not change config saves or default quality.

## Verification

Clean tested checkpoint45e014538d8174f63e70fdae7256017a423e992e, Windows11 Pro10.0.26300 UBR9457 (26H2), PS5.1.26100.9444 Desktop/PS7.6.5 Core. Existing Pester5.7.1/analyzer1.24.0 reused. Each host Focused47/0/0/0, Quick178/0/0/0, Targeted192/0/4/0 (passed/failed/skipped/NotRun), exit0, serial runs. All three formerly excluded enumeration regressions run normally. Four media skips per Targeted run lack FFmpeg/FFprobe; Full/Manual not rerun for this bounded task.

Copied committed805e450 application bytes/hash verified; both hosts automatically passed four synthetic Unicode, localhost administrative UNC and208/310-character-directory cases. **Actual human Explorer observation remains pending; A04 is not passed.** Localhost coverage does not establish remote/offline SMB, FFmpeg path support or media integrity.

[Evidence](evidence/WVC-M1-04.md), [exact commands/results](evidence/WVC-M1-04.json), [session](evidence/WVC-M1-04-session.md). Twenty-seven raw report/log/fixture files archived locally under ignored .test-results/m104-45e0145 with copy hashes equal. Test ACLs/junctions restored/removed. Synthetic manual root retained for owner observation; private raw data stays local.

## Git and next task

Feature/upstream codex/wvc-m1-04-discovery / origin/codex/wvc-m1-04-discovery at D:/projects/WinVidCompress-main; sole origin fetch/push URL https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR6; inspected main23f6fdd870b2649a3630a3d618c1c57d2fac1912 was the base. Open [draft PR7](https://github.com/PikkuJanne/WinVidCompress/pull/7); zero tested-head CI/check/workflow runs, no CI pass.

Previous clean live local/fetch/push equality at2026-10-05T15:58:10.580196+00:00 describes tested45e0145. Final documentation commit/push equality is pending here and reported externally; no self-SHA loop.

Exact next: finish **WVC-M1-04-A04** human path observation. Next bounded coding task: **WVC-M1-05 â€” Freeze and deduplicate the full batch before encoding**. The demonstrated implemented dependency permits that coding task while manual/milestone acceptance remains pending. Stop after this handoff.
