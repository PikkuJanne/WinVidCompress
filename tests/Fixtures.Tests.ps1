BeforeAll {
    . (Join-Path $PSScriptRoot 'New-Fixtures.ps1')
    $script:Inventory = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/inventory.json') -Raw | ConvertFrom-Json
}

Describe 'Synthetic fixture inventory' {
    It 'maps every fixture to a relative file, capabilities, recipe, expected streams and cleanup owner' {
        $script:Inventory.SchemaVersion | Should -Be 1
        $items = @($script:Inventory.Items)
        $items.Count | Should -Be 12
        @($items.Id | Select-Object -Unique).Count | Should -Be $items.Count
        @($items.File | Select-Object -Unique).Count | Should -Be $items.Count
        foreach ($item in $items) {
            [IO.Path]::GetFileName($item.File) | Should -Be $item.File
            $item.Arguments | Should -Contain '{output}'
            $item.Capabilities.Count | Should -BeGreaterThan 0
            $item.CleanupOwner | Should -Match 'Remove-WvcTestRoot'
            $item.PSObject.Properties['ExpectedStreams'] | Should -Not -BeNullOrEmpty
            $item.Provenance | Should -Match 'synthetic'
        }
    }

    It 'keeps all media recipes one second long, synthetic, mapped and no-clobber' {
        foreach ($item in @($script:Inventory.Items | Where-Object Kind -eq 'Media')) {
            $item.Arguments | Should -Contain '-n'
            $item.Arguments | Should -Contain '-nostdin'
            $item.Arguments | Should -Contain 'lavfi'
            $item.Arguments | Should -Contain '-map'
            $durationIndex = [array]::IndexOf($item.Arguments, '-t')
            $item.Arguments[$durationIndex + 1] | Should -Be '1'
            $item.Requires | Should -Contain 'ffprobe'
            $item.ExpectedStreams.Count | Should -BeGreaterThan 0
        }
    }

    It 'records missing native tools as four skips and copies eight JSON cases' {
        $owner = New-WvcTestRoot
        try {
            $result = New-WvcFixtures $owner $null $null
            @($result.Items | Where-Object Status -eq 'Skipped').Count | Should -Be 4
            @($result.Items | Where-Object Status -eq 'Passed').Count | Should -Be 8
            @($result.Items | Where-Object Status -eq 'Failed').Count | Should -Be 0
            foreach ($item in @($result.Items | Where-Object Kind -eq 'Media')) {
                $item.Generated | Should -BeFalse
                Test-Path -LiteralPath (Join-Path (Join-Path $owner.Path 'fixtures') $item.File) | Should -BeFalse
            }
            foreach ($item in @($result.Items | Where-Object Kind -eq 'ProbeJson')) {
                $source = Join-Path (Join-Path $PSScriptRoot 'fixtures') $item.Source
                $copied = Join-Path (Join-Path $owner.Path 'fixtures') $item.File
                (Get-FileHash -LiteralPath $copied).Hash | Should -Be (Get-FileHash -LiteralPath $source).Hash
            }
            { New-WvcFixtures $owner $null $null } | Should -Throw '*refusing reuse*'
        } finally { Remove-WvcTestRoot $owner }
    }

    It 'treats native generation errors as failures and preserves stderr instead of skipping them' {
        $owner = New-WvcTestRoot
        Mock Invoke-WvcTestProcess { [pscustomobject]@{ ExitCode = 9; StdOut = ''; StdErr = 'synthetic encoder error' } }
        try {
            $result = New-WvcFixtures $owner 'synthetic-ffmpeg-double' 'synthetic-ffprobe-double'
            @($result.Items | Where-Object Status -eq 'Failed').Count | Should -Be 4
            @($result.Items | Where-Object Status -eq 'Skipped').Count | Should -Be 0
            Get-Content -LiteralPath (Join-Path $owner.Path 'fixtures/silent.stderr.log') -Raw | Should -Match 'synthetic encoder error'
        } finally { Remove-WvcTestRoot $owner }
    }

    It 'fails zero-exit generation that produces no media output' {
        $owner = New-WvcTestRoot
        Mock Invoke-WvcTestProcess { [pscustomobject]@{ ExitCode = 0; StdOut = ''; StdErr = '' } }
        try {
            $result = New-WvcFixtures $owner 'synthetic-ffmpeg-double' 'synthetic-ffprobe-double'
            @($result.Items | Where-Object Status -eq 'Failed').Count | Should -Be 4
        } finally { Remove-WvcTestRoot $owner }
    }

    It 'preserves malformed and wrong-shaped responses as parser fixtures' {
        $malformed = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/probe/malformed.json') -Raw
        { $malformed | ConvertFrom-Json } | Should -Throw
        $wrong = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/probe/wrong-shape.json') -Raw | ConvertFrom-Json
        $wrong.streams | Should -BeOfType [string]
    }

    It 'keeps every valid synthetic probe stream array consistent with its inventory' {
        foreach ($item in @($script:Inventory.Items | Where-Object { $_.Kind -eq 'ProbeJson' -and -not $_.InvalidResponse })) {
            $probe = Get-Content -LiteralPath (Join-Path (Join-Path $PSScriptRoot 'fixtures') $item.Source) -Raw | ConvertFrom-Json
            ($probe.streams | ConvertTo-Json -Depth 20 -Compress) | Should -Be ($item.ExpectedStreams | ConvertTo-Json -Depth 20 -Compress)
        }
    }

    It 'rejects non-finite or out-of-range observed media durations' -TestCases @(
        @{ Duration = 'NaN' }, @{ Duration = 'Infinity' }, @{ Duration = '-Infinity' }, @{ Duration = '0' }, @{ Duration = '5' }
    ) {
        param($Duration)
        $definition = $script:Inventory.Items | Where-Object Id -eq 'silent'
        $probe = [pscustomobject]@{ streams = $definition.ExpectedStreams; format = [pscustomobject]@{ duration = $Duration } }
        { Assert-WvcFixtureProbe $probe $definition } | Should -Throw '*duration*'
    }

    It 'rejects unexpected probe streams instead of treating exit zero as fixture success' {
        $definition = $script:Inventory.Items | Where-Object Id -eq 'silent'
        $probe = [pscustomobject]@{ streams = @(); format = [pscustomobject]@{ duration = '1.0' } }
        { Assert-WvcFixtureProbe $probe $definition } | Should -Throw '*stream count*'
    }

    It 'labels rare probe data as synthetic and includes geometry, HDR and unknown duration cases' {
        $ids = @($script:Inventory.Items | Where-Object Kind -eq 'ProbeJson' | Select-Object -ExpandProperty Id)
        foreach ($id in @('attached-picture','display-geometry','hdr-pq','hdr-hlg','ten-bit-sdr','unknown-duration')) {
            $ids | Should -Contain $id
        }
        $rotation = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/probe/display-geometry.json') -Raw | ConvertFrom-Json
        $rotation.streams[0].side_data_list[0].rotation | Should -Be 90
        $rotation.streams[0].sample_aspect_ratio | Should -Be '16:15'
        $unknown = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'fixtures/probe/unknown-duration.json') -Raw | ConvertFrom-Json
        $unknown.format.PSObject.Properties['duration'] | Should -BeNullOrEmpty
    }
}
