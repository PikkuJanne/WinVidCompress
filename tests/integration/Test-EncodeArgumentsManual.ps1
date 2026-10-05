param([Parameter(Mandatory=$true)][string]$ReportPath)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
$owner = New-WvcTestRoot
$originalAppData = $env:APPDATA
$originalName = $env:NAME
$originalPath = $env:PATH
$cases = @()
try {
    $env:APPDATA = Join-Path $owner.Path 'appdata'
    . (Join-Path $repoRoot 'WinVidCompress.ps1')
    $env:NAME = 'EXPANSION MUST NOT OCCUR'
    $encoder = Join-Path $owner.Path 'encoder & (literal) [x].exe'
    $ps51 = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $compiled = Invoke-WvcTestProcess $ps51 @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
        (Join-Path $PSScriptRoot 'New-EncodeProcessFixture.ps1'),'-Destination',$encoder)
    if ($compiled.ExitCode -ne 0) { throw ('Native fixture compilation failed: ' + $compiled.StdErr) }
    $unicode = ([char]0x00E4).ToString() + [char]0x00F6 + [char]0x00FC + [char]0x4E2D
    $names = @("Band & (A) [x] !NAME! 25% O'Brien $unicode 29092025.mov",
        "Band %PATH% !NAME! $unicode 29092025.mov",'Quoted metadata 29092025.mov')
    $plan = Get-StreamPlan (ConvertFrom-ProbeJson '{"streams":[{"index":3,"codec_type":"video","codec_name":"h264","width":320,"height":240},{"index":7,"codec_type":"audio","codec_name":"aac"}]}')
    foreach ($name in $names) {
        $source = Join-Path $owner.Path $name
        $target = Join-Path $owner.Path ([IO.Path]::GetFileNameWithoutExtension($name)+'.mp4')
        [IO.File]::WriteAllText($source,'synthetic source sentinel')
        $hash = (Get-FileHash -LiteralPath $source).Hash
        $metadata = Parse-MetadataFromName $name
        if ($name -like 'Quoted*') { $metadata.Title = 'quote " backslash\" trailing\ $(throw ''evaluated''); & echo ignored' }
        $expected = @(Get-EncodeArguments $source $target $plan 22 $metadata)
        $native = Invoke-EncodeProcess $encoder $expected 6>$null
        $actual = @($native.StdOut.TrimEnd("`r","`n") -split '\r?\n' | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) })
        $exact = $native.Succeeded -and $actual.Count -eq $expected.Count
        for ($i=0; $exact -and $i -lt $expected.Count; $i++) { $exact = [StringComparer]::Ordinal.Equals($actual[$i],$expected[$i]) }
        $preserved = (Get-FileHash -LiteralPath $source).Hash -eq $hash -and -not (Test-Path -LiteralPath $target)
        $cases += [pscustomobject]@{ Case=$name; NativeExitCode=$native.ExitCode; ExactTokens=$exact;
            SourcePreserved=$preserved; TokenCount=$expected.Count; Passed=($exact -and $preserved) }
        Write-Host (('{0}: {1}' -f $(if ($exact -and $preserved) { 'PASS' } else { 'FAIL' }),$name))
    }
    $failed = @($cases | Where-Object { -not $_.Passed }).Count
    $report = [pscustomobject]@{ SchemaVersion=1; Kind='AgentExecutedManualNativeArgv';
        PowerShell=$PSVersionTable.PSVersion.ToString(); Edition=$PSVersionTable.PSEdition;
        TestedCommit=(git -C $repoRoot rev-parse HEAD).Trim(); TestedTreeDirty=[bool](git -C $repoRoot status --porcelain);
        Counts=[pscustomobject]@{Passed=($cases.Count-$failed);Failed=$failed;Skipped=0;NotRun=0}; Cases=$cases;
        Limitations=@('Actual Windows native argv inspection; no new Explorer or real-media result.',
            'Variable-shaped percent segments use literal PowerShell arguments under D005, not BAT drag/drop.') }
    $file = [IO.File]::Open([IO.Path]::GetFullPath($ReportPath),[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try {
        $bytes = (New-Object Text.UTF8Encoding($false)).GetBytes(($report | ConvertTo-Json -Depth 8))
        $file.Write($bytes,0,$bytes.Length)
    } finally { $file.Dispose() }
    Write-Host ("PowerShell $($report.PowerShell) $($report.Edition): $($report.Counts.Passed) passed, $failed failed.")
    if ($failed) { exit 1 }
} finally {
    $env:APPDATA = $originalAppData
    $env:NAME = $originalName
    $env:PATH = $originalPath
    Remove-WvcTestRoot $owner
}
