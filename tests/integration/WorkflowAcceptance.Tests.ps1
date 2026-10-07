BeforeDiscovery {
    $script:WorkflowToolsAvailable = [bool](Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue) -and
        [bool](Get-Command ffprobe.exe -CommandType Application -ErrorAction SilentlyContinue)
}
BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $RepoRoot 'tests/launcher/LauncherTestSupport.ps1')
    $script:HostExe = (Get-Process -Id $PID).Path
    $script:Owner = $null
    $script:PreviousFFReport = $env:FFREPORT
    # An empty FFREPORT passed through ProcessStartInfo enables FFmpeg reports.
    # Remove it from this isolated Pester process instead of sending an empty key.
    $env:FFREPORT = $null
    if ($WorkflowToolsAvailable) {
        $script:Encoder = (Get-Command ffmpeg.exe -CommandType Application | Select-Object -First 1).Source
        $script:Probe = (Get-Command ffprobe.exe -CommandType Application | Select-Object -First 1).Source
    }
}
AfterAll { $env:FFREPORT = $script:PreviousFFReport }
Describe 'Isolated real Windows user workflows [WVC-M4-05]' {
    BeforeEach {
        $script:Owner = New-WvcTestRoot
        $script:App = Join-Path $Owner.Path 'app'
        $script:Sources = Join-Path $Owner.Path 'sources !NAME! & [literal]'
        $script:Output = Join-Path $Owner.Path 'output'
        $script:AppData = Join-Path $Owner.Path 'appdata'
        $script:Config = Join-Path $AppData 'WinVidCompress/config.json'
        foreach ($directory in @($App,$Sources,$Output)) { [void][IO.Directory]::CreateDirectory($directory) }
        foreach ($file in @('WinVidCompress.ps1','WinVidCompress.bat')) {
            Copy-Item -LiteralPath (Join-Path $RepoRoot $file) -Destination (Join-Path $App $file)
        }
        $script:Environment = @{ APPDATA=$AppData; NAME='must remain literal';
            PATH=((Split-Path -Parent $Encoder)+';'+(Split-Path -Parent $Probe)+';'+$env:SystemRoot+'\System32') }
        $script:SourceHashes = @{}
        foreach ($name in @('Synthetic Band 29.02.2024 - A','Synthetic Band 29.02.2024 - B')) {
            $source = Join-Path $Sources ($name+'.mp4')
            $generated = Invoke-WvcTestProcess $Encoder @('-hide_banner','-nostdin','-v','error','-n',
                '-f','lavfi','-i','testsrc2=size=160x120:rate=24:duration=0.5',
                '-f','lavfi','-i','sine=frequency=440:sample_rate=48000:duration=0.5',
                '-map','0:v:0','-map','1:a:0','-c:v','libx264','-preset','veryfast','-crf','18',
                '-pix_fmt','yuv420p','-c:a','aac',$source)
            $generated.ExitCode | Should -Be 0 -Because $generated.StdErr
            $SourceHashes[$source] = (Get-FileHash -LiteralPath $source).Hash
        }
        $script:Sentinel = Join-Path $Output 'Synthetic Band 29.02.2024 - A.mp4'
        [IO.File]::WriteAllText($Sentinel,'existing final must survive the complete workflow')
        $script:SentinelHash = (Get-FileHash -LiteralPath $Sentinel).Hash
    }
    AfterEach {
        if ($null -ne $Owner) { Remove-WvcTestRoot $Owner; $script:Owner = $null }
    }
    It 'encodes fresh <Configuration> via <Route>, preserving sources, finals and preferences [A01]' -Skip:(-not $WorkflowToolsAvailable) -TestCases @(
        @{ Configuration='missing config with explicit output'; Route='PS1' },
        @{ Configuration='legacy OutputDir-only config'; Route='PS1' },
        @{ Configuration='legacy OutputDir-only config'; Route='BAT' },
        @{ Configuration='extended saved config'; Route='PS1' }
    ) {
        param($Configuration,$Route)
        $configHash = $null
        $arguments = @('-Unattended')
        if ($Configuration -eq 'missing config with explicit output') {
            # MyVideos is a Windows known folder, unaffected by APPDATA. The
            # supported per-run override isolates a genuine fresh entry without
            # mocking startup or probing the owner's actual Videos directory.
            Test-Path -LiteralPath $AppData | Should -BeFalse
            $arguments += @('-OutputDir',$Output)
        } else {
            [void][IO.Directory]::CreateDirectory((Split-Path -Parent $Config))
            $saved = [ordered]@{ OutputDir=$Output }
            if ($Configuration -eq 'extended saved config') {
                $saved.CollisionMode='rename'
                $saved.Future=[ordered]@{ Label='keep unknown fields'; Date='2024-02-29T01:02:03Z' }
            }
            Write-WvcTestJson $Config $saved
            $configHash = (Get-FileHash -LiteralPath $Config).Hash
        }
        $arguments += $Sources
        if ($Route -eq 'PS1') {
            $run = Invoke-WvcTestProcess $HostExe (@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass',
                '-File',(Join-Path $App 'WinVidCompress.ps1'))+$arguments) -Environment $Environment
        } else {
            $Environment.WVC_WORKFLOW_BAT = Join-Path $App 'WinVidCompress.bat'
            $Environment.WVC_WORKFLOW_SOURCE = $Sources
            $run = Invoke-WvcLauncherProcess $env:ComSpec '/d /v:off /s /c ""%WVC_WORKFLOW_BAT%" -Unattended "%WVC_WORKFLOW_SOURCE%""' $Environment
        }
        $run.ExitCode | Should -Be 0 -Because $run.StdErr
        $run.StdOut | Should -Match 'Done:\s+2'
        (Get-FileHash -LiteralPath $Sentinel).Hash | Should -BeExactly $SentinelHash
        foreach ($source in $SourceHashes.Keys) {
            (Get-FileHash -LiteralPath $source).Hash | Should -BeExactly $SourceHashes[$source]
        }
        if ($configHash) { (Get-FileHash -LiteralPath $Config).Hash | Should -BeExactly $configHash }
        else { Test-Path -LiteralPath $Config | Should -BeFalse }
        $outputs = @(Get-ChildItem -LiteralPath $Output -File -Filter '*.mp4' | Where-Object FullName -ne $Sentinel)
        $outputs.Count | Should -Be 2
        @(Get-ChildItem -LiteralPath $Output -Directory).Count | Should -Be 0
        foreach ($file in $outputs) {
            $inspected = Invoke-WvcTestProcess $Probe @('-v','error','-show_streams','-show_format','-of','json',$file.FullName)
            $inspected.ExitCode | Should -Be 0 -Because $inspected.StdErr
            $media = $inspected.StdOut | ConvertFrom-Json
            $video = @($media.streams | Where-Object codec_type -eq 'video')
            $audio = @($media.streams | Where-Object codec_type -eq 'audio')
            $video.Count | Should -Be 1
            $audio.Count | Should -Be 1
            $video[0].codec_name | Should -BeExactly 'h264'
            $video[0].width | Should -Be 160
            $video[0].height | Should -Be 120
            $audio[0].codec_name | Should -BeExactly 'aac'
            [double]::Parse($media.format.duration,[Globalization.CultureInfo]::InvariantCulture) | Should -BeGreaterThan 0.4
            [double]::Parse($media.format.duration,[Globalization.CultureInfo]::InvariantCulture) | Should -BeLessThan 0.8
            $media.format.tags.artist | Should -BeExactly 'Synthetic Band'
            $media.format.tags.date | Should -BeExactly '2024-02-29'
            $decoded = Invoke-WvcTestProcess $Encoder @('-hide_banner','-nostdin','-v','error','-i',$file.FullName,
                '-map','0:v:0','-map','0:a:0','-f','null','-')
            $decoded.ExitCode | Should -Be 0 -Because $decoded.StdErr
        }
        $logs = @(Get-ChildItem -LiteralPath (Join-Path $AppData 'WinVidCompress/logs') -Filter results.jsonl -Recurse)
        $logs.Count | Should -Be 1
        $records = @(Get-Content -LiteralPath $logs[0].FullName | ForEach-Object { $_ | ConvertFrom-Json })
        $records[0].OutputLayout | Should -BeExactly 'Flat'
        $jobs = @($records | Where-Object Kind -eq 'Job')
        $jobs.Count | Should -Be 2
        @($jobs | Where-Object Outcome -ne 'Completed').Count | Should -Be 0
        foreach ($job in $jobs) {
            $SourceHashes.ContainsKey($job.SourcePath) | Should -BeTrue
            @($outputs.FullName) | Should -Contain $job.OutputPath
        }
        # These are genuine native entry/encoding checks, not Explorer or
        # perceptual acceptance. Full retains its separate human NotRun rows.
    }
}
