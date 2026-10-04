[CmdletBinding()]
param(
    [string]$PowerShell7,
    [string]$ReportPath
)

# Run this fixture compiler under Windows PowerShell 5.1 (.NET Framework).
# The generated console executable is a recorder, not an encoder or downloaded tool.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'TestSupport.ps1')
if ($PowerShell7 -and -not (Get-WvcHostInfo $PowerShell7 'PowerShell7')) { $PowerShell7 = $null }
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Run this smoke harness with Windows PowerShell 5.1.' }
$repoRoot = Split-Path -Parent $PSScriptRoot
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('wvc-entry-' + [guid]::NewGuid().ToString('N'))
$temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
if (-not [IO.Path]::GetFullPath($fixtureRoot).StartsWith($temporaryRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Fixture root is outside the temporary directory.'
}

function Invoke-SmokeProcess([string]$Executable, [string]$Arguments) {
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $Executable
    $start.Arguments = $Arguments
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.RedirectStandardInput = $true
    $start.EnvironmentVariables['APPDATA'] = $appData
    $start.EnvironmentVariables['PATH'] = $bin + ';' + $env:PATH
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $start
    $started = $false
    try {
        [void]$process.Start()
        $started = $true
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        # The unchanged BAT uses -NoExit. Close its isolated shell through stdin.
        $process.StandardInput.WriteLine('exit')
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(15000)) {
            throw 'Owned entry smoke process exceeded 15 seconds.'
        }
        $output = $stdout.Result
        $errors = $stderr.Result
        if ($process.ExitCode -ne 0 -or $errors) { throw "Entry smoke failed: exit $($process.ExitCode); $errors" }
        if ($output -notmatch 'WVC_NATIVE_RECORDER' -or $output -notmatch 'Done:\s+2' -or $output -notmatch 'Failed:\s+0') {
            throw "Entry smoke did not reach existing folder processing: $output"
        }
        $captured = @($output -split '\r?\n' | Where-Object { $_.StartsWith('WVC_ARG:') } | ForEach-Object {
            [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_.Substring(8)))
        })
        foreach ($expectedArgument in @($source,$sourceTwo,$expectedOutput,$expectedOutputTwo)) {
            if ($captured -notcontains $expectedArgument) { throw 'Native recorder did not receive the expected source/output paths.' }
        }
        if ((Test-Path -LiteralPath $expectedOutput) -or (Test-Path -LiteralPath $expectedOutputTwo)) {
            throw 'Recorder unexpectedly created a media output.'
        }
        if ((Get-FileHash -LiteralPath $source).Hash -ne $sourceHash -or
            (Get-FileHash -LiteralPath $sourceTwo).Hash -ne $sourceHashTwo) { throw 'Synthetic source changed.' }
        [pscustomobject]@{ Executable = [IO.Path]::GetFileName($Executable); ExitCode = $process.ExitCode; NativeArguments = $captured.Count; Passed = $true }
    } finally {
        try {
            if ($started -and -not $process.HasExited) {
                # PS5.1 has no Kill(entireProcessTree) overload. Limit taskkill to
                # this owned process/children, including errors before WaitForExit.
                $script:KeepFixture = $true
                & (Join-Path $env:SystemRoot 'System32/taskkill.exe') /PID $process.Id /T /F | Out-Null
                if ($LASTEXITCODE -ne 0 -or -not $process.WaitForExit(5000)) {
                    $script:KeepFixture = $true
                    throw 'Could not stop the owned smoke process tree; fixture retained.'
                }
                Remove-Variable KeepFixture -Scope Script
            }
        } catch {
            $script:KeepFixture = $true
            throw
        } finally {
            $process.Dispose()
        }
    }
}

try {
    $bin = Join-Path $fixtureRoot 'bin'
    $appData = Join-Path $fixtureRoot 'appdata'
    $configDir = Join-Path $appData 'WinVidCompress'
    $outputRoot = Join-Path $fixtureRoot 'output'
    $inputRoot = Join-Path $fixtureRoot 'input'
    New-Item -ItemType Directory -Path $bin,$configDir,$outputRoot,$inputRoot | Out-Null
    $source = Join-Path $inputRoot 'Band Name 29092025.mov'
    $sourceTwo = Join-Path $inputRoot 'Other Band 29092025.mov'
    Set-Content -LiteralPath $source -Value 'synthetic source sentinel'
    Set-Content -LiteralPath $sourceTwo -Value 'synthetic second source sentinel'
    $sourceHash = (Get-FileHash -LiteralPath $source).Hash
    $sourceHashTwo = (Get-FileHash -LiteralPath $sourceTwo).Hash
    $expectedOutput = Join-Path $outputRoot 'Band Name 29092025.mp4'
    $expectedOutputTwo = Join-Path $outputRoot 'Other Band 29092025.mp4'
    [pscustomobject]@{ OutputDir = $outputRoot } | ConvertTo-Json |
        Set-Content -LiteralPath (Join-Path $configDir 'config.json') -Encoding UTF8

    $recorderCode = @'
using System;
using System.IO;
using System.Text;
public static class WvcEntryRecorder {
    public static int Main(string[] args) {
        if (Path.GetFileName(Environment.GetCommandLineArgs()[0]).Equals("ffprobe.exe", StringComparison.OrdinalIgnoreCase)) {
            Console.WriteLine("720");
        } else {
            Console.WriteLine("WVC_NATIVE_RECORDER");
            foreach (string arg in args) Console.WriteLine("WVC_ARG:" + Convert.ToBase64String(Encoding.UTF8.GetBytes(arg)));
        }
        return 0;
    }
}
'@
    Add-Type -TypeDefinition $recorderCode -OutputAssembly (Join-Path $bin 'ffmpeg.exe') -OutputType ConsoleApplication
    Copy-Item -LiteralPath (Join-Path $bin 'ffmpeg.exe') -Destination (Join-Path $bin 'ffprobe.exe')

    $application = Join-Path $repoRoot 'WinVidCompress.ps1'
    $launcher = Join-Path $repoRoot 'WinVidCompress.bat'
    $directArguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $application + '" "' + $inputRoot + '"'
    $windowsPowerShell = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $definitions = @(
        @{ Id = 'direct-ps51'; Executable = $windowsPowerShell; Arguments = $directArguments },
        @{ Id = 'direct-ps7'; Executable = $PowerShell7; Arguments = $directArguments },
        @{ Id = 'original-bat'; Executable = $env:ComSpec; Arguments = ('/d /s /c ""' + $launcher + '" "' + $inputRoot + '""') }
    )
    $cases = @()
    foreach ($definition in $definitions) {
        if (-not $definition.Executable -or -not (Test-Path -LiteralPath $definition.Executable -PathType Leaf)) {
            $cases += New-WvcTestCase $definition.Id 'Skipped' 'Required executable unavailable; entry not tested.'
            continue
        }
        try {
            $observation = Invoke-SmokeProcess $definition.Executable $definition.Arguments
            $case = New-WvcTestCase $definition.Id 'Passed'
            $case | Add-Member NoteProperty NativeArguments $observation.NativeArguments
            $cases += $case
        } catch {
            $cases += New-WvcTestCase $definition.Id 'Failed' 'Entry smoke failed; see local diagnostics.'
            [IO.File]::WriteAllText((Join-Path $fixtureRoot ($definition.Id + '.error.log')), $_.ToString())
            $script:KeepFixture = $true
        }
    }
    $summary = Get-WvcTierSummary 'Targeted' $cases
    $report = [pscustomobject][ordered]@{ SchemaVersion = 1; Kind = 'EntrySmoke'; Counts = $summary.Counts; Cases = $cases }
    if ($ReportPath) { Write-WvcTestJson $ReportPath $report }
    $report | ConvertTo-Json -Depth 6
} finally {
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureRoot)
    if (-not (Get-Variable KeepFixture -Scope Script -ErrorAction SilentlyContinue) -and
        $resolvedFixture.StartsWith($temporaryRoot, [StringComparison]::OrdinalIgnoreCase) -and
        [IO.Path]::GetFileName($resolvedFixture) -match '^wvc-entry-[a-f0-9]{32}$' -and
        (Test-Path -LiteralPath $resolvedFixture)) {
        Remove-Item -LiteralPath $resolvedFixture -Recurse -Force
    }
}
exit $summary.ExitCode
