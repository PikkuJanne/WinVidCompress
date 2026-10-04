# M0-02 characterization

These focused tests characterize the current application before its fix tasks.
Dot-source `WinVidCompress.ps1` to load helpers/defaults without application startup.
Execute it normally (including through the unchanged BAT) to retain the original flow.

Developer dependencies for this slice: Pester **5.7.1** and PSScriptAnalyzer **1.24.0**,
checked against the [Pester package](https://www.powershellgallery.com/packages/Pester/5.7.1)
and [analyzer release](https://github.com/PowerShell/PSScriptAnalyzer/releases/tag/1.24.0).
They are test dependencies, outside the repository and application runtime. The runner
never installs or downloads them. Full tier/setup/fixture policy belongs to WVC-M0-03.

If necessary, explicitly prepare an external developer module directory:

```powershell
Save-Module -Name Pester -RequiredVersion 5.7.1 -Path $moduleRoot
Save-Module -Name PSScriptAnalyzer -RequiredVersion 1.24.0 -Path $moduleRoot
```

Run in separate Windows PowerShell 5.1 and PowerShell 7 processes from the repo root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Invoke-Characterization.ps1 -ModuleRoot $moduleRoot
pwsh -NoProfile -ExecutionPolicy Bypass -File tests/Invoke-Characterization.ps1 -ModuleRoot $moduleRoot
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Invoke-Characterization.ps1 -ModuleRoot $moduleRoot -KnownDefects
pwsh -NoProfile -ExecutionPolicy Bypass -File tests/Invoke-Characterization.ps1 -ModuleRoot $moduleRoot -KnownDefects
powershell -NoProfile -ExecutionPolicy Bypass -File tests/Invoke-EntrySmoke.ps1 -PowerShell7 (Get-Command pwsh).Source
```

The first two runs select the passing characterization checks. The next two select
five desired-behavior regressions tagged `KnownDefect`: Quit, wrong-shaped config,
empty folder, single-video folder and explicit single file. They currently **fail**,
return exit 1 and remain separate from passing application results. When a fix lands,
move its regression into the normal run. A known-defect run unexpectedly passing is
a cue to review the baseline, not proof that all remaining fixes are complete.

Pester uses fixture-local APPDATA, inputs, output and config inside TestDrive. The real
TUI is never invoked; menu control flow is reproduced with the actual extracted switch
inside a bounded synthetic loop. Encoder/probe behavior is mocked. Sentinels confirm
source and existing final files remain unchanged under these doubles.

The entry smoke harness must run under Windows PowerShell 5.1 so Add-Type can build
a small .NET Framework console recorder in its owned temporary directory. That
recorder stands in for both native tools and writes no media. The harness exercises
actual `-File` invocations on both hosts and the original BAT using a two-video folder,
with isolated config/PATH and controlled stdin for the launcher's `-NoExit`. It checks
captured paths, counters and source hashes, then removes only its contained fixture.
A 15-second timeout stops only its owned process tree; failed termination retains
the fixture. It does not exercise Explorer drag/drop or full special-character argv.

Process-local `-ExecutionPolicy Bypass` matches the existing launcher; tests do not
change persistent execution policy. No real FFmpeg/FFprobe or private media is needed.
Argument construction and entry dispatch do not prove encoded media quality or integrity.

For targeted static analysis, explicitly import the pinned analyzer and invoke
`Invoke-ScriptAnalyzer -Path <changed.ps1> -Severity Error` for the application/tests.
Record legacy warning debt separately instead of reformatting the whole application.
The existing application has CRLF lines; use `git -c core.whitespace=cr-at-eol diff --check`
to check whitespace while preserving them. M0-03 will establish the repository policy.
