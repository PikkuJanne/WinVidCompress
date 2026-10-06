BeforeAll {
    $script:SavedAppData=$env:APPDATA
    $env:APPDATA=Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
    function New-ColourInspection([string]$Transfer='bt709',[string]$Pixels='yuv420p10le',
        [string]$Primaries='bt709',[string]$Matrix='bt709',[string]$Range='tv') {
        ConvertFrom-ProbeJson (@{streams=@(@{index=3;codec_type='video';codec_name='h264';width=640;height=480;
            pix_fmt=$Pixels;color_transfer=$Transfer;color_primaries=$Primaries;color_space=$Matrix;color_range=$Range;
            duration='1';sample_aspect_ratio='1:1'});format=@{format_name='mp4';duration='1'}} | ConvertTo-Json -Depth 12)
    }
}
AfterAll {$env:APPDATA=$SavedAppData}

Describe 'Selected-stream SDR and HDR policy [WVC-M3-02-A01/A02]' {
    It 'supports <Pixels> SDR without guessing HDR from bit depth' -TestCases @(
        @{Pixels='yuv420p'},@{Pixels='yuv420p10le'},@{Pixels='yuv422p10le'},@{Pixels='yuv444p12le'}
    ) {
        param($Pixels)
        $inspection=New-ColourInspection -Pixels $Pixels
        $before=$inspection | ConvertTo-Json -Depth 20
        $colour=Get-VideoColourPlan $inspection.PrimaryVideo
        $colour.State | Should -Be 'SDR'
        $colour.Supported | Should -BeTrue
        $colour.OutputPixelFormat | Should -BeExactly 'yuv420p'
        ($inspection | ConvertTo-Json -Depth 20) | Should -BeExactly $before
    }
    It 'rejects <Transfer> even on contradictory eight-bit BT709 input' -TestCases @(
        @{Transfer='smpte2084'},@{Transfer='arib-std-b67'}
    ) {
        param($Transfer)
        $inspection=New-ColourInspection $Transfer 'yuv420p'
        $colour=Get-VideoColourPlan $inspection.PrimaryVideo
        $colour.State | Should -Be 'UnsupportedHDR'
        $colour.Supported | Should -BeFalse
        $colour.Reason | Should -Match 'HDR.*separately.*SDR'
        {Get-StreamPlan $inspection} | Should -Throw '*Unsupported HDR*'
    }
    It 'retains and refuses <Kind> evidence even with missing transfer' -TestCases @(
        @{Kind='Mastering display metadata'},@{Kind='Content light level metadata'},
        @{Kind='DOVI configuration record'},@{Kind='HDR Dynamic Metadata SMPTE2094-40 (HDR10+)'},
        @{Kind='HDR Dynamic Metadata CUVA 005.1 2021 (Vivid)'}
    ) {
        param($Kind)
        $raw=@{streams=@(@{index=0;codec_type='video';codec_name='hevc';width=640;height=480;
            side_data_list=@(@{side_data_type=$Kind})})}
        $inspection=ConvertFrom-ProbeJson ($raw | ConvertTo-Json -Depth 12)
        $inspection.PrimaryVideo.HdrMetadataTypes | Should -Contain $Kind
        (Get-VideoColourPlan $inspection.PrimaryVideo).State | Should -Be 'UnsupportedHDR'
    }
    It 'warns about ambiguous <Kind> without inventing Rec709 tags' -TestCases @(
        @{Kind='absent'},@{Kind='unknown'},@{Kind='reserved'},@{Kind='wideGamut'}
    ) {
        param($Kind)
        $inspection=New-ColourInspection '' '' '' '' ''
        if ($Kind -eq 'unknown') {$inspection.PrimaryVideo.ColourTransfer='unknown'}
        if ($Kind -eq 'reserved') {$inspection.PrimaryVideo.ColourTransfer='reserved'}
        if ($Kind -eq 'wideGamut') {$inspection.PrimaryVideo.ColourPrimaries='bt2020';$inspection.PrimaryVideo.ColourMatrix='bt2020nc'}
        $colour=Get-VideoColourPlan $inspection.PrimaryVideo
        $colour.State | Should -Be 'Ambiguous'
        $colour.Supported | Should -BeTrue
        ($colour.Warnings -join ' ') | Should -Match 'ambiguous.*HDR.*cannot'
        $tokens=@(Get-EncodeArguments 'source' 'target' (Get-StreamPlan $inspection) 22 $null)
        $tokens | Should -Not -Contain 'bt709'
    }
    It 'does not classify known BT2020 SDR as HDR' {
        $colour=Get-VideoColourPlan (New-ColourInspection 'bt2020-10' 'yuv420p10le' 'bt2020' 'bt2020nc').PrimaryVideo
        $colour.State | Should -Be 'SDR'
        $colour.Supported | Should -BeTrue
        ($colour.Warnings -join ' ') | Should -Match 'wide gamut'
    }
    It 'refuses untested <Kind> transforms' -TestCases @(
        @{Kind='RGB'},@{Kind='linear'},@{Kind='log'},@{Kind='vlog'},@{Kind='constantLuminance'},@{Kind='ictcp'},@{Kind='contradictoryRange'}
    ) {
        param($Kind)
        $video=(New-ColourInspection).PrimaryVideo
        switch ($Kind) {
            RGB {$video.PixelFormat='gbrp';$video.ColourMatrix='gbr'}
            linear {$video.ColourTransfer='linear'}
            log {$video.ColourTransfer='log100'}
            vlog {$video.ColourTransfer='vlog'}
            contradictoryRange {$video.PixelFormat='yuvj420p';$video.ColourRange='tv'}
            constantLuminance {$video.ColourMatrix='bt2020c'}
            ictcp {$video.ColourMatrix='ictcp'}
        }
        (Get-VideoColourPlan $video).Supported | Should -BeFalse
    }
    It 'keeps multiple HDR metadata types readable in the unsupported reason' {
        $video=(New-ColourInspection '').PrimaryVideo
        $video.HdrMetadataTypes=@('Mastering display metadata','Content light level metadata')
        $colour=Get-VideoColourPlan $video
        $colour.Reason | Should -Match 'Mastering display metadata, Content light level metadata'
        $colour.Reason | Should -Not -Match 'System.Object'
    }
    It 'plans only the selected stream and recomputes colour from its same video reference' {
        $source=New-ColourInspection
        $alternate=(New-ColourInspection 'smpte2084').PrimaryVideo;$alternate.Index=9
        $source.Streams += $alternate
        $plan=Get-StreamPlan $source
        $plan.Colour.State | Should -Be 'SDR'
        $plan.Video.ColourTransfer='smpte2084'
        {Get-EncodeArguments 'source' 'target' $plan 22 $null} | Should -Throw '*Unsupported HDR*'
    }
    It 'fails HDR before allocation and encoding with an actionable recorded job' {
        $source=Join-Path $TestDrive 'hdr.mov';$output=Join-Path $TestDrive 'output'
        [IO.File]::WriteAllText($source,'source sentinel');[void][IO.Directory]::CreateDirectory($output)
        $script:HdrInspection=New-ColourInspection 'arib-std-b67'
        Mock Get-MediaInspection {$script:HdrInspection}
        Mock New-OutputJob {throw 'Allocated HDR output'}
        Mock Invoke-EncodeProcess {throw 'Encoded HDR'}
        Mock Write-Host {}
        $result=Compress-One 'unused' 'unused' $source $output 22
        $result.Outcome | Should -Be 'Failed'
        $result.Stage | Should -Be 'Colour'
        $result.Reason | Should -Match 'Unsupported HDR'
        Should -Invoke New-OutputJob -Times 0
        Should -Invoke Invoke-EncodeProcess -Times 0
    }
}

Describe 'Compatibility tokens and output colour checks [WVC-M3-02-A03]' {
    It 'preserves known SDR tags as literal arguments with the accepted quality profile' {
        $tokens=@(Get-EncodeArguments 'source' 'target' (Get-StreamPlan (New-ColourInspection)) 22 $null)
        foreach ($pair in @(@('-pix_fmt:v:0','yuv420p'),@('-color_primaries:v:0','bt709'),
            @('-color_trc:v:0','bt709'),@('-colorspace:v:0','bt709'),@('-color_range:v:0','tv'),
            @('-crf','22'),@('-preset','veryfast'))) {
            $tokens[[array]::IndexOf($tokens,$pair[0])+1] | Should -BeExactly $pair[1]
        }
        ($tokens -join ' ') | Should -Not -Match 'tonemap|zscale|setparams|fps='
    }
    It 'converts full range through samples and combines scale without a crop or upscale' {
        $plan=Get-StreamPlan (New-ColourInspection -Pixels 'yuvj420p' -Range 'pc')
        $plan.Video.Width=1920;$plan.Video.Height=2160
        $tokens=@(Get-EncodeArguments 'source' 'target' $plan 22 $null)
        $tokens[[array]::IndexOf($tokens,'-vf')+1] | Should -BeExactly 'scale=960:1080:in_range=pc:out_range=tv'
        $tokens[[array]::IndexOf($tokens,'-color_range:v:0')+1] | Should -BeExactly 'tv'
    }
    It 'rejects output <Kind> rather than promoting incompatible or falsely tagged media' -TestCases @(
        @{Kind='10bit'},@{Kind='missingPixel'},@{Kind='HDR'},@{Kind='lostTransfer'},@{Kind='changedMatrix'},@{Kind='fullRange'},@{Kind='missingRange'},@{Kind='sideHDR'}
    ) {
        param($Kind)
        $source=New-ColourInspection;$output=New-ColourInspection -Pixels 'yuv420p'
        switch ($Kind) {
            '10bit' {$output.PrimaryVideo.PixelFormat='yuv420p10le'}
            missingPixel {$output.PrimaryVideo.PixelFormat=$null}
            HDR {$output.PrimaryVideo.ColourTransfer='smpte2084'}
            lostTransfer {$output.PrimaryVideo.ColourTransfer=$null}
            changedMatrix {$output.PrimaryVideo.ColourMatrix='smpte170m'}
            fullRange {$output.PrimaryVideo.ColourRange='pc'}
            missingRange {$output.PrimaryVideo.ColourRange=$null}
            sideHDR {$output.PrimaryVideo.HdrMetadataTypes=@('Mastering display metadata')}
        }
        {Test-OutputColour $output.PrimaryVideo $source.PrimaryVideo} | Should -Throw
    }
    It 'reports unavailable limited-range signalling only for otherwise untagged output' {
        $source=New-ColourInspection '' 'yuv420p10le' '' '' 'tv'
        $output=New-ColourInspection '' 'yuv420p' '' '' ''
        $warnings=@(Test-OutputColour $output.PrimaryVideo $source.PrimaryVideo)
        ($warnings -join ' ') | Should -Match 'range signalling is unavailable'
        $source.PrimaryVideo.ColourRange='pc'
        {Test-OutputColour $output.PrimaryVideo $source.PrimaryVideo} | Should -Not -Throw
        $output.PrimaryVideo.ColourPrimaries='bt709'
        {Test-OutputColour $output.PrimaryVideo $source.PrimaryVideo} | Should -Throw
    }
    It 'accepts the intended 8bit SDR output and missing-source colour remains a limitation' {
        {Test-OutputColour (New-ColourInspection -Pixels 'yuv420p').PrimaryVideo (New-ColourInspection).PrimaryVideo} | Should -Not -Throw
        $warnings=@(Test-OutputColour (New-ColourInspection -Pixels 'yuv420p').PrimaryVideo (New-ColourInspection '' '' '' '' '').PrimaryVideo)
        ($warnings -join ' ') | Should -Match 'ambiguous'
    }
}
