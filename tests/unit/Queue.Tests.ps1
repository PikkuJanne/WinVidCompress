BeforeAll {
    $script:OriginalAppData = $env:APPDATA
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
    $script:RealScan = ${function:Get-InputScan}
}

AfterAll { $env:APPDATA = $script:OriginalAppData }

Describe 'Frozen sequential batch [WVC-M1-05]' {
    BeforeEach {
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Nested = Join-Path $script:Root 'nested'
        $script:Output = Join-Path $script:Root 'output'
        foreach ($directory in @($script:Root,$script:Nested,$script:Output)) {
            [void][IO.Directory]::CreateDirectory($directory)
        }
        $script:First = Join-Path $script:Root 'a.mov'
        $script:Second = Join-Path $script:Nested 'b.mp4'
        [IO.File]::WriteAllText($script:First, 'first source sentinel')
        [IO.File]::WriteAllText($script:Second, 'second source sentinel')
        $script:Encoded = New-Object 'Collections.Generic.List[string]'
        Mock Write-Host {}
        Mock Compress-One { $script:Encoded.Add($inPath) }
    }

    It 'encodes each source once for <Selection> [A01]' -TestCases @(
        @{ Selection = 'file plus parent' }, @{ Selection = 'parent plus child' },
        @{ Selection = 'repeated files and roots' }
    ) {
        param($Selection)
        $paths = switch ($Selection) {
            'file plus parent' { @($script:First,$script:Root) }
            'parent plus child' { @($script:Root,$script:Nested) }
            'repeated files and roots' { @($script:Root,$script:Second,$script:Root,$script:Nested,$script:Second) }
        }
        Process-Paths $paths 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Output })
        $script:Encoded.Count | Should -Be 2
        ($script:Encoded -join '|') | Should -Be (@($script:First,$script:Second) -join '|')
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Found:   2' }
    }

    It 'deduplicates case, relative, dot, provider, PSDrive and extended aliases [A01]' {
        Push-Location $script:Root
        try {
            Process-Paths @($script:First.ToUpperInvariant(),'.\a.mov',
                ($script:Nested + '\..\a.mov'),('FileSystem::' + $script:First),
                ('TestDrive:\' + [IO.Path]::GetFileName($script:Root) + '\a.mov'),
                ('\\?\' + $script:First)) 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Output })
        } finally { Pop-Location }
        $script:Encoded.Count | Should -Be 1
        $script:Encoded[0] | Should -Be $script:First
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Scanned: 6' }
    }

    It 'uses ordinal case-insensitive queue order regardless of selection or culture [A01]' {
        $other = Join-Path $script:Root (([char]0x00E4).ToString() + '.mov')
        [IO.File]::WriteAllText($other, 'unicode source sentinel')
        $originalCulture = [Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo('de-DE')
            Process-Paths @($other,$script:Second,$script:First) 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Output })
            $firstOrder = $script:Encoded -join '|'
            $script:Encoded.Clear()
            [Threading.Thread]::CurrentThread.CurrentCulture = [Globalization.CultureInfo]::GetCultureInfo('sv-SE')
            Process-Paths @($script:First,$script:Second,$other) 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Output })
            ($script:Encoded -join '|') | Should -Be $firstOrder
            $expected = [string[]]@($script:First,$script:Second,$other)
            [array]::Sort($expected, [StringComparer]::OrdinalIgnoreCase)
            $firstOrder | Should -Be ($expected -join '|')
        } finally { [Threading.Thread]::CurrentThread.CurrentCulture = $originalCulture }
    }

    It 'finishes every scan before encoding and ignores files created during encoding [A02]' {
        $script:LateFile = Join-Path $script:Output 'new (compressed).mp4'
        $script:LateTemporary = Join-Path $script:Output 'job.partial.mp4'
        Mock Compress-One {
            Should -Invoke Get-InputScan -Times 3 -Exactly
            if (-not $script:Encoded.Count) {
                [IO.File]::WriteAllText($script:LateFile, 'new output')
                [IO.File]::WriteAllText($script:LateTemporary, 'new owned temporary')
            }
            $script:Encoded.Add($inPath)
        }
        Mock Get-InputScan { & $script:RealScan $p }
        Process-Paths @($script:First,$script:Root,$script:Output) 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Output })
        $script:Encoded.Count | Should -Be 2
        $script:Encoded | Should -Not -Contain $script:LateFile
        $script:Encoded | Should -Not -Contain $script:LateTemporary
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq ('No videos found: ' + $script:Output) }
    }

    It 'keeps originals in the destination and ambiguous compressed/partial filenames [A03]' {
        $originals = @('original.mp4','original (compressed).mp4','original.partial.mp4') | ForEach-Object {
            $file = Join-Path $script:Output $_
            [IO.File]::WriteAllText($file, 'ambiguous original sentinel')
            $file
        }
        $hashes = @($originals | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash })
        Process-Paths @($script:Output,$script:Root) 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Output })
        $script:Encoded.Count | Should -Be 5
        foreach ($file in $originals) { $script:Encoded | Should -Contain $file }
        (@($originals | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash }) -join '|') | Should -Be ($hashes -join '|')
    }

    It 'retains distinct hard-link paths without claiming filesystem identity deduplication [A01]' {
        $link = Join-Path $script:Root 'linked.mov'
        New-Item -ItemType HardLink -Path $link -Target $script:First -ErrorAction Stop | Out-Null
        Process-Paths @($link,$script:First) 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Output })
        $script:Encoded.Count | Should -Be 2
        $script:Encoded | Should -Contain $link
        $script:Encoded | Should -Contain $script:First
        [IO.File]::ReadAllText($link) | Should -Be 'first source sentinel'
    }

    It 'preserves incomplete-scan diagnostics and readable sources across overlaps [A04]' {
        $missing = Join-Path $script:Root 'missing.mov'
        Process-Paths @($missing,$script:First,$script:Root) 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Output })
        $script:Encoded.Count | Should -Be 2
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Scanned: 2' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Scan errors: 1' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { ($Object -join ' ').StartsWith('Scan error [') -and ($Object -join ' ').Contains('missing.mov') }
        Should -Invoke Write-Host -Times 0 -Exactly -ParameterFilter { $Object -eq ('No videos found: ' + $missing) }
    }

    It 'reports partial read failure before encoding readable siblings once [A04]' {
        $locked = Join-Path $script:Root 'locked.mov'
        [IO.File]::WriteAllText($locked, 'locked sentinel')
        $lock = [IO.File]::Open($locked, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        Mock Compress-One {
            Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { ($Object -join ' ').StartsWith('Scan error [FileReadFailed]') }
            $script:Encoded.Add($inPath)
        }
        try {
            Process-Paths @($script:Root,$script:First) 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Output })
        } finally { $lock.Dispose() }
        $script:Encoded.Count | Should -Be 2
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Scanned: 1' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Scan errors: 1' }
        [IO.File]::ReadAllText($locked) | Should -Be 'locked sentinel'
    }

    It 'returns arrays for empty and single-source queue snapshots' {
        foreach ($paths in @(@(),@($script:First))) {
            $queue = Get-InputQueue $paths
            $queue.Files -is [array] | Should -BeTrue
            $queue.Scans -is [array] | Should -BeTrue
            $queue.Files.Count | Should -Be $paths.Count
        }
    }

    It 'chooses the same invocation spelling when ordinary and extended aliases are reversed [A01]' {
        $first = Get-InputQueue @($script:First,('\\?\' + $script:First))
        $second = Get-InputQueue @(('\\?\' + $script:First),$script:First)
        $first.Files.Count | Should -Be 1
        $first.Files[0] | Should -BeExactly $second.Files[0]
    }

    It 'compares ordinary extended UNC aliases but preserves special literal suffixes [A01]' {
        (Get-QueuePathKey '\\?\UNC\server\share\clip.mov') | Should -BeExactly '\\server\share\clip.mov'
        (Get-QueuePathKey '\\?\D:\folder.\clip.mov') | Should -BeExactly '\\?\D:\folder.\clip.mov'
        (Get-QueuePathKey '\\?\D:\folder \clip.mov') | Should -BeExactly '\\?\D:\folder \clip.mov'
    }

    It 'queues supported long ordinary/extended aliases without legacy .NET length failure [A01]' {
        # Discovery long-path IO has separate M1-04 Windows evidence. Inject its
        # normalized paths here to exercise the queue without creating deep trees.
        $script:LongFile = [IO.Path]::GetPathRoot($script:Root) + ('a' * 200) + '\' + ('b' * 100) + '\clip.mov'
        Mock Get-InputScan {
            [pscustomobject]@{ InputPath = $p; NormalizedPath = $p; Files = @($p); Errors = @(); Succeeded = $true }
        }
        $queue = Get-InputQueue @($script:LongFile,('\\?\' + $script:LongFile))
        $queue.Files.Count | Should -Be 1
        $queue.Files[0] | Should -BeExactly $script:LongFile
        (Get-QueuePathKey ($script:LongFile.Replace('\clip.mov','\.\clip.mov'))) | Should -BeExactly $script:LongFile
    }

    It 'handles an empty full selection without encoding' {
        Process-Paths @() 'unused' 'unused' ([pscustomobject]@{ OutputDir = $script:Output })
        $script:Encoded.Count | Should -Be 0
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Found:   0' }
    }
}

Describe 'Queue output separation using a file-writing encoder recorder [WVC-M1-05]' {
    BeforeEach {
        $script:Root = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($script:Root)
        $script:RecordedJobs = New-Object 'Collections.Generic.List[object]'
        # This suite tests its existing boundary; validation has separate real-helper tests.
        Mock Get-OutputValidation { [pscustomobject]@{Succeeded=$true;Inspection=$null;Warnings=@()} }
        $script:Counters = [pscustomobject]@{ Done = 0; Skipped = 0; Failed = 0 }
        Mock Write-Host {}
        Mock Get-MediaInspection {
            ConvertFrom-ProbeJson '{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":1920,"height":1080}],"format":{"duration":"1"}}'
        }
        $script:Recorder = {
            $inputIndex = [array]::IndexOf($args, '-i') + 1
            $script:RecordedJobs.Add([pscustomobject]@{ Input = $args[$inputIndex]; Output = $args[-1] })
            $stream = [IO.File]::Open($args[-1], [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
            try { $stream.WriteByte(1) } finally { $stream.Dispose() }
            $global:LASTEXITCODE = 0
        }
        Mock Invoke-EncodeProcess {
            & $script:Recorder @Arguments
            [pscustomobject]@{ Succeeded=$true; StdOutTruncated=$false; StdErrTruncated=$false }
        }
    }

    It 'aborts the batch when owned encoder cleanup fails instead of starting the next job [WVC-M2-03]' {
        $source = Join-Path $script:Root 'first.mov'
        $second = Join-Path $script:Root 'second.mov'
        foreach ($file in @($source,$second)) { [IO.File]::WriteAllText($file,'source sentinel') }
        $output = Join-Path $script:Root 'output'
        [void][IO.Directory]::CreateDirectory($output)
        Mock Invoke-EncodeProcess {
            $abort = New-Object InvalidOperationException 'Injected owned encoder cleanup failure'
            $abort.Data['WvcAbortBatch'] = $true
            throw $abort
        }
        { Process-Paths @($source,$second) 'unused' 'unused' ([pscustomobject]@{OutputDir=$output}) } | Should -Throw '*cleanup failure*'
        Should -Invoke Invoke-EncodeProcess -Times 1 -Exactly
        $script:RecordedJobs.Count | Should -Be 0
        [IO.File]::ReadAllText($second) | Should -BeExactly 'source sentinel'
    }

    It 'encodes a same-directory MP4 into a new suffix and preserves existing sources/finals [A03 A04]' {
        $source = Join-Path $script:Root 'original.mp4'
        $existing = Join-Path $script:Root 'original (compressed).mp4'
        [IO.File]::WriteAllText($source, 'original source sentinel')
        [IO.File]::WriteAllText($existing, 'existing final sentinel')
        $sourceHash = (Get-FileHash -LiteralPath $source).Hash
        $finalHash = (Get-FileHash -LiteralPath $existing).Hash
        Compress-One $script:Recorder 'unused' $source ($script:Root + '\.\') $DefaultCRF ([ref]$script:Counters)
        $script:RecordedJobs.Count | Should -Be 1
        [IO.Path]::GetFileName($script:RecordedJobs[0].Output) | Should -BeExactly 'encode.partial.mp4'
        Test-Path -LiteralPath (Join-Path $script:Root 'original (compressed 2).mp4') | Should -BeTrue
        $script:Counters.Done | Should -Be 1
        (Get-FileHash -LiteralPath $source).Hash | Should -Be $sourceHash
        (Get-FileHash -LiteralPath $existing).Hash | Should -Be $finalHash
    }

    It 'defends source/output identity for <Extended> extended spelling when an existence check races [A04]' -TestCases @(
        @{ Extended = $false }, @{ Extended = $true }
    ) {
        param($Extended)
        $source = Join-Path $script:Root 'original.mp4'
        [IO.File]::WriteAllText($source, 'source sentinel')
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -eq $source -and -not $PathType }
        $inputPath = $source
        if ($Extended) { $inputPath = '\\?\' + $source }
        Compress-One $script:Recorder 'unused' $inputPath $script:Root $DefaultCRF ([ref]$script:Counters)
        $script:RecordedJobs.Count | Should -Be 1
        [IO.Path]::GetFileName($script:RecordedJobs[0].Output) | Should -BeExactly 'encode.partial.mp4'
        Test-Path -LiteralPath (Join-Path $script:Root 'original (compressed).mp4') | Should -BeTrue
        $script:Counters.Done | Should -Be 1
        [IO.File]::ReadAllText($source) | Should -Be 'source sentinel'
    }

    It 'rejects any identical renamed output before probe or encoder [A04]' {
        $source = Join-Path $script:Root 'original.mp4'
        [IO.File]::WriteAllText($source, 'source sentinel')
        Mock Next-CompressedPath { $targetPath }
        Compress-One $script:Recorder 'unused' $source $script:Root $DefaultCRF ([ref]$script:Counters)
        $script:RecordedJobs.Count | Should -Be 0
        $script:Counters.Failed | Should -Be 1
        Should -Invoke Get-MediaInspection -Times 0 -Exactly
        [IO.File]::ReadAllText($source) | Should -Be 'source sentinel'
    }

    It 'honors skip policy for source/output identity despite a raced existence check [A04]' {
        $source = Join-Path $script:Root 'original.mp4'
        [IO.File]::WriteAllText($source, 'source sentinel')
        Mock Test-Path { $false } -ParameterFilter { $LiteralPath -eq $source -and -not $PathType }
        $previousCollisionMode = $CollisionMode
        try {
            $CollisionMode = 'skip'
            Compress-One $script:Recorder 'unused' $source $script:Root $DefaultCRF ([ref]$script:Counters)
        } finally { $CollisionMode = $previousCollisionMode }
        $script:RecordedJobs.Count | Should -Be 0
        $script:Counters.Skipped | Should -Be 1
        Should -Invoke Get-MediaInspection -Times 0 -Exactly
        [IO.File]::ReadAllText($source) | Should -Be 'source sentinel'
    }

    It 'freezes overlapping same-root and nested-destination batches before any recorder output [A01 A02 A03 A04]' -TestCases @(
        @{ NestedOutput = $false }, @{ NestedOutput = $true }
    ) {
        param($NestedOutput)
        $destination = $script:Root
        if ($NestedOutput) {
            $destination = Join-Path $script:Root 'destination'
            [void][IO.Directory]::CreateDirectory($destination)
        }
        $source = Join-Path $script:Root 'a.mov'
        $original = Join-Path $destination 'b (compressed).mp4'
        [IO.File]::WriteAllText($source, 'first sentinel')
        [IO.File]::WriteAllText($original, 'destination original sentinel')
        $hashes = @($source,$original) | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash }
        Process-Paths @($source,$script:Root,$destination,$original) $script:Recorder 'unused' ([pscustomobject]@{ OutputDir = $destination })
        $script:RecordedJobs.Count | Should -Be 2
        foreach ($job in $script:RecordedJobs) {
            [IO.Path]::GetFullPath($job.Input) | Should -Not -Be ([IO.Path]::GetFullPath($job.Output))
        }
        (@($source,$original) | ForEach-Object { (Get-FileHash -LiteralPath $_).Hash }) -join '|' | Should -Be ($hashes -join '|')
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Found:   2' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Done:    2' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -eq 'Failed:  0' }
    }
}
