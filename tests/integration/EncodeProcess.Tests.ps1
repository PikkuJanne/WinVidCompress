BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:OriginalEnvironment = @{APPDATA=$env:APPDATA;FFREPORT=$env:FFREPORT;WVC_ENCODE_PID=$env:WVC_ENCODE_PID;WVC_ENCODE_CHILD_PID=$env:WVC_ENCODE_CHILD_PID}
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    $script:Encoder = Join-Path $TestDrive 'native & (encoder) [x].exe'
    $ps51 = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $compile = Invoke-WvcTestProcess $ps51 @('-NoProfile','-NonInteractive','-File',(Join-Path $PSScriptRoot 'New-EncodeProcessFixture.ps1'),'-Destination',$Encoder)
    if ($compile.ExitCode -ne 0) { throw ('Native encoder fixture compilation failed: ' + $compile.StdErr) }
}
AfterAll {
    foreach ($name in $OriginalEnvironment.Keys) { Set-Item ('Env:' + $name) $OriginalEnvironment[$name] }
}
Describe 'Owned native encoding [WVC-M2-03-A03/A04]' {
    BeforeEach { Mock Write-Host {}; $env:WVC_ENCODE_PID=$null; $env:WVC_ENCODE_CHILD_PID=$null }

    It 'round-trips exact Windows argv including Unicode, empty, quotes and trailing slashes' {
        $unicode = ([char]0x00E4).ToString() + [char]0x00F6 + [char]0x4E2D
        $tokens = @('argv','','D:\space & (A) [x] !NAME! %PATH%\clip.mov',
            ('artist=' + $unicode),'title=quote " and \" and trailing\','D:\trailing\',
            '$(throw ''evaluated''); & echo ignored',"apostrophe ' and ordinary 25%")
        $result = Invoke-EncodeProcess $Encoder $tokens
        $result.Succeeded | Should -BeTrue
        $actual = @($result.StdOut.TrimEnd("`r","`n") -split '\r?\n' | ForEach-Object { [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_)) })
        $actual.Count | Should -Be $tokens.Count
        for ($i=0; $i -lt $tokens.Count; $i++) { $actual[$i] | Should -BeExactly $tokens[$i] }
    }

    It 'drains simultaneous large stdout/stderr and retains explicit diagnostic tails' {
        $result = Invoke-EncodeProcess $Encoder @('flood') -CaptureLimitCharacters 32768
        $result.Succeeded | Should -BeTrue
        $result.ExitCode | Should -Be 0
        $result.StdOut.Length | Should -Be 32768
        $result.StdErr.Length | Should -Be 32768
        $result.StdOutTruncated | Should -BeTrue
        $result.StdErrTruncated | Should -BeTrue
        $result.StdOut | Should -Match ('STDOUT END ' + [char]0x00E4 + '$')
        $result.StdErr | Should -Match ('STDERR END ' + [char]0x00F6 + '$')
        $result.StdOutCharacters | Should -BeGreaterThan 1048576
        $result.StdErrCharacters | Should -BeGreaterThan 1048576
        Should -Invoke Write-Host -ParameterFilter { $NoNewline } -Times 2
    }

    It 'recognizes a nonzero native exit even with no stderr and a stale LASTEXITCODE' {
        $global:LASTEXITCODE = 0
        $result = Invoke-EncodeProcess $Encoder @('fail')
        $result.Succeeded | Should -BeFalse
        $result.Started | Should -BeTrue
        $result.ExitCode | Should -Be 17
        $result.FailureKind | Should -Be 'NonZeroExit'
        $result.StdErr | Should -BeExactly ''
    }

    It 'treats stderr on exit zero as diagnostics under Stop error policy' {
        $ErrorActionPreference = 'Stop'
        $result = Invoke-EncodeProcess $Encoder @('warning')
        $result.Succeeded | Should -BeTrue
        $result.StdErr | Should -BeExactly 'benign native warning'
        $result.StdErrTruncated | Should -BeFalse
    }

    It 'returns a structured start failure with no invented exit code' {
        $result = Invoke-EncodeProcess (Join-Path $TestDrive 'missing.exe') @('argv')
        $result.SchemaVersion | Should -Be 1
        $result.Succeeded | Should -BeFalse
        $result.Started | Should -BeFalse
        $result.ExitCode | Should -BeNullOrEmpty
        $result.FailureKind | Should -Be 'StartFailed'
        $result.Error | Should -Not -BeNullOrEmpty
    }

    It 'closes child stdin before waiting so menu input cannot be consumed' {
        $result = Invoke-EncodeProcess $Encoder @('stdin')
        $result.Succeeded | Should -BeTrue
        $result.StdOut | Should -BeExactly 'EOF'
    }

    It 'does not apply the short post-exit drain deadline to a running encoder' {
        $result = Invoke-EncodeProcess $Encoder @('hold') -DrainTimeoutMilliseconds 100
        $result.Succeeded | Should -BeTrue
        $result.ElapsedSeconds | Should -BeGreaterThan 3
    }

    It 'clears only child FFREPORT to prevent incidental log writes' {
        $env:FFREPORT = 'file=unwanted.log'
        $result = Invoke-EncodeProcess $Encoder @('report')
        $result.StdOut | Should -BeExactly 'ABSENT'
        $env:FFREPORT | Should -BeExactly 'file=unwanted.log'
    }

    It 'bounds post-exit drains when a descendant inherits the pipes' {
        $env:WVC_ENCODE_CHILD_PID = Join-Path $TestDrive 'child-pid.txt'
        $clock = [Diagnostics.Stopwatch]::StartNew()
        try {
            $result = Invoke-EncodeProcess $Encoder @('inherit') -DrainTimeoutMilliseconds 100
            $result.Succeeded | Should -BeFalse
            $result.ExitCode | Should -Be 0
            $result.FailureKind | Should -Be 'PipeDrainTimeout'
            $clock.ElapsedMilliseconds | Should -BeLessThan 3000
        } finally {
            # This synthetic descendant is explicitly owned by the fixture.
            if (Test-Path -LiteralPath $env:WVC_ENCODE_CHILD_PID) {
                $childId = [int](Get-Content -LiteralPath $env:WVC_ENCODE_CHILD_PID)
                $child = Get-Process -Id $childId -ErrorAction SilentlyContinue
                if ($null -ne $child) {
                    try {
                        if (-not [StringComparer]::OrdinalIgnoreCase.Equals($child.Path,$Encoder)) { throw 'Fixture child identity mismatch; refusing termination.' }
                        $child.Kill()
                        if (-not $child.WaitForExit(2000)) { throw 'Fixture child cleanup failed.' }
                    } finally { $child.Dispose() }
                }
            }
        }
    }

    It 'stops its directly owned child when console display fails' {
        $env:WVC_ENCODE_PID = Join-Path $TestDrive 'owned-pid.txt'
        Mock Write-Host { throw 'Injected console failure' }
        $result = Invoke-EncodeProcess $Encoder @('hold')
        $result.Succeeded | Should -BeFalse
        $result.Error | Should -Match 'Injected console failure'
        $ownedId = [int](Get-Content -LiteralPath $env:WVC_ENCODE_PID)
        Get-Process -Id $ownedId -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }
}
