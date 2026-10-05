# Next session

Exact next task: **WVC-M1-02 — complete supported-route verification under approved D005**. Task implemented; revised A01/A02 not_run, A03/A04 passed. Next independent code task **WVC-M1-03 — Make configuration validation and recovery safe**. Do not implement another task silently.

## Accepted boundary and evidence

Owner replied “the proposed filename restriction accepted” on 2026-10-05. D005 excludes variable-shaped percent segments such as %PATH% anywhere in a BAT drop path. Use literal-path menu or direct PS1 from PowerShell for those paths. Ordinary percent names and BAT !NAME! support remain required. Historical direct BAT percent failure stays recorded; approval is not a passing test.

Supported kit: two direct Explorer drops (folder and all ten files) plus one real menu selection session. The menu helper dot-sources the byte-identical PS1 and replaces only Process-Paths; isolates APPDATA/PATH/NAME/output and invokes no encoder. Supplemental direct-native call is automated and labelled separately. Human observers and exact path/source/helper/hash/host data must agree before verifying A01/A02. Use fresh reports; do not erase/filter old failures. No full production compression/visual integrity claim.

## Current checkpoint

- Root D:/projects/WinVidCompress-main; feature/upstream codex/wvc-m1-02-launcher / origin/codex/wvc-m1-02-launcher.
- One origin fetch/push destination https://github.com/PikkuJanne/WinVidCompress.git; draft [PR #5](https://github.com/PikkuJanne/WinVidCompress/pull/5).
- Previous clean live equality 2026-10-05T14:18:28.852039+00:00 describes 67bb0e80b347817e3072fa7b23bdbafc892226cd. New implementation/final handoff sync reported externally; independently verify it.
- Original clean implementation e32fa11067bc8bb5133e8913840561deba79573f: each host Quick 101/0/0/4 and Targeted 115/0/4/4 (passed/failed/skipped/NotRun). D005 follow-up clean 67bb0e80b347817e3072fa7b23bdbafc892226cd: Quick106/0/0/4 and Targeted120/0/4/4 on each host, all exits0; supported-fixture scripted smoke passes both. Actual supported-route human checks remain pending in a fresh clean-commit kit already prepared.
- Real Windows 11 Pro 10.0.26300 UBR9457; PS5.1.26100.9444 and PS7.6.5. Pester5.7.1/analyzer1.24.0 reused externally. Four absent-media skips/four known config/enumeration NotRun; Full not rerun. No CI runs/pass.

Read AGENTS/INDEX/STATUS/GIT_SYNC, task/brief and [evidence](evidence/WVC-M1-02.md). Inspect branch/upstream/HEAD/dirty ownership, operation/conflict/hook state and effective URLs. Fetch --no-tags, then run tools/codex-winvidcompress/check_repo_sync.py against this root. Preserve unknown changes; one writer. If PR5 merged inspect current main before continuing.

New short fixture: powershell -NoProfile -ExecutionPolicy Bypass -File tests/launcher/New-LauncherSupportedFixture.ps1. Preparation and scripted smoke are not human acceptance. Give short exact instructions, inspect full UTF8 reports and source/helper hashes, keep private paths outside Git. Retain historical reports; close consoles before owned cleanup with Remove-LauncherManualFixture.ps1 (old full-character kit has one synthetic ACL to restore).

End with intentional evidence/status/next/session commit/push, live fetch/push equality and clean state; report exact SHAs/PR/CI/tests/omissions. No self-SHA loop. Main/merge/release/policy/quality/settings/secrets changes need explicit owner approval.
