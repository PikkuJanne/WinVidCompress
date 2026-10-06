BeforeAll {
    $script:OriginalAppData = $env:APPDATA
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
}
AfterAll { $env:APPDATA = $script:OriginalAppData }

Describe 'Pure encoder tokens [WVC-M2-03-A01]' {
    BeforeEach {
        $script:Plan = Get-StreamPlan (ConvertFrom-ProbeJson '{"streams":[{"index":3,"codec_type":"video","codec_name":"h264","width":1920,"height":1080},{"index":7,"codec_type":"audio","codec_name":"aac"}]}')
        $script:Metadata = Parse-MetadataFromName 'Band Name 29092025 - CamA.mov'
    }

    It 'preserves the complete default profile, absolute maps and metadata order' {
        $tokens = @(Get-EncodeArguments 'D:\source.mov' 'D:\output.mp4' $Plan 22 $Metadata)
        $expected = @('-hide_banner','-stdin','-nostats','-progress','pipe:1','-n','-i','D:\source.mov',
            '-map','0:3','-map','0:7','-c:v','libx264','-preset','veryfast','-crf','22','-pix_fmt:v:0','yuv420p',
            '-c:a','aac','-b:a','160k','-movflags','+faststart',
            '-metadata','title=Band Name 29092025 - CamA','-metadata','artist=Band Name',
            '-metadata','date=2025-09-29','-metadata','comment=Interview date 29.09.2025; Band: Band Name','D:\output.mp4')
        ($tokens -join "`n") | Should -BeExactly ($expected -join "`n")
    }

    It 'keeps paths and shell-looking metadata exact without filesystem or shell evaluation' {
        $source = 'D:\literal & (A) [x] !NAME! %PATH%\clip.mov'
        $target = 'D:\nonexistent\clip.mp4'
        $title = 'quote " & $(throw ''evaluated''); trailing\'
        $Metadata.Title = $title
        $before = $Plan | ConvertTo-Json -Depth 20
        Mock Test-Path { throw 'Pure helper performed IO' }
        $tokens = @(Get-EncodeArguments $source $target $Plan 23 $Metadata)
        $tokens[[array]::IndexOf($tokens,'-i')+1] | Should -BeExactly $source
        $tokens[-1] | Should -BeExactly $target
        $tokens | Should -Contain ('title=' + $title)
        $tokens[[array]::IndexOf($tokens,'-crf')+1] | Should -BeExactly '23'
        ($Plan | ConvertTo-Json -Depth 20) | Should -BeExactly $before
        Should -Invoke Test-Path -Times 0 -Exactly
    }

    It 'caps only heights above 1080 without upscaling or cropping <Height>' -TestCases @(
        @{Height=720;Filter=$false}, @{Height=1080;Filter=$false}, @{Height=2160;Filter=$true}
    ) {
        param($Height,$Filter)
        $Plan.Video.Height = $Height
        $tokens = @(Get-EncodeArguments 'source' 'target' $Plan 22 $Metadata)
        ($tokens -contains '-vf') | Should -Be $Filter
        if ($Filter) { $tokens[[array]::IndexOf($tokens,'-vf')+1] | Should -BeExactly 'scale=960:1080' }
        @($tokens | Where-Object { $_ -in @('-r','-ac','-ar','-filter_complex') }).Count | Should -Be 0
    }

    It 'omits audio options and absent metadata for a silent source' {
        $plan = Get-StreamPlan (ConvertFrom-ProbeJson '{"streams":[{"index":4,"codec_type":"video","codec_name":"h264","width":320,"height":240}]}')
        $tokens = @(Get-EncodeArguments 'source' 'target' $plan 22 $null)
        @($tokens | Where-Object { $_ -in @('-c:a','-b:a','-metadata') }).Count | Should -Be 0
        $tokens[[array]::IndexOf($tokens,'-map')+1] | Should -Be '0:4'
        $tokens[-1] | Should -Be 'target'
    }
}
