BeforeDiscovery {
    $script:LayoutMediaToolsAvailable=[bool](Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue) -and
        [bool](Get-Command ffprobe.exe -CommandType Application -ErrorAction SilentlyContinue)
}
BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $RepoRoot 'tests/launcher/LauncherTestSupport.ps1')
    $script:Owner=New-WvcTestRoot
    $script:App=Join-Path $Owner.Path 'app'; $script:Bin=Join-Path $Owner.Path 'bin'
    foreach ($dir in @($App,$Bin)) { [void][IO.Directory]::CreateDirectory($dir) }
    foreach ($file in @('WinVidCompress.ps1','WinVidCompress.bat')) { Copy-Item -LiteralPath (Join-Path $RepoRoot $file) -Destination (Join-Path $App $file) }
    $compile=Invoke-WvcTestProcess (Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe') @(
        '-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $PSScriptRoot 'New-ResumeFixture.ps1'),'-Destination',(Join-Path $Bin 'ffmpeg.exe'))
    if ($compile.ExitCode -ne 0) { throw $compile.StdErr }
    Copy-Item -LiteralPath (Join-Path $Bin 'ffmpeg.exe') -Destination (Join-Path $Bin 'ffprobe.exe')
    $script:HostExe=(Get-Process -Id $PID).Path
    if($LayoutMediaToolsAvailable) {
        $script:LayoutMediaEncoder=(Get-Command ffmpeg.exe -CommandType Application | Select-Object -First 1).Source
        $script:LayoutMediaProbe=(Get-Command ffprobe.exe -CommandType Application | Select-Object -First 1).Source
    }
    function Get-ProtectedSnapshot([string]$Directory) {
        if (-not [IO.Directory]::Exists($Directory)) { return 'absent' }
        $rows=New-Object 'Collections.Generic.List[object]'
        $pending=New-Object 'Collections.Generic.Stack[string]'; $pending.Push($Directory)
        while ($pending.Count) {
            $path=$pending.Pop(); $item=Get-Item -LiteralPath $path -Force
            $row=[ordered]@{Path=$path.Substring($Directory.Length);Directory=$item.PSIsContainer;Attributes=[int]$item.Attributes;Modified=$item.LastWriteTimeUtc.Ticks.ToString()}
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Protected snapshot refuses reparse roots.' }
            if ($item.PSIsContainer) { foreach ($child in @(Get-ChildItem -LiteralPath $path -Force)) { $pending.Push($child.FullName) } }
            else { $row.Length=$item.Length; $row.Hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash }
            $rows.Add([pscustomobject]$row)
        }
        return (ConvertTo-Json -InputObject @($rows | Sort-Object Path) -Depth 5 -Compress)
    }
    function Invoke-CliFixture([string[]]$Arguments, [string]$Route='PS1') {
        if ($Route -eq 'PS1') {
            return (Invoke-WvcTestProcess $HostExe (@('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',(Join-Path $App 'WinVidCompress.ps1'))+$Arguments) -Environment $Environment)
        }
        $slots=@(); $copy=$Environment.Clone()
        for ($i=0;$i -lt $Arguments.Count;$i++) { $key='WVC_CLI_ARG_'+$i; $copy[$key]=$Arguments[$i]; $slots+=('"%'+$key+'%"') }
        $copy.WVC_CLI_BAT=Join-Path $App 'WinVidCompress.bat'
        return (Invoke-WvcLauncherProcess $env:ComSpec ('/d /v:off /s /c ""%WVC_CLI_BAT%" '+($slots -join ' ')+'"') $copy)
    }
}
AfterAll { if ($null -ne $Owner) { Remove-WvcTestRoot $Owner } }
Describe 'Actual read-only preview, per-run options and help [WVC-M4-01]' {
    BeforeEach {
        $script:CaseRoot=Join-Path $Owner.Path ([guid]::NewGuid().ToString('N'))
        $script:SourceRoot=Join-Path $CaseRoot 'sources ! & [literal]'; $script:Output=Join-Path $CaseRoot 'output'
        $script:AppData=Join-Path $CaseRoot 'appdata'; $script:ConfigDir=Join-Path $AppData 'WinVidCompress'
        $script:ConfigPath=Join-Path $ConfigDir 'config.json'; $script:Manifest=Join-Path $CaseRoot 'batch.json'
        foreach ($dir in @($SourceRoot,$Output,$ConfigDir)) { [void][IO.Directory]::CreateDirectory($dir) }
        $script:Source=Join-Path $SourceRoot 'a.mov'; [IO.File]::WriteAllText($Source,'source sentinel')
        [IO.File]::WriteAllText($ConfigPath,([pscustomobject]@{OutputDir=$Output;Future='preserve'} | ConvertTo-Json))
        $script:Record=Join-Path $Owner.Path ([guid]::NewGuid().ToString('N')+'.encodes')
        $script:Environment=@{APPDATA=$AppData;PATH=($Bin+';'+$env:SystemRoot+'/System32');FFREPORT=('file='+ (Join-Path $CaseRoot 'forbidden-report.log')+':level=32');
            WVC_RESUME_RECORD=$Record;WVC_RESUME_FAIL='';WVC_RESUME_STOP='';WVC_RESUME_BAD_PROBE=''}
    }
    It 'keeps protected names, directories, attributes, sizes, hashes and times unchanged for <Case> [A02]' -TestCases @(
        @{Case='valid';Code=0},@{Case='missing config';Code=0},@{Case='corrupt config';Code=2},
        @{Case='offline saved output';Code=0},@{Case='missing explicit output';Code=2},
        @{Case='collision';Code=0},@{Case='duplicate basename';Code=0},@{Case='reserved partial';Code=0},
        @{Case='missing source';Code=2},@{Case='mixed scan';Code=1},@{Case='doctor';Code=2},
        @{Case='new manifest';Code=2},@{Case='foreign resume';Code=2},@{Case='corrupt resume';Code=2},@{Case='hash';Code=2}
    ) {
        param($Case,$Code)
        $arguments=@('-Unattended','-WhatIf','-OutputDir',$Output)
        switch ($Case) {
            'missing config' { Remove-Item -LiteralPath $ConfigPath; Remove-Item -LiteralPath $ConfigDir; Remove-Item -LiteralPath $AppData }
            'corrupt config' { [IO.File]::WriteAllText($ConfigPath,'{corrupt sentinel') }
            'offline saved output' { [IO.File]::WriteAllText($ConfigPath,([pscustomobject]@{OutputDir=(Join-Path $CaseRoot 'offline')} | ConvertTo-Json)) }
            'missing explicit output' { $arguments[3]=Join-Path $CaseRoot 'missing output' }
            'collision' { [IO.File]::WriteAllText((Join-Path $Output 'a.mp4'),'existing final') }
            'duplicate basename' { $other=Join-Path $SourceRoot 'other'; [void][IO.Directory]::CreateDirectory($other); [IO.File]::WriteAllText((Join-Path $other 'a.mov'),'second source') }
            'reserved partial' { $partial=Join-Path $SourceRoot ('.wvc-job-'+[guid]::NewGuid().ToString('N')); [void][IO.Directory]::CreateDirectory($partial); [IO.File]::WriteAllText((Join-Path $partial 'unverified.mp4'),'retained partial') }
            'doctor' { $arguments+='-CheckEnvironment' }
            'new manifest' { $arguments+=@('-ManifestPath',$Manifest) }
            'foreign resume' { [IO.File]::WriteAllText($Manifest,'{"Owner":"foreign","Commands":"delete source"}'); $arguments+=@('-ManifestPath',$Manifest,'-Resume') }
            'corrupt resume' { [IO.File]::WriteAllText($Manifest,'{corrupt sentinel'); $arguments+=@('-ManifestPath',$Manifest,'-Resume') }
            'hash' { $arguments+='-StrongSourceHash' }
        }
        if ($Case -eq 'missing source') { $arguments+=(Join-Path $CaseRoot 'missing.mov') }
        else { $arguments+=$SourceRoot }
        if ($Case -eq 'mixed scan') { $arguments+=(Join-Path $CaseRoot 'missing.mov') }
        $before=Get-ProtectedSnapshot $CaseRoot
        $result=Invoke-CliFixture $arguments
        $result.ExitCode | Should -Be $Code -Because ($result.StdOut+$result.StdErr)
        Get-ProtectedSnapshot $CaseRoot | Should -BeExactly $before
        Test-Path -LiteralPath $Record | Should -BeFalse
        if ($Code -eq 0) { $result.StdOut | Should -BeLike '*Preview only: no writes or native probes*' }
    }
    It 'runs <Route> positional multi-input preview with options after a path [A01 A04]' -TestCases @(@{Route='PS1'},@{Route='BAT'}) {
        param($Route)
        $second=Join-Path $SourceRoot 'b.mov'; [IO.File]::WriteAllText($second,'second source')
        $before=Get-ProtectedSnapshot $CaseRoot
        $result=Invoke-CliFixture @('-Unattended',$Source,'-OutputDir',$Output,'-WhatIf','-CollisionMode','skip',$second) $Route
        $result.ExitCode | Should -Be 0 -Because ($result.StdOut+$result.StdErr)
        @([regex]::Matches($result.StdOut,'WouldEncode:')).Count | Should -Be 2
        $result.StdOut | Should -Not -BeLike '*Choose an option*'
        $result.StdOut | Should -Not -BeLike '*Press any key*'
        Get-ProtectedSnapshot $CaseRoot | Should -BeExactly $before
    }
    It 'rejects unknown options using parameter dash <Value> before any writes [A03]' -TestCases @(
        @{Value=8211},@{Value=8212},@{Value=8213}
    ) {
        param($Value)
        $before=Get-ProtectedSnapshot $CaseRoot
        $result=Invoke-CliFixture @('-Unattended',([string][char]$Value+'CRF'),'23',$Source)
        $result.ExitCode | Should -Not -Be 0
        Get-ProtectedSnapshot $CaseRoot | Should -BeExactly $before
        Test-Path -LiteralPath $Record | Should -BeFalse
    }
    It 'rejects actual supplied <Case> before any writes [A03]' -TestCases @(
        @{Case='empty output';Options=@('-OutputDir','')},
        @{Case='relative output';Options=@('-OutputDir','relative')},
        @{Case='empty mode';Options=@('-CollisionMode','')},
        @{Case='invalid mode';Options=@('-CollisionMode','overwrite')}
    ) {
        param($Case,$Options)
        $before=Get-ProtectedSnapshot $CaseRoot
        $result=Invoke-CliFixture (@('-Unattended')+$Options+@($Source))
        $result.ExitCode | Should -Not -Be 0
        Get-ProtectedSnapshot $CaseRoot | Should -BeExactly $before
        Test-Path -LiteralPath $Record | Should -BeFalse
    }
    It 'rejects unsupported CRF before any application writes [A03]' {
        $before=Get-ProtectedSnapshot $CaseRoot
        $result=Invoke-CliFixture @('-Unattended','-CRF','23',$Source)
        $result.ExitCode | Should -Not -Be 0
        Get-ProtectedSnapshot $CaseRoot | Should -BeExactly $before
        Test-Path -LiteralPath $Record | Should -BeFalse
    }
    It 'uses run overrides over saved skip mode and restores the saved mode next invocation [A01 A03]' {
        [IO.File]::WriteAllText((Join-Path $Output 'a.mp4'),'existing final')
        [IO.File]::WriteAllText($ConfigPath,([pscustomobject]@{OutputDir=$Output;CollisionMode='skip';Future='keep'} | ConvertTo-Json))
        $before=(Get-FileHash -LiteralPath $ConfigPath).Hash
        (Invoke-CliFixture @('-Unattended','-CollisionMode','rename',$Source)).ExitCode | Should -Be 0
        [IO.File]::Exists((Join-Path $Output 'a (compressed).mp4')) | Should -BeTrue
        (Invoke-CliFixture @('-Unattended',$Source)).ExitCode | Should -Be 0
        @(Get-Content -LiteralPath $Record).Count | Should -Be 1
        (Get-FileHash -LiteralPath $ConfigPath).Hash | Should -BeExactly $before
        # Session logs are expected on conversion; compare only the preference bytes.
        (Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json).CollisionMode | Should -BeExactly 'skip'
        (Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json).Future | Should -BeExactly 'keep'
    }
    It 'overrides an unavailable saved output on actual <Route> conversion without rewriting config [A03 A04]' -TestCases @(@{Route='PS1'},@{Route='BAT'}) {
        param($Route)
        [IO.File]::WriteAllText($ConfigPath,([pscustomobject]@{OutputDir=(Join-Path $CaseRoot 'offline');Future='keep'} | ConvertTo-Json))
        $before=(Get-FileHash -LiteralPath $ConfigPath).Hash
        $result=Invoke-CliFixture @('-Unattended','-OutputDir',$Output,$Source) $Route
        $result.ExitCode | Should -Be 0 -Because ($result.StdOut+$result.StdErr)
        [IO.File]::Exists((Join-Path $Output 'a.mp4')) | Should -BeTrue
        (Get-FileHash -LiteralPath $ConfigPath).Hash | Should -BeExactly $before
        @(Get-Content -LiteralPath $Record).Count | Should -Be 1
    }
    It 'previews separated relative camera paths through actual <Route> without writes [M4-02 A02 A03]' -TestCases @(@{Route='PS1'},@{Route='BAT'}) {
        param($Route)
        $cameraA=Join-Path $SourceRoot 'camera-a'; $cameraB=Join-Path $SourceRoot 'camera-b'
        foreach($camera in @($cameraA,$cameraB)) { [void][IO.Directory]::CreateDirectory((Join-Path $camera 'scene')); [IO.File]::WriteAllText((Join-Path $camera 'scene/clip.mov'),'synthetic source sentinel') }
        $before=Get-ProtectedSnapshot $CaseRoot
        $run=Invoke-CliFixture @('-Unattended',$cameraB,'-PreserveSubfolders',$cameraA,'-OutputDir',$Output,'-WhatIf') $Route
        $run.ExitCode | Should -Be 0
        $run.StdOut | Should -Match 'Output layout: PreserveSubfolders'
        $run.StdOut.Contains((Join-Path $Output 'camera-a/scene/clip.mp4')) | Should -BeTrue
        $run.StdOut.Contains((Join-Path $Output 'camera-b/scene/clip.mp4')) | Should -BeTrue
        Get-ProtectedSnapshot $CaseRoot | Should -BeExactly $before
        Test-Path -LiteralPath $Record | Should -BeFalse
    }
    It 'publishes directory-local <Mode> collisions and logs actual <Route> relative output [M4-02 A01 A02 A03]' -TestCases @(
        @{Route='PS1';Mode='rename';Encoded=2},@{Route='BAT';Mode='rename';Encoded=2},
        @{Route='PS1';Mode='skip';Encoded=1},@{Route='BAT';Mode='skip';Encoded=1}
    ) {
        param($Route,$Mode,$Encoded)
        $cameraA=Join-Path $SourceRoot 'camera-a'; $cameraB=Join-Path $SourceRoot 'camera-b'
        foreach($camera in @($cameraA,$cameraB)) { [void][IO.Directory]::CreateDirectory((Join-Path $camera 'scene')); [IO.File]::WriteAllText((Join-Path $camera 'scene/clip.mov'),'synthetic source sentinel') }
        $final=Join-Path $Output 'camera-a/scene/clip.mp4'; [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($final)); [IO.File]::WriteAllText($final,'existing final sentinel')
        $sourceSnapshot=Get-ProtectedSnapshot $SourceRoot; $finalHash=(Get-FileHash -LiteralPath $final).Hash; $configHash=(Get-FileHash -LiteralPath $ConfigPath).Hash
        $run=Invoke-CliFixture @('-Unattended',$cameraB,'-PreserveSubfolders',$cameraA,'-OutputDir',$Output,'-CollisionMode',$Mode) $Route
        $run.ExitCode | Should -Be 0
        @(Get-Content -LiteralPath $Record).Count | Should -Be $Encoded
        Get-ProtectedSnapshot $SourceRoot | Should -BeExactly $sourceSnapshot
        (Get-FileHash -LiteralPath $final).Hash | Should -BeExactly $finalHash
        (Get-FileHash -LiteralPath $ConfigPath).Hash | Should -BeExactly $configHash
        Test-Path -LiteralPath (Join-Path $Output 'camera-b/scene/clip.mp4') | Should -BeTrue
        if($Mode -eq 'rename') { Test-Path -LiteralPath (Join-Path $Output 'camera-a/scene/clip (compressed).mp4') | Should -BeTrue }
        $log=@(Get-ChildItem -LiteralPath (Join-Path $ConfigDir 'logs') -Filter results.jsonl -Recurse)
        $log.Count | Should -Be 1
        $records=@(Get-Content -LiteralPath $log[0].FullName | ForEach-Object { $_ | ConvertFrom-Json })
        $records[0].OutputLayout | Should -BeExactly 'PreserveSubfolders'
        $jobs=@($records | Where-Object Kind -eq 'Job'); $jobs.Count | Should -Be 2
        $text=[IO.File]::ReadAllText((Join-Path $log[0].Directory.FullName 'session.txt'))
        $text | Should -Match 'output layout PreserveSubfolders'
        foreach($job in $jobs) {
            $job.CandidatePath.StartsWith($Output+'\',[StringComparison]::OrdinalIgnoreCase) | Should -BeTrue
            $text.Contains('candidate='+$job.CandidatePath) | Should -BeTrue
            if($job.Outcome -eq 'Completed') { $text.Contains('output='+$job.OutputPath) | Should -BeTrue }
        }
        @(Get-ChildItem -LiteralPath $Output -Directory -Recurse -Force | Where-Object Name -like '.wvc-job-*').Count | Should -Be 0
    }
    It 'encodes and structurally validates installed FFmpeg media in a nested destination [M4-02 A02 A03]' -Skip:(-not $LayoutMediaToolsAvailable) {
        $savedReport=$env:FFREPORT
        try {
            $env:FFREPORT=$null
            $camera=Join-Path $SourceRoot 'real-camera'; $directory=Join-Path $camera 'scene [literal]'
            [void][IO.Directory]::CreateDirectory($directory)
            $source=Join-Path $directory 'clip.mov'
            $generated=Invoke-WvcTestProcess $LayoutMediaEncoder @('-hide_banner','-loglevel','error','-f','lavfi','-i','testsrc2=size=320x240:rate=24:duration=0.5','-c:v','libx264','-pix_fmt','yuv420p','-an','-n',$source)
            $generated.ExitCode | Should -Be 0
            $sourceHash=(Get-FileHash -LiteralPath $source).Hash
            $Environment.PATH=([IO.Path]::GetDirectoryName($LayoutMediaEncoder)+';'+$env:SystemRoot+'/System32'); $Environment.Remove('FFREPORT')
            $run=Invoke-CliFixture @('-Unattended',$camera,'-PreserveSubfolders','-OutputDir',$Output)
            $run.ExitCode | Should -Be 0
            $outputPath=Join-Path $Output 'scene [literal]/clip.mp4'
            Test-Path -LiteralPath $outputPath | Should -BeTrue
            (Get-FileHash -LiteralPath $source).Hash | Should -BeExactly $sourceHash
            $probe=Invoke-WvcTestProcess $LayoutMediaProbe @('-v','error','-show_streams','-show_format','-of','json',$outputPath)
            $probe.ExitCode | Should -Be 0
            $media=$probe.StdOut | ConvertFrom-Json
            $media.streams[0].codec_name | Should -BeExactly 'h264'; $media.streams[0].height | Should -Be 240
            $media.format.format_name | Should -Match 'mp4'
        } finally { $env:FFREPORT=$savedReport }
    }
    It 'rejects actual preserve layout <Overlap> without filesystem writes [M4-02 A04]' -TestCases @(
        @{Overlap='equal'},@{Overlap='output inside source'},@{Overlap='source inside output'}
    ) {
        param($Overlap)
        $destination=switch($Overlap) { 'equal' {$SourceRoot}; 'output inside source' {Join-Path $SourceRoot 'exports'}; 'source inside output' {$CaseRoot} }
        [void][IO.Directory]::CreateDirectory($destination)
        $before=Get-ProtectedSnapshot $CaseRoot
        $run=Invoke-CliFixture @('-Unattended',$SourceRoot,'-PreserveSubfolders','-OutputDir',$destination)
        $run.ExitCode | Should -Be 2
        $run.StdErr | Should -Match 'disjoint input and output roots'
        Get-ProtectedSnapshot $CaseRoot | Should -BeExactly $before
        Test-Path -LiteralPath $Record | Should -BeFalse
    }
    It 'rejects actual preserve with a manifest before writing either [M4-02 A01 A04]' {
        $before=Get-ProtectedSnapshot $CaseRoot
        $run=Invoke-CliFixture @('-Unattended',$SourceRoot,'-PreserveSubfolders','-OutputDir',$Output,'-ManifestPath',$Manifest)
        $run.ExitCode | Should -Be 2
        $run.StdErr | Should -Match 'manifests require flat output'
        Get-ProtectedSnapshot $CaseRoot | Should -BeExactly $before
        Test-Path -LiteralPath $Record | Should -BeFalse
    }
    It 'executes real Get-Help example <Index> with owned placeholders [A04]' -TestCases @(@{Index=0},@{Index=1},@{Index=2}) {
        param($Index)
        $help=Get-Help (Join-Path $App 'WinVidCompress.ps1') -Full
        $help.Synopsis | Should -BeLike '*preview a batch*'
        @($help.examples.example).Count | Should -Be 3
        $tokens=$null; $errors=$null
        $ast=[Management.Automation.Language.Parser]::ParseInput($help.examples.example[$Index].code,[ref]$tokens,[ref]$errors)
        @($errors).Count | Should -Be 0
        $commands=@($ast.FindAll({param($node) $node -is [Management.Automation.Language.CommandAst]},$true))
        $commands.Count | Should -Be 1
        $arguments=@()
        foreach ($element in @($commands[0].CommandElements | Select-Object -Skip 1)) {
            if ($element -is [Management.Automation.Language.CommandParameterAst]) { $arguments+=('-'+$element.ParameterName) }
            elseif ($element -is [Management.Automation.Language.StringConstantExpressionAst]) {
                $value=$element.Value
                if ($value -eq 'D:\Output') { $value=$Output }
                elseif ($value -eq 'D:\Sources') { $value=$SourceRoot }
                $arguments+=$value
            } else { throw 'Help example contains unsupported executable syntax.' }
        }
        $before=Get-ProtectedSnapshot $CaseRoot
        $result=Invoke-CliFixture $arguments
        $result.ExitCode | Should -Be 0 -Because ($result.StdOut+$result.StdErr)
        if ($Index -eq 0) { Get-ProtectedSnapshot $CaseRoot | Should -BeExactly $before }
        if ($Index -eq 1) { @(Get-Content -LiteralPath $Record).Count | Should -Be 1 }
        else { Test-Path -LiteralPath $Record | Should -BeFalse }
    }
}
