BeforeAll {
    $script:SavedAppData=$env:APPDATA
    $env:APPDATA=Join-Path $TestDrive 'appdata'
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
}
AfterAll { $env:APPDATA=$script:SavedAppData }

Describe 'Operations terminal layouts [WVC-HOTFIX]' {
    It 'matches the <Name> ASCII menu snapshot' -TestCases @(
        @{Name='normal';Width=59},@{Name='narrow';Width=32}
    ) {
        param($Name,$Width)
        $actual=@(Get-TerminalMenuLines 'D:\Videos' 'v1.0.1' $Width) -join "`n"
        $expected=[IO.File]::ReadAllText((Join-Path $RepoRoot ('tests/fixtures/terminal/'+$Name+'.txt'))).Replace("`r`n","`n").TrimEnd("`n")
        $actual | Should -BeExactly $expected
        $actual | Should -Not -Match '[^\x00-\x7f]'
        @($actual -split "`n" | Where-Object Length -gt $Width).Count | Should -Be 0
    }

    It 'matches the normal snapshot with no color and no escape sequences' {
        Mock Get-TerminalStyle { [pscustomobject]@{Width=59;Color=$false} }
        Mock Get-TerminalVersion { 'v1.0.1' }
        $script:Lines=New-Object 'Collections.Generic.List[string]'
        Mock Write-Host { $script:Lines.Add([string]$Object) }
        Write-TerminalMenu 'D:\Videos' $true
        $actual=($script:Lines.ToArray() -join "`n").TrimStart("`n")
        $expected=[IO.File]::ReadAllText((Join-Path $RepoRoot 'tests/fixtures/terminal/normal.txt')).Replace("`r`n","`n").TrimEnd("`n")
        $actual | Should -BeExactly $expected
        $actual | Should -Not -Match ([string][char]27)
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { $null -ne $ForegroundColor }
    }

    It 'uses restrained host colors with no ANSI literals' {
        Mock Get-TerminalStyle { [pscustomobject]@{Width=59;Color=$true} }
        Mock Write-Host {}
        Write-TerminalText 'Heading' 'Heading'
        Write-TerminalText 'Separator' 'Muted'
        Write-TerminalText 'Done' 'Success'
        Write-TerminalText 'Failed' 'Warning'
        foreach ($color in @('Cyan','DarkCyan','Green','Yellow')) {
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $ForegroundColor -eq $color }
        }
    }

    It 'preserves every character of a long path and filename on a narrow console' {
        $path="D:\Interview archives\Artist with a long name\Interview 31102026.mov"
        $lines=@(Split-TerminalLine $path 24)
        ($lines -join '') | Should -BeExactly $path
        $lines.Count | Should -BeGreaterThan 1
        @($lines | Where-Object Length -gt 24).Count | Should -Be 0
        ($lines -join '') | Should -Match 'Interview 31102026.mov$'
    }

    It 'does not report ready when an engine argument is unavailable' {
        $text=Get-TerminalMenuLines 'D:\Videos' 'v1.0.1' 59 $false
        ($text -join "`n") | Should -Match 'ENGINE   Dependency unavailable'
        ($text -join "`n") | Should -Not -Match 'ready'
    }

    It 'reads the version beside the application rather than from the working directory' {
        $saved=$script:ApplicationPath
        $folder=Join-Path $TestDrive 'versioned-app'
        [void][IO.Directory]::CreateDirectory($folder)
        [IO.File]::WriteAllText((Join-Path $folder 'VERSION'),"1.2.3`r`n")
        try {
            $script:ApplicationPath=Join-Path $folder 'WinVidCompress.ps1'
            Get-TerminalVersion | Should -BeExactly 'v1.2.3'
            [IO.File]::WriteAllText((Join-Path $folder 'VERSION'),"not a version`nprivate text")
            Get-TerminalVersion | Should -BeExactly 'local build'
        } finally { $script:ApplicationPath=$saved }
    }
}

Describe 'Operations terminal real stages and outcomes [WVC-HOTFIX]' {
    BeforeEach {
        $script:TerminalSession=$true
        Mock Get-TerminalStyle { [pscustomobject]@{Width=80;Color=$false} }
        Mock Write-Host {}
        Mock Write-Progress {}
    }
    AfterEach { $script:TerminalSession=$false }

    It 'prints queue position, full filename and actual state changes without cursor control' {
        $progress=New-EncodeProgress 2 2 5
        $progress.SourceName='Band 31102026.mov'
        $job=New-JobResult 'opaque' 22
        foreach ($state in @('Encoding','Finalizing','Validating','Publishing','Completed')) {
            Set-JobProgressState $progress $job $state
        }
        Write-JobProgress $progress -Finish
        foreach ($state in @('ENCODING','FINALIZING','VALIDATING','PUBLISHING','DONE')) {
            $expected='[2/5] '+$state+' // Band 31102026.mov'
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq $expected }
        }
        Should -Invoke Write-Progress -Times 0 -Exactly
        $progress.Percent | Should -Be 100
    }

    It 'prints failed as failed without a success indicator' {
        $progress=New-EncodeProgress 2 1 1
        $progress.SourceName='failed.mov'
        Set-JobProgressState $progress (New-JobResult 'opaque' 22) 'Failed'
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq '[1/1] FAILED // failed.mov' }
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { $Object -match 'DONE|ready' }
        $progress.Percent | Should -BeLessThan 100
    }

    It 'shows <Status> summary counts, output and available log paths' -TestCases @(
        @{Status='COMPLETE';Outcome='Completed';Code=0},@{Status='ATTENTION';Outcome='Failed';Code=1}
    ) {
        param($Status,$Outcome,$Code)
        $job=New-JobResult 'opaque' 22
        $job.Outcome=$Outcome
        $batch=Get-BatchResult @($job) @() -Requested
        $batch.ExitCode | Should -Be $Code
        Write-TerminalBatchSummary $batch 'D:\Output' ([pscustomobject]@{JsonPath='D:\Logs\results.jsonl'})
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq ('RESULTS  //  '+$Status) }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'OUTPUT   D:\Output' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'LOG      D:\Logs\results.jsonl' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'Found 1 | Done * | Skipped 0 | Failed *' }
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { $Object -match 'ready' }
    }

    It 'omits a nonexistent log location' {
        Write-TerminalBatchSummary (Get-BatchResult @() @()) 'D:\Output' $null
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { $Object -like 'LOG*' }
    }

    It 'restores terminal scope after Quit and after an input failure' {
        $script:TerminalSession=$false
        Mock Read-Host { '4' }
        [void](Run-TUI 'encoder' 'probe' ([pscustomobject]@{OutputDir='D:\Output'}))
        $script:TerminalSession | Should -BeFalse
        Mock Read-Host { throw 'fixture input failure' }
        $run=Run-TUI 'encoder' 'probe' ([pscustomobject]@{OutputDir='D:\Output'})
        $run.ExitCode | Should -Be 2
        $script:TerminalSession | Should -BeFalse
    }

    It 'leaves progress free of terminal headings when terminal scope is disabled' {
        $script:TerminalSession=$false
        $progress=New-EncodeProgress 2 1 1
        $progress.SourceName='clip.mov'
        Write-JobProgress $progress
        Should -Invoke Write-Host -Times 0 -Exactly
        Should -Invoke Write-Progress -Times 1 -Exactly -ParameterFilter { $Activity -eq 'File 1/1 // clip.mov' }
    }
}
