# Next session

Exact next acceptance action: **WVC-M1-04-A04 â€” actual human Windows path observation**. Next bounded coding task: **WVC-M1-05 â€” Freeze and deduplicate the full batch before encoding**. M1-04 is implemented/A01-A03 passed; do not repeat verified config/launcher work or silently implement the rest of M1.

## Current state

- Root D:/projects/WinVidCompress-main; feature/upstream codex/wvc-m1-04-discovery / origin/codex/wvc-m1-04-discovery; sole origin fetch/push https://github.com/PikkuJanne/WinVidCompress.git.
- Owner merged PR6; current feature starts from inspected main23f6fdd870b2649a3630a3d618c1c57d2fac1912. Open [draft PR7](https://github.com/PikkuJanne/WinVidCompress/pull/7); tested head has zero CI/status/workflow checks/runs. Keep draft/no merge.
- Implementation805e4500bbc8c727e70ba799c9e12218d937736d; clean tested45e014538d8174f63e70fdae7256017a423e992e restores unrelated tracker formatting. Previous live clean local/fetch/push equality at2026-10-05T15:58:10.580196+00:00 describes45e0145. Final handoff SHA is reported externally; independently verify live state before editing.

Read AGENTS/INDEX/STATUS/GIT_SYNC, M1-05 entry/brief and targeted queue/output-safety specs/evidence. Inspect checkout/upstream/HEAD/dirty ownership, operations/conflicts/hooks, effective URLs and live refs. Fetch --no-tags, inspect ancestry and run tools/codex-winvidcompress/check_repo_sync.py against the real root. One writer; preserve unknown changes. Retain feature work if PR7 is not yet merged.

## Discovery and pending manual observation

Get-InputScan returns InputPath/NormalizedPath/Files[]/Errors[]/Succeeded. Process-Paths prints every diagnostic, retains readable siblings, counts complete scans separately and prints empty-folder text only on a complete empty scan. Explicit files use baseline extensions and read-only access preflight. Literal relative/provider/PSDrive/Unicode/extended syntax is supported. Reparse files/directories and selections beneath junction ancestors are excluded with records; nonrecursive stack + visited paths prevent ordinary loops. Concurrent replacement races remain documented; hard-link identity/whole queue freeze and dedup are M1-05 scope.

A04 remains not_run. The synthetic manual fixture is retained at `Join-Path $env:TEMP 'wvc-tests-a2e5ecc6930a40fe9da3969903195f8b'`; its Check-Discovery.bat runs PS5.1 then PS7 for actual owner path/Unicode/count observation. Enter PASS/FAIL as observed, then Enter for each host. Human reports are manual-Desktop.json/manual-Core.json; verify actual owner observation, copied application hash and source commit before grading. Automated reports already passed but are not manual acceptance. If the root is absent, prepare with `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/unit/New-DiscoveryManualFixture.ps1`.

Observed automatic path coverage is local Unicode,208/310-character directories (227/329 full file paths), and existing localhost administrative UNC. Remote/offline SMB, FFmpeg long paths and broader Explorer/media/release gates are untested. The kit creates no shares/policies/dependencies. Keep raw root/config/logs out of Git. After human checks and both consoles close, archive reports with hashes and use PS7 Remove-WvcTestRoot only after ownership/containment/reparse checks.

## Tested checkpoint and handoff

On clean45e0145, each Windows host PS5.1.26100.9444 / PS7.6.5: Focused47/0/0/0, Quick178/0/0/0, Targeted192/0/4/0 exit0. Existing pinned modules are at `Join-Path $env:TEMP 'wvc-m0-02-dev-modules'`; no download. Prefer serial broad runs. Four Targeted media fixtures lack FFmpeg/FFprobe. The three repaired KnownDefect enumeration regressions now run normally. Full/Manual tiers were not rerun for this bounded gate.

[Exact evidence](evidence/WVC-M1-04.json), [session](evidence/WVC-M1-04-session.md). Twenty-seven raw report/log/fixture files archived under ignored .test-results/m104-45e0145 with copy hashes equal. Test ACLs and junctions restored/removed; manual kit remains pending owner check. No implementation blocker; A04 human/milestone acceptance pending.

M1-03 config safety and owner-approved M1-02 D005 routes remain verified. Preserve them when freezing the queue. End the next thread with intentional evidence/status/next/session commit/push, clean live fetch/push equality, exact SHAs, PR/CI/tests/omissions and the next bounded task.
