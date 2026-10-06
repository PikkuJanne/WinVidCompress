BeforeDiscovery {
    $script:GeometryToolsAvailable = [bool](Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue) -and
        [bool](Get-Command ffprobe.exe -CommandType Application -ErrorAction SilentlyContinue)
}
BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:SavedEnvironment = @{APPDATA=$env:APPDATA;FFREPORT=$env:FFREPORT}
    $script:BootstrapOwner = New-WvcTestRoot
    $env:APPDATA = Join-Path $BootstrapOwner.Path 'appdata'
    $env:FFREPORT = $null
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    if ($GeometryToolsAvailable) {
        $script:GeometryEncoder = (Get-Command ffmpeg.exe -CommandType Application).Source
        $script:GeometryProbe = (Get-Command ffprobe.exe -CommandType Application).Source
    }
    function Invoke-GeometryFixture($Arguments) {
        $native = Invoke-WvcTestProcess $GeometryEncoder $Arguments
        if ($native.ExitCode -ne 0) { throw ('Geometry fixture failed: ' + $native.StdErr) }
    }
    function Get-GeometryCorners([string]$InputPath,[string]$RgbPath,[int]$Width,[int]$Height) {
        # Decode raw physical pixels, disabling any residual output autorotation.
        Invoke-GeometryFixture @('-hide_banner','-nostdin','-v','error','-n','-noautorotate','-i',$InputPath,
            '-map','0:v:0','-frames:v','1','-pix_fmt','rgb24','-f','rawvideo',$RgbPath)
        $bytes = [IO.File]::ReadAllBytes($RgbPath)
        $bytes.Length | Should -Be ($Width*$Height*3)
        $labels = @()
        foreach ($position in @(@(0.25,0.25),@(0.75,0.25),@(0.25,0.75),@(0.75,0.75))) {
            $offset = 3*([int][Math]::Floor($position[1]*$Height)*$Width+[int][Math]::Floor($position[0]*$Width))
            $r,$g,$b = $bytes[$offset..($offset+2)]
            if ($r -gt 180 -and $g -lt 70 -and $b -lt 70) { $labels += 'R' }
            elseif ($g -gt 180 -and $r -lt 70 -and $b -lt 70) { $labels += 'G' }
            elseif ($b -gt 180 -and $r -lt 70 -and $g -lt 70) { $labels += 'B' }
            elseif ($r -gt 180 -and $g -gt 180 -and $b -lt 70) { $labels += 'Y' }
            else { throw "Unexpected quadrant colour at $offset (RGB $r,$g,$b)." }
        }
        $labels -join ''
    }
    function Get-GeometryFrameTimes([string]$InputPath) {
        $native = Invoke-WvcTestProcess $GeometryProbe @('-v','error','-select_streams','v:0','-show_frames',
            '-show_entries','frame=best_effort_timestamp_time','-of','json',$InputPath)
        if ($native.ExitCode -ne 0) { throw ('Frame probe failed: ' + $native.StdErr) }
        @((ConvertFrom-Json $native.StdOut).frames | ForEach-Object { ConvertTo-ProbeNumber $_.best_effort_timestamp_time })
    }
}
AfterAll {
    foreach ($key in $SavedEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key,$SavedEnvironment[$key],'Process') }
    Remove-WvcTestRoot $BootstrapOwner
}

Describe 'Actual generated filter, SAR and physical orientation [WVC-M3-01-A01/A02; FFmpeg/FFprobe required]' {
    BeforeEach {
        $script:Owner = New-WvcTestRoot
        $env:APPDATA = Join-Path $Owner.Path 'appdata'
        $script:Output = Join-Path $Owner.Path 'output'
        [void][IO.Directory]::CreateDirectory($Output)
        $script:CollisionMode = 'rename'
    }
    AfterEach { if ($null -ne $Owner) { Remove-WvcTestRoot $Owner } }
    It 'confirms <Name> pixels and probe geometry without touching source or existing output' -Skip:(-not $GeometryToolsAvailable) -TestCases @(
        @{Name='SD';W=640;H=480;R=0;Sar='1/1';TW=640;TH=480;Corners='RGBY'},
        @{Name='1080';W=1920;H=1080;R=0;Sar='1/1';TW=1920;TH=1080;Corners='RGBY'},
        @{Name='4K';W=3840;H=2160;R=0;Sar='1/1';TW=1920;TH=1080;Corners='RGBY'},
        @{Name='portrait';W=1080;H=1920;R=0;Sar='1/1';TW=608;TH=1080;Corners='RGBY'},
        @{Name='90';W=1920;H=1080;R=90;Sar='1/1';TW=608;TH=1080;Corners='GYRB'},
        @{Name='180';W=640;H=480;R=180;Sar='1/1';TW=640;TH=480;Corners='YBGR'},
        @{Name='270';W=640;H=480;R=270;Sar='1/1';TW=480;TH=640;Corners='BRYG'},
        @{Name='ultrawide';W=3440;H=1440;R=0;Sar='1/1';TW=2580;TH=1080;Corners='RGBY'},
        @{Name='anamorphic';W=720;H=576;R=0;Sar='16/15';TW=720;TH=576;Corners='RGBY'},
        @{Name='rotatedAnamorphic';W=720;H=576;R=90;Sar='16/15';TW=576;TH=720;Corners='GYRB'},
        @{Name='oddWidth';W=641;H=480;R=0;Sar='1/1';TW=640;TH=480;Corners='RGBY'},
        @{Name='oddHeight';W=640;H=479;R=0;Sar='1/1';TW=638;TH=478;Corners='RGBY'},
        @{Name='bothOdd';W=641;H=479;R=0;Sar='16/15';TW=640;TH=478;Corners='RGBY'}
    ) {
        param($Name,$W,$H,$R,$Sar,$TW,$TH,$Corners)
        $base = Join-Path $Owner.Path 'base.mp4'
        $source = Join-Path $Owner.Path 'geometry.mp4'
        # Four asymmetric solid quadrants: red/green above blue/yellow. Explicit scale permits odd 4:4:4 sources.
        $pattern = "color=c=black:s=64x64:r=24:d=0.125,format=yuv444p,scale=${W}:${H}," +
            'drawbox=x=0:y=0:w=iw/2:h=ih/2:color=red:t=fill,' +
            'drawbox=x=iw/2:y=0:w=iw/2:h=ih/2:color=lime:t=fill,' +
            'drawbox=x=0:y=ih/2:w=iw/2:h=ih/2:color=blue:t=fill,' +
            "drawbox=x=iw/2:y=ih/2:w=iw/2:h=ih/2:color=yellow:t=fill,setsar=$Sar"
        Invoke-GeometryFixture @('-hide_banner','-nostdin','-v','error','-n','-f','lavfi','-i',$pattern,
            '-c:v','libx264','-preset','ultrafast','-crf','0','-pix_fmt','yuv444p',$base)
        Invoke-GeometryFixture @('-hide_banner','-nostdin','-v','error','-n','-display_rotation:v:0',"$R",'-i',$base,'-c','copy',$source)
        $inspection = Get-MediaInspection $GeometryProbe $source
        $inspection.Succeeded | Should -BeTrue
        $inspection.PrimaryVideo.Width | Should -Be $W
        $inspection.PrimaryVideo.Height | Should -Be $H
        ((($inspection.PrimaryVideo.RotationDegrees % 360)+360)%360) | Should -Be $R
        $geometry = Get-VideoGeometryPlan $inspection.PrimaryVideo
        $sentinel = Join-Path $Output 'geometry.mp4'
        [IO.File]::WriteAllText($sentinel,'existing final sentinel')
        $sourceHash = (Get-FileHash -LiteralPath $source).Hash
        $sentinelHash = (Get-FileHash -LiteralPath $sentinel).Hash
        $job = Compress-One $GeometryEncoder $GeometryProbe $source $Output 22
        $job.Outcome | Should -BeExactly 'Completed' -Because $job.Reason
        $job.Diagnostics.Validation.Succeeded | Should -BeTrue
        $result = $job.Diagnostics.Validation.Inspection.PrimaryVideo
        $result.Width | Should -Be $TW
        $result.Height | Should -Be $TH
        $sarResult = ConvertTo-ProbeRatio $result.SampleAspectRatio ':'
        [Math]::Abs(($TW/[double]$TH*$sarResult.Value)/$geometry.ExpectedDisplayAspectRatio-1) | Should -BeLessOrEqual 0.001
        (Get-GeometryCorners $job.OutputPath (Join-Path $Owner.Path 'decoded.rgb') $TW $TH) | Should -BeExactly $Corners
        (Get-FileHash -LiteralPath $source).Hash | Should -BeExactly $sourceHash
        (Get-FileHash -LiteralPath $sentinel).Hash | Should -BeExactly $sentinelHash
        @((Get-ChildItem -LiteralPath $Output -Recurse -File) | Where-Object Name -eq 'encode.partial.mp4').Count | Should -Be 0
    }
    It 'retains actual <Kind> frame timestamps without a new FPS override [WVC-M3-01-A03]' -Skip:(-not $GeometryToolsAvailable) -TestCases @(@{Kind='HFR'},@{Kind='VFR'}) {
        param($Kind)
        $source=Join-Path $Owner.Path 'timing.mp4'
        $pattern=$(if ($Kind -eq 'HFR') {'testsrc2=s=320x240:r=120:d=0.25'} else {'testsrc2=s=320x240:r=30:d=0.5,select=not(eq(mod(n\,3)\,1))'})
        # Passthrough belongs only to VFR fixture creation; the application adds no FPS policy.
        Invoke-GeometryFixture @('-hide_banner','-nostdin','-v','error','-n','-f','lavfi','-i',$pattern,
            '-fps_mode','passthrough','-c:v','libx264','-preset','ultrafast','-crf','0',$source)
        $before=@(Get-GeometryFrameTimes $source)
        $job=Compress-One $GeometryEncoder $GeometryProbe $source $Output 22
        $job.Outcome | Should -BeExactly 'Completed' -Because $job.Reason
        $after=@(Get-GeometryFrameTimes $job.OutputPath)
        $after.Count | Should -Be $before.Count
        for ($index=0;$index -lt $before.Count;$index++) {
            [Math]::Abs(($after[$index]-$after[0])-($before[$index]-$before[0])) | Should -BeLessThan 0.0001
        }
        if ($Kind -eq 'VFR') { @((1..($before.Count-1)) | ForEach-Object {[Math]::Round($before[$_]-$before[$_-1],3)} | Select-Object -Unique).Count | Should -BeGreaterThan 1 }
    }
}
