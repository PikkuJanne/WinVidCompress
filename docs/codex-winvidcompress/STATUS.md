# Current programme status

Updated: 2026-10-05. Repository: `PikkuJanne/WinVidCompress`.

M0-01/M0-02/M0-03/M1-01 are verified. **M1-02 is implemented: A01/A02 failed in the prepared Explorer run due literal %PATH% substitution; A03/A04 pass. Folder/direct-BAT follow-up pending.** The owner reported all appeared to pass; recorded argv contradicts the literal-percent result. Remaining 27 tasks are todo; 108 criteria are not_run. TASKS.json is authoritative. No milestone/release acceptance.

## Repository and reconciliation

- Root `D:/projects/WinVidCompress-main`; feature/upstream `codex/wvc-m1-02-launcher` / `origin/codex/wvc-m1-02-launcher`.
- Single expected fetch/push destination: `https://github.com/PikkuJanne/WinVidCompress.git`.
- Began clean at M1-01 confirmation `bf4b3416db1d404600f0430512b86ebf3ffc4675`, live synchronized, no operations/conflicts/active hooks/unknown changes.
- Owner merged PR #4. Fetched main `096c65c7fb1b7d02ee6bc2efcaffedd7a8952b67` descended from that feature with the identical tree. Created this feature from inspected main; no reset/stash/clean/history rewrite.
- Implementation/tested commit `e32fa11067bc8bb5133e8913840561deba79573f`: BAT disables delayed expansion and directly forwards `%*` once to installed Windows PowerShell 5.1, retaining NoExit/process-only Bypass. Missing script/host and native launch failures display diagnostics/remedies.
- Minimal Ensure-Tool application/leaf/readability check reports permission details before config creation. Defaults/media processing unchanged. Existing PS1 encoding/CRLF and BAT ASCII/CRLF retained.

## Evidence

[Evidence](evidence/WVC-M1-02.md), [exact JSON commands/results](evidence/WVC-M1-02.json), [session](evidence/WVC-M1-02-session.md), [launcher workflow](../../tests/launcher/README.md). Earlier [M1-01 evidence](evidence/WVC-M1-01.md) is historical; its completed menu check does not establish new argv criteria.

Windows 11 Pro 10.0.26300 (UBR 9457), PS5.1.26100.9444 Desktop and PS7.6.5 Core. External pinned Pester 5.7.1/analyzer 1.24.0 reused without download.

| Clean implementation, 2026-10-05 | Passed | Failed | Skipped | NotRun | Exit |
|---|---:|---:|---:|---:|---:|
| Quick, each host | 101 | 0 | 0 | 4 | 0 |
| Targeted, each host | 115 | 0 | 4 | 4 | 0 |

Quick is 97 Pester checks (22 new) plus four static/schema gates. New coverage measures native argv and production-matching Path for zero/single/folder/multiple arguments, eleven special-character/Unicode names, matching PATH/NAME variables and a special-character script directory; seven startup-error cases include a real read-denied synthetic dependency with restored ACL. Four report-integrity tests reject absent/wrong/duplicate/raw-bound-mismatched evidence. Sources/APPDATA/output are isolated. Targeted adds six native entry/menu and eight synthetic JSON cases. BAT exercises actual PS5.1 under both suites; direct PS1 also exercises PS7.

Four unrelated config/empty/single enumeration defects remain NotRun per host (M1-03/M1-04). Four media recipes skip for absent FFmpeg/FFprobe. Full not rerun for this bounded task; earlier failed Full remains historical.

## Manual state and limits

The clean implementation Explorer kit and source hashes were verified. It uses byte-identical BAT plus recorder PS1, per-process APPDATA/PATH/NAME setup and production-script error cases. Preparation/data checks are not human Explorer observations. Owner reported all prepared checks appeared to pass. Four reports show zero args, an unchanged single parentheses filename and 10/11 unchanged multiple paths; literal %PATH% changed. Folder/direct-BAT follow-up pending. A04 passes from the owner's direct report; tentative wording retained.

Measured caller limits: raw outer CMD expands `%PATH%`, /V:ON can expand `!NAME!`, and a quoted CMD folder ending in one backslash can arrive with a literal closing quote. BAT cannot recover already-altered arguments. Use menu literal-path entry/direct PS1 single-quoted paths where needed; omit CMD folder trailing slashes or use `D:\.`. CMD/batch expanded text has an 8,191-character limit. Any actual Explorer mismatch must remain failed, not waived.

NoExit leaves startup exceptions visible at a prompt; a later plain exit may return zero. No unattended startup-exit contract. Readability does not establish executable format/execute ACLs/capabilities/media integrity.

Draft [PR #5](https://github.com/PikkuJanne/WinVidCompress/pull/5) open against main; zero implementation check/workflow runs, no CI pass. Previous clean live equality at `2026-10-05T13:10:20.088784+00:00` describes `e32fa11`. Final documentation handoff push/live check pending when committed, reported externally afterwards without a self-SHA loop.

Exact next: **resolve WVC-M1-02 literal %PATH% failure or obtain an explicit owner decision; finish folder/direct-BAT follow-up**. Next code task: **WVC-M1-03 — Make configuration validation and recovery safe**. No main push/merge, quality change, release/deployment/settings/secrets action.
