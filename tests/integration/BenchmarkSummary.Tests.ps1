BeforeDiscovery {
    $script:BenchTools=[bool](Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue) -and
        [bool](Get-Command ffprobe.exe -CommandType Application -ErrorAction SilentlyContinue)
}
BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:Runner=Join-Path $RepoRoot 'tools/benchmark.ps1'
    $script:Shell=(Get-Process -Id $PID).Path
    if ($BenchTools) {
        $script:Encoder=(Get-Command ffmpeg.exe -CommandType Application).Source
        $script:Probe=(Get-Command ffprobe.exe -CommandType Application).Source
        $script:RunId=[guid]::NewGuid().ToString('N')
        $script:RunRoot=Join-Path $RepoRoot ('.test-results/benchmarks/'+$RunId)
        $script:Arguments=@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Runner,
            '-FFmpeg',$Encoder,'-FFprobe',$Probe,'-Repeats','2','-SyntheticSeconds','0.5','-CandidatePresets','medium','-RunId',$RunId)
        $script:Run=Invoke-WvcTestProcess $Shell $Arguments
        if ($Run.ExitCode -ne 0) {throw ($Run.StdOut+$Run.StdErr)}
        $script:RawReport=Get-Content -Raw -LiteralPath (Join-Path $RunRoot 'report.json')
        $script:Report=$RawReport | ConvertFrom-Json
    }
}
Describe 'Actual isolated benchmark provenance and publication [WVC-M3-04-A01/A03; native tools required]' {
    It 'records actual tools, settings, source provenance, exact tokens and stage times' -Skip:(-not $BenchTools) {
        $Report.Runs.Count | Should -Be 4
        $Report.Repeats | Should -Be 2
        $Report.Tools.Count | Should -Be 2
        $Report.SourceCommit | Should -Match '^[a-f0-9]{40}$'
        $Report.ApplicationSHA256 | Should -Match '^[a-f0-9]{64}$'
        $Report.RunnerSHA256 | Should -Match '^[a-f0-9]{64}$'
        $Report.Sources[0].Provenance | Should -Match 'Generated testsrc2'
        $Report.Sources[0].RecipeTokens[-1] | Should -BeExactly '<OUTPUT>'
        $Report.Sources[0].InputBytes | Should -BeGreaterThan 0
        $Report.Sources[0].Codec | Should -BeExactly 'ffv1'
        $Report.Sources[0].DurationSeconds | Should -BeGreaterThan 0
        foreach ($run in $Report.Runs) {
            $run.Outcome | Should -BeExactly 'Completed'
            $run.StructuralValidation | Should -BeExactly 'Passed'
            $run.Settings.CRF | Should -Be 22
            $run.Settings.AudioBitrate | Should -BeExactly '160k'
            $run.Settings.VideoCodec | Should -BeExactly 'libx264'
            $run.Settings.FastStart | Should -BeTrue
            $run.CommandTokens | Should -Contain '<SOURCE>'
            $run.CommandTokens[-1] | Should -BeExactly '<OUTPUT>'
            $run.CommandTokens[[array]::IndexOf($run.CommandTokens,'-preset')+1] | Should -BeExactly $run.Settings.Preset
            $run.ElapsedSeconds | Should -BeGreaterThan 0
            $run.Timings.ProbeSeconds | Should -BeGreaterThan 0
            $run.Timings.EncodeAndMuxSeconds | Should -BeGreaterThan 0
            $run.Timings.ValidationSeconds | Should -BeGreaterThan 0
            $run.Timings.PromotionSeconds | Should -BeGreaterOrEqual 0
            $run.FastStartRelocationSeconds | Should -BeNullOrEmpty
            $run.Playback.Status | Should -BeExactly 'NotRun'
            $run.Playback.Observer | Should -BeNullOrEmpty
            $local=Get-Content -Raw -LiteralPath (Join-Path $RunRoot ('outputs/synthetic-01/'+$run.Repeat+'/'+$run.ProfileId+'/job.local.json')) | ConvertFrom-Json
            $local.DurationState | Should -BeExactly 'Known'
            $local.SizeState | Should -BeExactly $run.Size.State
            $local.SavingsPercent | Should -Be $run.Size.SavingsPercent
        }
        ($Report.Runs.ProfileId -join '|') | Should -BeExactly 'default|preset-medium|default|preset-medium'
        foreach ($spread in $Report.Spread) {
            $spread.ElapsedSeconds.Count | Should -Be 2
            $spread.ElapsedSeconds.Minimum | Should -BeLessOrEqual $spread.ElapsedSeconds.Median
            $spread.ElapsedSeconds.Median | Should -BeLessOrEqual $spread.ElapsedSeconds.Maximum
        }
    }
    It 'keeps raw private diagnostics local and projected reports/media ignored by Git' -Skip:(-not $BenchTools) {
        $RawReport | Should -Not -Match [regex]::Escape($RepoRoot)
        $RawReport | Should -Not -Match [regex]::Escape($env:USERPROFILE)
        $RawReport | Should -Not -Match 'SourcePath|TemporaryPath|StdOut|StdErr'
        $ignored=Invoke-WvcTestProcess 'git.exe' @('-C',$RepoRoot,'check-ignore','--quiet',$RunRoot)
        $ignored.ExitCode | Should -Be 0
        @((Get-ChildItem -LiteralPath (Join-Path $RunRoot 'outputs') -Filter '*.mp4' -Recurse)).Count | Should -Be 4
        @((Get-ChildItem -LiteralPath (Join-Path $RunRoot 'outputs') -Filter 'job.local.json' -Recurse)).Count | Should -Be 4
    }
    It 'refuses an existing run without changing any owned outputs or reports' -Skip:(-not $BenchTools) {
        $before=@(Get-ChildItem -LiteralPath $RunRoot -File -Recurse | ForEach-Object {
            $_.FullName+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash
        })
        $again=Invoke-WvcTestProcess $Shell $Arguments
        $again.ExitCode | Should -Not -Be 0
        $after=@(Get-ChildItem -LiteralPath $RunRoot -File -Recurse | ForEach-Object {
            $_.FullName+'|'+(Get-FileHash -LiteralPath $_.FullName).Hash
        })
        ($after -join "`n") | Should -BeExactly ($before -join "`n")
    }
    It 'uses approved synthetic copies as opaque duplicates and retains a larger valid result' -Skip:(-not $BenchTools) {
        $owner=New-WvcTestRoot
        try {
            $source=Join-Path $owner.Path 'PRIVATE synthetic name & source.mp4'
            $generated=Invoke-WvcTestProcess $Encoder @('-hide_banner','-nostdin','-v','error','-n','-f','lavfi','-i',
                'color=c=black:s=64x64:r=24:d=0.5','-c:v','libx264','-crf','45','-metadata','title=PRIVATE tag',$source)
            $generated.ExitCode | Should -Be 0 -Because $generated.StdErr
            $before=(Get-FileHash -LiteralPath $source).Hash
            $copyId=[guid]::NewGuid().ToString('N')
            $copyRun=Invoke-WvcTestProcess $Shell @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$Runner,
                '-FFmpeg',$Encoder,'-FFprobe',$Probe,'-Repeats','2','-ApprovedCopies',$source,'-CandidateCRFs','0','-RunId',$copyId)
            $copyRun.ExitCode | Should -Be 0 -Because ($copyRun.StdOut+$copyRun.StdErr)
            $copyRoot=Join-Path $RepoRoot ('.test-results/benchmarks/'+$copyId)
            $raw=Get-Content -Raw -LiteralPath (Join-Path $copyRoot 'report.json')
            $copyReport=$raw | ConvertFrom-Json
            $raw | Should -Not -Match 'PRIVATE synthetic name|PRIVATE tag'
            $raw | Should -Not -Match [regex]::Escape($source)
            $copyReport.Sources[0].Id | Should -BeExactly 'copy-01'
            $copyReport.Sources[0].Provenance | Should -Match 'approved copy'
            $copyReport.Sources[0].RecipeTokens | Should -BeNullOrEmpty
            @($copyReport.Runs | Where-Object {$_.Size.State -eq 'Growth'}).Count | Should -BeGreaterThan 0
            @((Get-ChildItem -LiteralPath (Join-Path $copyRoot 'outputs') -Filter '*.mp4' -Recurse)).Count | Should -Be 4
            foreach ($run in $copyReport.Runs) {$run.Playback.Status | Should -BeExactly 'NotRun'}
            (Get-FileHash -LiteralPath $source).Hash | Should -BeExactly $before
        } finally {Remove-WvcTestRoot $owner}
    }
}
