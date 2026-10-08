BeforeAll {
    $RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $ContentRoot=Join-Path $RepoRoot 'website-content'
    $Product=Get-Content -LiteralPath (Join-Path $ContentRoot 'product.json') -Raw | ConvertFrom-Json
    $Schema=Get-Content -LiteralPath (Join-Path $ContentRoot 'product.schema.json') -Raw | ConvertFrom-Json
    $Example=Get-Content -LiteralPath (Join-Path $ContentRoot 'examples/synthetic-default.json') -Raw | ConvertFrom-Json
    . (Join-Path $RepoRoot 'tests/WebsiteContentSupport.ps1')
    function New-PublishedWebsiteFixture {
        $document=$Product | ConvertTo-Json -Depth 12 | ConvertFrom-Json
        $document.status='published'
        $document.published_version='1.0.0'
        $document.release_date='2026-10-08'
        $document.release_url='https://github.com/PikkuJanne/WinVidCompress/releases/tag/v1.0.0'
        $document.download_url='https://github.com/PikkuJanne/WinVidCompress/releases/download/v1.0.0/WinVidCompress-1.0.0.zip'
        $document.sha256='a'*64
        # Structural fixture only; this is not a real capture or published release.
        if (-not @($document.screenshots).Count) {
            $document.screenshots=@([pscustomobject]@{
                file='screenshots/schema-only-fixture.png';sha256=('a'*64);alt='Schema fixture only';
                caption='Schema fixture only, not application evidence';source_commit=$Product.candidate.source_commit;
                capture_method='actual_window_capture';redactions=@()
            })
        }
        return $document
    }
}
Describe 'Static product content [WVC-M5-04]' {
    It 'declares the schema version and explicit draft state [A01]' {
        $Product.schema_version | Should -Be 1
        $Schema.properties.schema_version.const | Should -Be 1
        $Product.status | Should -BeExactly 'draft_not_for_publication'
        $Schema.additionalProperties | Should -BeFalse
        foreach ($property in $Product.PSObject.Properties.Name) { $Schema.properties.PSObject.Properties.Name | Should -Contain $property }
        foreach ($property in $Schema.required) { $Product.PSObject.Properties.Name | Should -Contain $property }
    }
    It 'keeps all public download facts null [A01 A02]' {
        foreach ($field in @('published_version','release_date','release_url','download_url','sha256')) {
            $Product.$field | Should -BeNullOrEmpty
            $Schema.allOf[0].then.properties.$field.type | Should -BeExactly 'null'
            $Schema.allOf[0].else.properties.$field.type | Should -BeExactly 'string'
        }
    }
    It 'binds the unpublished candidate to actual application and launcher bytes [A01]' {
        $Product.candidate.status | Should -BeExactly 'unpublished_candidate'
        $version=@(& git -C $RepoRoot show ($Product.candidate.source_commit+':VERSION'))
        $LASTEXITCODE | Should -Be 0
        $Product.candidate.version | Should -BeExactly ($version -join "`n").Trim()
        $Product.candidate.application_sha256 | Should -BeExactly (Get-FileHash -LiteralPath (Join-Path $RepoRoot 'WinVidCompress.ps1')).Hash.ToLowerInvariant()
        $Product.candidate.launcher_sha256 | Should -BeExactly (Get-FileHash -LiteralPath (Join-Path $RepoRoot 'WinVidCompress.bat')).Hash.ToLowerInvariant()
        $Example.SourceCommit | Should -BeExactly $Product.candidate.source_commit
        $Example.Dirty | Should -BeFalse
    }
    It 'validates release-field state and canonical cross-field versions [A01 A02]' {
        { Assert-WvcWebsiteReleaseFields $Product } | Should -Not -Throw
        $document=New-PublishedWebsiteFixture
        { Assert-WvcWebsiteReleaseFields $document } | Should -Not -Throw
    }
    It 'rejects published version mismatch in <Field> [A01 A02]' -TestCases @(
        @{Field='published_version';Value='2.0.0'},
        @{Field='release_url';Value='https://github.com/PikkuJanne/WinVidCompress/releases/tag/v2.0.0'},
        @{Field='download_url';Value='https://github.com/PikkuJanne/WinVidCompress/releases/download/v2.0.0/WinVidCompress-1.0.0.zip'},
        @{Field='download_url';Value='https://github.com/PikkuJanne/WinVidCompress/releases/download/v1.0.0/WinVidCompress-2.0.0.zip'}
    ) {
        param($Field,$Value)
        $document=New-PublishedWebsiteFixture
        { Assert-WvcWebsiteReleaseFields $document } | Should -Not -Throw
        $document.$Field=$Value
        { Assert-WvcWebsiteReleaseFields $document } | Should -Throw
    }
    It 'rejects impossible date, invalid checksum and false draft release facts [A01 A02]' {
        $document=New-PublishedWebsiteFixture
        $document.release_date='2026-02-30'
        { Assert-WvcWebsiteReleaseFields $document } | Should -Throw
        $document=New-PublishedWebsiteFixture
        $document.sha256='invalid'
        { Assert-WvcWebsiteReleaseFields $document } | Should -Throw
        $document=New-PublishedWebsiteFixture
        $document.sha256=('a'*64)+"`n"
        { Assert-WvcWebsiteReleaseFields $document } | Should -Throw
        $document=New-PublishedWebsiteFixture
        $document.published_version="1.0.0`n"
        { Assert-WvcWebsiteReleaseFields $document } | Should -Throw
        $document=$Product | ConvertTo-Json -Depth 12 | ConvertFrom-Json
        $document.published_version='1.0.0'
        { Assert-WvcWebsiteReleaseFields $document } | Should -Throw
    }
    It 'preserves the reviewed default profile [A02]' {
        $profile=$Product.reviewed_default_profile
        $profile.video | Should -BeExactly 'libx264'
        $profile.preset | Should -BeExactly 'veryfast'
        $profile.crf | Should -Be 22
        $profile.audio | Should -BeExactly 'aac'
        $profile.audio_bitrate | Should -BeExactly '160k'
        $profile.pixel_format | Should -BeExactly 'yuv420p'
        $profile.container | Should -BeExactly 'mp4'
        $profile.faststart | Should -BeTrue
        $profile.oriented_height_cap | Should -Be 1080
        $profile.crop | Should -BeFalse
        $profile.upscale | Should -BeFalse
        $profile.output_layout | Should -BeExactly 'flat'
    }
    It 'uses real source-pinned document links and actual support routes [A02]' {
        $Product.links.source | Should -BeExactly $Product.source_repository
        $Product.links.support | Should -BeExactly ($Product.source_repository+'/issues')
        foreach ($name in @('license','security','changelog','instructions','verification')) {
            $prefix=$Product.source_repository+'/blob/'+$Product.candidate.source_commit+'/'
            $Product.links.$name.StartsWith($prefix) | Should -BeTrue
            $relative=$Product.links.$name.Substring($prefix.Length)
            Test-Path -LiteralPath (Join-Path $RepoRoot $relative) -PathType Leaf | Should -BeTrue
        }
    }
    It 'requires genuine local screenshot references with matching bytes [A03]' {
        @($Product.screenshots).Count | Should -BeGreaterThan 0
        foreach ($capture in $Product.screenshots) {
            $capture.capture_method | Should -BeExactly 'actual_window_capture'
            $capture.source_commit | Should -BeExactly $Product.candidate.source_commit
            $capture.file | Should -Match '^screenshots/[a-z0-9-]+\.png$'
            $path=Join-Path $ContentRoot $capture.file
            Test-Path -LiteralPath $path -PathType Leaf | Should -BeTrue
            (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant() | Should -BeExactly $capture.sha256
            $bytes=[IO.File]::ReadAllBytes($path)
            [BitConverter]::ToString($bytes[0..7]) | Should -BeExactly '89-50-4E-47-0D-0A-1A-0A'
        }
    }
    It 'binds each measured example to an actual local report [A02]' {
        @($Product.measured_examples).Count | Should -BeGreaterThan 0
        foreach ($measurement in $Product.measured_examples) {
            $measurement.file | Should -Match '^examples/[a-z0-9-]+\.json$'
            (Get-FileHash -LiteralPath (Join-Path $ContentRoot $measurement.file)).Hash.ToLowerInvariant() | Should -BeExactly $measurement.sha256
            $measurement.scope | Should -Match 'Synthetic'
            $measurement.scope | Should -Match 'results vary'
        }
    }
    It 'records synthetic provenance and real installed native builds [A02]' {
        $Example.ApplicationSHA256 | Should -BeExactly $Product.candidate.application_sha256
        $Example.Sources[0].Provenance | Should -Match 'Generated testsrc2'
        $Example.Sources[0].RecipeTokens | Should -Contain 'testsrc2=size=320x240:rate=24:duration=4'
        $Example.Sources[0].RecipeTokens | Should -Contain '<OUTPUT>'
        $Example.Sources[0].Codec | Should -BeExactly 'ffv1'
        @($Example.Tools).Count | Should -Be 2
        foreach ($tool in $Example.Tools) { $tool.SHA256 | Should -Match '^[a-f0-9]{64}$'; $tool.Version | Should -Match '2026-10-04-git-a35c879992' }
    }
    It 'recomputes real byte savings for each successful default run [A02]' {
        @($Example.Runs).Count | Should -Be 3
        foreach ($run in $Example.Runs) {
            $run.Outcome | Should -BeExactly 'Completed'
            $run.Experimental | Should -BeFalse
            $run.Settings.CRF | Should -Be 22
            $run.Settings.Preset | Should -BeExactly 'veryfast'
            $run.Size.InputBytes | Should -Be $Example.Sources[0].InputBytes
            $run.Size.OutputBytes | Should -BeGreaterThan 0
            $run.Size.SizeChangeBytes | Should -Be ($run.Size.OutputBytes-$run.Size.InputBytes)
            $savings=100.0*($run.Size.InputBytes-$run.Size.OutputBytes)/$run.Size.InputBytes
            [Math]::Abs($run.Size.SavingsPercent-$savings) | Should -BeLessThan 0.00000001
            $run.ElapsedSeconds | Should -BeGreaterThan 0
        }
    }
    It 'recomputes timing spread without a performance guarantee [A02]' {
        $times=@($Example.Runs.ElapsedSeconds | Sort-Object)
        $Example.Spread[0].ElapsedSeconds.Minimum | Should -Be $times[0]
        $Example.Spread[0].ElapsedSeconds.Median | Should -Be $times[1]
        $Example.Spread[0].ElapsedSeconds.Maximum | Should -Be $times[2]
        $Example.Limitations -join ' ' | Should -Match 'Results vary'
        $Example.Limitations -join ' ' | Should -Match 'not.*representative|do not.*representative'
    }
    It 'does not invent playback, testimonials, or deployment [A02 A04]' {
        foreach ($run in $Example.Runs) { $run.Playback.Status | Should -BeExactly 'NotRun'; $run.FastStartRelocationSeconds | Should -BeNullOrEmpty }
        $Product.PSObject.Properties.Name | Should -Not -Contain 'testimonials'
        $Product.processing_location | Should -BeExactly 'user_device'
        $Product.uploads_supported | Should -BeFalse
        @(Get-ChildItem -LiteralPath $ContentRoot -Recurse -File | Where-Object Extension -in @('.html','.js','.ts','.exe','.dll','.mp4','.mkv')).Count | Should -Be 0
    }
    It 'keeps shared content free of personal paths and credential patterns [A03 A04]' {
        $text=@(Get-ChildItem -LiteralPath $ContentRoot -Recurse -File | Where-Object Extension -ne '.png' | ForEach-Object {Get-Content -LiteralPath $_.FullName -Raw}) -join "`n"
        $text | Should -Not -Match '(?i)[A-Z]:[\\/]Users[\\/]|github_pat_|ghp_[A-Za-z0-9]{20}|-----BEGIN .*PRIVATE KEY|[A-Z]:[\\/]projects[\\/]'
        $text | Should -Not -Match '(?i)guaranteed (reduction|savings|safe)\b|certified safe|verified publisher'
    }
}
if ($PSVersionTable.PSVersion.Major -ge 7) {
    Describe 'Actual JSON schema validation on PowerShell 7 [WVC-M5-04 A01 A02]' {
        It 'validates the actual draft and a structural published fixture' {
            Test-Json -Json ($Product | ConvertTo-Json -Depth 12) -SchemaFile (Join-Path $ContentRoot 'product.schema.json') | Should -BeTrue
            $document=New-PublishedWebsiteFixture
            Test-Json -Json ($document | ConvertTo-Json -Depth 12) -SchemaFile (Join-Path $ContentRoot 'product.schema.json') | Should -BeTrue
        }
        It 'rejects a draft with populated <Field>' -TestCases @(
            @{Field='published_version';Value='1.0.0'},
            @{Field='release_date';Value='2026-10-08'},
            @{Field='release_url';Value='https://github.com/PikkuJanne/WinVidCompress/releases/tag/v1.0.0'},
            @{Field='download_url';Value='https://github.com/PikkuJanne/WinVidCompress/releases/download/v1.0.0/WinVidCompress-1.0.0.zip'},
            @{Field='sha256';Value=('a'*64)}
        ) {
            param($Field,$Value)
            $document=$Product | ConvertTo-Json -Depth 12 | ConvertFrom-Json
            Test-Json -Json ($document | ConvertTo-Json -Depth 12) -SchemaFile (Join-Path $ContentRoot 'product.schema.json') | Should -BeTrue
            $document.$Field=$Value
            Test-Json -Json ($document | ConvertTo-Json -Depth 12) -SchemaFile (Join-Path $ContentRoot 'product.schema.json') -ErrorAction SilentlyContinue | Should -BeFalse
        }
        It 'rejects a published state with missing release facts' {
            $document=$Product | ConvertTo-Json -Depth 12 | ConvertFrom-Json
            $document.status='published'
            Test-Json -Json ($document | ConvertTo-Json -Depth 12) -SchemaFile (Join-Path $ContentRoot 'product.schema.json') -ErrorAction SilentlyContinue | Should -BeFalse
        }
        It 'rejects published content with no screenshot entry' {
            $document=New-PublishedWebsiteFixture
            Test-Json -Json ($document | ConvertTo-Json -Depth 12) -SchemaFile (Join-Path $ContentRoot 'product.schema.json') | Should -BeTrue
            $document.screenshots=@()
            Test-Json -Json ($document | ConvertTo-Json -Depth 12) -SchemaFile (Join-Path $ContentRoot 'product.schema.json') -ErrorAction SilentlyContinue | Should -BeFalse
        }
        It 'rejects unsupported schema and default quality drift' {
            $document=$Product | ConvertTo-Json -Depth 12 | ConvertFrom-Json
            $document.schema_version=2
            Test-Json -Json ($document | ConvertTo-Json -Depth 12) -SchemaFile (Join-Path $ContentRoot 'product.schema.json') -ErrorAction SilentlyContinue | Should -BeFalse
            $document.schema_version=1
            $document.reviewed_default_profile.crf=18
            Test-Json -Json ($document | ConvertTo-Json -Depth 12) -SchemaFile (Join-Path $ContentRoot 'product.schema.json') -ErrorAction SilentlyContinue | Should -BeFalse
        }
        It 'rejects unknown fields and invalid asset paths' {
            $document=$Product | ConvertTo-Json -Depth 12 | ConvertFrom-Json
            $document | Add-Member -NotePropertyName testimonials -NotePropertyValue @('invented fixture')
            Test-Json -Json ($document | ConvertTo-Json -Depth 12) -SchemaFile (Join-Path $ContentRoot 'product.schema.json') -ErrorAction SilentlyContinue | Should -BeFalse
            $document=$Product | ConvertTo-Json -Depth 12 | ConvertFrom-Json
            $document.measured_examples[0].file='../private.json'
            Test-Json -Json ($document | ConvertTo-Json -Depth 12) -SchemaFile (Join-Path $ContentRoot 'product.schema.json') -ErrorAction SilentlyContinue | Should -BeFalse
        }
    }
}
