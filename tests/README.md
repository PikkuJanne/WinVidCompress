# Developer tests and fixture setup

Application entry points remain WinVidCompress.ps1 and WinVidCompress.bat. Tests run in separate processes, use isolated APPDATA/output/source roots, and never launch the real interactive menu.

## Pinned developer dependencies

`tests/Dependencies.psd1` pins Pester **5.7.1** and PSScriptAnalyzer **1.24.0**, verified against their official [Pester release](https://github.com/pester/Pester/releases/tag/5.7.1) and [analyzer release](https://github.com/PowerShell/PSScriptAnalyzer/releases/tag/1.24.0). Actual compatibility is tested on Windows PowerShell 5.1 and supported PowerShell 7 (minimum 7.4). Retain these tested versions until a separate reviewed update.

Prepare an external developer module directory explicitly if needed:

```powershell
$moduleRoot = Join-Path ([IO.Path]::GetTempPath()) 'wvc-dev-modules'
Save-Module -Name Pester -RequiredVersion 5.7.1 -Path $moduleRoot
Save-Module -Name PSScriptAnalyzer -RequiredVersion 1.24.0 -Path $moduleRoot
```

Setup is a developer action. Runners never install/download dependencies, elevate or change persistent execution policy. FFmpeg/FFprobe must already be installed or supplied through `-FFmpeg`/`-FFprobe`; no codec fallback or automatic download occurs. Python is used only for the existing developer tracker validator.

## Tier entry points

From the repository root, execute in a fresh shell:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -Tier Quick -ModuleRoot $moduleRoot
pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -Tier Quick -ModuleRoot $moduleRoot
pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -Tier Targeted -ModuleRoot $moduleRoot
pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -Tier Full -ModuleRoot $moduleRoot
pwsh -NoProfile -ExecutionPolicy Bypass -File tools/test.ps1 -Tier Manual
```

- **Quick**: current-host Pester characterization/harness/fixture checks, parse, pinned error-severity analyzer, new PS1 encoding policy and task/evidence schema.
- **Targeted**: Quick plus actual direct PS1/BAT entry smoke with native recorders and runtime fixture generation/probing. With FFmpeg unavailable, four media fixtures plus two M2-02 output confirmation tests are explicitly skipped and eight synthetic JSON cases copied/tested.
- **Full**: defaults to both required hosts and runs Targeted components. It also records remaining manual/future coverage as NotRun; full-harness execution is not completed release acceptance.
- **Manual**: creates an unfilled checklist for Explorer, real cancellation, playback, paths and benchmarks. It performs no manual checks and returns incomplete; an agent must not mark those checks passed from mocks.

Quick/Targeted exclude KnownDefect cases with visible NotRun records. Add `-IncludeKnownDefects` to run them explicitly. Fix tasks should move repaired regressions into normal coverage. Original focused `tests/Invoke-Characterization.ps1` remains available with its `-KnownDefects` switch.

The tier runner bounds the complete Pester subprocess at 120 seconds; individual native fixture deadlines remain separate. M2-02's additional owned native compilers exposed the former 60-second whole-suite deadline in one PS7 Targeted run. A timeout still fails the gate and retains owned diagnostics; the allowance does not turn an incomplete suite into a pass.

M1-01 replaces the old AST-only Quit defect probe with normal nested menu/path regressions that execute the real menu function with bounded mocked input. Quit returns to its caller; the unchanged BAT's `-NoExit` leaves its PowerShell prompt open. Actual Explorer double-click acceptance must still be recorded separately.

For an isolated human menu check when real encoders are unavailable, run `powershell -NoProfile -ExecutionPolicy Bypass -File tests/unit/New-MenuManualFixture.ps1`. It copies the actual PS1/BAT bytes into an owned temp root, supplies startup-only native dependency sentinels, and creates `Check-Menu.bat` to isolate APPDATA/PATH before calling the unchanged launcher. Double-click that preparation wrapper in Explorer, select 4 once, verify a usable PowerShell prompt remains, then type `exit`. Record the wrapper/sentinel limitation and actual observer/result; preparation or scripted stdin is not manual acceptance. Clean only this returned Owner using `Remove-WvcTestRoot` after closing its console.

The tier runner automatically discovers all nested `tests/**/*.Tests.ps1` in stable path order, so later unit/integration regressions are included without changing a hard-coded suite list.

M1-02 adds measured PS1/BAT argv and actionable startup-error regressions in [launcher](launcher/README.md), including an isolated actual Explorer check kit. The current BAT forwards `%*` once with delayed expansion disabled and retains its PowerShell prompt. The six older native entry case labels retain their historical `original-bat` name but execute the current launcher. Automated caller/recorder results never establish Explorer/manual acceptance.

M1-03 adds [config regressions](unit/Config.Tests.ps1) with a new isolated APPDATA/output root per case, malformed-byte backups, no silent destination fallback, unknown nested keys, timestamp strings and excessive-depth refusal. Real Windows ACL listing denial, file-as-directory, read/replace sharing denial, lock contention and no-clobber backup/temp primitives complement simulated offline drive/UNC and write/promotion faults. The fixture ACL is restored in finally. The repaired wrong-shaped config characterization is now normal coverage. These checks do not require FFmpeg or Explorer and do not claim real disconnected-share/crash durability coverage.

Choose `-Hosts Current`, `WindowsPowerShell`, or `PowerShell7`; Full's default is both named hosts. Executable overrides are `-WindowsPowerShell` and `-PowerShell7`. The harness verifies each host's actual version/edition before assigning its label. An explicit missing override is unavailable, rather than a request to fall back silently to PATH.

M1-04 adds [discovery regressions](unit/Discovery.Tests.ps1) for arrays, literal normalization, explicit extension/provider rejection, scan records, partial listing errors, read-sharing/real ACL denials and real junction loops/outside-root/ancestor selections. The three repaired enumeration characterizations now run normally in Quick/Targeted. All ACLs and junction objects are restored/removed in finally; synthetic source hashes/sentinels remain intact.

For the manual Windows path check, prepare `pwsh -NoProfile -ExecutionPolicy Bypass -File tests/unit/New-DiscoveryManualFixture.ps1`. It copies the actual application into an owned temp root and creates Unicode, below/above-260-character and existing localhost administrative-UNC selections. No shares, policies or dependencies are created. In Explorer, double-click the returned root's Check-Discovery.bat. Each host checks counts/hashes/paths automatically and shows four short PASS/FAIL rows. Confirm only that the window opened normally and its character sample is readable; type PASS, FAIL or UNSURE, then Enter. UNSURE records incomplete observation (exit2); an automatic failure cannot become a human pass. Detailed no-clobber reports are saved automatically and need no human comparison. Preparation or `Invoke-DiscoveryPathCheck.ps1 -Automated` does not establish manual acceptance. Localhost UNC coverage does not establish remote/offline SMB behavior or FFmpeg long-path support. Use Remove-WvcTestRoot under PS7 after both windows close; long paths may exceed Explorer/PS5.1 cleanup capabilities.

M1-05 adds [queue regressions](unit/Queue.Tests.ps1) for overlapping/repeated selections, stable ordinal order, case/provider/extended aliases, long-path key compatibility, complete scan-before-encode ordering, visible partial failures and originals in equal/nested destinations. File-writing encoder recorders use CreateNew and hash source/existing-output sentinels; they exercise the actual sequential dispatch and collision policy without FFmpeg. Hard links remain distinct path identities. Existing compressed/partial names are ambiguous until a later ownership protocol exists. These automated queue checks do not establish playback, source-change detection or Explorer multi-drop acceptance.

## Reports and exit codes

M1-06 adds `unit/Environment.Tests.ps1` with real Windows processes compiled from synthetic C# recorders under PS5.1. Cases cover PATH/adjacent precedence, command shadows, unreadable/non-executable/wrong binaries, exact capabilities, native exits/stderr, hung checks, inherited pipe handles, large concurrent streams, argv and actual create-file ACL denial. Doctor tests isolate APPDATA/output and preserve saved/absent/malformed preferences; menu selection and batch checks refuse inaccessible destinations. The shared environment responder keeps the existing entry/manual fixtures usable. Two actual PS1 `-CheckEnvironment` entry cases join the six existing dispatch cases. No recorder establishes real FFmpeg/media support or Explorer acceptance; installed-tool media omissions remain explicit.

M2-01 adds 44 `unit/Probe.Tests.ps1` cases and an owned native JSON/exit/hang recorder. Cases cover one-call literal argv, UTF-8 metadata, structured failure/timeout, invalid schemas/required fields, artwork/audio-only rejection, source/final hashes, invariant optional metadata/duration and unknown-duration encoder dispatch. The recorder emits no media; existing probe JSON fixtures cover uncommon metadata. Characterization/queue mocks and the entry responder now match the structured inspection contract. Real FFmpeg checks remain separate.

M2-02 adds 13 `unit/Streams.Tests.ps1` cases with real native probe/encoder argument recorders. They cover shuffled absolute indices, video/height coupling, artwork, unique/no/multiple-default audio selection, silence, channels/metadata/omission reports and unchanged source/final hashes/default tokens. `integration/Streams.Tests.ps1` adds two short real-output checks when FFmpeg/FFprobe applications are on PATH: multi-video/multi-audio output selection and silent output without audio. Existing recipes are reused, with a larger later video to expose automatic selection. APPDATA/FFREPORT/output roots are isolated; no dependencies downloaded. These Pester cases are discovered by Quick/Targeted; without native tools they remain skipped, including two Quick skips. Recorder success does not establish actual encoded output identity or silent media completion.

`-ReportPath` selects a new report file; existing reports are never overwritten. Without it, the harness prints the location of a unique JSON report in temp. Reports use a stable schema and sorted case IDs, contain source SHA/dirty state, observed host/tool versions and real counts, and omit absolute fixture/module paths. They do not include elapsed-time or random fixture-root fields. Fixture recipes use relative files/output placeholders.

- **0**: selected Quick/Targeted checks succeeded; any excluded/skipped work stays visible as `PassedWithOmissions`.
- **1**: executed automated failure, native execution/report error, schema mismatch or cleanup failure.
- **2**: incomplete required prerequisites, no executed suite, or incomplete Full/Manual coverage.

Failed child execution, missing/corrupt/duplicate/count-mismatched reports and all-skipped required suites cannot become passing results. Pester tests exercise actual one-pass/one-fail/one-skip and all-skipped subprocess suites. Entry smoke publishes each case independently, preserving earlier observations when a later case fails.

Raw diagnostics are local to the owned temporary root and retained on failure; never commit them. Reports and dependencies under `.test-results/` and `.test-modules/` are ignored, but temporary roots are preferred. Review/sanitize evidence before sharing. Report counts include actual static/fixture checks as well as individual Pester cases; they are not exclusively application test counts.

## Fixtures and safety

See [fixture inventory](fixtures/inventory.json) and [fixture notes](fixtures/README.md). Media uses one-second lavfi signals and explicit maps/codecs; FFprobe checks structural properties and bounded finite duration. These checks do not prove full visual/audio integrity or playback.

Owned roots have unique names/tokens/markers under temp. Creation refuses reused fixture directories. Cleanup validates the absolute path, temp containment, ownership and absence of reparse points before recursive removal. Neighbors/source/final sentinels are preserved in tests. Native timeouts stop only the owned process tree using a PowerShell 5.1-compatible Windows fallback. Failed termination retains fixture roots.

The native entry recorder is compiled under Windows PowerShell 5.1 outside Git; it generates no media. Three batch cases use PS1 -File and BAT with a two-video synthetic folder; focused M1-04 regressions cover repaired single selections separately. Three menu cases use no-argument PS1/BAT and scripted Quit; a marker executed after Quit verifies BAT's PowerShell caller survives. The original launcher's -NoExit is closed through controlled stdin. These six cases are not Explorer drag/drop or comprehensive launcher argv acceptance.

## Line endings and encoding

`.gitattributes` preserves existing application PS1/BAT bytes using `-text`; both remain unchanged in M0-03. Preserve CRLF on any later BAT change. New `tests/**`, `tools/test*.ps1` and PSD1 developer files check out with CRLF. New PS1 files must be ASCII or UTF-8 **with BOM** so Windows PowerShell 5.1 reads Unicode correctly; Git does not manage the BOM. The quick gate enforces this policy without rewriting the legacy application.

JSON reports are UTF-8 without BOM, and fixture JSON is ASCII-compatible UTF-8. Use explicit UTF-8 when introducing Unicode data. Review staged whitespace using `git -c core.whitespace=cr-at-eol diff --cached --check`. PSScriptAnalyzerSettings.psd1 gates error-severity diagnostics; legacy warning/style debt is recorded, not hidden by source rewrites.
### Native encoder argv inspection (M2-03)

Run `tests/integration/Test-EncodeArgumentsManual.ps1 -ReportPath <existing-local-report-directory>/argv.json` explicitly under both `powershell.exe` and `pwsh.exe`, with the usual `-NoProfile -NonInteractive -ExecutionPolicy Bypass -File` development invocation. Inspect the three PASS/FAIL rows, host version and saved exact token/source-hash comparisons. This agent-executable manual-tier check compiles a local recorder with PS5.1 and uses an owned temporary root; it does not need FFmpeg or an owner visual judgement. It covers supported Unicode/punctuation filenames, D005 literal PowerShell variable-shaped percent routes, quotes/backslashes and shell-looking metadata. Retain earlier Explorer evidence separately; this is no new Explorer or produced-media acceptance claim.
