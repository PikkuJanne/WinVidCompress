[CmdletBinding()]
param(
    [ValidateSet('Quick','Targeted','Full','Manual')][string]$Tier = 'Quick',
    [string]$ModuleRoot,
    [ValidateSet('Current','WindowsPowerShell','PowerShell7')][string[]]$Hosts,
    [string]$WindowsPowerShell,
    [string]$PowerShell7,
    [string]$FFmpeg,
    [string]$FFprobe,
    [string]$ReportPath,
    [switch]$IncludeKnownDefects
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$testsRoot = Join-Path $repoRoot 'tests'
. (Join-Path $testsRoot 'TestSupport.ps1')
. (Join-Path $testsRoot 'New-Fixtures.ps1')
$pins = Import-PowerShellDataFile (Join-Path $testsRoot 'Dependencies.psd1')
$owner = New-WvcTestRoot
$cases = @()
$hostObservations = @()
$toolObservations = @()
$fixtureInventory = $null
$requiredHostMissing = $false
$fatalFailure = $false
$includeBaseline = $IncludeKnownDefects -or $Tier -eq 'Full'
$manualIds = @('explorer-menu-quit','explorer-file-folder-multi-drop','explorer-special-character-argv',
    'real-ctrl-c-and-console-close','playback-sdr-hdr-audio','unc-long-paths','representative-benchmarks')
if (-not $ReportPath) { $ReportPath = Join-Path ([IO.Path]::GetTempPath()) ('wvc-report-' + $owner.Token + '.json') }
try {
    if ($Tier -eq 'Manual') {
        $cases = @($manualIds | ForEach-Object { New-WvcTestCase ('manual/' + $_) 'NotRun' 'Requires actual human Windows execution/evidence.' })
    } else {
        if (-not $Hosts) { if ($Tier -eq 'Full') { $Hosts = @('WindowsPowerShell','PowerShell7') } else { $Hosts = @('Current') } }
        $ps51 = Resolve-WvcTestExecutable $WindowsPowerShell 'powershell.exe'
        $ps7 = Resolve-WvcTestExecutable $PowerShell7 'pwsh.exe'
        if ($ps51 -and -not (Get-WvcHostInfo $ps51 'WindowsPowerShell')) { $ps51 = $null }
        if ($ps7 -and -not (Get-WvcHostInfo $ps7 'PowerShell7')) { $ps7 = $null }
        foreach ($hostName in $Hosts) {
            $executable = $null
            switch ($hostName) {
                'Current' { $executable = (Get-Process -Id $PID).Path }
                'WindowsPowerShell' { $executable = $ps51 }
                'PowerShell7' { $executable = $ps7 }
            }
            $pesterPath = $null
            if ($ModuleRoot) { $pesterPath = Join-Path $ModuleRoot ('Pester/' + $pins.Pester + '/Pester.psd1') }
            if (-not $executable -or -not $pesterPath -or -not (Test-Path -LiteralPath $pesterPath -PathType Leaf)) {
                $cases += New-WvcTestCase ($hostName + '/pester') 'Skipped' 'Required host or pinned Pester unavailable; unit suite not tested.'
                $requiredHostMissing = $true
                continue
            }
            try {
                $hostVersion = Get-WvcHostInfo $executable $hostName
                if (-not $hostVersion) {
                    $cases += New-WvcTestCase ($hostName + '/pester') 'Skipped' 'Unsupported requested host version; unit suite not tested.'
                    $requiredHostMissing = $true
                    continue
                }
                $hostObservations += [pscustomobject]@{ Name = $hostName; Version = $hostVersion.Version; Edition = $hostVersion.Edition }
                $selected = @(Get-WvcPesterTestPaths $testsRoot)
                if (-not $selected.Count) { throw 'No Pester test files discovered.' }
                $childPath = Join-Path $owner.Path ($hostName + '.pester.json')
                $arguments = @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
                    (Join-Path $testsRoot 'Invoke-PesterRun.ps1'),'-ModuleRoot',$ModuleRoot,
                    '-TestPath',($selected -join '|'),'-ReportPath',$childPath)
                if ($includeBaseline) { $arguments += '-IncludeKnownDefects' }
                # M4-01 adds about 75 seconds of PS7 CLI/preview cases. The full
                # PS7 suite exceeded the previous five-minute bound. Keep a
                # seven-minute suite bound; individual fixture limits are unchanged.
                $child = Invoke-WvcTestProcess $executable $arguments -TimeoutMilliseconds 420000 -Environment @{ APPDATA = (Join-Path $owner.Path 'appdata') }
                [IO.File]::WriteAllText((Join-Path $owner.Path ($hostName + '.stdout.log')), $child.StdOut)
                [IO.File]::WriteAllText((Join-Path $owner.Path ($hostName + '.stderr.log')), $child.StdErr)
                $childReport = Read-WvcChildReport $childPath $child.ExitCode
                if ($child.ExitCode -eq 2) { $requiredHostMissing = $true }
                $cases += @($childReport.Cases | ForEach-Object { New-WvcTestCase ($hostName + '/' + $_.Id) $_.Status $_.Reason })
            } catch {
                $cases += New-WvcTestCase ($hostName + '/harness') 'Failed' 'Host/test execution or child report failed; inspect local diagnostics.'
                [IO.File]::WriteAllText((Join-Path $owner.Path ($hostName + '.error.log')), $_.ToString())
            }
        }

        $psFiles = @((Join-Path $repoRoot 'WinVidCompress.ps1')) + @(Get-ChildItem -LiteralPath $testsRoot -Filter '*.ps1' -Recurse |
            Select-Object -ExpandProperty FullName) + @(Get-ChildItem -LiteralPath $PSScriptRoot -File |
            Where-Object { $_.Name -like 'test*.ps1' -or $_.Name -like 'benchmark*.ps1' } |
            Select-Object -ExpandProperty FullName)
        $parseFailures = 0
        foreach ($path in $psFiles) {
            $tokens = $null; $errors = $null
            [void][Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$errors)
            if (@($errors).Count) { $parseFailures++ }
        }
        if ($parseFailures) { $cases += New-WvcTestCase 'static/parse' 'Failed' 'PowerShell parse errors.' }
        else { $cases += New-WvcTestCase 'static/parse' 'Passed' }
        $encodingFailures = 0
        foreach ($path in @($psFiles | Where-Object { $_ -ne (Join-Path $repoRoot 'WinVidCompress.ps1') })) {
            $bytes = [IO.File]::ReadAllBytes($path)
            $hasUnicode = @($bytes | Where-Object { $_ -gt 127 }).Count -gt 0
            $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191
            if ($hasUnicode -and -not $hasBom) { $encodingFailures++ }
        }
        if ($encodingFailures) { $cases += New-WvcTestCase 'static/ps51-encoding' 'Failed' 'New PS1 must be ASCII or UTF-8 with BOM.' }
        else { $cases += New-WvcTestCase 'static/ps51-encoding' 'Passed' }
        $python = Resolve-WvcTestExecutable '' 'python.exe'
        if ($python) {
            $tracker = Invoke-WvcTestProcess $python @('-B',(Join-Path $repoRoot 'tools/codex-winvidcompress/validate_tracker.py'),'--repo',$repoRoot)
            [IO.File]::WriteAllText((Join-Path $owner.Path 'tracker.stdout.log'), $tracker.StdOut)
            [IO.File]::WriteAllText((Join-Path $owner.Path 'tracker.stderr.log'), $tracker.StdErr)
            if ($tracker.ExitCode -ne 0 -or -not ($tracker.StdOut | ConvertFrom-Json).valid) {
                $cases += New-WvcTestCase 'static/tracker' 'Failed' 'Task/evidence schema validation failed.'
            } else { $cases += New-WvcTestCase 'static/tracker' 'Passed' }
        } else {
            $cases += New-WvcTestCase 'static/tracker' 'Skipped' 'Developer Python unavailable; tracker not tested.'
            $requiredHostMissing = $true
        }
        $analyzerPath = $null
        if ($ModuleRoot) { $analyzerPath = Join-Path $ModuleRoot ('PSScriptAnalyzer/' + $pins.PSScriptAnalyzer + '/PSScriptAnalyzer.psd1') }
        if (-not $analyzerPath -or -not (Test-Path -LiteralPath $analyzerPath -PathType Leaf)) {
            $cases += New-WvcTestCase 'static/analyzer' 'Skipped' 'Pinned PSScriptAnalyzer unavailable.'
            $requiredHostMissing = $true
        } else {
            Import-Module $analyzerPath -ErrorAction Stop
            if ((Get-Module PSScriptAnalyzer).Version -ne [version]$pins.PSScriptAnalyzer) { throw 'Unexpected analyzer version.' }
            $diagnostics = @($psFiles | ForEach-Object { Invoke-ScriptAnalyzer -Path $_ -Settings (Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1') })
            if ($diagnostics.Count) {
                $cases += New-WvcTestCase 'static/analyzer' 'Failed' 'Analyzer error diagnostics; inspect local diagnostics.'
                [IO.File]::WriteAllText((Join-Path $owner.Path 'analyzer.log'), ($diagnostics | Out-String))
            } else { $cases += New-WvcTestCase 'static/analyzer' 'Passed' }
        }

        if ($Tier -in @('Targeted','Full')) {
            if ($ps51) {
                try {
                    $entryPath = Join-Path $owner.Path 'entry.json'
                    $arguments = @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
                        (Join-Path $testsRoot 'Invoke-EntrySmoke.ps1'),'-ReportPath',$entryPath)
                    if ($ps7) { $arguments += @('-PowerShell7',$ps7) }
                    $entry = Invoke-WvcTestProcess $ps51 $arguments
                    [IO.File]::WriteAllText((Join-Path $owner.Path 'entry.stdout.log'), $entry.StdOut)
                    [IO.File]::WriteAllText((Join-Path $owner.Path 'entry.stderr.log'), $entry.StdErr)
                    $entryReport = Read-WvcChildReport $entryPath $entry.ExitCode
                    $cases += @($entryReport.Cases | ForEach-Object { New-WvcTestCase ('entry/' + $_.Id) $_.Status $_.Reason })
                } catch { $cases += New-WvcTestCase 'entry/harness' 'Failed' 'Native entry smoke/report failed.' }
            } else {
                $cases += @('direct-ps51','direct-ps7','original-bat') | ForEach-Object {
                    New-WvcTestCase ('entry/' + $_) 'Skipped' 'Windows PowerShell 5.1 compiler host unavailable.'
                }
            }
            $ffmpegExecutable = Resolve-WvcTestExecutable $FFmpeg 'ffmpeg.exe'
            $ffprobeExecutable = Resolve-WvcTestExecutable $FFprobe 'ffprobe.exe'
            foreach ($tool in @(@{ Name = 'FFmpeg'; Path = $ffmpegExecutable },@{ Name = 'FFprobe'; Path = $ffprobeExecutable })) {
                if ($tool.Path) {
                    $version = Invoke-WvcTestProcess $tool.Path @('-version')
                    if ($version.ExitCode -ne 0) { throw 'Available native fixture tool version query failed.' }
                    $toolObservations += [pscustomobject]@{ Name = $tool.Name; Version = ($version.StdOut -split '\r?\n')[0]; Available = $true }
                } else { $toolObservations += [pscustomobject]@{ Name = $tool.Name; Version = $null; Available = $false } }
            }
            $fixtureInventory = New-WvcFixtures $owner $ffmpegExecutable $ffprobeExecutable
            $cases += @($fixtureInventory.Items | ForEach-Object { New-WvcTestCase ('fixture/' + $_.Id) $_.Status $_.Reason })
        }
        if ($Tier -eq 'Full') {
            $cases += @($manualIds | ForEach-Object { New-WvcTestCase ('manual/' + $_) 'NotRun' 'Actual manual acceptance outstanding.' })
            $cases += New-WvcTestCase 'coverage/future-media-cli-safety-packaging' 'NotRun' 'Later task acceptance matrix not implemented; full is not release acceptance.'
        }
    }
} catch {
    $cases += New-WvcTestCase 'harness/fatal' 'Failed' 'Harness error; inspect local diagnostics.'
    [IO.File]::WriteAllText((Join-Path $owner.Path 'fatal.log'), $_.ToString())
    $fatalFailure = $true
}
$sourceCommit = $null
$dirty = $null
try {
    $sourceCommit = (& git -C $repoRoot rev-parse HEAD | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $sourceCommit -notmatch '^[a-f0-9]{40}$') { throw 'Git HEAD query failed.' }
    $gitStatus = @(& git -C $repoRoot status --porcelain=v1 --untracked-files=all)
    if ($LASTEXITCODE -ne 0) { throw 'Git dirty-state query failed.' }
    $dirty = [bool]$gitStatus.Count
} catch {
    $sourceCommit = $null; $dirty = $null
    $cases += New-WvcTestCase 'harness/source-provenance' 'Failed' 'Git source/dirty-state query failed.'
}
$retainDiagnostics = @($cases | Where-Object Status -eq 'Failed').Count -gt 0 -or $fatalFailure
if (-not $retainDiagnostics) {
    try { Remove-WvcTestRoot $owner }
    catch {
        $retainDiagnostics = $true
        $cases += New-WvcTestCase 'harness/cleanup' 'Failed' 'Owned fixture cleanup failed; directory retained.'
    }
}
$summary = Get-WvcTierSummary $Tier $cases
if ($requiredHostMissing -and $summary.ExitCode -eq 0) { $summary.Status = 'Incomplete'; $summary.ExitCode = 2 }
$report = [pscustomobject][ordered]@{
    SchemaVersion = 1; Tier = $Tier; SourceCommit = $sourceCommit; Dirty = $dirty
    Status = $summary.Status; ExitCode = $summary.ExitCode; Counts = $summary.Counts
    KnownDefectsIncluded = [bool]$includeBaseline; ReleaseAcceptance = $false
    Dependencies = [pscustomobject][ordered]@{
        Pester = $pins.Pester; PSScriptAnalyzer = $pins.PSScriptAnalyzer
        WindowsPowerShell = $pins.WindowsPowerShell; PowerShell7Minimum = $pins.PowerShell7Minimum
    }
    Hosts = $hostObservations
    NativeTools = $toolObservations
    Cases = @($cases | Sort-Object Id); Fixtures = $fixtureInventory
    Limitations = @('Synthetic fixtures/structural probes do not establish playback or full visual/audio integrity.',
        'Full includes known baseline failures and outstanding coverage; Manual remains unfilled until human evidence.')
}
Write-WvcTestJson $ReportPath $report
$report | ConvertTo-Json -Depth 30
Write-Host ('Report: ' + [IO.Path]::GetFullPath($ReportPath))
if ($retainDiagnostics) { Write-Host ('Retained owned diagnostics: ' + $owner.Path) }
exit $summary.ExitCode
