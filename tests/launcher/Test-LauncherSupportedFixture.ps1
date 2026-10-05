Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ./tests/launcher/LauncherTestSupport.ps1
$prepared = (& ./tests/launcher/New-LauncherSupportedFixture.ps1) | ConvertFrom-Json
$metadata = Get-Content -LiteralPath $prepared.Manifest -Raw -Encoding UTF8 | ConvertFrom-Json
try {
    [void](Assert-WvcTestRoot $metadata.Owner)
    $runner = Join-Path $metadata.MenuApp 'Record-MenuPaths.ps1'
    $native = (@('-NoProfile','-ExecutionPolicy','Bypass','-File',$runner) | ForEach-Object { ConvertTo-WvcNativeArgument $_ }) -join ' '
    $result = Invoke-WvcLauncherProcess (Get-Process -Id $PID).Path $native @{} "2`r`nliteral %PATH% !NAME!.mov`r`n3`r`nFolder %PATH% !NAME!`r`n4`r`n"
    if ($result.ExitCode -ne 0 -or $result.StdErr) { throw ('Menu smoke failed: ' + $result.StdErr + $result.StdOut) }
    $reports = @(Get-ChildItem -LiteralPath $metadata.MenuApp -Filter 'menu-*.json' -File | ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json })
    if ($reports.Count -ne 2) { throw 'Expected two exact menu selections.' }
    foreach ($expected in @($metadata.MenuFile,$metadata.MenuFolder)) {
        $matches = @($reports | Where-Object { @($_.Paths).Count -eq 1 -and $_.Paths[0] -ceq $expected -and $_.MatchingPathVariable -and $_.MatchingNameVariable -and $_.ApplicationSHA256 -eq $metadata.ApplicationSHA256 })
        if ($matches.Count -ne 1) { throw 'Menu path/hash/variables mismatch.' }
    }
    $directFiles = @(Get-ChildItem -LiteralPath $metadata.DirectApp -Filter 'argv-*.json' -File)
    if ($directFiles.Count -ne 1) { throw 'Direct call did not record exactly once.' }
    $direct = Get-Content -LiteralPath $directFiles[0].FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $expectedPaths = @($metadata.MenuFile,$metadata.MenuFolder)
    $index = [Array]::IndexOf([object[]]$direct.RawArguments, '-File')
    if ($index -lt 0 -or @($direct.RawArguments).Count -ne $index + 4 -or
        $direct.RawArguments[$index + 1] -cne (Join-Path $metadata.DirectApp 'WinVidCompress.ps1') -or @($direct.Paths).Count -ne 2) { throw 'Direct native shape mismatch.' }
    for ($i = 0; $i -lt 2; $i++) {
        if ($direct.Paths[$i] -cne $expectedPaths[$i] -or $direct.RawArguments[$index + 2 + $i] -cne $expectedPaths[$i]) { throw 'Direct literal path changed.' }
    }
    if (Test-Path -LiteralPath (Join-Path $metadata.MenuApp 'appdata/WinVidCompress/config.json')) { throw 'Unexpected config write.' }
    foreach ($source in @($metadata.Inputs) + @($metadata.MenuFile)) {
        if ([IO.File]::ReadAllText($source) -cne 'synthetic filename sentinel') { throw 'Synthetic source changed.' }
    }
    $hashChecks = @(
        @{ Path = (Join-Path $metadata.ArgumentApp 'WinVidCompress.bat'); Hash = $metadata.LauncherSHA256 },
        @{ Path = (Join-Path $metadata.ArgumentApp 'WinVidCompress.ps1'); Hash = $metadata.ArgumentRecorderSHA256 },
        @{ Path = (Join-Path $metadata.MenuApp 'WinVidCompress.ps1'); Hash = $metadata.ApplicationSHA256 },
        @{ Path = $runner; Hash = $metadata.MenuRecorderSHA256 },
        @{ Path = (Join-Path $metadata.DirectApp 'WinVidCompress.ps1'); Hash = $metadata.DirectRecorderSHA256 }
    )
    foreach ($item in $hashChecks) { if ((Get-FileHash -LiteralPath $item.Path).Hash -ne $item.Hash) { throw 'Prepared hash mismatch.' } }
    [pscustomobject]@{
        Kind = 'Automated supported fixture smoke, not human Explorer'; HostVersion = $PSVersionTable.PSVersion.ToString()
        MenuFileExact = $true; MenuFolderExact = $true; DirectNativeAndBoundExact = $true
        SourcesPreserved = $true; NoConfigWrite = $true; HashesMatch = $true
    } | ConvertTo-Json
} finally { & ./tests/launcher/Remove-LauncherManualFixture.ps1 -Manifest $prepared.Manifest }
