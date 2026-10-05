# WVC-M1-02 evidence — 2026-10-05

Implemented/tested at `e32fa11067bc8bb5133e8913840561deba79573f`, based on owner-merged M1-01 main `096c65c7fb1b7d02ee6bc2efcaffedd7a8952b67`. [Exact JSON](WVC-M1-02.json), [session](WVC-M1-02-session.md), [launcher workflow](../../../tests/launcher/README.md). Current A01/A02 are not_run under owner-approved D005, pending revised supported-route observations; A03/A04 pass. Historical direct BAT percent failure is retained below. No full/release acceptance.

Valid initial regression: original application plus eight new uncommitted tests, PS5.1, 3 passed/5 failed, exit 1. The BAT erased ! from its own script path and reconstructed folder arguments incorrectly. A preceding harness attempt accidentally omitted PowerShell from PATH (1 pass/7 failed); it is not application defect evidence.

## Implementation and verification

BAT disables delayed expansion, directly forwards %* once to installed Windows PowerShell 5.1, and retains NoExit/process-only Bypass. Missing PS1/host and native launch failures remain visible with remedies/diagnostics. Narrow Ensure-Tool application/leaf/readability check reports permission details before config creation. Defaults/quality/media processing unchanged. Existing PS1 encoding/CRLF and BAT ASCII/CRLF retained.

The isolated dedicated PS1 recorder matches production parameters and captures real native host argv plus bound Path using UTF-8/base64. Zero/single/folder/multiple selections, eleven special-character/Unicode names, matching PATH/NAME variables, special-character script directory, count/order/ordinal equality and source sentinels are measured. BAT uses actual PS5.1 under both suites; direct PS1 also uses PS7. Inherited /V:ON case claims only no-argument startup.

Seven startup cases cover missing script/host, unusable host, missing FFmpeg/FFprobe, directory masquerading as executable, and read-denied synthetic FFmpeg with restored ACL. Four manual-report checks reject absent/wrong/duplicate/raw-bound-mismatched data. Preparation/empty-check/ACL-restoring cleanup smoke passed; none is a human Explorer check.

| Clean implementation on Windows 11 Pro 10.0.26300 | Passed | Failed | Skipped | NotRun | Exit |
|---|---:|---:|---:|---:|---:|
| PS5.1.26100.9444 Quick | 101 | 0 | 0 | 4 | 0 |
| PS7.6.5 Quick | 101 | 0 | 0 | 4 | 0 |
| PS5.1.26100.9444 Targeted | 115 | 0 | 4 | 4 | 0 |
| PS7.6.5 Targeted | 115 | 0 | 4 | 4 | 0 |

Pester 5.7.1/analyzer 1.24.0 reused externally. Quick is 97 Pester checks (22 new) plus four static gates. Targeted adds six existing native entry/menu/eight synthetic probe JSON cases. Four media recipes skip for absent FFmpeg/FFprobe; four unrelated config/enumeration KnownDefect cases remain NotRun per host. Full not rerun for this bounded slice; prior failed Full remains historical.

## Acceptance

| Criterion | Status | Actual evidence/remaining work |
|---|---|---|
| A01 | not_run | D005 now excludes variable-shaped percent paths from BAT drops. Revised manual observations pending; historical evidence: Prepared Explorer multiple run preserves 10/11 names; literal %PATH% changes. Single parentheses name preserved. Direct BAT percent failure confirmed; folder/multiple fixture subcases remain unverified. |
| A02 | not_run | D005 now requires literal menu/direct PS1 routes for these paths. Revised manual observations pending; historical evidence: Direct Explorer BAT drop also substitutes literal %PATH%, so Check.bat is not the sole cause. Initial matching-NAME fixture preserves !NAME!. |
| A03 | passed | Direct -File %*, DisableDelayedExpansion, no ARGS/CALL/expression eval/cmd pipeline/broad policy change; both-host static/targeted pass. |
| A04 | passed | Owner reported prepared error checks passed on 2026-10-05; tentative wording retained. Seven automated scenarios also pass. |

Owner first replied “I’ll run the prepared checks now”, then “I think all checks passed. Some of them were a bit too wall of text for human iteration, but I'm pretty sure all passed.” on 2026-10-05. Exact native/bound records contradict literal %PATH% preservation: 10/11 multiple names unchanged, one expanded to PATH. The private expansion value is omitted. Clean e32fa11 kit/source hashes rechecked. Argument kit uses byte-identical BAT plus recorder PS1; setup isolates per-process APPDATA/PATH/NAME and forwards without CALL. Error kits use production-script copies; synthetic files only. Require human observer/date/completed steps and any mismatch.

## Limits and continuity

Outer CMD can expand %PATH% (or !NAME! under /V:ON) before BAT starts; a quoted CMD folder ending in one backslash can arrive with a literal closing quote. These measured limits are not successful round trips/waived criteria. Menu literal-path entry/direct PS1 single-quoted paths and documented folder spelling avoid caller issues; actual Explorer mismatches remain failures. Microsoft documents [caller interpretation for -File](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_exe?view=powershell-5.1) and the [8,191-character CMD/batch limit](https://learn.microsoft.com/en-us/troubleshoot/windows-client/shell-experience/command-line-string-limitation).

NoExit leaves startup exceptions visible; user exit may later return zero. No unattended status claim. Readability does not establish executable format/execute ACL/capabilities/media integrity. Raw local paths/reports/config/ACL/dependency files stay outside Git. No automatic download/private media/policy change/main push/merge/quality change/release/deployment/settings/secrets action.

Draft [PR #5](https://github.com/PikkuJanne/WinVidCompress/pull/5), zero implementation check/workflow runs. Previous clean live local/fetch/push equality at `2026-10-05T13:10:20.088784+00:00` describes e32fa11. Final documentation sync externally reported after commit/push, not embedded in its own commit.

Exact next: resolve M1-02 literal %PATH% failure or obtain an explicit owner decision, and retain unverified folder/multiple fixture subcases; next code task WVC-M1-03 configuration validation/recovery.

## Direct Explorer follow-up — 2026-10-05

The owner confirmed: “Completed all three drops using Explorer and WinVidCompress.bat directly.” Prepared BAT/PS1 hashes still match tested e32fa11; all eleven synthetic source sentinels are unchanged.

The new percent-file record (13:48:03 UTC) contains one substituted path in both native argv and bound Path. This confirms a direct BAT failure independent of Check.bat, so A01/A02 remain failed. The next report contains a different existing folder; the last contains one generated argv JSON file instead of eleven .mov fixtures. Those requested subcases remain unverified; neither is evidence of launcher argument loss. Private paths/expanded environment values are omitted.

Exact earlier expansion stage is not isolated by these records; the proven boundary is before PS1 parameter binding. A read-only review found no robust thin-forwarding fix that reconstructs already-substituted arguments within the current task constraints. Raw parent-command-line recovery would require specialized shell parsing, cannot undo earlier execution, and conflicts with avoiding multi-stage reconstruction.

No new application/test code, dependency download, policy/association change or broad test rerun. Prior clean Quick/Targeted results retained; owned-root/hash/sentinel/data/schema/whitespace checks performed. A03/A04 remain passed. Task stays implemented and PR draft. Exact next is an explicit owner decision on a documented BAT %NAME% filename restriction (literal-path menu/direct PS1 route), or separately scoped launcher work under unchanged requirements. No acceptance change/waiver is inferred. Folder/multiple fixture subcases still require correct inputs after resolving that decision.

## Proposed supported-path boundary — historical pre-approval record

The concrete proposal for the owner's decision is:

- A01 retains the listed characters and all four invocation shapes. BAT drops exclude environment-variable-shaped percent segments such as %PATH% in any path component. Such paths use the literal-path menu or direct PS1 invocation from PowerShell with literal string arguments.
- A02 tests literal %PATH% and !NAME! with matching variables through those supported literal-path routes; BAT !NAME! preservation remains required. The observed BAT %PATH% failure stays recorded as the reason for the restriction.

This changes the existing A02 requirement, not its test result. TASKS.json and the task brief are unchanged. Approval would authorize documentation/criteria updates and focused verification of the supported routes; it would not immediately make M1-02 verified. Folder and multiple-file checks still need the requested inputs. Keeping the existing requirement requires separately scoped launcher work, with its design and acceptance reviewed before implementation.

## Accepted boundary D005 — 2026-10-05

The owner replied “the proposed filename restriction accepted”. D005 is applied explicitly in TASKS.json, the task brief, process/testing/full-matrix documentation, README and application help. BAT drops exclude variable-shaped percent segments such as %PATH% in any full-path component; these use literal-path menu entry or direct PS1 invocation from PowerShell with literal string arguments. Ordinary percent and BAT !NAME! support remain required. Historical direct BAT substitution remains recorded, not repaired.

Current revised A01/A02 are not_run while supported folder/multiple/menu observations remain pending. A03/A04 retain passing evidence; the task remains implemented. A new short owned kit provides ten supported BAT names and a folder plus the actual Run-TUI/Prompt-Path with only Process-Paths replaced by a recorder. APPDATA/PATH/NAME/output are isolated, no encoder runs, and a supplemental direct native PowerShell call records literal file/folder values. This establishes selection/binding, not compression integrity or full production startup.

Two menu regressions and three checker regressions are added. Case-limited grading validates all records; full defaults remain unchanged. Explicit UTF8 metadata/report reads fix PS5.1 Unicode decoding. Initial dirty-tree Quick checker failure and smoke decoding failure are retained in JSON; focused fixes/smoke passed. Exact clean-commit Quick/Targeted and fresh human checks are pending at this implementation checkpoint.

## D005 clean-commit validation and manual handoff

Tested clean implementation 67bb0e80b347817e3072fa7b23bdbafc892226cd on Windows 11 Pro 10.0.26300 UBR9457, PS5.1.26100.9444 Desktop and PS7.6.5 Core. Each host: Quick 106 passed/0 failed/0 skipped/4 NotRun; Targeted 120 passed/0 failed/4 skipped/4 NotRun; all exits 0. Quick includes 102 Pester cases (27 launcher/checker) plus four gates. Targeted adds six native entry and eight JSON fixture cases. Four absent-media recipes skip and four known config/enumeration cases remain NotRun. Full not rerun. Exact commands/counts/case IDs retained in JSON; pinned modules reused, no downloads.

Versioned supported-fixture smoke passed on both hosts: exact menu file/folder and native direct PS1 paths, source sentinels preserved, no config write, all five hashes match; owned smoke roots cleaned. Scripted data is not human acceptance. Read-only review found no safety blocker and qualified that new direct Explorer drops do not themselves establish matching NAME; matching-variable evidence comes from menu/direct plus earlier tests/observation.

Prepared a fresh clean-commit D005 kit and requested three short human checks: folder drop, ten-file drop and literal-path menu session. No completion report received yet; A01/A02 remain not_run, A03/A04 passed, task implemented. Raw paths/reports remain outside Git. Keep both manual kits until consoles/checks complete; earlier kit includes one synthetic ACL restored by owned cleanup. Draft PR5 remains open; zero check/workflow runs at 67bb0e8, no CI pass.

Live clean local/fetch/push equality at 2026-10-05T14:18:28.852039+00:00 verifies 67bb0e8. Final documentation handoff push/live check is pending when committed; report externally without a self-SHA loop. Exact next: finish WVC-M1-02 supported-route observations under D005; next independent code task WVC-M1-03 configuration validation/recovery.
