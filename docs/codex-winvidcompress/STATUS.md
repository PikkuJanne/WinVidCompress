# Current programme status

Updated: 2026-10-05. Repository: PikkuJanne/WinVidCompress.

**WVC-M1-04 is verified; A01-A04 passed.** M0-01/M0-02/M0-03/M1-01/M1-02/M1-03/M1-04 are verified;25 tasks remain todo. Criteria:28 passed,100 not_run. TASKS.json is authoritative. No milestone/release acceptance.

## Behavior and supported boundary

Discovery returns literal normalized filesystem selections, Files/Errors arrays and completeness. Explicit supported files receive read-access preflight; missing/provider/extension/access errors are visible. Readable siblings survive incomplete subtree scans. Summary separates complete Scanned selections and Scan errors from encode counters; inaccessible scans are not reported as empty.

Traversal is nonrecursive with an explicit stack, reparse/ancestor exclusions and case-insensitive visited-directory guard. Path checks have a concurrent-replacement race; stable-filesystem policy is documented. Full queue snapshot/deduplication remains M1-05. The existing compression defaults, simple menu/launcher and sequential processing are preserved.

Verified M1-03 config transactions and M1-02 owner-approved D005 launcher boundary remain in force. Variable-shaped BAT percent segments use literal menu/direct PS1 routes.

## Verification

Clean broad checkpoint45e014538d8174f63e70fdae7256017a423e992e, Windows11 Pro10.0.26300 UBR9457 (26H2), PS5.1.26100.9444 Desktop/PS7.6.5 Core. Existing Pester5.7.1/analyzer1.24.0 reused. Each host Focused47/0/0/0, Quick178/0/0/0, Targeted192/0/4/0 (passed/failed/skipped/NotRun), exit0, serial runs. All three formerly excluded enumeration regressions run normally. Four media skips per Targeted run lack FFmpeg/FFprobe; broader Full/Manual/release gates remain.

Owner reported: "Again path check seemingly pass, but these are very difficult for human testing". Tentative wording is preserved. Both real PS5.1/PS7 manual reports record PASS, Automated=false and4/4 matching sources/hashes on copied committed805e450 application bytes. A04 passes within the tested Unicode,208/310-character-directory and localhost administrative-UNC discovery boundary. Remote/offline SMB, FFmpeg path support and media integrity remain untested.

Helper-only5c786f9fbf75fd12dde32519f04129e6dd1a877f makes future manual checks concise: four result rows, a readable character sample, automatic technical checks and saved details. UNSURE remains incomplete. Both hosts passed parse/analyzer/encoding3, automatic path4 and scripted UNSURE expected exit2/NotRun. Scripted follow-up reports are developer checks; original owner reports supply manual acceptance. Application/regression code matches45e0145; no broad rerun or repeat human check.

[Evidence](evidence/WVC-M1-04.md), [exact commands/results](evidence/WVC-M1-04.json), [session](evidence/WVC-M1-04-session.md). Twenty-nine original raw report/log/fixture files archived under ignored .test-results/m104-45e0145 with copy hashes equal; follow-up diagnostics under .test-results/m104-completion. Both synthetic roots removed after no matching process and ownership/temp containment/reparse checks. Private raw data stays local.

## Git and next task

Feature/upstream codex/wvc-m1-04-discovery / origin/codex/wvc-m1-04-discovery at D:/projects/WinVidCompress-main; sole origin fetch/push URL https://github.com/PikkuJanne/WinVidCompress.git. Owner merged PR6; inspected main23f6fdd870b2649a3630a3d618c1c57d2fac1912 was the base. Open [draft PR7](https://github.com/PikkuJanne/WinVidCompress/pull/7); zero helper-head CI/check/workflow runs, no CI pass.

Previous clean live local/fetch/push equality at2026-10-05T16:22:21.436206+00:00 describes helper5c786f9. Final completion documentation commit/push equality is pending here and reported externally; no self-SHA loop.

Exact next: **WVC-M1-05 - Freeze and deduplicate the full batch before encoding**. No M1-04 task blocker remains. Stop after this handoff.
