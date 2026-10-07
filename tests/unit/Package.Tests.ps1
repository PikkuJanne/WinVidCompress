BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $RepoRoot 'tests/TestSupport.ps1')
    . (Join-Path $RepoRoot 'tools/package.ps1')
    $script:Owner=New-WvcTestRoot
    $script:Fixture=Join-Path $Owner.Path 'repository [literal] !NAME! &'
    [void][IO.Directory]::CreateDirectory($Fixture)
    $script:Git=(Get-Command git.exe -CommandType Application | Select-Object -First 1).Source
    function Invoke-FixtureGit([string[]]$Arguments) {
        $run=Invoke-WvcTestProcess $Git (@('-C',$Fixture)+$Arguments)
        if ($run.ExitCode -ne 0) { throw ('Fixture Git failed: '+$run.StdErr) }
        $run.StdOut.Trim()
    }
    $seed=Join-Path $Owner.Path 'tracked-source.zip'
    $export=Invoke-WvcTestProcess $Git @('-C',$RepoRoot,'archive','--format=zip',('--output='+$seed),'HEAD')
    if ($export.ExitCode -ne 0) { throw $export.StdErr }
    [IO.Compression.ZipFile]::ExtractToDirectory($seed,$Fixture)
    foreach ($file in @('VERSION','CHANGELOG.md','tools/package.ps1','docs/releases/TESTED_ENVIRONMENT.json')) {
        $target=Join-Path $Fixture $file
        [void][IO.Directory]::CreateDirectory((Split-Path -Parent $target))
        Copy-Item -LiteralPath (Join-Path $RepoRoot $file) -Destination $target -Force
    }
    # Synthetic private-like tracked/untracked data must not leak into artifacts.
    foreach ($file in @('config.json','private.env','synthetic-private.mp4','session.log')) {
        [IO.File]::WriteAllText((Join-Path $Fixture $file),'synthetic private sentinel')
    }
    [void](Invoke-FixtureGit @('init','--quiet'))
    [void](Invoke-FixtureGit @('config','user.name','Package fixture'))
    [void](Invoke-FixtureGit @('config','user.email','fixture@example.invalid'))
    [void](Invoke-FixtureGit @('config','core.autocrlf','false'))
    [void](Invoke-FixtureGit @('remote','add','origin','https://github.com/PikkuJanne/WinVidCompress.git'))
    [void](Invoke-FixtureGit @('add','--all'))
    [void](Invoke-FixtureGit @('commit','--quiet','-m','Owned package fixture'))
    $script:OriginalVersion=[IO.File]::ReadAllBytes((Join-Path $Fixture 'VERSION'))
    function New-TestPackage([string]$Name) {
        $directory=Join-Path $Owner.Path $Name
        [void][IO.Directory]::CreateDirectory($directory)
        New-WvcPackage $Fixture $directory (Invoke-FixtureGit @('rev-parse','HEAD'))
    }
}
AfterAll { if ($Owner) { Remove-WvcTestRoot $Owner } }
Describe 'Tool-only local packaging [WVC-M5-02]' {
    It 'provides the explicit clean-commit package builder [A01 A04]' {
        Test-Path -LiteralPath (Join-Path $RepoRoot 'tools/package.ps1') -PathType Leaf | Should -BeTrue
    }
    It 'loads helpers from a command and runs default-root Build and Verify CLI [A02 A03]' {
        $hostExe=(Get-Process -Id $PID).Path
        $scriptPath=Join-Path $Fixture 'tools/package.ps1'
        $escaped=$scriptPath.Replace("'","''")
        $load=Invoke-WvcTestProcess $hostExe @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-Command',(". '"+$escaped+"'; (Get-WvcPackagePaths).Count"))
        $load.ExitCode | Should -Be 0
        $load.StdOut.Trim() | Should -BeExactly '9'
        $output=Join-Path $Owner.Path 'cli';[void][IO.Directory]::CreateDirectory($output)
        $build=Invoke-WvcTestProcess $hostExe @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$scriptPath,'-OutputDirectory',$output,'-ExpectedCommit',(Invoke-FixtureGit @('rev-parse','HEAD')))
        $build.ExitCode | Should -Be 0
        $result=$build.StdOut | ConvertFrom-Json
        $verify=Invoke-WvcTestProcess $hostExe @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$scriptPath,'-VerifyDirectory',$result.Directory)
        $verify.ExitCode | Should -Be 0
        ($verify.StdOut | ConvertFrom-Json).Passed | Should -BeTrue
    }
    It 'serializes compact UTF8 JSON without host-dependent indentation [A02]' {
        $bytes=ConvertTo-WvcPackageJson ([ordered]@{Version='0.1.0-rc.1';Files=@([ordered]@{Path='LICENSE';Bytes=12})})
        [Text.Encoding]::UTF8.GetString($bytes) | Should -BeExactly ('{"Version":"0.1.0-rc.1","Files":[{"Path":"LICENSE","Bytes":12}]}' + "`n")
    }
    It 'preserves exact runtime bytes, excludes poison files and pins excluded links [A01 A03]' {
        $result=New-TestPackage 'content'
        $check=Test-WvcPackage $result.Directory
        $check.Passed | Should -BeTrue
        $check.Files | Should -Be 11
        $extracted=Join-Path $Owner.Path 'extracted'
        Expand-Archive -LiteralPath (Join-Path $result.Directory 'WinVidCompress-0.1.0-rc.1.zip') -DestinationPath $extracted
        foreach ($file in @('WinVidCompress.ps1','WinVidCompress.bat')) {
            (Get-FileHash -LiteralPath (Join-Path $extracted $file)).Hash | Should -BeExactly (Get-FileHash -LiteralPath (Join-Path $Fixture $file)).Hash
        }
        foreach ($excluded in @('config.json','private.env','synthetic-private.mp4','session.log','.git','tools','tests','docs/codex-winvidcompress')) {
            Test-Path -LiteralPath (Join-Path $extracted $excluded) | Should -BeFalse
        }
        $readme=[IO.File]::ReadAllText((Join-Path $extracted 'README.md'))
        $readme | Should -Match ('https://github.com/PikkuJanne/WinVidCompress/blob/'+$result.SourceCommit+'/docs/benchmarks/README.md')
        $readme | Should -Match '\]\(docs/user/REFERENCE.md\)'
        $manifest=Get-Content -LiteralPath (Join-Path $result.Directory 'manifest.json') -Raw | ConvertFrom-Json
        $manifest.ExcludedSelf | Should -BeExactly 'MANIFEST.json'
        @($manifest.Files).Count | Should -Be 10
        @($manifest.Files | Where-Object Path -eq 'MANIFEST.json').Count | Should -Be 0
        $package=Get-Content -LiteralPath (Join-Path $extracted 'PACKAGE.json') -Raw | ConvertFrom-Json
        $package.RuntimeTestEvidence.ApplicationTestCommit | Should -BeExactly '2c2b45362ab14d18fd3c13635fa1d2f987cabc60'
        $package.DependenciesBundled | Should -BeFalse
    }
    It 'repeats identical manifests and ZIP bytes in one host [A02]' {
        $first=New-TestPackage 'repeat-a';$second=New-TestPackage 'repeat-b'
        $first.SourceCommit | Should -BeExactly $second.SourceCommit
        $first.ZipSHA256 | Should -BeExactly $second.ZipSHA256
        (Get-FileHash -LiteralPath (Join-Path $first.Directory 'manifest.json')).Hash | Should -BeExactly (Get-FileHash -LiteralPath (Join-Path $second.Directory 'manifest.json')).Hash
    }
    It 'refuses existing candidate artifacts without changing their bytes [A01 A04]' {
        $first=New-TestPackage 'no-clobber'
        $zip=Join-Path $first.Directory 'WinVidCompress-0.1.0-rc.1.zip'
        $before=(Get-FileHash -LiteralPath $zip).Hash
        { New-TestPackage 'no-clobber' } | Should -Throw '*already exists*'
        (Get-FileHash -LiteralPath $zip).Hash | Should -BeExactly $before
    }
    It 'refuses wrong HEAD guard and untracked dirty sources before artifacts [A03]' {
        $output=Join-Path $Owner.Path 'refusal';[void][IO.Directory]::CreateDirectory($output)
        { New-WvcPackage $Fixture $output ('a'*40) } | Should -Throw '*ExpectedCommit*'
        $dirty=Join-Path $Fixture 'untracked-private.json'
        try {
            [IO.File]::WriteAllText($dirty,'synthetic private sentinel')
            { New-WvcPackage $Fixture $output '' } | Should -Throw '*clean tracked*'
        } finally { [IO.File]::Delete($dirty) }
        @(Get-ChildItem -LiteralPath $output -Force).Count | Should -Be 0
    }
    It 'refuses invalid tracked version before artifacts [A03]' {
        try {
            [IO.File]::WriteAllText((Join-Path $Fixture 'VERSION'),'../bad')
            [void](Invoke-FixtureGit @('add','VERSION'));[void](Invoke-FixtureGit @('commit','--quiet','-m','Invalid version fixture'))
            { New-TestPackage 'invalid-version' } | Should -Throw '*VERSION*'
            @(Get-ChildItem -LiteralPath (Join-Path $Owner.Path 'invalid-version') -Force).Count | Should -Be 0
        } finally {
            [IO.File]::WriteAllBytes((Join-Path $Fixture 'VERSION'),$OriginalVersion)
            [void](Invoke-FixtureGit @('add','VERSION'));[void](Invoke-FixtureGit @('commit','--quiet','-m','Restore version fixture'))
        }
    }
    It 'refuses missing allowlisted tracked source before artifacts [A01]' {
        $file=Join-Path $Fixture 'CHANGELOG.md';$bytes=[IO.File]::ReadAllBytes($file)
        try {
            [IO.File]::Delete($file);[void](Invoke-FixtureGit @('add','CHANGELOG.md'));[void](Invoke-FixtureGit @('commit','--quiet','-m','Missing source fixture'))
            { New-TestPackage 'missing-source' } | Should -Throw '*Missing/nonregular*'
        } finally {
            [IO.File]::WriteAllBytes($file,$bytes);[void](Invoke-FixtureGit @('add','CHANGELOG.md'));[void](Invoke-FixtureGit @('commit','--quiet','-m','Restore source fixture'))
        }
    }
    It 'refuses nonmatching runtime test provenance before artifacts [A03]' {
        $file=Join-Path $Fixture 'docs/releases/TESTED_ENVIRONMENT.json';$bytes=[IO.File]::ReadAllBytes($file)
        try {
            $text=[Text.Encoding]::UTF8.GetString($bytes).Replace('ead0c7b785a4a6092ce70af8b34097a579e9c6ac31ecaeba2087692c9266476b',('a'*64))
            [IO.File]::WriteAllText($file,$text);[void](Invoke-FixtureGit @('add','docs/releases/TESTED_ENVIRONMENT.json'));[void](Invoke-FixtureGit @('commit','--quiet','-m','Bad runtime provenance fixture'))
            { New-TestPackage 'bad-runtime' } | Should -Throw '*tested-environment*'
        } finally {
            [IO.File]::WriteAllBytes($file,$bytes);[void](Invoke-FixtureGit @('add','docs/releases/TESTED_ENVIRONMENT.json'));[void](Invoke-FixtureGit @('commit','--quiet','-m','Restore runtime fixture'))
        }
    }
    It 'rejects artifact damage at <Kind> [A03]' -TestCases @(@{Kind='zip'},@{Kind='checksum'},@{Kind='manifest'},@{Kind='provenance'}) {
        param($Kind)
        $result=New-TestPackage ('tamper-'+$Kind)
        $file=switch($Kind){'zip'{'WinVidCompress-0.1.0-rc.1.zip'}'checksum'{'WinVidCompress-0.1.0-rc.1.zip.sha256'}'manifest'{'manifest.json'}'provenance'{'build.json'}}
        [IO.File]::AppendAllText((Join-Path $result.Directory $file),'tampered fixture')
        { Test-WvcPackage $result.Directory } | Should -Throw
    }
    It 'retains only owned staging and returns failure after write fault [A01 A04]' {
        Mock Write-WvcPackageBytes { throw 'fixture write fault' }
        $output=Join-Path $Owner.Path 'write-fault';[void][IO.Directory]::CreateDirectory($output)
        { New-WvcPackage $Fixture $output '' } | Should -Throw '*owned staging*fixture write fault*'
        @(Get-ChildItem -LiteralPath $output -Directory -Filter 'WinVidCompress-*').Count | Should -Be 0
        @(Get-ChildItem -LiteralPath $output -Directory -Filter '.wvc-package-*').Count | Should -Be 1
    }
    It 'refuses unapproved origin and in-repository artifact destinations [A04]' {
        $output=Join-Path $Owner.Path 'origin-refusal';[void][IO.Directory]::CreateDirectory($output)
        try {
            [void](Invoke-FixtureGit @('remote','set-url','origin','https://example.invalid/fixture.git'))
            { New-WvcPackage $Fixture $output '' } | Should -Throw '*origin*'
        } finally { [void](Invoke-FixtureGit @('remote','set-url','origin','https://github.com/PikkuJanne/WinVidCompress.git')) }
        { New-WvcPackage $Fixture $Fixture '' } | Should -Throw '*ignored .test-results*'
    }
    It 'rejects escaping or missing local documentation links [A01]' {
        $tree=New-Object 'Collections.Generic.Dictionary[string,object]' ([StringComparer]::Ordinal)
        { Convert-WvcPackageLinks '[bad](../../private.json)' 'README.md' ('a'*40) $tree @('README.md') } | Should -Throw '*escapes*'
        { Convert-WvcPackageLinks '[bad](missing.md)' 'README.md' ('a'*40) $tree @('README.md') } | Should -Throw '*Missing source*'
    }
    It 'refuses linked output directories and preserves absolute drive roots [A01]' {
        $target=Join-Path $Owner.Path 'junction-target';$link=Join-Path $Owner.Path 'junction-output'
        [void][IO.Directory]::CreateDirectory($target)
        try {
            [void](New-Item -ItemType Junction -Path $link -Target $target -ErrorAction Stop)
            { New-WvcPackage $Fixture $link '' } | Should -Throw '*reparse*'
            @(Get-ChildItem -LiteralPath $target -Force).Count | Should -Be 0
        } finally { if (Test-Path -LiteralPath $link) { [IO.Directory]::Delete($link,$false) } }
        $driveRoot=[IO.Path]::GetPathRoot($Owner.Path)
        Assert-WvcPackageDirectory $driveRoot | Should -BeExactly $driveRoot
    }
    It 'uses binary Git blobs and contains no publication/network/dependency commands [A04]' {
        $text=[IO.File]::ReadAllText((Join-Path $RepoRoot 'tools/package.ps1'))
        $text | Should -Match 'StandardOutput.BaseStream.CopyToAsync'
        $text | Should -Not -Match 'git push|gh release|gh pr merge|Invoke-WebRequest|Invoke-RestMethod|Start-BitsTransfer|Save-Module|Install-Module'
        $text | Should -Not -Match 'reset --hard|git clean|Remove-Item.*Recurse|CompressionLevel.*Optimal'
    }
}
