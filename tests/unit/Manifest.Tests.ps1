BeforeAll {
    $script:OldAppData=$env:APPDATA; $env:APPDATA=Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
}
AfterAll { $env:APPDATA=$OldAppData }
Describe 'Bounded owned manifest schema and persistence [WVC-M3-07]' {
    BeforeEach {
        $script:Root=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Output=Join-Path $Root 'out'; [void][IO.Directory]::CreateDirectory($Output)
        $script:Source=Join-Path $Root 'a.mov'; [IO.File]::WriteAllText($Source,'source sentinel')
        $script:Manifest=Join-Path $Root 'batch.json'
        $script:Context=Open-BatchManifest $Manifest $Output @($Source)
        $script:OriginalBytes=[IO.File]::ReadAllText($Manifest)
    }
    AfterEach { $Context.Lock.Dispose() }
    It 'persists canonical identity and Unstarted state before any native job [A02]' {
        $record=$OriginalBytes | ConvertFrom-Json
        $record.Owner | Should -BeExactly 'WinVidCompress.Batch'
        $record.Jobs[0].State | Should -BeExactly 'Unstarted'
        $record.Jobs[0].SourceIdentity.Length | Should -Be 15
        $record.Jobs[0].SourcePath | Should -BeExactly $Source
    }
    It 'rejects <Kind> before updating an existing manifest [A01 A04]' -TestCases @(
        @{Kind='schema'},@{Kind='owner'},@{Kind='owner type'},@{Kind='batch ID'},@{Kind='manifest path'},@{Kind='output root'},
        @{Kind='unknown field'},@{Kind='jobs type'},@{Kind='source traversal'},@{Kind='source outside queue'},
        @{Kind='identity source path'},@{Kind='identity path type'},@{Kind='identity size'},@{Kind='identity ticks'},@{Kind='hash'},@{Kind='state'},@{Kind='job ID'},@{Kind='settings type'},
        @{Kind='foreign output'},@{Kind='output traversal'},@{Kind='unfinished output'}
    ) {
        param($Kind)
        $m=$Context.Manifest; $entry=$m.Jobs[0]
        switch ($Kind) {
            'schema' {$m.SchemaVersion='1'}
            'owner' {$m.Owner='Foreign'}
            'owner type' {$m.Owner=@('WinVidCompress.Batch')}
            'batch ID' {$m.BatchId='invalid'}
            'manifest path' {$m.ManifestPath=Join-Path $Root 'foreign.json'}
            'output root' {$m.OutputDirectory=$Root}
            'unknown field' {$m | Add-Member Commands 'Remove-Item source'}
            'jobs type' {$m.Jobs=$entry}
            'source traversal' {$entry.SourcePath=Join-Path $Root 'out/../a.mov'}
            'source outside queue' {$entry.SourcePath=Join-Path $Root 'outside.mov'}
            'identity source path' {$entry.SourceIdentity.Path=Join-Path $Root 'foreign.mov'; $entry.SourceIdentity.Length=[int]15}
            'identity path type' {$entry.SourceIdentity.Path=1; $entry.SourceIdentity.Length=[int]15}
            'identity size' {$entry.SourceIdentity.Length=1.5}
            'identity ticks' {$entry.SourceIdentity.LastWriteUtcTicks='bad'}
            'hash' {$entry.SourceIdentity.SHA256='0'*64}
            'state' {$entry.State='Execute'}
            'job ID' {$entry.JobId='invalid'}
            'settings type' {$entry.SettingsFingerprint=1}
            'foreign output' {$entry.State='Completed'; $entry.OutputIdentity=[pscustomobject]@{Path=(Join-Path $Root 'foreign.mp4')}}
            'output traversal' {$entry.State='Completed'; $entry.OutputIdentity=[pscustomobject]@{Path=(Join-Path $Output '../a.mp4')}}
            'unfinished output' {$entry.OutputIdentity=[pscustomobject]@{Path=(Join-Path $Output 'a.mp4')}}
        }
        { Save-BatchManifest $Context } | Should -Throw
        [IO.File]::ReadAllText($Manifest) | Should -BeExactly $OriginalBytes
        [IO.File]::ReadAllText($Source) | Should -BeExactly 'source sentinel'
    }
    It 'rejects duplicate job identities and a reordered or expanded queue [A04]' {
        $second=Join-Path $Root 'b.mov'; [IO.File]::WriteAllText($second,'second')
        $entry=$Context.Manifest.Jobs[0] | ConvertTo-Json -Depth 5 | ConvertFrom-Json
        $entry.SourcePath=$second; $entry.SourceIdentity=Get-ManifestIdentity $second
        $Context.Manifest.Jobs+=@($entry); $Context.Sources+=@($second)
        { Save-BatchManifest $Context } | Should -Throw '*identity*'
        $entry.JobId=[guid]::NewGuid().ToString('N')
        { Assert-BatchManifest $Context.Manifest $Manifest $Output @($second,$Source) } | Should -Throw
    }
    It 'rejects lock contention before admitting a second writer [A04]' {
        { Open-BatchManifest $Manifest $Output @($Source) -Resume } | Should -Throw
        [IO.File]::ReadAllText($Manifest) | Should -BeExactly $OriginalBytes
    }
    It 'preserves the prior manifest bytes when atomic replacement fails [A02 A04]' {
        Mock Publish-BatchManifestFile { throw 'injected atomic replace failure' }
        $Context.Manifest.Jobs[0].State='Running'
        { Save-BatchManifest $Context } | Should -Throw '*injected*'
        [IO.File]::ReadAllText($Manifest) | Should -BeExactly $OriginalBytes
        @(Get-ChildItem -LiteralPath $Root -Filter '*.tmp').Count | Should -Be 1
    }
    It 'refuses outside-lock edits rather than replacing them [A04]' {
        [IO.File]::WriteAllText($Manifest,'foreign edit sentinel')
        { Save-BatchManifest $Context } | Should -Throw '*changed*'
        [IO.File]::ReadAllText($Manifest) | Should -BeExactly 'foreign edit sentinel'
    }
    It 'rejects existing foreign JSON and one-element root arrays [A04]' {
        $Context.Lock.Dispose()
        foreach ($text in @('{"Owner":"foreign"}',('['+$OriginalBytes+']'),'null','"text"','{broken')) {
            [IO.File]::WriteAllText($Manifest,$text)
            { Open-BatchManifest $Manifest $Output @($Source) -Resume } | Should -Throw
            [IO.File]::ReadAllText($Manifest) | Should -BeExactly $text
        }
    }
    It 'bounds file size before JSON parsing [A04]' {
        $Context.Lock.Dispose(); [IO.File]::WriteAllText($Manifest,(' '*4194305))
        { Open-BatchManifest $Manifest $Output @($Source) -Resume } | Should -Throw '*4 MiB*'
    }
    It 'bounds outside-lock edits before uncancellable checkpoint hashing [A04]' {
        [IO.File]::WriteAllText($Manifest,(' '*4194305))
        { Save-BatchManifest $Context } | Should -Throw '*4 MiB*'
        (Get-Item -LiteralPath $Manifest).Length | Should -Be 4194305
    }
    It 'refuses reparse-point manifest paths [A04]' {
        $link=Join-Path $Root 'link'; New-Item -ItemType Junction -Path $link -Target $Output | Out-Null
        { Get-ManifestPath (Join-Path $link 'batch.json') } | Should -Throw '*reparse*'
    }
    It 'requires canonical local paths, rejecting <Value> [A04]' -TestCases @(
        @{Value='relative.json'},@{Value='C:batch.json'},@{Value='C:\a\..\batch.json'},
        @{Value='C:\batch.json:stream'},@{Value='FileSystem::C:\batch.json'},@{Value='\\server\share\batch.json'},
        @{Value='C:\.wvc-job-0123456789abcdef0123456789abcdef\batch.json'}
    ) { param($Value); { Get-ManifestPath $Value } | Should -Throw }
    It 'fingerprints current CRF without changing the default profile [A01]' {
        (Get-ManifestSettingsFingerprint 22) | Should -BeExactly (Get-ManifestSettingsFingerprint 22)
        (Get-ManifestSettingsFingerprint 23) | Should -Not -BeExactly (Get-ManifestSettingsFingerprint 22)
        $DefaultCRF | Should -Be 22
    }
    It 'discloses fast same-size/time limitation and detects it with stored hash [A03]' {
        $fast=Get-ManifestIdentity $Source; $strong=Get-ManifestIdentity $Source -Hash
        $time=[IO.File]::GetLastWriteTimeUtc($Source)
        [IO.File]::WriteAllText($Source,'source SENTINEL'); [IO.File]::SetLastWriteTimeUtc($Source,$time)
        (Test-ManifestIdentity $fast (Get-ManifestIdentity $Source)) | Should -BeTrue
        (Test-ManifestIdentity $strong (Get-ManifestIdentity $Source -Hash)) | Should -BeFalse
    }
}
