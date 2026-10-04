# Evidence — WVC-M0-03

Recorded 2026-10-04. Bounded harness acceptance A01-A04 verified; no owner, milestone or release acceptance. [Exact commands/results](WVC-M0-03.json), [session](WVC-M0-03-session.md).

Implementation `7d37d0ef80238d9482fec4976dc377487f7b4818`; final tested follow-up `dffc714ba3f6269f12e8e88056f49bae345ead68`. Every final run below observed that exact latter commit with a clean tree. Final handoff changes are documentation/evidence only.

## Change and boundaries

Added the `tools/test.ps1` Quick/Targeted/Full/Manual entry point, pinned developer dependencies, Pester child reporting, shared native-process/ownership/report helpers, harness regressions and synthetic fixture generator/inventory. Existing focused runners use central pins and per-case reporting. Nested regression files are discovered automatically in stable order.

`.gitattributes` preserves existing application/launcher bytes and uses CRLF for new developer files. New PS1 files must be ASCII or UTF-8 with BOM for Windows PowerShell 5.1. `.gitignore` excludes generated dependencies/results/media/binaries. Analyzer gates error-severity diagnostics without rewriting legacy style. The developer setup is explicit; compression and tests never download dependencies automatically.

No change to WinVidCompress.ps1, WinVidCompress.bat, original README, license, assets or quality defaults. PS1 SHA256 `6F7015B37DD492CBD62511A76DAE16FAECDBB2873C45E2860A233E5C815F38FA`; BAT SHA256 `C5A38591DDE911446A97B210F2E7C520F52DCFD456DCF381A2A351B94D4A9F6D`.

## Actual validation

Host: Windows 11 Pro 10.0.26300; Windows PowerShell 5.1.26100.9444 Desktop and PowerShell 7.6.5 Core tested separately. Pester 5.7.1/analyzer 1.24.0 reused from external temporary developer modules prepared in M0-02. Python 3.14.7, Git 2.56.0.windows.1, GitHub CLI 2.97.0. No FFmpeg/FFprobe available.

| Exact-commit run | Passed | Failed | Skipped | NotRun | Exit |
|---|---:|---:|---:|---:|---:|
| Quick, PS5.1 | 59 | 0 | 0 | 5 | 0 |
| Quick, PS7 | 59 | 0 | 0 | 5 | 0 |
| Targeted, PS5.1 | 70 | 0 | 4 | 5 | 0 |
| Targeted, PS7 | 70 | 0 | 4 | 5 | 0 |
| Full, both hosts | 125 | 10 | 4 | 8 | 1 |
| Manual, no human checks executed | 0 | 0 | 0 | 7 | 2 |
| Explicit absent PS7, Quick | 4 | 0 | 1 | 0 | 2 |
| PS5.1 supplied as PS7, Targeted | 14 | 0 | 6 | 0 | 2 |

Quick includes 22 positive characterization, 19 harness and 14 fixture Pester checks plus four static/schema gates. Targeted adds three native recorder entry cases and eight copied/hashed synthetic JSON cases. Counts include individual static/fixture cases, not just Pester or media encodes. Quick/Targeted's five NotRun cases are explicitly excluded KnownDefect checks.

Full's ten failures are five desired application assertions on each host: Quit returns; valid `{}` configuration recovers; empty folder queues safely; single-video folder and explicit single file process without scalar Count errors. They remain broken baseline behavior for M1-01/M1-03/M1-04. Full's eight NotRun records include seven actual manual checks and future media/CLI/safety/packaging coverage. This is a failing gate, not verified application/release behavior.

The negative prerequisite runs execute no falsely labelled PS7 unit suite. Static/JSON/available entry checks may pass while the required host is unavailable, but aggregate status stays Incomplete/exit 2. Actual Pester subprocess regressions also verify 1 pass/1 fail/1 skip with exit 1 and all-skipped suites with exit 2. Missing/corrupt/count-mismatched/duplicate reports and nonzero exits cannot be promoted to success.

Repeating clean-commit PS7 Quick with a distinct report path produced byte-identical JSON, SHA256 `7E2EBE146143EAA5651D17FC354B9E354BAFE8FADB42D12984F06AF2F30157CA`. All command wrappers, observed versions, case IDs, omissions and fixture outcomes are recorded in JSON. Tracker validates 32 tasks/128 criteria/23 mappings; CRLF-aware staged whitespace check passes.

## Acceptance mapping

- **A01 passed:** deterministic real counts and exit policy verified by mixed/all-skipped child executions, full baseline failures and invalid-report regressions on both hosts. Cleanup/report errors propagate before final report serialization.
- **A02 passed:** four media cases explicitly Skipped in both Targeted reports; absent and wrong-version required hosts produce Incomplete/exit 2. Requested host identity is checked before unit/entry execution.
- **A03 passed:** reviewed intended artifacts contain no private media/config/paths/raw logs, secrets, executables or packages. Application/launcher hashes are unchanged. Native recorders and isolated APPDATA/source/output roots stay outside Git; generated outputs are ignored. No dependencies were downloaded in this task.
- **A04 passed:** [inventory](../../../tests/fixtures/inventory.json) maps all 12 cases to files, full argument arrays, capabilities, expected streams, synthetic provenance and cleanup ownership. Runtime inventories add observed generation/probe outcomes and owner information. Eight JSON cases copied/hashed; four media recipes explicitly skipped.

## Fixtures and outstanding checks

Implemented one-second SDR video/audio, silent video, multi-stream and audio-only recipes. Native success requires exit zero, an actual output and structurally matching FFprobe streams/finite duration. Tests exercise recipe/inventory consistency, missing tools, native failures/no output, non-finite duration, malformed/wrong-shaped JSON and unexpected streams. Actual successful FFmpeg generation/probing remains unexercised because the tools are absent. Structural checks do not establish full visual/audio integrity.

Eight probe JSON cases are hand-authored synthetic data: attached picture/non-contiguous indexes, odd display geometry/SAR/rotation, PQ, HLG, 10-bit SDR, unknown duration, wrong shape and malformed raw JSON. Copying them is not real media handling validation. Roots use unique temp names/tokens/markers; cleanup validates containment, ownership and reparse absence. Failure diagnostics remain local. Source/final-output/neighbor sentinels are preserved by checks.

Actual PS1 -File on both hosts and unchanged BAT pass with a two-file synthetic folder/native recorders; no media is produced. No actual Explorer, double-click menu, real cancellation, playback/colour judgement, UNC/long-path or benchmark check ran. Manual checklist is unfilled and incomplete.

## Git and continuity

Branch `codex/wvc-m0-03-harness`, based on inspected owner-merged main `d1b28add3cd72375ff15ac6a3c625e4de619c8c8`. Origin has one fetch and push destination: `https://github.com/PikkuJanne/WinVidCompress.git`. Both implementation commits pushed. Last verified clean live fetch/push equality: `dffc714ba3f6269f12e8e88056f49bae345ead68` at `2026-10-04T17:09:49.610890+00:00`.

Draft [PR #3](https://github.com/PikkuJanne/WinVidCompress/pull/3) open against main; zero workflow runs and empty PR checks at the final implementation commit. No CI pass. Final handoff push/live check is pending when committed; report its final SHA externally after push, without a self-SHA loop.

No blocker to **WVC-M1-01 — Repair menu exit and separate source/output folder selection**. Actual encoder/media/manual acceptance remains outstanding. No main push/merge, history rewrite, release, deployment, repository settings/secrets or default-quality change performed.
