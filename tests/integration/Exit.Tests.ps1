BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $RepoRoot 'tests/launcher/LauncherTestSupport.ps1')
    $script:Owner=New-WvcTestRoot
    $script:App=Join-Path $Owner.Path 'app'
    $script:Bin=Join-Path $Owner.Path 'bin'
    foreach ($directory in @($App,$Bin)) { [void][IO.Directory]::CreateDirectory($directory) }
    foreach ($file in @('WinVidCompress.ps1','WinVidCompress.bat')) {
        Copy-Item -LiteralPath (Join-Path $RepoRoot $file) -Destination (Join-Path $App $file)
    }
    $compiled=Invoke-WvcTestProcess (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe') `
        @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
        (Join-Path $PSScriptRoot 'New-ExitFixture.ps1'),'-Destination',(Join-Path $Bin 'ffmpeg.exe'))
    if ($compiled.ExitCode -ne 0) { throw $compiled.StdErr }
    Copy-Item -LiteralPath (Join-Path $Bin 'ffmpeg.exe') -Destination (Join-Path $Bin 'ffprobe.exe')
    $script:HostExe=(Get-Process -Id $PID).Path
}
AfterAll { if ($null -ne $script:Owner) { Remove-WvcTestRoot $script:Owner } }

Describe 'Actual Windows executable exit boundary [WVC-M2-06]' {
    BeforeEach {
        $script:CaseRoot=Join-Path $Owner.Path ([guid]::NewGuid().ToString('N'))
        $script:SourceRoot=Join-Path $CaseRoot 'sources'
        $script:OutputRoot=Join-Path $CaseRoot 'output'
        $script:AppData=Join-Path $CaseRoot 'appdata'
        $config=Join-Path $AppData 'WinVidCompress'
        foreach ($directory in @($SourceRoot,$OutputRoot,$config)) { [void][IO.Directory]::CreateDirectory($directory) }
        Write-WvcTestJson (Join-Path $config 'config.json') ([pscustomobject]@{OutputDir=$OutputRoot})
        $script:Good=Join-Path $SourceRoot 'ok & [x] !NAME!.mov'
        $script:Bad=Join-Path $SourceRoot 'fail.mov'
        $script:Environment=@{APPDATA=$AppData;PATH=($Bin+';'+$env:SystemRoot+'\System32');FFREPORT='';
            WVC_EXIT_BAT=(Join-Path $App 'WinVidCompress.bat');WVC_EXIT_SOURCE=$SourceRoot}
    }

    It 'returns exact <Code> for actual <Route> <Case> without stdin or pause [A01 A04]' -TestCases @(
        @{Route='PS1';Case='success';Code=0}, @{Route='BAT';Case='success';Code=0},
        @{Route='PS1';Case='mixed failure';Code=1}, @{Route='BAT';Case='mixed failure';Code=1},
        @{Route='PS1';Case='empty batch';Code=2}, @{Route='BAT';Case='empty batch';Code=2},
        @{Route='PS1';Case='no input';Code=2}, @{Route='BAT';Case='no input';Code=2},
        @{Route='PS1';Case='startup failure';Code=2}, @{Route='BAT';Case='startup failure';Code=2},
        @{Route='PS1';Case='scan failure plus success';Code=1}, @{Route='BAT';Case='scan failure plus success';Code=1}
    ) {
        param($Route,$Case,$Code)
        if ($Case -in @('success','mixed failure','scan failure plus success')) { [IO.File]::WriteAllText($Good,'source sentinel') }
        if ($Case -eq 'mixed failure') { [IO.File]::WriteAllText($Bad,'failed source sentinel') }
        if ($Case -eq 'startup failure') { $Environment.PATH=Join-Path $CaseRoot 'absent-bin' }
        $arguments=@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
            (Join-Path $App 'WinVidCompress.ps1'),'-Unattended')
        $cmd='/d /v:off /s /c ""%WVC_EXIT_BAT%" -Unattended'
        if ($Case -ne 'no input') { $arguments+=@($SourceRoot); $cmd+=' "%WVC_EXIT_SOURCE%"' }
        if ($Case -eq 'scan failure plus success') {
            $missing=Join-Path $CaseRoot 'missing.mov'; $arguments+=@($missing)
            $Environment.WVC_EXIT_MISSING=$missing; $cmd+=' "%WVC_EXIT_MISSING%"'
        }
        $cmd+='"'
        $result=if ($Route -eq 'PS1') { Invoke-WvcTestProcess $HostExe $arguments -Environment $Environment }
            else { Invoke-WvcLauncherProcess $env:ComSpec $cmd $Environment }
        $result.ExitCode | Should -Be $Code
        $result.StdOut | Should -Not -Match 'Choose \[1-4\]|Press any key'
        if ($Case -in @('success','mixed failure','scan failure plus success')) {
            [IO.File]::ReadAllText($Good) | Should -BeExactly 'source sentinel'
            Test-Path -LiteralPath (Join-Path $OutputRoot 'ok & [x] !NAME!.mp4') | Should -BeTrue
        }
        if ($Case -eq 'mixed failure') {
            $result.StdOut | Should -Match 'Failed:  1'
            [IO.File]::ReadAllText($Bad) | Should -BeExactly 'failed source sentinel'
        }
        if ($Case -eq 'startup failure') { $result.StdErr | Should -Match 'ffmpeg.exe not found' }
        if ($Case -eq 'scan failure plus success') { $result.StdOut | Should -Match 'Scan errors: 1' }
    }

    It 'returns actual code0 for all valid skips with unchanged source and final [A01]' {
        [IO.File]::WriteAllText($Good,'source sentinel')
        $final=Join-Path $OutputRoot 'ok & [x] !NAME!.mp4'
        [IO.File]::WriteAllText($final,'existing output sentinel')
        $result=Invoke-WvcTestProcess $HostExe @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
            (Join-Path $PSScriptRoot 'Invoke-ExitWorker.ps1'),'-Application',(Join-Path $App 'WinVidCompress.ps1'),
            '-SourceRoot',$SourceRoot,'-Mode','Skip') -Environment $Environment
        $result.ExitCode | Should -Be 0
        $result.StdOut | Should -Match 'Skipped: 1'
        [IO.File]::ReadAllText($final) | Should -BeExactly 'existing output sentinel'
        [IO.File]::ReadAllText($Good) | Should -BeExactly 'source sentinel'
    }

    It 'returns actual code3 at the controlled cancellation seam and leaves rest unstarted [A01]' {
        foreach ($file in @($Good,$Bad)) { [IO.File]::WriteAllText($file,'source sentinel') }
        $result=Invoke-WvcTestProcess $HostExe @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
            (Join-Path $PSScriptRoot 'Invoke-ExitWorker.ps1'),'-Application',(Join-Path $App 'WinVidCompress.ps1'),
            '-SourceRoot',$SourceRoot,'-Mode','Cancel') -Environment $Environment
        $result.ExitCode | Should -Be 3
        $result.StdOut | Should -Match 'Cancelled: 1'
        $result.StdOut | Should -Match 'Unstarted: 1'
        @(Get-ChildItem -LiteralPath $OutputRoot -Filter '*.mp4').Count | Should -Be 0
    }

    It 'dot-sources even with unattended switches and continues the real caller [A03]' {
        $worker=Join-Path $CaseRoot 'load.ps1'
        [IO.File]::WriteAllText($worker, 'param([string]$Application)' + "`r`n" + '. $Application -Unattended' + "`r`n" +
            'Write-Output ("WVC_CALLER_" + "ALIVE"); exit 37', [Text.Encoding]::ASCII)
        $result=Invoke-WvcTestProcess $HostExe @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
            $worker,'-Application',(Join-Path $App 'WinVidCompress.ps1')) -Environment $Environment
        $result.ExitCode | Should -Be 37
        $result.StdOut | Should -Match 'WVC_CALLER_ALIVE'
        $result.StdErr | Should -BeNullOrEmpty
    }

    It 'keeps the default BAT menu and PowerShell prompt usable after Quit [A04 automated portion]' {
        $result=Invoke-WvcLauncherProcess $env:ComSpec '/d /v:off /s /c ""%WVC_EXIT_BAT%""' $Environment `
            ("4`r`nWrite-Output ('WVC_INTERACTIVE_' + 'ALIVE')`r`nexit 0`r`n")
        $result.ExitCode | Should -Be 0
        $result.StdOut | Should -Match '1\) Set output folder'
        $result.StdOut | Should -Match 'WVC_INTERACTIVE_ALIVE'
        $result.StdErr | Should -BeNullOrEmpty
    }
}
