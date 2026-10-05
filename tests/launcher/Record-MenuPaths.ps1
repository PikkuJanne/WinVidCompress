[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Test-only literal-path session. Processing is replaced before the real menu runs.
if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot '.wvc-menu-recorder') -PathType Leaf)) {
    throw 'Run only from the prepared owned manual fixture.'
}
$env:APPDATA = Join-Path $PSScriptRoot 'appdata'
$env:PATH = (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0') + ';WVC_PATH_SENTINEL'
$env:NAME = 'WVC_NAME_SENTINEL'
. (Join-Path $PSScriptRoot 'WinVidCompress.ps1')

function Process-Paths([string[]]$paths, [string]$ffmpeg, [string]$ffprobe, $cfg) {
    $record = [pscustomobject]@{
        Kind = 'ManualMenuPath'; Paths = @($paths)
        PowerShell = $PSVersionTable.PSVersion.ToString(); Edition = $PSVersionTable.PSEdition
        MatchingPathVariable = $env:PATH.Contains('WVC_PATH_SENTINEL')
        MatchingNameVariable = $env:NAME -ceq 'WVC_NAME_SENTINEL'
        ApplicationSHA256 = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'WinVidCompress.ps1')).Hash
    }
    $report = Join-Path $PSScriptRoot ('menu-' + [guid]::NewGuid().ToString('N') + '.json')
    $bytes = [Text.Encoding]::UTF8.GetBytes(($record | ConvertTo-Json -Depth 5))
    $stream = [IO.File]::Open($report, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    try { $stream.Write($bytes, 0, $bytes.Length) } finally { $stream.Dispose() }
    Write-Host ('Recorded literal path: ' + [IO.Path]::GetFileName($paths[0]))
}

Set-Location -LiteralPath $PSScriptRoot
Write-Host 'Recorder only; no video processing.'
Write-Host 'Choose 2, then paste: literal %PATH% !NAME!.mov'
Write-Host 'Choose 3, then paste: Folder %PATH% !NAME!'
Write-Host 'Choose 4 to finish, then type exit.'
$cfg = [pscustomobject]@{ OutputDir = (Join-Path $PSScriptRoot 'output') }
Run-TUI 'unused-encoder' 'unused-probe' $cfg

# Supplemental automated call through the real PowerShell native call operator.
# It is not a second human Explorer action or a production encoder invocation.
$directRecorder = Join-Path (Split-Path -Parent $PSScriptRoot) 'Direct PS1/WinVidCompress.ps1'
$directFile = Join-Path $PSScriptRoot 'literal %PATH% !NAME!.mov'
$directFolder = Join-Path $PSScriptRoot 'Folder %PATH% !NAME!'
$env:WVC_ARGV_AUTOMATED = '1'
$env:WVC_ARGV_REPORT = ''
try {
    $directOutput = @(& (Get-Process -Id $PID).Path -NoProfile -ExecutionPolicy Bypass -File $directRecorder $directFile $directFolder)
    if ($LASTEXITCODE -ne 0) { throw 'Direct PowerShell recorder failed.' }
    $lines = @($directOutput | Where-Object { $_.StartsWith('WVC_ARGV:') })
    if ($lines.Count -ne 1) { throw 'Direct PowerShell recorder did not return one record.' }
    $directRecord = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($lines[0].Substring(9))) | ConvertFrom-Json
    if (@($directRecord.Paths).Count -ne 2 -or $directRecord.Paths[0] -cne $directFile -or $directRecord.Paths[1] -cne $directFolder) {
        throw 'Direct PowerShell changed a literal path. Preserve reports and report the error.'
    }
    Write-Host 'Direct PowerShell literal paths preserved.'
} finally {
    $env:WVC_ARGV_AUTOMATED = ''
    $env:WVC_ARGV_REPORT = ''
}
