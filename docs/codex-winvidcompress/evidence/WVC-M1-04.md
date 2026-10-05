# WVC-M1-04 discovery evidence

Recorded 2026-10-05. **Verified; A01-A04 passed.** No milestone/release acceptance.

Implementation: `805e4500bbc8c727e70ba799c9e12218d937736d`. Clean required-test checkpoint: `45e014538d8174f63e70fdae7256017a423e992e` (same application/test bytes; tracker-formatting correction only). Base: fetched main `23f6fdd870b2649a3630a3d618c1c57d2fac1912`, which includes owner-merged PR6 and has the prior feature's identical tree.

## Behavior and bounded scope

Get-InputScan returns normalized literal filesystem selections, arrays of eligible files/errors, and completeness. Missing/provider/extension/read failures have Path/Kind/Message records; readable siblings remain usable. Process-Paths prints each error, counts only complete scans, and distinguishes an empty scan from an inaccessible one. Explicit files use the existing case-insensitive extension filter and read-only access preflight. Default encoding arguments remain covered by unchanged characterization assertions.

Nonrecursive stack traversal excludes reparse files/directories, explicit links and selections beneath junction ancestors. A case-insensitive visited-directory set refuses repeated traversal. This is a stable-filesystem policy; checks and later listing/open are separate path operations with a concurrent-replacement race. Full queue freezing/deduplication, hard-link identity and aggregate exit semantics remain later scope.

Scope expansion is limited to promoting the three existing repaired characterization cases, developer manual preparation/check helpers, tests/README, and required specification/evidence/handoff files. BAT, compression quality and processing model retain their existing behavior.

## Clean committed verification

Windows 11 Pro 10.0.26300 UBR9457 (26H2), Windows PowerShell5.1.26100.9444 Desktop / PowerShell7.6.5 Core. Existing pinned Pester5.7.1 and analyzer1.24.0 were reused; no downloads.

Counts are passed/failed/skipped/NotRun. Every selected required run exited0.

| Host | Focused discovery + characterization | Quick | Targeted |
|---|---|---|---|
| PS5.1 | 47/0/0/0 | 178/0/0/0 | 192/0/4/0 |
| PS7.6.5 | 47/0/0/0 | 178/0/0/0 | 192/0/4/0 |

Exact commands, source cleanliness, host observations, skipped case IDs and local artifact names are in [JSON evidence](WVC-M1-04.json). Broad runs were serial. The 21 focused discovery cases cover empty/one/many, mixed/explicit extensions, literal relative/dot/provider/PSDrive/Unicode/extended paths, provider/missing/blank inputs, terminating/nonterminating errors, partial subtrees, real ACL/read-sharing denials, real loop/outside-root junctions and explicit ancestor-link selections, summary counts and repeated-directory protection. ACLs were restored and junction objects deleted nonrecursively in finally. Source/outside sentinels/hashes were preserved.

Quick executes all three formerly KnownDefect enumeration cases normally, with no exclusions. Targeted includes native entry recorders but skips four media fixtures per host because FFmpeg/FFprobe are absent. Full/Manual tiers were not rerun for this bounded task; broader manual/media/release gates remain.

## Acceptance

| Criterion | Result | Evidence |
|---|---|---|
| A01 strict zero/one/many and mixed extensions | Passed | Both-host focused/Quick/Targeted and promoted characterizations |
| A02 missing/unreadable and unsuccessful-scan records | Passed | Real ACL/read-sharing denial, partial/nonterminating listing faults, missing inputs and caller summary |
| A03 reparse loop/broad-scan protection | Passed for stable-filesystem policy | Real loop/outside junctions, explicit links/ancestor selection and repeated-directory guard |
| A04 Windows UNC/non-ASCII/long paths | Passed, bounded to tested cases | Owner-reported prepared check and both real PASS reports; source/hash/cases verified |

## Windows path observations and manual limitation

A clean805e450 application copy was verified against committed805e450 and45e0145: SHA256 `2248e0b4db90b1659f4c7fbe70b3ef5292a26586aaf47053fbfa9c1912f10ab7`. Both actual Windows hosts automatically scanned all four synthetic selections and matched exactly one source/hash. Preparation and automated results do not establish manual acceptance.

| Selection | Directory length | Complete file-path length | Each host |
|---|---:|---:|---|
| Literal brackets + Finnish/German/CJK local | 97 | 116 | Passed |
| Longer local below260 | 208 | 227 | Passed |
| Longer local above260 | 310 | 329 | Passed |
| Unicode via existing localhost administrative UNC | 109 | 128 | Passed |

No share, policy, elevation or dependency setup was performed. Localhost UNC does not prove remote/offline SMB behavior; discovery checks do not prove FFmpeg long-path support, video validity or playback. The preparation helper records HEAD as an anchor while copying working-tree bytes; future dirty preparations need tree/hash evidence.

The owner reported on2026-10-05: "Again path check seemingly pass, but these are very difficult for human testing". This tentative wording is preserved. Both actual manual-Desktop/Core reports contain Automated=false, HumanObservation=Passed and4/4 matching source/hash cases, with the committed805e450 application hash. The paired reports and owner statement close A04 for the observed cases; no broader platform claim is implied. Native exit codes were not recorded in these human reports.

Feedback-only commit5c786f9fbf75fd12dde32519f04129e6dd1a877f simplifies future manual presentation: four friendly PASS/FAIL rows, a character sample and one human observation question. Counts/hashes remain automatic; detailed JSON is saved without being displayed. UNSURE records NotRun/exit2. Both hosts passed helper parse/analyzer/encoding (3 checks) and automatic path checks (4 cases); scripted UNSURE tests preserved incompleteness with expected exit2. These scripted follow-up reports are not actual human acceptance. Application/discovery tests remain byte-identical to the clean45e0145 broad gates; no broad rerun or human repeat was requested. Future manual-check guidance is recorded in TESTING.md.

## Diagnostics, Git and continuation

Uncommitted initial regressions failed17/17 because Get-InputScan did not exist. The first implementation draft passed16/failed1 because the partial-result mock emitted a shadowed local variable; script-scoped fixture correction then passed17,20 and47 in successive drafts. These draft runs are retained diagnostics, not clean acceptance evidence.

Twenty-nine raw report/log/fixture files (including both actual manual reports) were copied to ignored `.test-results/m104-45e0145` with SHA256 equality. Pester fixtures cleaned normally after ACL/junction restoration. The original and follow-up owned synthetic roots were removed after no matching process and verified ownership/temp containment/reparse checks. Follow-up reports remain locally under ignored .test-results/m104-completion. No private raw artifacts were pushed.

Feature `codex/wvc-m1-04-discovery`, upstream `origin/codex/wvc-m1-04-discovery`; sole effective fetch/push endpoint is PikkuJanne/WinVidCompress on github.com. Clean helper5c786f9 live local/fetch/push equality was verified at2026-10-05T16:22:21.436206+00:00; the earlier45e0145 test checkpoint remains historical. Final documentation sync is pending commit/push and reported externally without a self-SHA loop.

[Draft PR7](https://github.com/PikkuJanne/WinVidCompress/pull/7) is open. Tested helper5c786f9 has zero check runs, zero combined-status checks and zero workflow runs; the empty combined status is pending, not a CI pass. No M1-04 task blocker remains; broader milestone/release/media acceptance is pending.

Exact next: **WVC-M1-05 - Freeze and deduplicate the full batch before encoding**. M1-04 is verified; broader milestone/release acceptance remains explicit.
