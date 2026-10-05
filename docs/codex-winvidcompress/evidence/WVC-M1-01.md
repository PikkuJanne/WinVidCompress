# Evidence — WVC-M1-01

Updated 2026-10-05. **Verified: A01-A04 passed.** The repository owner confirmed the actual Explorer check on 2026-10-05; automated results below were run on 2026-10-04 and have not been rerun for this documentation-only update. No broader milestone/release acceptance is claimed. [Exact JSON commands/results](WVC-M1-01.json), [session](WVC-M1-01-session.md).

Implementation and every final test: clean `6337b73d41cf65b9f12cb412800bc3d68780693c`. Branch `codex/wvc-m1-01-menu-paths`, based on inspected main `e8b54d1fdd03bdd3e0135c67c38335788a6f8112` after the owner's PR #3 merge.

## Behavior and boundaries

Quit uses function return, so it leaves the menu and preserves its caller. Prompt-Path validates source files/folders without creating directories. Only output selection supplies CreateIfMissing. Blank/whitespace, including quoted whitespace after normalization, cancels. Test-Path/Resolve-Path remain literal; .NET directory creation preserves bracket/Unicode names. Validation/creation errors display their actual diagnostic and allow retry/cancellation.

The four options, default compression profile, source processing and unchanged BAT remain. PS1 help documents that BAT's -NoExit leaves its PowerShell prompt after Quit. Existing PS1 CRLF/encoding were preserved with bounded ASCII byte replacements; no wholesale formatting/style rewrite.

Twenty focused nested menu/path regressions replace the old AST-only Quit KnownDefect probe with actual bounded menu behavior. Minimal existing test-runner additions add three native menu entry cases and developer manual-fixture preparation/instructions; these scope extensions support caller/launcher acceptance without an application framework.

## Actual results

Windows 11 Pro 10.0.26300; PS5.1.26100.9444 Desktop and PS7.6.5 Core separately tested. Pester 5.7.1/analyzer 1.24.0 reused from external temporary developer modules. No dependency download. FFmpeg/FFprobe absent.

| Clean-commit run | Passed | Failed | Skipped | NotRun | Exit |
|---|---:|---:|---:|---:|---:|
| Quick, PS5.1 | 79 | 0 | 0 | 4 | 0 |
| Quick, PS7 | 79 | 0 | 0 | 4 | 0 |
| Targeted, PS5.1 | 93 | 0 | 4 | 4 | 0 |
| Targeted, PS7 | 93 | 0 | 4 | 4 | 0 |
| Full, both required hosts | 168 | 8 | 4 | 8 | 1 |

Quick counts 75 individual Pester cases and four static/schema gates. Twenty task-specific cases pass per host. Targeted adds six actual native entry cases and eight copied/hashed synthetic probe JSON cases. Native batch smoke preserves synthetic source hashes; menu smoke renders once and Quit returns. BAT executes an output marker after Quit in its retained shell; the input splits the marker string so echoing input cannot pass the check.

Full fails the remaining four baseline assertions per host: wrong-shaped valid JSON/config recovery; empty-folder FullName; single-video folder Count; explicit single-file Count. These are M1-03/M1-04, not repaired here. Full is a failed gate. Four media fixtures skip because tools are absent; eight broader manual/future records remain NotRun. No actual encoding/probe/playback or full integrity result.

Before application edits, the initial 19 focused cases against the original application plus dirty test-only additions gave 8 passed/11 failed, exit 1. This reproduced repeated Quit, missing-source creation and uncaught access/creation failures. It is baseline regression evidence, not the final clean tested tree. Final coverage adds the real output-menu integration case for 20 focused cases. Quoted-whitespace regression now temporarily directs .NET working directory to TestDrive for isolation.

## Acceptance mapping

- **A01 passed:** real Run-TUI reads Quit once, renders once and continues its caller; native PS1 returns and BAT retained shell executes after Quit.
- **A02 passed:** a missing source selected through real menu/prompt stays missing and is not processed; existing source sentinel preserved. Only explicit output menu selection creates a nested directory and saves that selection.
- **A03 passed:** cancellation, literal brackets/Finnish/German/CJK file/folder/output names, wildcard-lookalike neighbor preservation, file-vs-folder rejection, mocked access denial and real file-blocked creation verified on both hosts. Fixture APPDATA/source/output only.
- **A04 passed:** on 2026-10-05 the repository owner quoted the actual Explorer double-click Check-Menu.bat / enter 4 / confirm a usable PowerShell prompt / type exit steps and replied **"Confirmed"**. This direct human observation completes the manual criterion (1 passed, 0 failed/skipped/NotRun); it is separate from scripted stdin. The prepared copy hashes were rechecked against the tested implementation and unchanged BAT.

Manual fixture preparation command: `powershell -NoProfile -ExecutionPolicy Bypass -File tests/unit/New-MenuManualFixture.ps1`. Prepared copies identify tested commit/hash. The generated Check-Menu.bat isolates APPDATA/PATH/PSModulePath and calls byte-identical application/BAT copies. Locally compiled startup-only dependency sentinels return 13 if accidentally invoked; no real media. The owner confirmed the prescribed Explorer/menu/Quit/exit steps. The isolation wrapper and startup sentinels limit this observation to menu/console behavior; it does not verify actual FFmpeg, special-character drag/drop or media integrity. No private absolute path/config/exe/token is committed.

Application SHA256 `46BF016996FF6A18372A77577ABF7D9C193E7F5AB542F317A5ACB5B93C4AC3D4`; unchanged BAT `C5A38591DDE911446A97B210F2E7C520F52DCFD456DCF381A2A351B94D4A9F6D`. Tracker/CRLF-aware whitespace pass. Read-only reviewer found no actionable final fix/test issue. No private media, raw logs, dependencies or executable artifact enters Git.

## Continuity

Origin one fetch/push destination `https://github.com/PikkuJanne/WinVidCompress.git`. Implementation pushed; live fetch/push/local equality and clean state at `2026-10-04T17:27:56.672063+00:00` for `6337b73d41cf65b9f12cb412800bc3d68780693c`. Confirmation follow-up began clean and live-synchronized at `17a49c0cd9c8193b983b0acfc3bbcfeea3e03aae`, checked `2026-10-05T12:42:56.214979+00:00`; fetch found no newer main/feature changes. Draft [PR #4](https://github.com/PikkuJanne/WinVidCompress/pull/4) open; zero workflow runs/empty PR checks, no CI pass.

Final documentation handoff push/check pending when committed; final equality reported externally after push. No own final SHA embedded. No main push/merge, history rewrite, quality change, release/deployment or settings/secrets change performed.

Next bounded task: **WVC-M1-02 — Harden the .bat launcher using measured argument round trips**. M1-01 has no remaining criterion/blocker. Full's known failures and broader media/manual gaps remain explicit.
