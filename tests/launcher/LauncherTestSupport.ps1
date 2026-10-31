Set-StrictMode -Version Latest
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')

function Write-WvcMissingToolApplication([string]$Application, [string]$Destination) {
    # Negative discovery fixtures must not fall back to an owner's persisted tools.
    # Only this copied test application's scoped reader is replaced. Packaged
    # integration proof always runs the unmodified application and real scopes.
    $text = [IO.File]::ReadAllText($Application)
    $tokens = $null; $errors = $null
    $ast = [Management.Automation.Language.Parser]::ParseInput($text,[ref]$tokens,[ref]$errors)
    if ($errors.Count) { throw 'Cannot prepare a malformed application fixture.' }
    $readers = @($ast.FindAll({ param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -eq 'Get-ToolEnvironmentVariable'
    },$true))
    if ($readers.Count -ne 1) { throw 'Missing-tool fixture requires exactly one scoped environment reader.' }
    $replacement = @'
function Get-ToolEnvironmentVariable([string]$Name, [string]$Scope) {
    # MODIFIED TEST FIXTURE: hide Process/User/Machine hint values, without writes.
    return $null
}
'@
    $reader = $readers[0].Extent
    $text = $text.Substring(0,$reader.StartOffset)+$replacement+$text.Substring($reader.EndOffset)
    if (Test-Path -LiteralPath $Destination) { throw 'Missing-tool fixture destination must be new.' }
    [IO.File]::WriteAllText($Destination,$text,(New-Object Text.UTF8Encoding($true)))
}

function Invoke-WvcLauncherProcess([string]$Executable, [string]$Arguments,
    [hashtable]$Environment = @{}, [string]$InputText = '') {
    # Arguments is an observed Windows command line, not a shell-built program.
    # Batch test paths enter via fixed environment slots, expanded once by cmd.
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $Executable
    $start.Arguments = $Arguments
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $start.RedirectStandardInput = $true
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
        if ($InputText) { $process.StandardInput.Write($InputText) }
        $process.StandardInput.Close()
        if (-not $process.WaitForExit(15000)) { throw 'Owned launcher test process timed out.' }
        [pscustomobject]@{ ExitCode = $process.ExitCode; StdOut = $stdout.Result; StdErr = $stderr.Result }
    } finally {
        try {
            if ($started -and -not $process.HasExited) {
                & (Join-Path $env:SystemRoot 'System32/taskkill.exe') /PID $process.Id /T /F | Out-Null
                if ($LASTEXITCODE -ne 0 -or -not $process.WaitForExit(5000)) {
                    $script:WvcProcessCleanupFailed = $true
                    throw 'Owned launcher process cleanup failed; retain fixtures.'
                }
            }
        } finally { $process.Dispose() }
    }
}

function Read-WvcArgumentRecord($Result) {
    $lines = @($Result.StdOut -split '\r?\n' | Where-Object { $_.StartsWith('WVC_ARGV:') })
    if ($Result.ExitCode -ne 0 -or $Result.StdErr -or $lines.Count -ne 1) {
        throw "Argument recorder failed: exit $($Result.ExitCode); $($Result.StdErr); $($Result.StdOut)"
    }
    [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($lines[0].Substring(9))) | ConvertFrom-Json
}
