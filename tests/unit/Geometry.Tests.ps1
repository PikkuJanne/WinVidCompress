BeforeAll {
    $script:SavedAppData = $env:APPDATA
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
    function New-GeometryInspection($Width,$Height,$Rotation=0,$Sar='1:1') {
        $video = [ordered]@{index=2;codec_type='video';codec_name='h264';pix_fmt='yuv420p';width=$Width;height=$Height;
            sample_aspect_ratio=$Sar;duration='1';nb_frames='24';avg_frame_rate='24/1';tags=@{rotate=$Rotation}}
        ConvertFrom-ProbeJson (@{streams=@($video);format=@{format_name='mp4';duration='1'}} | ConvertTo-Json -Depth 12)
    }
}
AfterAll { $env:APPDATA = $SavedAppData }

Describe 'Selected display geometry and literal filter [WVC-M3-01-A01/A02]' {
    It 'plans <Name> without cropping, enlargement or a width cap' -TestCases @(
        @{Name='SD';W=640;H=480;R=0;TW=640;TH=480;Filter=$null},
        @{Name='1080';W=1920;H=1080;R=0;TW=1920;TH=1080;Filter=$null},
        @{Name='4K';W=3840;H=2160;R=0;TW=1920;TH=1080;Filter='scale=1920:1080'},
        @{Name='portrait';W=1080;H=1920;R=0;TW=608;TH=1080;Filter='scale=608:1080'},
        @{Name='90';W=1920;H=1080;R=90;TW=608;TH=1080;Filter='scale=608:1080'},
        @{Name='180';W=1920;H=1080;R=180;TW=1920;TH=1080;Filter=$null},
        @{Name='270';W=1920;H=1080;R=270;TW=608;TH=1080;Filter='scale=608:1080'},
        @{Name='negative90';W=640;H=480;R=-90;TW=480;TH=640;Filter=$null},
        @{Name='ultrawide';W=3440;H=1440;R=0;TW=2580;TH=1080;Filter='scale=2580:1080'},
        @{Name='wideSmall';W=2560;H=720;R=0;TW=2560;TH=720;Filter=$null},
        @{Name='oddWidth';W=641;H=480;R=0;TW=640;TH=480;Filter='scale=640:480'},
        @{Name='oddHeight';W=640;H=479;R=0;TW=638;TH=478;Filter='scale=638:478'},
        @{Name='bothOdd';W=641;H=479;R=0;TW=640;TH=478;Filter='scale=640:478'},
        @{Name='nearCap';W=1921;H=1081;R=0;TW=1920;TH=1080;Filter='scale=1920:1080'}
    ) {
        param($Name,$W,$H,$R,$TW,$TH,$Filter)
        $inspection = New-GeometryInspection $W $H $R
        $before = $inspection | ConvertTo-Json -Depth 20
        $plan = Get-StreamPlan $inspection
        $geometry = Get-VideoGeometryPlan $plan.Video
        $geometry.TargetWidth | Should -Be $TW
        $geometry.TargetHeight | Should -Be $TH
        $geometry.Filter | Should -Be $Filter
        ($geometry.TargetWidth -le $geometry.OrientedWidth) | Should -BeTrue
        ($geometry.TargetHeight -le $geometry.OrientedHeight) | Should -BeTrue
        $geometry.TargetHeight | Should -BeLessOrEqual 1080
        $tokens = @(Get-EncodeArguments 'source' 'target' $plan 22 $null)
        if ($Filter) { $tokens[[array]::IndexOf($tokens,'-vf')+1] | Should -BeExactly $Filter }
        else { $tokens | Should -Not -Contain '-vf' }
        ($tokens -join ' ') | Should -Not -Match 'transpose|rotate=|crop=|setsar=|pad='
        ($inspection | ConvertTo-Json -Depth 20) | Should -BeExactly $before
        [object]::ReferenceEquals($plan.Video,$inspection.PrimaryVideo) | Should -BeTrue
    }

    It 'preserves anamorphic display aspect through quarter turns and rounding' -TestCases @(
        @{W=720;H=576;R=0;Sar='16:15';DAR=1.3333333333333333},
        @{W=720;H=576;R=90;Sar='16:15';DAR=0.75},
        @{W=641;H=479;R=270;Sar='16:15';DAR=0.700565522620905},
        @{W=1080;H=1920;R=0;Sar='1:1';DAR=0.5625}
    ) {
        param($W,$H,$R,$Sar,$DAR)
        $geometry = Get-VideoGeometryPlan (New-GeometryInspection $W $H $R $Sar).PrimaryVideo
        [Math]::Abs($geometry.ExpectedDisplayAspectRatio-$DAR) | Should -BeLessThan 0.000001
        [Math]::Abs(($geometry.TargetWidth / [double]$geometry.TargetHeight * $geometry.ExpectedSampleAspectRatio)-$DAR) | Should -BeLessThan 0.000001
    }

    It 'rejects <Kind> geometry before constructing any native arguments' -TestCases @(
        @{Kind='arbitraryRotation';W=640;H=480;R=45},
        @{Kind='invalidRotation';W=640;H=480;R='broken'},
        @{Kind='onePixelWidth';W=1;H=480;R=0},
        @{Kind='onePixelHeight';W=640;H=1;R=0}
    ) {
        param($Kind,$W,$H,$R)
        { Get-StreamPlan (New-GeometryInspection $W $H $R) } | Should -Throw
    }

    It 'reports unknown SAR instead of claiming square pixels' {
        $geometry = Get-VideoGeometryPlan (New-GeometryInspection 640 480 0 '0:1').PrimaryVideo
        $geometry.ExpectedDisplayAspectRatio | Should -BeNullOrEmpty
        ($geometry.Warnings -join ' ') | Should -Match 'aspect.*unknown'
    }
    It 'rejects contradictory coded DAR and SAR' {
        $video = (New-GeometryInspection 640 480).PrimaryVideo
        $video.DisplayAspectRatio = '16:9'
        { Get-VideoGeometryPlan $video } | Should -Throw
    }
}

Describe 'Exact output geometry checks [WVC-M3-01-A02]' {
    It 'accepts rotated geometry once and rejects <Kind> wrong output' -TestCases @(
        @{Kind='valid'},@{Kind='codedOrientation'},@{Kind='doubleRotation'},@{Kind='aspect'},@{Kind='odd'}
    ) {
        param($Kind)
        $source = New-GeometryInspection 1920 1080 90
        $plan = Get-StreamPlan $source
        $output = New-GeometryInspection 608 1080 0 '1215:1216'
        switch ($Kind) {
            codedOrientation { $output.PrimaryVideo.Width=1920;$output.PrimaryVideo.Height=1080 }
            doubleRotation { $output.PrimaryVideo.RotationDegrees=90 }
            aspect { $output.PrimaryVideo.SampleAspectRatio='2:1' }
            odd { $output.PrimaryVideo.Width=607 }
        }
        if ($Kind -eq 'valid') { {Test-OutputStructure $output $source $plan} | Should -Not -Throw }
        else { {Test-OutputStructure $output $source $plan} | Should -Throw }
    }
    It 'discloses unavailable aspect verification' {
        $source = New-GeometryInspection 640 480 0 '0:1'
        $output = New-GeometryInspection 640 480 0 '0:1'
        $result = Test-OutputStructure $output $source (Get-StreamPlan $source)
        ($result.Warnings -join ' ') | Should -Match 'aspect.*unavailable'
    }
}

Describe 'Conservative display matrix boundaries [WVC-M3-01-A01/A02]' {
    BeforeAll {
        function Set-GeometryMatrix($Video,$Values,$Rotation=0) {
            $Video.DisplayMatrixCount=1
            $Video.RotationDegrees=$Rotation
            $Video.DisplayMatrix = ("`n00000000: {0} {1} {2}`n00000001: {3} {4} {5}`n00000002: {6} {7} {8}`n" -f $Values)
        }
    }
    It 'accepts canonical <Name> through default autorotation' -TestCases @(
        @{Name='identity';Values=@(65536,0,0,0,65536,0,0,0,1073741824);R=0},
        @{Name='horizontalFlip';Values=@(-65536,0,0,0,65536,0,0,0,1073741824);R=180},
        @{Name='verticalFlip';Values=@(65536,0,0,0,-65536,0,0,0,1073741824);R=0},
        @{Name='180';Values=@(-65536,0,0,0,-65536,0,0,0,1073741824);R=180},
        @{Name='90';Values=@(0,-65536,0,65536,0,0,0,0,1073741824);R=90},
        @{Name='270';Values=@(0,65536,0,-65536,0,0,0,0,1073741824);R=270},
        @{Name='diagonalFlip';Values=@(0,65536,0,65536,0,0,0,0,1073741824);R=270},
        @{Name='otherDiagonalFlip';Values=@(0,-65536,0,-65536,0,0,0,0,1073741824);R=90},
        @{Name='rebased180';Values=@(-65536,0,0,0,-65536,0,41943040,31457280,1073741824);R=180}
    ) {
        param($Name,$Values,$R)
        $video=(New-GeometryInspection 640 480).PrimaryVideo
        Set-GeometryMatrix $video $Values $R
        {Get-VideoGeometryPlan $video} | Should -Not -Throw
    }
    It 'rejects supplied <Kind> transforms rather than discarding them' -TestCases @(
        @{Kind='singular'},@{Kind='scale'},@{Kind='skew'},@{Kind='perspective'},@{Kind='translation'},
        @{Kind='missingText'},@{Kind='junk'},@{Kind='overflow'},@{Kind='wrongRow'},@{Kind='duplicate'},@{Kind='contradiction'},
        @{Kind='identity180'},@{Kind='reverse90'}
    ) {
        param($Kind)
        $video=(New-GeometryInspection 640 480).PrimaryVideo
        Set-GeometryMatrix $video @(65536,0,0,0,65536,0,0,0,1073741824)
        switch ($Kind) {
            singular {$video.DisplayMatrix=$video.DisplayMatrix.Replace('65536','0')}
            scale {$video.DisplayMatrix=$video.DisplayMatrix.Replace('65536','32768')}
            skew {$video.DisplayMatrix=$video.DisplayMatrix.Replace('65536 0 0','65536 1 0')}
            perspective {$video.DisplayMatrix=$video.DisplayMatrix.Replace('65536 0 0','65536 0 1')}
            translation {$video.DisplayMatrix=$video.DisplayMatrix.Replace('0 0 1073741824','1 0 1073741824')}
            missingText {$video.DisplayMatrix=$null}
            junk {$video.DisplayMatrix+=' junk'}
            overflow {$video.DisplayMatrix=$video.DisplayMatrix.Replace('65536','2147483648')}
            wrongRow {$video.DisplayMatrix=$video.DisplayMatrix.Replace('00000001','00000003')}
            duplicate {$video.DisplayMatrixCount=2}
            contradiction {$video.RotationDegrees=90}
            identity180 {$video.RotationDegrees=180}
            reverse90 {Set-GeometryMatrix $video @(0,-65536,0,65536,0,0,0,0,1073741824) 270}
        }
        {Get-VideoGeometryPlan $video} | Should -Throw
    }
    It 'retains invalid authoritative matrix metadata despite a valid legacy tag' {
        $document=@{streams=@(@{index=0;codec_type='video';codec_name='h264';width=640;height=480;
            side_data_list=@(@{side_data_type='Display Matrix';rotation='invalid';displaymatrix=$null});tags=@{rotate=0}})}
        $inspection=ConvertFrom-ProbeJson ($document | ConvertTo-Json -Depth 12)
        $inspection.Succeeded | Should -BeTrue
        $inspection.PrimaryVideo.DisplayMatrixCount | Should -Be 1
        {Get-StreamPlan $inspection} | Should -Throw
    }
    It 'rejects a residual output reflection even with rotation zero' {
        $source=New-GeometryInspection 640 480
        $output=New-GeometryInspection 640 480
        Set-GeometryMatrix $output.PrimaryVideo @(65536,0,0,0,-65536,0,0,0,1073741824)
        {Test-OutputStructure $output $source (Get-StreamPlan $source)} | Should -Throw
    }
    It 'does not plan an unsupported omitted alternate stream' {
        $source=New-GeometryInspection 640 480
        $alternate=(New-GeometryInspection 640 480 45).PrimaryVideo
        $alternate.Index=9
        $source.Streams += $alternate
        (Get-StreamPlan $source).VideoIndex | Should -Be 2
    }
}

Describe 'No new frame-rate policy [WVC-M3-01-A03]' {
    It 'keeps <Rate> rate information out of encoder overrides' -TestCases @(@{Rate='120/1'},@{Rate='30000/1001'},@{Rate='0/0'}) {
        param($Rate)
        $source = New-GeometryInspection 641 479
        $source.PrimaryVideo.AverageFrameRate = ConvertTo-ProbeRatio $Rate
        $tokens = @(Get-EncodeArguments 'source' 'target' (Get-StreamPlan $source) 22 $null)
        @($tokens | Where-Object {$_ -in @('-r','-vsync','-fps_mode')}).Count | Should -Be 0
        ($tokens -join ' ') | Should -Not -Match 'fps='
    }
}
