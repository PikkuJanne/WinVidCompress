# Next session

Exact next task: **resolve WVC-M1-02 literal %PATH% failure or obtain an explicit owner decision; finish folder/direct-BAT follow-up**. Implementation/automation complete; prepared Explorer argv fails A01/A02 for literal %PATH%; A03/A04 pass. Folder/direct-BAT follow-up pending. Next code task: **WVC-M1-03 — Make configuration validation and recovery safe**. Do not repeat completed M1-01 acceptance or implement the rest of M1 silently.

## Actual state

- Root `D:/projects/WinVidCompress-main`; feature/upstream `codex/wvc-m1-02-launcher` / `origin/codex/wvc-m1-02-launcher`.
- One expected origin fetch/push destination: `https://github.com/PikkuJanne/WinVidCompress.git`.
- Clean implementation/tested commit `e32fa11067bc8bb5133e8913840561deba79573f`, Quick/Targeted both hosts dated 2026-10-05.
- Previous live equality at `2026-10-05T13:10:20.088784+00:00` describes implementation, not final documentation. Final handoff SHA reported externally; independently verify it.
- Draft [PR #5](https://github.com/PikkuJanne/WinVidCompress/pull/5), zero implementation check/workflow runs.
- Owner merged PR #4; this feature starts at inspected main `096c65c7fb1b7d02ee6bc2efcaffedd7a8952b67`.

Read AGENTS/INDEX/STATUS/GIT_SYNC/TASKS, targeted brief and [M1-02 evidence](evidence/WVC-M1-02.md). Inspect branch/upstream/HEAD, dirty ownership, operations/conflicts/hooks and effective/live URLs. Fetch with `git fetch --no-tags origin`, then `python -B tools/codex-winvidcompress/check_repo_sync.py --repo D:/projects/WinVidCompress-main`. Preserve unknown changes; one writer only. If PR #5 merged inspect main; otherwise retain this feature ancestry.

## Pending manual completion

Prepare with `powershell -NoProfile -ExecutionPolicy Bypass -File tests/launcher/New-LauncherManualFixture.ps1` if no kit remains on this machine. Follow returned Instructions.txt. The owner ran the clean e32fa11 kit and reported all appeared to pass; exact data contradicts literal %PATH% preservation. Ten other multiple names and a single parentheses name arrived unchanged. A04 is owner-reported pass; folder/direct-BAT follow-up pending. Require observer/date/completed Explorer steps, then use `Test-LauncherManualReports.ps1 -Manifest <manifest>` for exact native/bound data and BAT-hash checks. Data checker alone does not establish human Explorer use. Keep raw paths/environment/report/ACL data outside Git. Close consoles then run `Remove-LauncherManualFixture.ps1`; it restores the one owned synthetic ACL and checks cleanup containment/reparse points.

Kit: zero/single/folder/multiple, eleven benign special-character/Unicode names, matching PATH/NAME variables, visible missing PS1/FFmpeg/FFprobe and read-denied FFmpeg diagnostics. Arguments use byte-identical actual BAT plus dedicated recorder PS1; error checks use production PS1/BAT copies. Per-process wrapper isolates APPDATA/PATH/NAME and forwards once without CALL; disclose its extra shell layer. No real media/config/encoder.

Raw outer CMD expands %PATH% before BAT starts; /V:ON can expand !NAME!. Quoted folder trailing backslash has native quoting loss; documented CMD spelling omits slash or uses D:\. Actual Explorer must determine variable-like filenames. Any mismatch stays failed and blocks verification; do not waive A01/A02 or substitute env-seeded automation. No system association/policy rewrite or broad raw-commandline recovery in this slice. M1-02 remains implemented until all applicable manual items pass.

## Tested scope and handoff

Each host Quick 101/0/0/4; Targeted 115/0/4/4 (passed/failed/skipped/NotRun), exit 0. Windows 11 Pro 10.0.26300, PS5.1.26100.9444/PS7.6.5, external pinned Pester 5.7.1/analyzer 1.24.0 reused. Quick includes 22 new +75 existing Pester and four static gates; Targeted adds six native entry/menu/eight synthetic JSON. Four known config/enumeration defects excluded; four media recipes skipped for absent FFmpeg/FFprobe; Full not rerun.

BAT directly forwards %* with DisableDelayedExpansion, installed PS5.1, retained NoExit/process-only Bypass and visible startup failures. Minimal Ensure-Tool application/leaf/readability check reports underlying permission details before config creation; it does not validate format/execute ACL/capabilities. NoExit startup errors may later exit zero. Defaults/media processing and existing PS1 encoding/CRLF preserved; BAT ASCII/CRLF.

End with task/evidence/status/next/session updates, intentional commit/push and clean live fetch/push equality check; update draft PR/check state. Main push/merge, release/tags/settings/secrets/deployment and quality changes need explicit owner approval.
