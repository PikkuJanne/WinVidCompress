param([string]$ModuleRoot)
BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $RepoRoot 'tests/TestSupport.ps1')
    . (Join-Path $RepoRoot 'tests/CiSupport.ps1')
    $script:TestModules=$ModuleRoot
    Add-Type -AssemblyName System.IO.Compression,System.IO.Compression.FileSystem
    function New-CiTestReport {
        [pscustomobject]@{SchemaVersion=1;SourceCommit=('a'*40);Dirty=$false;Status='Passed';ExitCode=0;
            Counts=[pscustomobject]@{Passed=1;Failed=0;Skipped=0;NotRun=0};
            Hosts=@([pscustomobject]@{Version='5.1.26100.9444';Edition='Desktop'});
            Dependencies=[pscustomobject]@{Pester='5.7.1';PSScriptAnalyzer='1.24.0'};
            NativeTools=@([pscustomobject]@{Name='FFmpeg';Version='ffmpeg version fixture-build';Available=$true},[pscustomobject]@{Name='FFprobe';Version='ffprobe version fixture-build';Available=$true});
            Cases=@([pscustomobject]@{Id='fixture';Status='Passed';Reason='private diagnostic'})}
    }
    function New-CiZip([string[]]$Names) {
        $path=Join-Path $TestDrive ([guid]::NewGuid().ToString('N')+'.zip')
        $zip=[IO.Compression.ZipFile]::Open($path,[IO.Compression.ZipArchiveMode]::Create)
        try {foreach($name in $Names){$entry=$zip.CreateEntry($name);$stream=$entry.Open();try{$stream.WriteByte(42)}finally{$stream.Dispose()}}} finally{$zip.Dispose()}
        $path
    }
}
Describe 'Windows CI contract [WVC-M4-04]' {
    It 'provides an unprivileged two-host workflow with pinned actions [A03]' {
        $workflow=[IO.File]::ReadAllText((Join-Path $RepoRoot '.github/workflows/windows-tests.yml'))
        $workflow | Should -Match 'WindowsPowerShell'
        $workflow | Should -Match 'PowerShell7'
        $workflow | Should -Match 'contents: read'
        $workflow | Should -Match 'persist-credentials: false'
        $workflow | Should -Not -Match 'pull_request_target|secrets\.|contents: write|id-token: write'
        @([regex]::Matches($workflow,'uses: [^\r\n@]+@([a-f0-9]{40})')).Count | Should -Be 2
        $workflow | Should -Not -Match 'gh pr merge|git push|gh release|deployment|continue-on-error|secrets:'
        $workflow | Should -Match 'exit \$LASTEXITCODE'
        $workflow | Should -Match 'path: .*summary\.json'
        $workflow | Should -Match 'if-no-files-found: error'
        $workflow | Should -Not -Match 'path: .*\*|include-hidden-files'
        $workflow | Should -Match 'git merge-base HEAD refs/remotes/origin/main'
        $workflow | Should -Not -Match 'git rev-parse HEAD\^'
        $setup=[IO.File]::ReadAllText((Join-Path $RepoRoot 'tools/test-ci-dependencies.ps1'))
        $setup | Should -Match "requested isolated root\.'\)\r?\n\s+exit 0"
    }
    It 'keeps direct dependency pins consistent and digest lengths appropriate [A02 A03]' {
        $pins=Import-PowerShellDataFile (Join-Path $RepoRoot 'tests/CiDependencies.psd1')
        $modules=Import-PowerShellDataFile (Join-Path $RepoRoot 'tests/Dependencies.psd1')
        foreach($pin in $pins.Modules){$pin.Version | Should -BeExactly $modules[$pin.Name]; $pin.Algorithm | Should -BeExactly 'SHA512';$pin.Hash | Should -Match '^[a-f0-9]{128}$';$pin.Url | Should -Match '^https://www\.powershellgallery\.com/api/v2/package/'}
        foreach($pin in @($pins.PowerShell,$pins.FFmpeg)){$pin.Algorithm | Should -BeExactly 'SHA256';$pin.Hash | Should -Match '^[a-f0-9]{64}$';$pin.Url | Should -Match '^https://github\.com/'}
    }
    It 'accepts verified bytes and refuses a modified dependency before extraction [A01]' {
        $file=Join-Path $TestDrive 'archive.zip'; [IO.File]::WriteAllText($file,'owned package sentinel')
        $pin=@{Algorithm='SHA256';Hash=(Get-FileHash -LiteralPath $file).Hash.ToLowerInvariant()}
        {Assert-WvcCiArchive $file $pin} | Should -Not -Throw
        [IO.File]::AppendAllText($file,'changed')
        {Assert-WvcCiArchive $file $pin} | Should -Throw '*digest mismatch*'
    }
    It 'rejects unsafe zip entry <Name> without creating output [A01]' -TestCases @(
        @{Name='../escaped.ps1'},@{Name='C:/absolute.ps1'},@{Name='nested/../escaped.ps1'},@{Name='nested/file:ads'},@{Name='NUL.ps1'},@{Name='trailing /file.ps1'}
    ) {
        param($Name)
        $zip=New-CiZip @($Name);$destination=Join-Path $TestDrive 'never-extracted'
        {Assert-WvcCiZipPaths $zip $destination} | Should -Throw '*Unsafe archive entry*'
        Test-Path -LiteralPath $destination | Should -BeFalse
    }
    It 'accepts normal module zip entries and rejects case aliases [A01]' {
        {Assert-WvcCiZipPaths (New-CiZip @('Pester.psd1','bin/module.dll')) (Join-Path $TestDrive 'normal')} | Should -Not -Throw
        {Assert-WvcCiZipPaths (New-CiZip @('module.ps1','MODULE.ps1')) (Join-Path $TestDrive 'aliases')} | Should -Throw '*aliases*'
    }
    It 'requires a full available static base rather than accepting a shell expression [A01]' {
        {Get-WvcCiChangedPaths $RepoRoot 'HEAD; Write-Host private'} | Should -Throw '*full commit SHA*'
        {Get-WvcCiChangedPaths $RepoRoot ('0'*40)} | Should -Throw '*not available locally*'
    }
    It 'accepts complete current-source results and emits ordinal sanitized cases [A01 A02]' {
        $report=New-CiTestReport
        $summary=ConvertTo-WvcCiSummary $report 0 ('a'*40) WindowsPowerShell ([pscustomobject]@{SchemaVersion=1;Passed=$true;DiagnosticCount=0;AnalyzedFiles=1})
        $summary.ExitCode | Should -Be 0; $summary.Status | Should -BeExactly 'Passed'
        $summary.Cases[0].Id | Should -BeExactly 'case-0001'
        ($summary | ConvertTo-Json -Depth 8) | Should -Not -Match 'private diagnostic|fixture"|Reason'
    }
    It 'rejects source/dirty/count corruption for <Fault> [A01]' -TestCases @(@{Fault='source'},@{Fault='dirty'},@{Fault='counts'}) {
        param($Fault)
        $report=New-CiTestReport
        switch($Fault){'source'{$report.SourceCommit='b'*40};'dirty'{$report.Dirty=$true};'counts'{$report.Counts.Passed=9}}
        {ConvertTo-WvcCiSummary $report 0 ('a'*40) WindowsPowerShell ([pscustomobject]@{SchemaVersion=1;Passed=$true;DiagnosticCount=0;AnalyzedFiles=1})} | Should -Throw
    }
    It 'fails the CI gate for <Fault> even when a producer claims success [A01]' -TestCases @(
        @{Fault='failed test'},@{Fault='skipped test'},@{Fault='not run test'},@{Fault='native exit'},@{Fault='wrong host'},@{Fault='missing native'},@{Fault='static failure'},@{Fault='wrong module'}
    ) {
        param($Fault)
        $report=New-CiTestReport; $exitCode=0; $static=[pscustomobject]@{SchemaVersion=1;Passed=$true;DiagnosticCount=0;AnalyzedFiles=1}
        switch($Fault){
            'failed test'{$report.Cases[0].Status='Failed';$report.Counts.Passed=0;$report.Counts.Failed=1}
            'skipped test'{$report.Cases[0].Status='Skipped';$report.Counts.Passed=0;$report.Counts.Skipped=1}
            'not run test'{$report.Cases[0].Status='NotRun';$report.Counts.Passed=0;$report.Counts.NotRun=1}
            'native exit'{$exitCode=1}
            'wrong host'{$report.Hosts[0].Version='7.6.6';$report.Hosts[0].Edition='Core'}
            'missing native'{$report.NativeTools[0].Available=$false}
            'static failure'{$static.Passed=$false;$static.DiagnosticCount=1}
            'wrong module'{$report.Dependencies.Pester='0.0.1'}
        }
        (ConvertTo-WvcCiSummary $report $exitCode ('a'*40) WindowsPowerShell $static).ExitCode | Should -Be 1
    }
    It 'drops private names/reasons/fixtures/paths and emits only validated version tokens [A02]' {
        $report=New-CiTestReport
        $secret='C:\private-media\owner-secret.mov'
        $report.Cases[0].Id=$secret; $report.Cases[0].Reason=$secret
        $report | Add-Member NoteProperty Fixtures ([pscustomobject]@{Path=$secret})
        $report | Add-Member NoteProperty StdErr $secret
        $report.NativeTools[0].Version+=' '+$secret
        $json=ConvertTo-WvcCiSummary $report 0 ('a'*40) WindowsPowerShell ([pscustomobject]@{SchemaVersion=1;Passed=$true;DiagnosticCount=0;AnalyzedFiles=1}) | ConvertTo-Json -Depth 8
        $json | Should -Not -Match 'private-media|owner-secret|Fixtures|StdErr|Path|Reason'
        $json | Should -Match 'fixture-build'
    }
    It 'returns nonzero from a real analyzer subprocess for a selected safety-rule violation [A01]' {
        $fixture=Join-Path $TestDrive 'unsafe.ps1'; [IO.File]::WriteAllText($fixture,'Invoke-Expression $untrusted')
        $reportPath=Join-Path $TestDrive 'analysis.json'
        $result=Invoke-WvcTestProcess (Get-Process -Id $PID).Path @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
            (Join-Path $RepoRoot 'tools/test-static.ps1'),'-ModuleRoot',$TestModules,'-Paths',$fixture,'-ReportPath',$reportPath)
        $result.ExitCode | Should -Be 1
        $report=Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
        $report.Passed | Should -BeFalse; $report.DiagnosticCount | Should -BeGreaterThan 0
        $result.StdOut | Should -Not -Match 'untrusted|unsafe.ps1'
    }
    It 'refuses an existing CI report directory without changing its sentinel [A01]' {
        $directory=Join-Path $TestDrive 'existing'; [void][IO.Directory]::CreateDirectory($directory)
        $sentinel=Join-Path $directory 'summary.json'; [IO.File]::WriteAllText($sentinel,'existing final sentinel')
        $hash=(Get-FileHash -LiteralPath $sentinel).Hash
        $result=Invoke-WvcTestProcess (Get-Process -Id $PID).Path @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
            (Join-Path $RepoRoot 'tools/test-ci.ps1'),'-HostName','WindowsPowerShell','-ModuleRoot',$TestModules,'-NativeDirectory',$TestDrive,'-BaseCommit',('a'*40),'-ResultDirectory',$directory)
        $result.ExitCode | Should -Be 1
        (Get-FileHash -LiteralPath $sentinel).Hash | Should -BeExactly $hash
        @(Get-ChildItem -LiteralPath $directory -Force).Count | Should -Be 1
    }
}
