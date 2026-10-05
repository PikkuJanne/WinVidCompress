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
        function Invoke-ReportCheck {
            Invoke-WvcTestProcess (Get-Process -Id $PID).Path @('-NoProfile','-ExecutionPolicy','Bypass',
                '-File',$Checker,'-Manifest',$Manifest)
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
}
