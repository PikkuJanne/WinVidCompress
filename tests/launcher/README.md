# Launcher round trips (WVC-M1-02)

`Launcher.Tests.ps1` runs automatically in Quick/Targeted on both supported hosts.
The BAT always starts Windows PowerShell 5.1; the direct PS1 recorder also runs on
the selected test host. An isolated byte-identical BAT sits next to the dedicated
`Record-Arguments.ps1`, whose parameter declaration matches production. It reports
both native argv entering the real host and the bound `Path` array, as UTF-8/base64.
No synthetic filename is executed and no encoder or real user config is used.

Tests cover no arguments, one file, folder and ordered multiple selections, spaces,
`!`, `&`, parentheses, apostrophes, brackets, `%`, Finnish/German/CJK names, literal
`%PATH%` and `!NAME!` with matching variables, and the launcher's own special-character
directory. CMD receives benign paths through fixed environment slots expanded once.
This distinguishes forwarding inside BAT from expansion in its caller. Seven error
checks cover absent PS1/PowerShell, unusable host, missing FFmpeg/FFprobe, directory
masquerading as an executable and a real read-denied file. ACL changes affect only an
owned synthetic file and are restored in `finally`; tests create no real media.

## Shell and length limits

The launcher disables delayed expansion, forwards `%*` once, and retains `-NoExit`
and the existing process-only `-ExecutionPolicy Bypass`. It does not change persistent
execution policy. No `CALL`, expression evaluation or reconstructed argument string
is used in production.

Caller interpretation occurs before `powershell.exe -File`. A raw `%PATH%` in a CMD
command expands before BAT starts; a caller with `/V:ON` can similarly expand
`!NAME!`. BAT cannot recover already-changed arguments. This is measured as a
limitation, not a passing literal-percent round trip. For these names, use the real
menu's literal-path prompt or invoke PS1 from PowerShell with single-quoted paths.
Actual Explorer drops still require separate observation and may expose the same
outer-shell limitation. Do not mark A01/A02 passed from these automated tests.

In a CMD/BAT command, omit a quoted folder's trailing backslash. Use `D:\.` for a
drive root, or paste `D:\` into the menu. The recorder demonstrates that a closing
quote following a single backslash can arrive as a literal quote in native argv.
Explorer's folder spelling must be observed separately.

CMD/batch processing has an **8,191-character** limit, including expanded paths,
quotes and launcher text. There is no unlimited multiple-file drop guarantee;
drop a folder or select smaller batches. Shell limits can be lower than native
Windows process limits. Windows filenames also cannot contain `<>:"/\|?*`, although
path separators and drive colons naturally appear in full paths.

Primary references: [Microsoft CMD limits](https://learn.microsoft.com/en-us/troubleshoot/windows-client/shell-experience/command-line-string-limitation),
[Windows PowerShell CLI](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_exe?view=powershell-5.1),
[setlocal](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/setlocal).

## Actual Explorer checks

Prepare an owned temporary kit with:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/launcher/New-LauncherManualFixture.ps1
```

Follow the returned `Instructions.txt`. This records preparation only, never a
manual pass. The argument launcher copies the actual BAT bytes and substitutes
the test recorder PS1. Error checks use production PS1/BAT copies. A small preparation
wrapper sets only per-process APPDATA/PATH/NAME and directly forwards arguments
without `CALL`. Its extra shell layer remains explicit in evidence.

Keep returned metadata/reports outside Git. Run `Test-LauncherManualReports.ps1`
against the returned manifest after performing Explorer drops; it checks exact
arguments and copied BAT hashes, but cannot establish that Explorer was used.
Record the human observer, steps, date, actual errors and console behavior too.
Close all fixture shells before calling `Remove-LauncherManualFixture.ps1`.
