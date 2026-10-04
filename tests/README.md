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
- **Targeted**: Quick plus actual direct PS1/BAT entry smoke with native recorders and runtime fixture generation/probing. With FFmpeg unavailable, four media cases are explicitly skipped and eight synthetic JSON cases copied/tested.
- **Full**: defaults to both required hosts, includes the five known baseline regressions on each, and runs Targeted components. It also records remaining manual/future coverage as NotRun. This presently fails on the known application defects; full-harness execution is not completed release acceptance.
- **Manual**: creates an unfilled checklist for Explorer, real cancellation, playback, paths and benchmarks. It performs no manual checks and returns incomplete; an agent must not mark those checks passed from mocks.

Quick/Targeted exclude KnownDefect cases with visible NotRun records. Add `-IncludeKnownDefects` to run them explicitly. Fix tasks should move repaired regressions into normal coverage. Original focused `tests/Invoke-Characterization.ps1` remains available with its `-KnownDefects` switch.

Choose `-Hosts Current`, `WindowsPowerShell`, or `PowerShell7`; Full's default is both named hosts. Executable overrides are `-WindowsPowerShell` and `-PowerShell7`. The harness verifies each host's actual version/edition before assigning its label. An explicit missing override is unavailable, rather than a request to fall back silently to PATH.

## Reports and exit codes

`-ReportPath` selects a new report file; existing reports are never overwritten. Without it, the harness prints the location of a unique JSON report in temp. Reports use a stable schema and sorted case IDs, contain source SHA/dirty state, observed host/tool versions and real counts, and omit absolute fixture/module paths. They do not include elapsed-time or random fixture-root fields. Fixture recipes use relative files/output placeholders.

- **0**: selected Quick/Targeted checks succeeded; any excluded/skipped work stays visible as `PassedWithOmissions`.
- **1**: executed automated failure, native execution/report error, schema mismatch or cleanup failure.
- **2**: incomplete required prerequisites, no executed suite, or incomplete Full/Manual coverage.

Failed child execution, missing/corrupt/duplicate/count-mismatched reports and all-skipped required suites cannot become passing results. Pester tests exercise actual one-pass/one-fail/one-skip and all-skipped subprocess suites. Entry smoke publishes each case independently, preserving earlier observations when a later case fails.

Raw diagnostics are local to the owned temporary root and retained on failure; never commit them. Reports and dependencies under `.test-results/` and `.test-modules/` are ignored, but temporary roots are preferred. Review/sanitize evidence before sharing. Report counts include actual static/fixture checks as well as individual Pester cases; they are not exclusively application test counts.

## Fixtures and safety

See [fixture inventory](fixtures/inventory.json) and [fixture notes](fixtures/README.md). Media uses one-second lavfi signals and explicit maps/codecs; FFprobe checks structural properties and bounded finite duration. These checks do not prove full visual/audio integrity or playback.

Owned roots have unique names/tokens/markers under temp. Creation refuses reused fixture directories. Cleanup validates the absolute path, temp containment, ownership and absence of reparse points before recursive removal. Neighbors/source/final sentinels are preserved in tests. Native timeouts stop only the owned process tree using a PowerShell 5.1-compatible Windows fallback. Failed termination retains fixture roots.

The native entry recorder is compiled under Windows PowerShell 5.1 outside Git; it generates no media. PS1 -File and BAT use a two-video synthetic folder because single selections still have the baseline Count defect. The original launcher's -NoExit is closed through controlled stdin. This is not Explorer drag/drop or comprehensive launcher argv acceptance.

## Line endings and encoding

`.gitattributes` preserves existing application PS1/BAT bytes using `-text`; both remain unchanged in M0-03. Preserve CRLF on any later BAT change. New `tests/**`, `tools/test*.ps1` and PSD1 developer files check out with CRLF. New PS1 files must be ASCII or UTF-8 **with BOM** so Windows PowerShell 5.1 reads Unicode correctly; Git does not manage the BOM. The quick gate enforces this policy without rewriting the legacy application.

JSON reports are UTF-8 without BOM, and fixture JSON is ASCII-compatible UTF-8. Use explicit UTF-8 when introducing Unicode data. Review staged whitespace using `git -c core.whitespace=cr-at-eol diff --cached --check`. PSScriptAnalyzerSettings.psd1 gates error-severity diagnostics; legacy warning/style debt is recorded, not hidden by source rewrites.
