BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:HostExe = (Get-Process -Id $PID).Path
    $script:PS51 = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    function Read-CollisionPayload([string]$Path) {
        $bytes = [IO.File]::ReadAllBytes($Path)
        $offset = if ($bytes.Length -ge 16 -and [Text.Encoding]::ASCII.GetString($bytes,4,4) -eq 'ftyp') { 16 } else { 0 }
        [Text.Encoding]::UTF8.GetString($bytes,$offset,$bytes.Length-$offset)
    }
}
Describe 'Actual concurrent publication [WVC-M2-04-A01/A02]' {
    It 'preserves both payloads with <Policy> and <Existing> while two native encoders target the same basename' -TestCases @(
        @{Policy='rename';Existing=$false},@{Policy='rename';Existing=$true},@{Policy='skip';Existing=$false}
    ) {
        param($Policy,$Existing)
        $owner = New-WvcTestRoot
        $processes = @()
        try {
            $root = $owner.Path
            $output = Join-Path $root 'output'
            [void][IO.Directory]::CreateDirectory($output)
            $source = Join-Path $root 'same & [x] !NAME! %PATH% source.mov'
            [IO.File]::WriteAllText($source,'source sentinel')
            $sourceHash = (Get-FileHash -LiteralPath $source).Hash
            $final = Join-Path $output 'same & [x] !NAME! %PATH% source.mp4'
            if ($Existing) { [IO.File]::WriteAllText($final,'existing final sentinel'); $finalHash=(Get-FileHash -LiteralPath $final).Hash }
            $compile = Invoke-WvcTestProcess $PS51 @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
                (Join-Path $PSScriptRoot 'New-CollisionFixture.ps1'),'-Destination',(Join-Path $root 'encoder.exe'))
            if ($compile.ExitCode -ne 0) { throw ('Native collision fixture compilation failed: '+$compile.StdErr) }
            [IO.File]::Copy((Join-Path $root 'encoder.exe'),(Join-Path $root 'probe.exe'))
            foreach ($worker in @('one','two')) {
                $tokens = @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'Invoke-CollisionWorker.ps1'),
                    '-SourcePath',$source,'-OutputRoot',$output,'-FixtureRoot',$root,'-WorkerId',$worker,'-Policy',$Policy,'-ReportPath',(Join-Path $root ($worker+'.json')))
                $start = New-Object Diagnostics.ProcessStartInfo
                $start.FileName=$HostExe; $start.UseShellExecute=$false; $start.CreateNoWindow=$true
                $start.Arguments=(@($tokens | ForEach-Object { ConvertTo-WvcNativeArgument $_ }) -join ' ')
                $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true; $start.RedirectStandardInput=$true
                $process = New-Object Diagnostics.Process
                $process.StartInfo=$start
                $tracked = @{Process=$process;Started=$false;Readers=@();Out=$null;Err=$null}
                $processes += $tracked
                [void]$process.Start()
                $tracked.Started=$true
                $tracked.Readers=@($process.StandardOutput,$process.StandardError,$process.StandardInput)
                $tracked.Out=$tracked.Readers[0].ReadToEndAsync()
                $tracked.Err=$tracked.Readers[1].ReadToEndAsync()
                $tracked.Readers[2].Close()
            }
            foreach ($child in $processes) {
                $child.Process.WaitForExit(20000) | Should -BeTrue
                $child.Out.Wait(2000) | Should -BeTrue
                $child.Err.Wait(2000) | Should -BeTrue
                $child.Process.ExitCode | Should -Be 0
                $child.Err.Result | Should -BeExactly ''
            }
            $reports = @('one','two') | ForEach-Object { Get-Content -LiteralPath (Join-Path $root ($_+'.json')) -Raw | ConvertFrom-Json }
            ($reports.Failed | Measure-Object -Sum).Sum | Should -Be 0
            $targets = @('one','two') | ForEach-Object { [IO.File]::ReadAllText((Join-Path $root ($_+'.target'))) }
            @($targets | Select-Object -Unique).Count | Should -Be 2
            foreach ($target in $targets) { [IO.Path]::GetFileName($target) | Should -BeExactly 'encode.partial.mp4' }
            $finals = @(Get-ChildItem -LiteralPath $output -File -Filter '*.mp4')
            $payloads = @($finals | ForEach-Object { Read-CollisionPayload $_.FullName })
            if ($Policy -eq 'rename') {
                ($reports.Done | Measure-Object -Sum).Sum | Should -Be 2
                $payloads | Should -Contain 'synthetic payload one'
                $payloads | Should -Contain 'synthetic payload two'
                @((Get-ChildItem -LiteralPath $output -Directory)).Count | Should -Be 0
                $finals.Count | Should -Be (2+[int]$Existing)
            } else {
                ($reports.Done | Measure-Object -Sum).Sum | Should -Be 1
                ($reports.Skipped | Measure-Object -Sum).Sum | Should -Be 1
                $finals.Count | Should -Be 1
                $partials = @(Get-ChildItem -LiteralPath $output -Recurse -File -Filter 'encode.partial.mp4')
                $partials.Count | Should -Be 1
                @($payloads + (Read-CollisionPayload $partials[0].FullName) | Select-Object -Unique).Count | Should -Be 2
            }
            if ($Existing) { (Get-FileHash -LiteralPath $final).Hash | Should -BeExactly $finalHash }
            (Get-FileHash -LiteralPath $source).Hash | Should -BeExactly $sourceHash
        } finally {
            $cleanupFailures = New-Object 'Collections.Generic.List[string]'
            foreach ($child in $processes) {
                try {
                    if ($child.Started -and -not $child.Process.HasExited) {
                        & (Join-Path $env:SystemRoot 'System32/taskkill.exe') /PID $child.Process.Id /T /F | Out-Null
                        if ($LASTEXITCODE -ne 0 -or -not $child.Process.WaitForExit(5000)) { throw 'Owned collision process cleanup failed; retain root.' }
                    }
                } catch { $cleanupFailures.Add($_.Exception.Message) } finally {
                    foreach ($reader in $child.Readers) {
                        try { $reader.Dispose() } catch { $cleanupFailures.Add($_.Exception.Message) }
                    }
                    try { $child.Process.Dispose() } catch { $cleanupFailures.Add($_.Exception.Message) }
                }
            }
            if ($cleanupFailures.Count) {
                $script:WvcProcessCleanupFailed = $true
                throw ('Owned collision cleanup failed; root retained: ' + ($cleanupFailures -join '; '))
            }
            Remove-WvcTestRoot $owner
        }
    }
}
