# WVC-M5-05 — final clean-GitHub candidate and reconciliation

Current 2026-10-08: A04 accepted; PR 34merged **7d6a13ab411f36943b538607db455531145f2a9a**; GitHub v1.0.0 published **2026-10-08T15:15:15Z**, tag/package source **06e803d8bfb56df0fd48cd5e073439f3ea93a4fd**, unchanged approved primary ZIP SHA256 **5c26d993e482204f80b81f10b8833315ac40c2c8d800b5bdaa7424567298b858**. Actualpublicdownload readback32/0. [Verified publication](WVC-M5-05-publication.md). No website hosting; all unverified checks/accepted exclusions remain unverified. Earlier pending statements below are dated preparation/approval history, not the current publication state.

Owner accepted A04 on2026-10-08 with "A04 approved" and separately authorized "Also authorize merging PR 34". **WVC-M5-05 accepted; all128 criteria passed (31 verified /1 accepted).** Exact06e primary ZIP/source/stated exclusions remain the acceptance target; unverified tests/support claims remain excluded. [Actual approval and completed handoff CI](WVC-M5-05-approval.md). Merge/conditional v1.0.0 publication pending execution at this approval checkpoint. The preparation record below preserves the earlier pending state and raw outcomes as history.

## Preparation record (before owner approval)

Prepared 2026-10-08. **Implemented; A01–A03 passed in their recorded scopes, A04 not_run pending actual owner acceptance.** The local v1.0.0 candidate is concrete and reviewable; no merge, tag, GitHub release or website publication was performed. [Exact commands, reports, hashes and history](WVC-M5-05.json), [candidate review](../../releases/V1.0.0_CANDIDATE.md), [all 23 mappings and raw omissions](../../releases/FINAL_RECONCILIATION.md).

## Source and bounded change

Owner merged PR 33 before this task. Fetch/live/API inspection confirms main **2c90ca324ec147485644b1a738ae03fb3c901274**, with the previous feature handoff as its parent; its tree matches the previous checkout. Sole origin fetch/push destination is https://github.com/PikkuJanne/WinVidCompress.git. No unknown dirty files or in-progress operation existed. New feature is `codex/wvc-m5-05-candidate`; no reset, stash, force push, branch deletion or default-branch write.

Implementation/candidate/tested source **06e803d8bfb56df0fd48cd5e073439f3ea93a4fd** follows initial version commit3921955441768a2609b0d5c92fb4e1ce98c63c33. VERSION/CHANGELOG select the owner's 1.0.0. Release documents preserve that prior conditional publication instruction. Minimal expanded scope fixes stale0.1.0-rc.1 ZIP/checksum expectations in existing package regressions by using the builder's recorded version and asserting the expected fixture version. No assertion is dropped. PS1/BAT/LICENSE/package builder and all runtime/default behavior remain unchanged.

## Windows tests and final artifacts

Counts are passed/failed/skipped/not_run; exits are observed, not inferred success labels.

| Actual scope at clean source 06e803d | Result |
| --- | --- |
| Windows PowerShell 5.1 Quick, all known defects included | 986/0/0/0 exit 0 |
| Windows PowerShell 5.1 Full alone | 1006/0/0/8 exit 2 |
| Supported PowerShell 7 raw Full alone (whole-suite watchdog) | 24/1/0/8 exit 1 |
| PS7 recovered full automated coverage: disjoint Pester groups + shared checks | 1016/0/0/0; 992 Pester + 24 shared passes; both group exits0; original raw Full failure/8 omissions retained |
| Affected package tests before committing the precise correction | PS5.1 19/0/0/0 exit 0; PS7 19/0/0/0 exit 0; explicitly dirty corrected test tree later committed 06e803d |
| Changed-file analysis from owner-merged base | 1 file, zero diagnostics, exit 0 |
| Final clean-clone Build/Verify and repeatability recovery checks | 7/0/0/0 exit 0 |
| Fresh extracted real-native smoke across both hosts | 80/0/0/0 exit 0 |
| Bounded candidate source/privacy inspection | 20/0/0/0 exit 0 |
| Independent saved archive/source/link audit | 90/0, exit 0; all 26 candidate entries reviewed |

Actual local Windows 11Pro10.0.26300 UBR9457 26H2 x64 (legacy registry ProductName says Windows 10Pro); Windows PowerShell 5.1.26100.9444/Desktop, supported stable PowerShell 7.6.6/Core, Pester 5.7.1, PSScriptAnalyzer 1.24.0, developer Python 3.12.14. Existing exact-path/digest-verified FFmpeg/FFprobe 2026-10-04-git-a35c879992 build is external, not bundled. Process-only PATH and unset FFREPORT; no downloads, elevation, persistent policy/PATH/profile/default-Videos changes.

Clone the actual pushed feature into a new owned ignored directory; all builds use its tracked builder/Git blobs/documented dependencies, not hidden application files from the developer checkout. Two builds in each runtime pass actual Build/Verify CLI checks. Every final entry/hash/manifest/provenance checks, and the clean clone remains unchanged. All four manifests/payloads agree; each exact-runtime ZIP pair is byte-identical. Cross-runtime ZIPs differ90bytes by method8/flags0 DEFLATE framing versus method0/flags2048 stored entries, not payload differences. No cross-runtime/universal byte-reproducibility claim.

Primary PS5.1 ZIP:250197 bytes, SHA256 **5c26d993e482204f80b81f10b8833315ac40c2c8d800b5bdaa7424567298b858**. PS7 alternative:250107 bytes, SHA256 **c248fa469b7df1d26d9d8efaae19a1a08b07d7f08f4772b807f6385bd4771d74**. All external manifests SHA256 **dcae43cfa18e688e7cbd8828a221f77d10ebac92e967d8e030c9b4cc77870c21**. Candidate review records relative artifact names; local root binding remains ignored. Source 06e identifies these exact bytes; later provenance builds cannot inherit their checksum/acceptance automatically.

Fresh extraction runs doctor/preview with no persistent writes, synthetic first conversion with isolated APPDATA/output, stream/geometry/tag probes and full decode, rename/skip collisions, full help and real BAT-unattended entry, source/final hash preservation, absent config, expected private session logs and no active partials. Separately copied documented native executables are used only in the owned extraction fixture and never added to the ZIP. No private owner media or fresh human observation is used. Structural/decode checks do not establish perceptual integrity.

## Acceptance

- **A01 passed:** final-source live-GitHub clone builds/verifies four candidates and fresh extraction works on actual supported Windows hosts with tracked code/external documented dependencies.7 recovery checks,80 smoke,20 bounded inspection and 90 independent audit.
- **A02 passed:** all prior 31 verified tasks/124 criteria retain real evidence; all 23 improvements reconcile.91 distinct paths exist; 31 JSON records have matching IDs/non-template status; all implementation commits resolve; 118 local links across64 prior targeted/spec/evidence files resolve. Full raw8 omissions per run remain; PS5.1 exit 2 and PS7 watchdog exit 1 are preserved. Split PS7 covers every discovered file without duplicates, with actual passing group reports plus the original shared checks. Required task-local passes and broader pending/support limits remain distinct.
- **A03 passed at clean implementation checkpoint:** read-only sync at 2026-10-08T13:42:03.554075+00:00 confirms local/live fetch/live push **06e803d8bfb56df0fd48cd5e073439f3ea93a4fd**, correct feature/upstream, no operations and clean original checkout. Two owned untracked draft documents were moved aside to the ignored draft directory for this check then restored; no unknown work was hidden. Final handoff commit/live refs/clean state are verified and reported externally after push, avoiding a self-SHA loop.
- **A04 not_run:** desired version and conditional publication are retained owner instructions, not acceptance of these final bytes or exclusion of unverified broader support claims. No concrete acceptance or separate merge permission is recorded. Until that actual decision, the broader-support gaps remain publication blockers.

Exact implementation push 37786226213/PR 37786235487 both pass PS51 1006/0/0/0 and PS7 1016/0/0/0; static1 file/zero diagnostics per host. Independent CI audit 88/0 exit 0 confirms actual PR merge b8e74c06d3140a4c48a7fa8fa2352febdf8b3571 parents 2c90ca3+06e. Every step, all four sanitized summaries, host/source/counts/static policy and merge parents are inspected in JSON. Raw runner diagnostics stay local; only the workflow's allowlisted summaries are retrieved. Current final-handoff CI is reported externally; no queued/pending check is called passed.

## Failures and omissions retained

Initial 392 Quick **982/4/0/0 exit 1**, dirty only by the authored documentation/test session state, exposes four stale release-version path expectations. Initial push 37784979986 and PR 37785776790 both fail with PS5.1 **1002/4/0/0** and PS7 **1012/4/0/0**, static0 files/zero diagnostics. Every step/all four sanitized summaries and actual PR merge parents remain inspected historical failures. Minimal existing-test correction passes19 per host. Final clean-clone Quick/Full51/current CI verify source 06e. Raw Full7 retains 24/1/0/8 exit 1 from its420000ms whole-suite watchdog; all 44 selected Pester files rerun in disjoint 14 integration/30 other bounded groups, preserving all assertions. Actual passing reports plus 24 passing shared checks supply recovered full automated coverage, not a rewritten raw Full pass.

The obsolete392 Full driver/owned descendants were stopped before a complete report after the deterministic version failures were identified; no complete counts/pass is invented. Partial diagnostics remain. Final-source four Build/Verify pairs/repetition checks completed, then aggregate report CreateNew correctly refused the retained earlier392 report: orchestration exit 1. Original artifacts/report/error logs were preserved; fresh verification/recovery measured7/0 exit 0 and extraction80/0 exit 0. This reporting failure is not erased or reported as an application failure.

Eight raw Full composite manual/future NotRun records remain as emitted, with exact IDs/reasons in JSON and dated narrower evidence overlays in FINAL_RECONCILIATION. Earlier missing-tool skips, watchdog/cancellation/CI failures, rejected screenshot and packaging differences remain dated history. Existing owner Explorer/menu/five-mode Ctrl+C/geometry/SDR/short representative playback passes are retained without repeats or broadened claims.

## Remaining decision and limits

No default-quality change, tag/release/merge/site/settings/account/signing/dependency-bundling action. Existing release-blocking support gaps include remote SMB/disconnection, arbitrary paths/filesystems, power-loss and hostile substitution; console-close/Ctrl+Break/crash/detached descendants, browser/MOTW, fresh-profile/default-Videos and final-candidate/whole-original/other-player perceptual checks remain unobserved. HDR/tone mapping/GPU/automatic updates remain absent. Tool-only unsigned distribution and checksum/authentication/legal boundaries stay explicit.

Next: finish **WVC-M5-05-A04** with an actual owner decision on this concrete 1.0.0 candidate and its stated exclusions; obtain separate merge permission if desired. Retain the conditional GitHub publication instruction without repeating the version/publication-desire question. Stop before gated actions.

Final authored-document/tracker/source/artifact/privacy audit:561/0/0/0 exit0,125 local links resolved; exact command/helper/report hash in JSON. Explicit UTF-8 projection preserves all prior task/status/matrix content. Earlier projection encoding and copied private-path errors were caught in diff/privacy review and repaired before handoff. Independent split review22/0 retains its initial21/1 label-readback observation; the original UTF-8 labels are canonical and all case statuses/counts agree.
