# Developer-only helpers. No application startup or dependency installation.
Set-StrictMode -Version Latest

function Write-WvcTestJson([string]$Path, $Value) {
    $json = $Value | ConvertTo-Json -Depth 30
    $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes($json + "`n")
    $stream = [IO.File]::Open($Path, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
}

function New-WvcTestRoot {
    $token = [guid]::NewGuid().ToString('N')
    $temporary = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    $root = [IO.Path]::GetFullPath((Join-Path $temporary ('wvc-tests-' + $token)))
    if (-not $root.StartsWith($temporary, [StringComparison]::OrdinalIgnoreCase)) { throw 'Test root escapes temp.' }
    [void][IO.Directory]::CreateDirectory($root)
    [IO.File]::WriteAllText((Join-Path $root '.wvc-owner'), $token)
    [pscustomobject]@{ Path = $root; Token = $token }
}

function Assert-WvcTestRoot($Owner) {
    $temporary = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    $resolved = [IO.Path]::GetFullPath($Owner.Path)
    if (-not $resolved.StartsWith($temporary, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($resolved) -ne ('wvc-tests-' + $Owner.Token) -or
        $Owner.Token -notmatch '^[a-f0-9]{32}$') { throw 'Unowned/out-of-root test directory.' }
    if (-not (Test-Path -LiteralPath $resolved -PathType Container) -or
        [IO.File]::ReadAllText((Join-Path $resolved '.wvc-owner')) -ne $Owner.Token) { throw 'Test ownership marker mismatch.' }
    # Inspect one level at a time; never recurse into a reparse point.
    $pending = New-Object 'Collections.Generic.Stack[string]'
    $pending.Push($resolved)
    while ($pending.Count) {
        $directory = $pending.Pop()
        $items = @((Get-Item -LiteralPath $directory -Force)) + @(Get-ChildItem -LiteralPath $directory -Force)
        foreach ($item in $items) {
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse point in owned test tree.' }
            if ($item.PSIsContainer -and $item.FullName -ne $directory) { $pending.Push($item.FullName) }
        }
    }
    $resolved
}

function Remove-WvcTestRoot($Owner) {
    if (Get-Variable WvcProcessCleanupFailed -Scope Script -ErrorAction SilentlyContinue) {
        throw 'Process cleanup failed; retain owned test roots.'
    }
    $resolved = Assert-WvcTestRoot $Owner
    Remove-Item -LiteralPath $resolved -Recurse -Force
}

function ConvertTo-WvcNativeArgument([string]$Value) {
    # Windows CRT quoting; ProcessStartInfo.Arguments also works on PS5.1.
    '"' + ([regex]::Replace([regex]::Replace($Value, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1')) + '"'
}

function Invoke-WvcTestProcess([string]$Executable, [string[]]$Arguments,
    [int]$TimeoutMilliseconds = 60000, [hashtable]$Environment = @{}) {
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $Executable
    $start.Arguments = ($Arguments | ForEach-Object { ConvertTo-WvcNativeArgument $_ }) -join ' '
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    # Let each PowerShell host rebuild its own compatible built-in module paths.
    # Cross-version inherited PSModulePath can hide Windows PowerShell cmdlets.
    $start.EnvironmentVariables.Remove('PSModulePath')
    foreach ($key in $Environment.Keys) { $start.EnvironmentVariables[$key] = $Environment[$key] }
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $start
    $started = $false
    try {
        [void]$process.Start()
        $started = $true
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutMilliseconds)) { throw 'Owned test process timed out.' }
        [pscustomobject]@{ ExitCode = $process.ExitCode; StdOut = $stdout.Result; StdErr = $stderr.Result }
    } finally {
        try {
            if ($started -and -not $process.HasExited) {
                & (Join-Path $env:SystemRoot 'System32/taskkill.exe') /PID $process.Id /T /F | Out-Null
                if ($LASTEXITCODE -ne 0 -or -not $process.WaitForExit(5000)) {
                    $script:WvcProcessCleanupFailed = $true
                    throw 'Owned process tree termination failed; retain its fixture directory.'
                }
            }
        } catch {
            $script:WvcProcessCleanupFailed = $true
            throw
        } finally { $process.Dispose() }
    }
}

function Resolve-WvcTestExecutable([string]$Candidate, [string]$DefaultName) {
    if ($Candidate) {
        if (Test-Path -LiteralPath $Candidate -PathType Leaf) { return (Resolve-Path -LiteralPath $Candidate).Path }
        return $null
    }
    $command = Get-Command $DefaultName -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) { return $command.Source }
    return $null
}

function Get-WvcHostInfo([string]$Executable, [string]$ExpectedHost) {
    if (-not $Executable) { return $null }
    $version = Invoke-WvcTestProcess $Executable @('-NoProfile','-NonInteractive','-Command',
        '[pscustomobject]@{Version=$PSVersionTable.PSVersion.ToString();Edition=$PSVersionTable.PSEdition}|ConvertTo-Json')
    if ($version.ExitCode -ne 0) { throw 'Host version query failed.' }
    $info = $version.StdOut | ConvertFrom-Json
    $parsed = [version]$info.Version
    $supported = ($parsed.Major -eq 5 -and $parsed.Minor -eq 1 -and $info.Edition -eq 'Desktop') -or
        ($parsed.Major -eq 7 -and $parsed -ge [version]'7.4' -and $info.Edition -eq 'Core')
    if (-not $supported -or ($ExpectedHost -eq 'WindowsPowerShell' -and $parsed.Major -ne 5) -or
        ($ExpectedHost -eq 'PowerShell7' -and $parsed.Major -ne 7)) { return $null }
    [pscustomobject]@{ Version = $info.Version; Edition = $info.Edition; Executable = $Executable }
}

function New-WvcTestCase([string]$Id, [string]$Status, [string]$Reason = '') {
    if ($Status -notin @('Passed','Failed','Skipped','NotRun')) { throw 'Unknown test case status.' }
    [pscustomobject][ordered]@{ Id = $Id; Status = $Status; Reason = $Reason }
}

function Get-WvcPesterTestPaths([string]$Root) {
    @(Get-ChildItem -LiteralPath $Root -Filter '*.Tests.ps1' -File -Recurse |
        Sort-Object FullName | Select-Object -ExpandProperty FullName)
}

function Get-WvcTierSummary([string]$Tier, [object[]]$Cases) {
    $counts = [ordered]@{}
    foreach ($state in @('Passed','Failed','Skipped','NotRun')) {
        $counts[$state] = @($Cases | Where-Object Status -eq $state).Count
    }
    $exitCode = 0
    $status = 'Passed'
    if ($counts.Failed) { $status = 'Failed'; $exitCode = 1 }
    elseif (-not $counts.Passed -or ($Tier -in @('Full','Manual') -and ($counts.Skipped -or $counts.NotRun))) {
        $status = 'Incomplete'; $exitCode = 2
    } elseif ($counts.Skipped -or $counts.NotRun) { $status = 'PassedWithOmissions' }
    [pscustomobject]@{ Status = $status; ExitCode = $exitCode; Counts = [pscustomobject]$counts }
}

function Read-WvcChildReport([string]$Path, [int]$ExitCode) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Child process produced no report.' }
    $report = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ($report.SchemaVersion -ne 1 -or -not $report.PSObject.Properties['Cases'] -or
        -not $report.PSObject.Properties['Counts']) { throw 'Child report schema is invalid.' }
    $cases = @($report.Cases)
    if (-not $cases.Count) { throw 'Child report contains no test cases.' }
    if (@($cases.Id | Select-Object -Unique).Count -ne $cases.Count) { throw 'Duplicate child test case IDs.' }
    foreach ($case in $cases) {
        if (-not $case.Id -or $case.Status -notin @('Passed','Failed','Skipped','NotRun')) { throw 'Child case is invalid.' }
    }
    $actual = (Get-WvcTierSummary 'Quick' $cases).Counts
    foreach ($state in @('Passed','Failed','Skipped','NotRun')) {
        if ($report.Counts.$state -ne $actual.$state) { throw 'Child report count mismatch.' }
    }
    if ($ExitCode -ne 0 -and -not $actual.Failed -and
        -not ($ExitCode -eq 2 -and $actual.Passed -eq 0)) { throw 'Nonzero child exit without reported failure.' }
    if ($ExitCode -eq 0 -and $actual.Failed) { throw 'Failed child tests returned zero.' }
    $report
}
