param([string]$ModuleRoot)

BeforeAll {
    . (Join-Path $PSScriptRoot 'TestSupport.ps1')
    $script:Runner = Join-Path $PSScriptRoot 'Invoke-PesterRun.ps1'
    $script:TestModuleRoot = $ModuleRoot
}

Describe 'Harness result accounting' {
    It 'discovers future nested unit tests and excludes helper scripts' {
        $root = Join-Path $TestDrive 'discovery'
        $nested = Join-Path $root 'unit'
        New-Item -ItemType Directory -Path $nested | Out-Null
        $top = Join-Path $root 'Top.Tests.ps1'
        $menu = Join-Path $nested 'Menu.Tests.ps1'
        Set-Content -LiteralPath $top -Value '# synthetic test'
        Set-Content -LiteralPath $menu -Value '# synthetic test'
        Set-Content -LiteralPath (Join-Path $root 'Helper.ps1') -Value '# synthetic helper'
        $paths = @(Get-WvcPesterTestPaths $root)
        $paths.Count | Should -Be 2
        $paths | Should -Contain $top
        $paths | Should -Contain $menu
    }

    It 'publishes actual mixed Pester outcomes and returns nonzero on a failure' {
        $suite = Join-Path $TestDrive 'mixed.Tests.ps1'
        @'
Describe 'Synthetic mixed results' {
    It 'passes' { 1 | Should -Be 1 }
    It 'fails' { 1 | Should -Be 2 }
    It 'skips' -Skip { throw 'Must not execute' }
}
'@ | Set-Content -LiteralPath $suite -Encoding ASCII
        $reportPath = Join-Path $TestDrive 'mixed.json'
        $process = Invoke-WvcTestProcess (Get-Process -Id $PID).Path @('-NoProfile','-NonInteractive',
            '-ExecutionPolicy','Bypass','-File',$script:Runner,'-ModuleRoot',$script:TestModuleRoot,
            '-TestPath',$suite,'-ReportPath',$reportPath)
        $process.ExitCode | Should -Be 1
        $report = Read-WvcChildReport $reportPath $process.ExitCode
        $report.Counts.Passed | Should -Be 1
        $report.Counts.Failed | Should -Be 1
        $report.Counts.Skipped | Should -Be 1
        $report.Counts.NotRun | Should -Be 0
    }

    It 'rejects a successful child with no report' {
        { Read-WvcChildReport (Join-Path $TestDrive 'absent.json') 0 } | Should -Throw '*no report*'
    }

    It 'preserves an all-skipped Pester child as incomplete' {
        $suite = Join-Path $TestDrive 'skipped.Tests.ps1'
        "Describe 'Skipped suite' { It 'skips' -Skip { throw 'Must not run' } }" |
            Set-Content -LiteralPath $suite -Encoding ASCII
        $reportPath = Join-Path $TestDrive 'skipped.json'
        $process = Invoke-WvcTestProcess (Get-Process -Id $PID).Path @('-NoProfile','-NonInteractive',
            '-ExecutionPolicy','Bypass','-File',$script:Runner,'-ModuleRoot',$script:TestModuleRoot,
            '-TestPath',$suite,'-ReportPath',$reportPath)
        $process.ExitCode | Should -Be 2
        $report = Read-WvcChildReport $reportPath $process.ExitCode
        $report.Counts.Passed | Should -Be 0
        $report.Counts.Skipped | Should -Be 1
    }

    It 'does not relabel a supported PS5.1 executable as PS7' {
        Mock Invoke-WvcTestProcess { [pscustomobject]@{ ExitCode = 0; StdOut = '{"Version":"5.1.26100.9444","Edition":"Desktop"}'; StdErr = '' } }
        Get-WvcHostInfo 'synthetic-host-double' 'PowerShell7' | Should -BeNullOrEmpty
        (Get-WvcHostInfo 'synthetic-host-double' 'WindowsPowerShell').Edition | Should -Be 'Desktop'
    }

    It 'rejects corrupt child JSON' {
        $path = Join-Path $TestDrive 'corrupt.json'
        Set-Content -LiteralPath $path -Value '{' -Encoding ASCII
        { Read-WvcChildReport $path 0 } | Should -Throw
    }

    It 'rejects a count mismatch instead of accepting a false pass' {
        $path = Join-Path $TestDrive 'mismatch.json'
        Write-WvcTestJson $path ([pscustomobject]@{
            SchemaVersion = 1; Counts = @{ Passed = 1; Failed = 0; Skipped = 0; NotRun = 0 }
            Cases = @((New-WvcTestCase 'actual' 'Failed'))
        })
        { Read-WvcChildReport $path 0 } | Should -Throw '*count mismatch*'
    }

    It 'rejects duplicate case IDs even when the advertised totals match' {
        $path = Join-Path $TestDrive 'duplicates.json'
        Write-WvcTestJson $path ([pscustomobject]@{
            SchemaVersion = 1; Counts = @{ Passed = 2; Failed = 0; Skipped = 0; NotRun = 0 }
            Cases = @((New-WvcTestCase 'duplicate' 'Passed'),(New-WvcTestCase 'duplicate' 'Passed'))
        })
        { Read-WvcChildReport $path 0 } | Should -Throw '*Duplicate*'
    }

    It 'rejects nonzero execution with a falsely green child report' {
        $path = Join-Path $TestDrive 'false-pass.json'
        Write-WvcTestJson $path ([pscustomobject]@{
            SchemaVersion = 1; Counts = @{ Passed = 1; Failed = 0; Skipped = 0; NotRun = 0 }
            Cases = @((New-WvcTestCase 'actual' 'Passed'))
        })
        { Read-WvcChildReport $path 1 } | Should -Throw '*Nonzero*'
    }

    It 'keeps absent executables explicitly unavailable without falling back to PATH' {
        Resolve-WvcTestExecutable (Join-Path $TestDrive 'missing-pwsh.exe') 'pwsh.exe' | Should -BeNullOrEmpty
    }

    It 'selects one PATH executable when multiple application matches exist' {
        Mock Get-Command { @([pscustomobject]@{ Source = 'first.exe' },[pscustomobject]@{ Source = 'second.exe' }) } -ParameterFilter {
            $Name -contains 'synthetic-host.exe'
        }
        Resolve-WvcTestExecutable '' 'synthetic-host.exe' | Should -Be 'first.exe'
    }

    It 'does not call a missing-only or zero-case run passed' {
        $summary = Get-WvcTierSummary 'Quick' @((New-WvcTestCase 'missing-host' 'Skipped' 'unavailable'))
        $summary.Status | Should -Be 'Incomplete'
        $summary.ExitCode | Should -Be 2
        $summary.Counts.Skipped | Should -Be 1
        (Get-WvcTierSummary 'Quick' @()).ExitCode | Should -Be 2
    }

    It 'keeps incomplete full and manual tiers nonzero' {
        $cases = @((New-WvcTestCase 'automated' 'Passed'),(New-WvcTestCase 'actual-explorer' 'NotRun'))
        (Get-WvcTierSummary 'Full' $cases).ExitCode | Should -Be 2
        (Get-WvcTierSummary 'Manual' @((New-WvcTestCase 'actual-explorer' 'NotRun'))).Status | Should -Be 'Incomplete'
    }

    It 'prioritizes an automated failure over incomplete coverage' {
        $cases = @((New-WvcTestCase 'failure' 'Failed'),(New-WvcTestCase 'manual' 'NotRun'))
        (Get-WvcTierSummary 'Full' $cases).ExitCode | Should -Be 1
    }

    It 'writes stable JSON without BOM and refuses an existing report' {
        $path = Join-Path $TestDrive 'stable.json'
        $value = [pscustomobject][ordered]@{ SchemaVersion = 1; Cases = @((New-WvcTestCase 'alpha' 'Skipped' 'unavailable')) }
        Write-WvcTestJson $path $value
        $bytes = [IO.File]::ReadAllBytes($path)
        $bytes[0] | Should -Be 123
        $original = (Get-FileHash -LiteralPath $path).Hash
        { Write-WvcTestJson $path $value } | Should -Throw
        (Get-FileHash -LiteralPath $path).Hash | Should -Be $original
    }
}

Describe 'Owned root and Windows argument safety' {
    It 'removes only its owned temporary root and preserves a neighboring sentinel' {
        $owner = New-WvcTestRoot
        $neighbor = Join-Path ([IO.Path]::GetTempPath()) ('wvc-neighbor-' + [guid]::NewGuid().ToString('N') + '.txt')
        try {
            Set-Content -LiteralPath $neighbor -Value 'sentinel' -Encoding ASCII
            $hash = (Get-FileHash -LiteralPath $neighbor).Hash
            Remove-WvcTestRoot $owner
            Test-Path -LiteralPath $owner.Path | Should -BeFalse
            (Get-FileHash -LiteralPath $neighbor).Hash | Should -Be $hash
        } finally { Remove-Item -LiteralPath $neighbor }
    }

    It 'rejects an unowned target before recursive deletion' {
        $sentinel = Join-Path $TestDrive 'safe.txt'
        Set-Content -LiteralPath $sentinel -Value 'sentinel'
        { Remove-WvcTestRoot ([pscustomobject]@{ Path = $TestDrive; Token = 'invalid' }) } | Should -Throw '*Unowned*'
        Test-Path -LiteralPath $sentinel | Should -BeTrue
    }

    It 'rejects a mismatched ownership marker' {
        $owner = New-WvcTestRoot
        try {
            [IO.File]::WriteAllText((Join-Path $owner.Path '.wvc-owner'), 'wrong')
            { Remove-WvcTestRoot $owner } | Should -Throw '*marker*'
        } finally {
            [IO.File]::WriteAllText((Join-Path $owner.Path '.wvc-owner'), $owner.Token)
            Remove-WvcTestRoot $owner
        }
    }

    It 'round-trips spaces, quotes, trailing backslashes and Unicode through a native shell' {
        $scriptPath = Join-Path $TestDrive 'argv.ps1'
        '[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($args | ConvertTo-Json -Compress)))' |
            Set-Content -LiteralPath $scriptPath -Encoding ASCII
        $values = @('space value','a"b','C:\trailing\','',('B' + [char]0xE4 + 'nd & !x! %PATH%'))
        $process = Invoke-WvcTestProcess (Get-Process -Id $PID).Path (@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$scriptPath) + $values)
        $process.ExitCode | Should -Be 0
        $decoded = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($process.StdOut.Trim())) | ConvertFrom-Json
        $captured = @($decoded)
        ($captured -join "`n") | Should -Be ($values -join "`n")
    }
}
