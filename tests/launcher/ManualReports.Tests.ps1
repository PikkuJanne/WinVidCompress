BeforeAll {
    . (Join-Path $PSScriptRoot 'LauncherTestSupport.ps1')
    $script:Checker = Join-Path $PSScriptRoot 'Test-LauncherManualReports.ps1'
}

Describe 'Manual argv evidence integrity [WVC-M1-02]' {
    BeforeEach {
        $script:ReportOwner = New-WvcTestRoot
        $script:ReportApp = Join-Path $ReportOwner.Path 'app'
        [void][IO.Directory]::CreateDirectory($ReportApp)
        $launcher = Join-Path $ReportApp 'WinVidCompress.bat'
        [IO.File]::WriteAllText($launcher, 'synthetic hash sentinel')
        $script:Manifest = Join-Path $ReportOwner.Path 'manual-fixture.json'
        $script:ExpectedInputs = @('one.mov','two.mov')
        Write-WvcTestJson $Manifest ([pscustomobject]@{
            Owner = $ReportOwner; ArgumentApp = $ReportApp; Inputs = $ExpectedInputs
            Folder = 'folder'; LauncherSHA256 = (Get-FileHash -LiteralPath $launcher).Hash
        })
        function Write-RecorderReport([string[]]$Paths, [string[]]$RawPaths = $Paths) {
            Write-WvcTestJson (Join-Path $ReportApp ('argv-' + [guid]::NewGuid().ToString('N') + '.json')) ([pscustomobject]@{
                Paths = $Paths
                RawArguments = @('powershell.exe','-File',(Join-Path $ReportApp 'WinVidCompress.ps1')) + $RawPaths
                Edition = 'Desktop'; PowerShell = '5.1.26100.9444'
            })
        }
        function Invoke-ReportCheck([string]$Case) {
            $arguments = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$Checker,'-Manifest',$Manifest)
            if ($Case) { $arguments += @('-Case',$Case) }
            Invoke-WvcTestProcess (Get-Process -Id $PID).Path $arguments
        }
    }
    AfterEach { Remove-WvcTestRoot $ReportOwner }

    It 'leaves absent reports incomplete' {
        $result = Invoke-ReportCheck
        $result.ExitCode | Should -Be 2
        ($result.StdOut | ConvertFrom-Json).Counts.NotRun | Should -Be 4
    }

    It 'accepts exact records while declaring human observation unestablished' {
        Write-RecorderReport @()
        Write-RecorderReport @('one.mov')
        Write-RecorderReport @('folder')
        Write-RecorderReport @('two.mov','one.mov')
        $result = Invoke-ReportCheck
        $result.ExitCode | Should -Be 0
        $report = $result.StdOut | ConvertFrom-Json
        $report.Counts.Passed | Should -Be 4
        $report.HumanExplorerObservation | Should -Match 'Not established'
    }

    It 'fails a wrong single selection and duplicate multi-selection with omissions' {
        Write-RecorderReport @('two.mov')
        Write-RecorderReport @('one.mov','one.mov')
        $result = Invoke-ReportCheck
        $result.ExitCode | Should -Be 1
        ($result.StdOut | ConvertFrom-Json).Counts.Failed | Should -Be 1
    }

    It 'fails raw argv that differs from the bound paths' {
        Write-RecorderReport @('one.mov') @('changed.mov')
        $result = Invoke-ReportCheck
        $result.ExitCode | Should -Be 1
        ($result.StdOut | ConvertFrom-Json).Counts.Failed | Should -Be 1
    }

    It 'grades only a requested shape while accepting other valid report shapes' {
        Write-RecorderReport @('one.mov')
        Write-RecorderReport @('folder')
        $result = Invoke-ReportCheck 'folder'
        $result.ExitCode | Should -Be 0
        $report = $result.StdOut | ConvertFrom-Json
        $report.Counts.Passed | Should -Be 1
        $report.Counts.NotRun | Should -Be 0
    }

    It 'does not hide a malformed earlier report when grading one requested shape' {
        Write-RecorderReport @('folder')
        Write-RecorderReport @('one.mov') @('changed.mov')
        $result = Invoke-ReportCheck 'folder'
        $result.ExitCode | Should -Be 1
        ($result.StdOut | ConvertFrom-Json).Counts.Failed | Should -Be 1
    }

    It 'reads UTF8 Unicode paths literally on both supported hosts' {
        $unicode = 'Finnish ' + [char]0x00e4 + [char]0x00f6 + ' ' + [char]0x4e2d + '.mov'
        $metadata = Get-Content -LiteralPath $Manifest -Raw -Encoding UTF8 | ConvertFrom-Json
        $metadata.Inputs = @($unicode,'two.mov')
        # Rewriting this owned synthetic manifest is intentional for the regression.
        [IO.File]::WriteAllText($Manifest, ($metadata | ConvertTo-Json -Depth 5), (New-Object Text.UTF8Encoding($false)))
        Write-RecorderReport @($unicode)
        $result = Invoke-ReportCheck 'single'
        $result.ExitCode | Should -Be 0
        ($result.StdOut | ConvertFrom-Json).Counts.Passed | Should -Be 1
    }
}
