BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:SavedAppData=$env:APPDATA
    $env:APPDATA=Join-Path $TestDrive 'appdata'
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
}
AfterAll { $env:APPDATA=$SavedAppData }
Describe 'Opt-in relative output layout [WVC-M4-02]' {
    BeforeEach {
        $script:Root=Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:Output=Join-Path $Root 'output'
        $script:CameraA=Join-Path $Root 'camera-a'; $script:CameraB=Join-Path $Root 'camera-b'
        foreach ($dir in @($Output,(Join-Path $CameraA 'scene'),(Join-Path $CameraB 'scene'))) { [void][IO.Directory]::CreateDirectory($dir) }
        $script:SourceA=Join-Path $CameraA 'scene/clip.mov'; $script:SourceB=Join-Path $CameraB 'scene/clip.mov'
        [IO.File]::WriteAllText($SourceA,'camera A sentinel'); [IO.File]::WriteAllText($SourceB,'camera B sentinel')
        $ConfigDir=Join-Path $Root 'appdata/WinVidCompress'; $ConfigPath=Join-Path $ConfigDir 'config.json'
        Mock Write-Host {}; Mock Read-Host { throw 'Unexpected prompt' }
    }
    It 'labels filesystem root <RootPath> without relying on a file leaf [A02]' -TestCases @(
        @{RootPath='D:\';Label='drive-D'},@{RootPath='d:\';Label='drive-D'},@{RootPath='\\server\share\';Label='share'}
    ) {
        param($RootPath,$Label)
        Get-LayoutRootLabel $RootPath | Should -BeExactly $Label
    }
    It 'separates repeated camera clip names under fixed root labels [A02]' {
        $run=Invoke-WinVidCompress -Paths @($CameraB,$CameraA) -OutputDir $Output -WhatIf -PreserveSubfolders
        $run.ExitCode | Should -Be 0
        $run.Plans[0].OutputPath | Should -BeExactly (Join-Path $Output 'camera-a/scene/clip.mp4')
        $run.Plans[1].OutputPath | Should -BeExactly (Join-Path $Output 'camera-b/scene/clip.mp4')
        Test-Path -LiteralPath (Join-Path $Output 'camera-a') | Should -BeFalse
        Test-Path -LiteralPath $ConfigDir | Should -BeFalse
    }
    It 'retains flat <Mode> collisions without the flag [A01]' -TestCases @(@{Mode='rename';Action='WouldEncode';Name='clip (compressed).mp4'},@{Mode='skip';Action='WouldSkip';Name='clip.mp4'}) {
        param($Mode,$Action,$Name)
        $run=Invoke-WinVidCompress -Paths @($CameraA,$CameraB) -OutputDir $Output -WhatIf -CollisionMode $Mode
        $run.OutputLayout | Should -BeExactly 'Flat'
        $run.Plans[0].OutputPath | Should -BeExactly (Join-Path $Output 'clip.mp4')
        $run.Plans[1].OutputPath | Should -BeExactly (Join-Path $Output $Name)
        $run.Plans[1].Action | Should -BeExactly $Action
    }
    It 'uses one shallowest folder root for nested and explicit selections [A02]' {
        $run=Invoke-WinVidCompress -Paths @($SourceA,(Join-Path $CameraA 'scene'),$CameraA,$SourceA) -OutputDir $Output -WhatIf -PreserveSubfolders
        $run.Plans.Count | Should -Be 1
        $run.Plans[0].OutputPath | Should -BeExactly (Join-Path $Output 'scene/clip.mp4')
    }
    It 'uses parent folders for explicit files and disambiguates repeated leaves [A02]' {
        $run=Invoke-WinVidCompress -Paths @($SourceB,$SourceA) -OutputDir $Output -WhatIf -PreserveSubfolders
        $run.Plans[0].OutputPath | Should -BeExactly (Join-Path $Output 'scene/clip.mp4')
        $run.Plans[1].OutputPath | Should -BeExactly (Join-Path $Output 'scene (root 2)/clip.mp4')
    }
    It 'has identical path identities after selection reversal, aliases and culture change [A02]' {
        $before=Invoke-WinVidCompress -Paths @($CameraA,$CameraB) -OutputDir $Output -WhatIf -PreserveSubfolders
        $culture=[Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [Threading.Thread]::CurrentThread.CurrentCulture=[Globalization.CultureInfo]::GetCultureInfo('tr-TR')
            $after=Invoke-WinVidCompress -Paths @($CameraB,$CameraA.ToUpperInvariant(),$CameraA,(Join-Path $CameraA '.'),$SourceA) -OutputDir $Output -WhatIf -PreserveSubfolders
            ($after.Plans | ForEach-Object { ($_.SourcePath+'|'+$_.OutputPath).ToUpperInvariant() }) -join ';' |
                Should -BeExactly (($before.Plans | ForEach-Object { ($_.SourcePath+'|'+$_.OutputPath).ToUpperInvariant() }) -join ';')
        } finally { [Threading.Thread]::CurrentThread.CurrentCulture=$culture }
    }
    It 'disambiguates three repeated root leaves without colliding with a real suffixed name [A02]' {
        $paths=@('left/camera','right/camera','zeta/camera (root 2)') | ForEach-Object { Join-Path $Root $_ }
        foreach($dir in $paths) { [void][IO.Directory]::CreateDirectory($dir); [IO.File]::WriteAllText((Join-Path $dir 'clip.mov'),'root sentinel') }
        $layout=Get-RelativeOutputLayout (Get-InputQueue @($paths[2],$paths[0],$paths[1])) $Output
        ($layout.Roots.Label -join '|') | Should -BeExactly 'camera|camera (root 2)|camera (root 2) (root 2)'
        @($layout.Entries.OutputDirectory | Select-Object -Unique).Count | Should -Be 3
    }
    It 'keeps an existing collision local to one camera under <Mode> [A02 A03]' -TestCases @(@{Mode='rename';Action='WouldEncode';Name='clip (compressed).mp4'},@{Mode='skip';Action='WouldSkip';Name='clip.mp4'}) {
        param($Mode,$Action,$Name)
        $directory=Join-Path $Output 'camera-a/scene'; [void][IO.Directory]::CreateDirectory($directory)
        $final=Join-Path $directory 'clip.mp4'; [IO.File]::WriteAllText($final,'existing final sentinel'); $hash=(Get-FileHash -LiteralPath $final).Hash
        $run=Invoke-WinVidCompress -Paths @($CameraA,$CameraB) -OutputDir $Output -CollisionMode $Mode -WhatIf -PreserveSubfolders
        $run.Plans[0].OutputPath | Should -BeExactly (Join-Path $directory $Name)
        $run.Plans[0].Action | Should -BeExactly $Action
        $run.Plans[1].OutputPath | Should -BeExactly (Join-Path $Output 'camera-b/scene/clip.mp4')
        $run.Plans[1].Action | Should -BeExactly 'WouldEncode'
        (Get-FileHash -LiteralPath $final).Hash | Should -BeExactly $hash
    }
    It 'rejects unsafe relative path <Value> [A03]' -TestCases @(
        @{Value='../escape.mp4'},@{Value='cam/../escape.mp4'},@{Value='/escape.mp4'},@{Value='C:\escape.mp4'},
        @{Value='\\server\share\escape.mp4'},@{Value='./clip.mp4'},@{Value='cam//clip.mp4'},@{Value='cam/file:ads.mp4'},
        @{Value='cam/file?.mp4'},@{Value='cam/NUL.mp4'},@{Value='cam/trailing./clip.mp4'},@{Value='cam/trailing /clip.mp4'},
        @{Value='.wvc-job-00000000000000000000000000000000/clip.mp4'}
    ) {
        param($Value)
        { Get-LayoutDestination $Output $Value } | Should -Throw
        @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 0
    }
    It 'allows a prefix sibling and keeps every nominal path strictly beneath output [A03]' {
        $sibling=$Output+' sibling'; [void][IO.Directory]::CreateDirectory($sibling)
        [IO.File]::WriteAllText((Join-Path $sibling 'clip.mov'),'sibling sentinel')
        $layout=Get-RelativeOutputLayout (Get-InputQueue @($CameraA,$sibling)) $Output
        foreach($entry in $layout.Entries) {
            $entry.NominalPath.StartsWith($Output+'\',[StringComparison]::OrdinalIgnoreCase) | Should -BeTrue
            [IO.Path]::GetFullPath($entry.NominalPath) | Should -BeExactly $entry.NominalPath
        }
    }
    It 'refuses an existing file blocking a descendant without modifying it [A03]' {
        $block=Join-Path $Output 'scene'; [IO.File]::WriteAllText($block,'block sentinel')
        $hash=(Get-FileHash -LiteralPath $block).Hash
        (Invoke-WinVidCompress -Paths @($CameraA) -OutputDir $Output -WhatIf -PreserveSubfolders).ExitCode | Should -Be 2
        (Get-FileHash -LiteralPath $block).Hash | Should -BeExactly $hash
    }
    It 'refuses a destination junction introduced after planning [A03]' {
        $layout=Get-RelativeOutputLayout (Get-InputQueue @($CameraA)) $Output
        $outside=Join-Path $Root 'outside'; [void][IO.Directory]::CreateDirectory($outside)
        $sentinel=Join-Path $outside 'clip.mp4'; [IO.File]::WriteAllText($sentinel,'outside sentinel'); $hash=(Get-FileHash -LiteralPath $sentinel).Hash
        $junction=Join-Path $Output 'scene'
        & $env:ComSpec /d /c mklink /J $junction $outside *> $null
        if ($LASTEXITCODE -ne 0) { throw 'Owned fixture junction creation failed.' }
        try {
            { New-LayoutOutputDirectory $layout.OutputDirectory $layout.Entries[0].RelativePath } | Should -Throw '*reparse*'
            (Get-FileHash -LiteralPath $sentinel).Hash | Should -BeExactly $hash
            @(Get-ChildItem -LiteralPath $outside).Count | Should -Be 1
        } finally { [IO.Directory]::Delete($junction) }
    }
    It 'rejects <Overlap> before native, writing and prompt boundaries [A04]' -TestCases @(@{Overlap='equal'},@{Overlap='output inside source'},@{Overlap='source inside output'}) {
        param($Overlap)
        $destination=switch($Overlap) { 'equal' {$CameraA}; 'output inside source' {Join-Path $CameraA 'exports'}; 'source inside output' {$Root} }
        [void][IO.Directory]::CreateDirectory($destination)
        foreach($name in @('Ensure-Tool','Load-Config','Get-OutputEnvironment','New-SessionLog','Process-Paths')) { Mock $name { throw 'Forbidden overlap boundary' } }
        (Invoke-WinVidCompress -Paths @($CameraA) -OutputDir $destination -PreserveSubfolders -Unattended).ExitCode | Should -Be 2
        foreach($name in @('Ensure-Tool','Load-Config','Get-OutputEnvironment','New-SessionLog','Process-Paths','Read-Host')) { Should -Invoke $name -Times 0 -Exactly }
        Test-Path -LiteralPath $ConfigDir | Should -BeFalse
        [IO.File]::ReadAllText($SourceA) | Should -BeExactly 'camera A sentinel'
    }
    It 'refuses unsupported <Case> before startup [A01 A04]' -TestCases @(
        @{Case='manifest';Options=@{ManifestPath='C:\layout.json'}},@{Case='resume';Options=@{Resume=$true}},
        @{Case='strong hash';Options=@{StrongSourceHash=$true}},@{Case='doctor';Options=@{CheckEnvironment=$true}}
    ) {
        param($Case,$Options)
        Mock Ensure-Tool { throw 'Unexpected native startup' }; Mock Load-Config { throw 'Unexpected config write' }
        (Invoke-WinVidCompress -Paths @($CameraA) -OutputDir $Output -PreserveSubfolders @Options).ExitCode | Should -Be 2
        Should -Invoke Ensure-Tool -Times 0 -Exactly; Should -Invoke Load-Config -Times 0 -Exactly
    }
    It 'requires inputs without changing the menu route [A01]' {
        Mock Ensure-Tool { throw 'Unexpected startup' }
        (Invoke-WinVidCompress -OutputDir $Output -PreserveSubfolders).ExitCode | Should -Be 2
        Should -Invoke Ensure-Tool -Times 0 -Exactly
    }
    It 'creates only validated descendants for actual dispatch [A03]' {
        $layout=Get-RelativeOutputLayout (Get-InputQueue @($CameraA,$CameraB)) $Output
        $script:Dispatched=New-Object 'Collections.Generic.List[string]'
        Mock Get-OutputEnvironment { [pscustomobject]@{} }
        Mock Compress-One {
            $Dispatched.Add($outDir)
            Test-Path -LiteralPath $outDir -PathType Container | Should -BeTrue
            $job=New-JobResult $inPath $crf; $job.Outcome='Completed'; $job
        }
        $batch=Process-Paths @($CameraA,$CameraB) 'fixture' 'fixture' ([pscustomobject]@{OutputDir=$Output}) -BatchLayout $layout
        $batch.ExitCode | Should -Be 0
        ($Dispatched -join '|') | Should -BeExactly ((Join-Path $Output 'camera-a/scene')+'|'+(Join-Path $Output 'camera-b/scene'))
    }
    It 'refuses to recreate a selected root removed after planning [A03]' {
        $layout=Get-RelativeOutputLayout (Get-InputQueue @($CameraA)) $Output
        [IO.Directory]::Delete($Output)
        { New-LayoutOutputDirectory $layout.OutputDirectory $layout.Entries[0].RelativePath } | Should -Throw
        Test-Path -LiteralPath $Output | Should -BeFalse
    }
    It 'preserves literal Unicode and special-character subfolders [A02 A03]' {
        $name=([char]0x00E4).ToString()+' [x] !NAME! %PATH% & apostrophe''s'
        $directory=Join-Path $CameraA $name; [void][IO.Directory]::CreateDirectory($directory)
        $source=Join-Path $directory 'other.mov'; [IO.File]::WriteAllText($source,'literal sentinel')
        $layout=Get-RelativeOutputLayout (Get-InputQueue @($CameraA)) $Output
        @($layout.Entries | Where-Object SourcePath -eq $source)[0].NominalPath | Should -BeExactly (Join-Path (Join-Path $Output $name) 'other.mp4')
    }
    It 'rejects reserved superscript device path <Value> [A03]' -TestCases @(
        @{Value=('COM'+[char]0x00b9+'.mp4')},@{Value=('COM'+[char]0x00b2+'.mp4')},@{Value=('COM'+[char]0x00b3+'.mp4')},
        @{Value=('LPT'+[char]0x00b9+'.mp4')},@{Value=('LPT'+[char]0x00b2+'.mp4')},@{Value=('LPT'+[char]0x00b3+'.mp4')}
    ) {
        param($Value)
        { Get-LayoutDestination $Output $Value } | Should -Throw '*Unsafe*'
    }
}
