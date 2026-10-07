# WVC-M5-03 — Licensing and distribution security evidence

Recorded 2026-10-07 on Windows. Implementation/tested source **0b61d54ab2490a53528001270928b45c847ce6d2**, base owner-merged PR31/main **0fa5502cd55d31d1b234d8db24f3fdc9caf3b07f**. Feature `codex/wvc-m5-03-security`; [draft PR32](https://github.com/PikkuJanne/WinVidCompress/pull/32). Exact commands, counts, hashes, sanitized projections and limitations are in [JSON](WVC-M5-03.json); [session](WVC-M5-03-session.md). TASKS.json is the status authority.

## Change and acceptance scope

The original Unlicense is unchanged. README, root SECURITY.md/THIRD_PARTY_NOTICES.md and [distribution review](../../releases/DISTRIBUTION_REVIEW.md) describe actual local-tool trust/privacy boundaries, separate build-specific dependency terms, unsigned/checksum status and reporting availability. Policies ship in the offline candidate. Minimal expanded scope is the two-file positive allowlist addition in `tools/package.ps1` and existing package regressions: exact LICENSE/runtime bytes, local policy links and tracked FFmpeg/FFprobe poison-file exclusions. Mandatory evidence/tracker/status/next/session updates complete the scope. Application/launcher/default profile are unchanged.

| Criterion | Passing evidence | Boundary |
|---|---|---|
| A01 original license | LICENSE diff empty; original Git blob/worktree SHA unchanged; both actual candidates match original Git bytes; regression checks raw LICENSE/PS1/BAT blobs | No license change authorized or made |
| A02 tool-only distribution | Exact 13-entry allowlist; no FFmpeg/FFprobe/library/archive/installer/developer/config/log/media in either candidate; poison binaries excluded in both-host regressions | External dependencies keep their actual terms; none bundled |
| A03 honest release claims | PS1 and developer builder Authenticode NotSigned/no certificate; human-readable README/policy/release review has no unsupported signed/certified/guaranteed-safe claim | BAT query returned UnknownError/no certificate, not successful signature verification; checksum is not publisher authentication |
| A04 privacy/security content | Every entry in both candidate ZIPs read; 20 grouped automated assertions passed, independent 26-entry inspection found zero bounded credential/private-path matches and no unintended telemetry | Bounded patterns/source review, not universal secret detection or a security certification |

Original LICENSE Git blob `fdddb29aa445bf3d6a5d843d6dd77e10a9f99657`; worktree SHA256 `6b0382b16279f26ff69014300541967a356a666eb0b91b422f6862f6b7dad17e`. PS1 SHA256 `ead0c7b785a4a6092ce70af8b34097a579e9c6ac31ecaeba2087692c9266476b`; BAT `0d97c046847d7002e78b23d91c4caca3498c88b9c932ae84158da9e4db51ba3f`. LICENSE is 1211 bytes with 24 LF and no CRLF in the current worktree, original Git blob and candidates. Candidate assertions use binary Git blobs.

## Dependency and reporting observations

Official [FFmpeg legal guidance](https://ffmpeg.org/legal.html) and [download/provider links](https://ffmpeg.org/download.html) checked on 2026-10-07. The separately installed Gyan essentials `2026-10-04-git-a35c879992` used here reports GPL version 3 or later; both `-L` invocations exited 0 and version configuration contains `--enable-gpl`, `--enable-version3`, `--enable-libx264`. Executable hashes rechecked against `tests/CiDependencies.psd1`. License/build reports describe these tested external binaries; no arbitrary build is labelled LGPL-only/Unlicense and no legal/codec-patent clearance is inferred. Raw configuration/native output stays local.

Read-only GitHub API confirmed issues enabled and private vulnerability reporting disabled on 2026-10-07. SECURITY.md follows [GitHub's documented fallback](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately): a minimal public request for a preferred private channel, with no sensitive details; wait for that channel. No invented email, reporting request, repository setting/account change or promised response deadline. Ordinary bugs use synthetic reproductions and reviewed sanitized diagnostics.

PATH precedes adjacent executables. The doctor executes selected tools and checks compatibility, not publisher identity or safety. The application has no download/upload/account/telemetry feature; explicitly selected UNC/native media are not a network/hostile-file sandbox. Metadata/private diagnostics require review; the optional exporter is not encryption or a private-ACL guarantee. Run without elevation and respect existing organizational policy.

## Local tests and candidate reconstruction

Hosts: Windows 11 Pro 10.0.26300 UBR9457/26H2 x64 (registry legacy ProductName Windows 10 Pro); Windows PowerShell 5.1.26100.9444/Desktop, supported PowerShell 7.6.6/Core; Pester 5.7.1, PSScriptAnalyzer 1.24.0. Prepared dependencies reused, no new downloads/system policy changes. APPDATA/output isolated; inherited FFREPORT unset.

At clean 0b61d54, PS5.1 Quick **968/0/0/0**, affected PS7 package **19/0/0/0**, and changed-file analysis **2 files / 0 diagnostics** all exited 0. Counts are passed/failed/skipped/not_run. Four actual default-root Build/Verify CLI pairs run from a fresh clean HTTPS clone of pushed 0b61d54, twice per host. Separate reconstruction measurements pass **7/0/0/0**. All four manifests and decompressed payloads match; each same-runtime ZIP pair is byte-identical. Both ZIPs have 13 sorted entries, fixed 1980 timestamps and zero external attributes. Independent review checks 20 local links and 29 exact-source excluded-file links per ZIP, all valid.

| Candidate builder | ZIP bytes | ZIP SHA256 |
|---|---:|---|
| PS5.1/.NET Framework 4.0.30319.42000 | 248706 | `7a7d519d6cd12dd5ba5daf28391e126066cfff6d52d249a4c94fb6a2fbf3c555` |
| PS7/.NET 10.0.12 | 248616 | `166997bdbddb6fd8690d4c8d141a7f5c8871dda57fc19f8ee1a125e824c372a4` |

Common manifest SHA256 `1f1e8840370a8c39064bffee59278369d3780d118d1d29257707b69ab2333f7c`. Actual cross-runtime ZIP difference **90 bytes**: PS5.1 method 8/uncompressed DEFLATE/flags 0; PS7 method 0/stored/UTF8 flags 2048. This applies to the new 13-entry candidate; historical M5-02's 11-entry difference remains 80 bytes. No universal/cross-runtime byte-identical claim.

PS5.1-built candidate independently extracted per host, documented separately digest-verified adjacent native binaries, system-only PATH and isolated APPDATA/source/output: **80/0/0/0**, 40 assertions per host. Doctor/preview snapshots, real synthetic encode/probe/full decode, geometry/audio/filename tags, rename/skip, eleven-parameter help, system-PS5.1 BAT, source/final hashes, absent config/four private session logs/no active partials passed. Successful owned smoke roots safely removed through existing containment/reparse guards. Ignored `.test-results/m503/rebuild-path.local.txt` locates retained clone/four candidates; raw reports/helpers/logs remain local. No private media used or candidate uploaded.

Initial failures retained: regression-first PS5.1 17/2/0/0 before policy implementation; development 18/1/0/0 because fixture archived old README, corrected by overlaying current README; corrected dirty-tree PS5.1/PS7 each 19/0/0/0. Reconstruction orchestrator exited 1 after all four successful Build/Verify pairs because PS5.1 driver had not loaded ZipFile for post-build inspection; existing artifacts preserved and separate loaded-assembly measurements/inspections passed. Native-pin diagnostic parser error occurred before execution; corrected statement verified both digests. These are not erased or relabelled as passing original runs.

## CI, synchronization and remaining gates

Implementation live clean local/fetch/push equality at `2026-10-07T20:48:30.575351+00:00` proves 0b61d54 only. Exact [push 37684831753](https://github.com/PikkuJanne/WinVidCompress/actions/runs/37684831753) and [PR 37684863505](https://github.com/PikkuJanne/WinVidCompress/actions/runs/37684863505) both completed successfully: **988/0/0/0 per host**, changed analysis 2 files/zero diagnostics. Every job step and all four distinct sanitized summaries/cases were inspected. Push summaries identify 0b61d54; PR summaries identify merge `8ee495c307d505cdcdb7b7e6a96bf64a72ec750a`, whose parents 0fa5502/0b61d54 were API-confirmed. Hosted Targeted is not Full/manual/release acceptance. Final handoff is a later evidence/documentation commit; final local/live refs and its CI state are reported externally after push to avoid self-SHA.

This task's candidate inspection does not replace M5-05 final-source reconstruction/acceptance. No new Full/Explorer/Ctrl+C/playback/browser-MOTW/fresh-profile/default-Videos acceptance; earlier owner Windows/manual/source/playback evidence stays scoped. Broader filesystem/remote SMB/disconnection/durability/hostile-substitution/HDR/other-player/whole-original/default-quality limits remain. Structural/decode checks are not perceptual proof. Signing, bundled dependency redistribution, license/settings/account changes and publication/tag/release/merge/website deployment require separate owner approval; none performed here.

Final handoff audit **332/0/0/0** checks tracker totals, unchanged tested files, exact report hashes/source/counts, native license/pins, signing/reporting observations, all smoke token boundaries, 79 local links and bounded public-evidence privacy patterns. Tracker validator passes **32 tasks / 128 criteria**; programme now 30 verified/2 todo, 120 passed/8 not_run. These are documentation/evidence checks, not new application/manual acceptance. Earlier generic tracker serialization/newline-prose errors were caught and corrected before handoff; all unrelated task data/Unicode stays unchanged.

Exact next **WVC-M5-04 — Prepare website product metadata and genuine demonstration content**, only when requested. No next-task implementation.
