BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:SavedAppData=$env:APPDATA
    $env:APPDATA=Join-Path $TestDrive 'appdata'
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
}
AfterAll { $env:APPDATA=$SavedAppData }
Describe 'Per-run CLI and read-only preview [WVC-M4-01]' {
    BeforeEach {
        $script:Root=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Output=Join-Path $Root 'output'; $script:Sources=Join-Path $Root 'sources'
        [void][IO.Directory]::CreateDirectory($Output); [void][IO.Directory]::CreateDirectory($Sources)
        $script:Source=Join-Path $Sources 'a.mov'; [IO.File]::WriteAllText($Source,'source sentinel')
        $ConfigDir=Join-Path $Root 'appdata/WinVidCompress'; $ConfigPath=Join-Path $ConfigDir 'config.json'
        $DefaultCRF=22; $CollisionMode='rename'
        Mock Get-DefaultOutputDir { $Output }
        Mock Write-Host {}
        Mock Read-Host { throw 'Unexpected prompt' }
    }
    It 'previews before every writing or native boundary [A02 A04]' {
        foreach ($name in @('Load-Config','Get-OutputEnvironment','New-SessionLog','Process-Paths','Open-BatchManifest','Ensure-Tool')) {
            Mock $name { throw 'Forbidden preview boundary' }
        }
        $run=Invoke-WinVidCompress -Paths @($Source) -WhatIf
        $run.ExitCode | Should -Be 0
        $run.Preview | Should -BeTrue
        $run.Plans.Count | Should -Be 1
        $run.Plans[0].Action | Should -BeExactly 'WouldEncode'
        foreach ($name in @('Load-Config','Get-OutputEnvironment','New-SessionLog','Process-Paths','Open-BatchManifest','Ensure-Tool','Read-Host')) {
            Should -Invoke $name -Times 0 -Exactly
        }
        Test-Path -LiteralPath $ConfigDir | Should -BeFalse
    }
    It 'merges defaults, optional saved mode and explicit options without mutating preferences [A01 A03]' {
        $cfg=[pscustomobject]@{OutputDir=$Output;Future='preserve'}
        (Resolve-RunConfiguration $cfg @{}).CollisionMode | Should -BeExactly 'rename'
        $cfg | Add-Member -NotePropertyName CollisionMode -NotePropertyValue skip
        (Resolve-RunConfiguration $cfg @{}).CollisionMode | Should -BeExactly 'skip'
        $other=Join-Path $Root 'other'
        $effective=Resolve-RunConfiguration $cfg @{OutputDir=$other;CollisionMode='rename'}
        $effective.Config.OutputDir | Should -BeExactly $other
        $effective.CollisionMode | Should -BeExactly 'rename'
        $effective.Config.Future | Should -BeExactly 'preserve'
        $cfg.OutputDir | Should -BeExactly $Output
        $cfg.CollisionMode | Should -BeExactly 'skip'
    }
    It 'rejects invalid supplied <Case> before native or writable startup [A03]' -TestCases @(
        @{Case='empty output';Options=@{OutputDir=''}},
        @{Case='relative output';Options=@{OutputDir='relative'}},
        @{Case='provider output';Options=@{OutputDir='HKCU:\Software'}},
        @{Case='wildcard output';Options=@{OutputDir='C:\bad*'}},
        @{Case='empty mode';Options=@{CollisionMode=''}},
        @{Case='invalid mode';Options=@{CollisionMode='overwrite'}},
        @{Case='doctor preview';Options=@{WhatIf=$true;CheckEnvironment=$true}},
        @{Case='manifest preview';Options=@{WhatIf=$true;ManifestPath='C:\batch.json'}},
        @{Case='resume preview';Options=@{WhatIf=$true;Resume=$true}},
        @{Case='hash preview';Options=@{WhatIf=$true;StrongSourceHash=$true}},
        @{Case='doctor mode';Options=@{CheckEnvironment=$true;CollisionMode='skip'}}
    ) {
        param($Case,$Options)
        Mock Ensure-Tool { throw 'Unexpected native startup' }; Mock Load-Config { throw 'Unexpected config write' }
        $run=Invoke-WinVidCompress -Paths @($Source) @Options
        $run.ExitCode | Should -Be 2
        Should -Invoke Ensure-Tool -Times 0 -Exactly
        Should -Invoke Load-Config -Times 0 -Exactly
        Should -Invoke Read-Host -Times 0 -Exactly
    }
    It 'rejects invalid configured CRF <Value> before conversion [A03]' -TestCases @(@{Value=-1},@{Value=52}) {
        param($Value)
        $DefaultCRF=$Value; Mock Ensure-Tool { throw 'Unexpected native startup' }
        (Invoke-WinVidCompress -Paths @($Source) -WhatIf).ExitCode | Should -Be 2
        Should -Invoke Ensure-Tool -Times 0 -Exactly
    }
    It 'requires explicit input for <Case> without opening menu [A04]' -TestCases @(
        @{Case='preview';Options=@{WhatIf=$true}},
        @{Case='output override';Options=@{OutputDir='C:\existing'}},
        @{Case='mode override';Options=@{CollisionMode='skip'}}
    ) {
        param($Case,$Options)
        Mock Ensure-Tool { throw 'Unexpected startup' }; Mock Run-TUI { throw 'Unexpected menu' }
        (Invoke-WinVidCompress @Options).ExitCode | Should -Be 2
        Should -Invoke Ensure-Tool -Times 0 -Exactly
        Should -Invoke Run-TUI -Times 0 -Exactly
    }
    It 'plans disk and prior planned basename collisions under <Mode> [A02]' -TestCases @(
        @{Mode='rename';Actions='WouldEncode,WouldEncode';Names='a (compressed).mp4,a (compressed 2).mp4'},
        @{Mode='skip';Actions='WouldSkip,WouldSkip';Names='a.mp4,a.mp4'}
    ) {
        param($Mode,$Actions,$Names)
        $other=Join-Path $Sources 'other'; [void][IO.Directory]::CreateDirectory($other)
        [IO.File]::WriteAllText((Join-Path $other 'a.mov'),'second source')
        [IO.File]::WriteAllText((Join-Path $Output 'a.mp4'),'existing final')
        $run=Invoke-WinVidCompress -Paths @($Sources,$Source) -WhatIf -CollisionMode $Mode
        $run.ExitCode | Should -Be 0
        ($run.Plans.Action -join ',') | Should -BeExactly $Actions
        (($run.Plans | ForEach-Object { [IO.Path]::GetFileName($_.OutputPath) }) -join ',') | Should -BeExactly $Names
        $run.PSObject.Properties.Name | Should -Not -Contain 'Jobs'
        $run.PSObject.Properties.Name | Should -Not -Contain 'Counters'
    }
    It 'plans a source-equal nominal name with safe rename [A02]' {
        $source=Join-Path $Output 'a.mp4'; [IO.File]::WriteAllText($source,'original mp4 sentinel')
        $run=Invoke-WinVidCompress -Paths @($source) -WhatIf
        $run.Plans[0].OutputPath | Should -BeExactly (Join-Path $Output 'a (compressed).mp4')
    }
    It 'supports a dash-leading relative filename with explicit filesystem prefix [A01 A03]' {
        $source=Join-Path $Sources '-a.mov'; [IO.File]::WriteAllText($source,'literal source sentinel')
        $before=Get-Location
        try {
            Set-Location -LiteralPath $Sources
            $run=Invoke-WinVidCompress -Paths @('.\-a.mov') -WhatIf
            $run.ExitCode | Should -Be 0
            $run.Plans[0].SourcePath | Should -BeExactly $source
        } finally { Set-Location -LiteralPath $before.Path }
    }
    It 'reports empty and partly invalid scans without conversion [A02]' {
        (Invoke-WinVidCompress -Paths @((Join-Path $Root 'missing')) -WhatIf).ExitCode | Should -Be 2
        $run=Invoke-WinVidCompress -Paths @($Source,(Join-Path $Root 'missing')) -WhatIf
        $run.ExitCode | Should -Be 1; $run.Plans.Count | Should -Be 1; $run.ScanErrors.Count | Should -Be 1
    }
    It 'validates optional saved CollisionMode without losing unknown config keys [A03]' {
        { ConvertFrom-ConfigText ([pscustomobject]@{OutputDir=$Output;CollisionMode='overwrite'} | ConvertTo-Json) } | Should -Throw '*CollisionMode*'
        $cfg=ConvertFrom-ConfigText ([pscustomobject]@{OutputDir=$Output;CollisionMode='skip';Future='keep'} | ConvertTo-Json)
        $cfg.Future | Should -BeExactly 'keep'
    }
    It 'keeps no-option menu startup on its existing config route [A01]' {
        Mock Ensure-Tool { 'fixture.exe' }; Mock Get-ToolEnvironment { [pscustomobject]@{} }
        Mock Load-Config { [pscustomobject]@{OutputDir=$Output} }
        Mock Get-EnvironmentConfig { throw 'Unexpected read-only override route' }
        Mock Get-OutputEnvironment { [pscustomobject]@{} }; Mock Write-EnvironmentReport {}
        Mock New-SessionLog { $null }; Mock Run-TUI { Get-SessionResult @() }
        $run=Invoke-WinVidCompress
        $run.ExitCode | Should -Be 0
        Should -Invoke Load-Config -Times 1 -Exactly
        Should -Invoke Run-TUI -Times 1 -Exactly
        $DefaultCRF | Should -Be 22; $CollisionMode | Should -BeExactly 'rename'
    }
}
