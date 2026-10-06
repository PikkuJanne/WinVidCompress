BeforeDiscovery {
    $script:MetadataToolsAvailable=[bool](Get-Command ffmpeg.exe -CommandType Application -ErrorAction SilentlyContinue) -and
        [bool](Get-Command ffprobe.exe -CommandType Application -ErrorAction SilentlyContinue)
}
BeforeAll {
    $script:RepoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:SavedEnvironment=@{APPDATA=$env:APPDATA;FFREPORT=$env:FFREPORT}
    $script:BootstrapOwner=New-WvcTestRoot
    $env:APPDATA=Join-Path $BootstrapOwner.Path 'appdata';$env:FFREPORT=$null
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    if ($MetadataToolsAvailable) {
        $script:MetadataEncoder=(Get-Command ffmpeg.exe -CommandType Application).Source
        $script:MetadataProbe=(Get-Command ffprobe.exe -CommandType Application).Source
    }
}
AfterAll {
    foreach ($key in $SavedEnvironment.Keys) {[Environment]::SetEnvironmentVariable($key,$SavedEnvironment[$key],'Process')}
    Remove-WvcTestRoot $BootstrapOwner
}

Describe 'Actual MP4 interview tags and inheritance [WVC-M3-03-A02/A03/A04; FFmpeg/FFprobe required]' {
    BeforeEach {
        if (Get-Variable WvcProcessCleanupFailed -Scope Script -ErrorAction SilentlyContinue) {throw 'Process cleanup failed; retain roots and stop.'}
        $script:Owner=New-WvcTestRoot
        $env:APPDATA=Join-Path $Owner.Path 'appdata'
        $script:Output=Join-Path $Owner.Path 'output';[void][IO.Directory]::CreateDirectory($Output)
        $script:Source=$null;$script:SourceHash=$null;$script:Sentinel=$null;$script:FinalHash=$null
        $script:CollisionMode='rename'
    }
    AfterEach {
        if ($SourceHash) {(Get-FileHash -LiteralPath $Source).Hash | Should -BeExactly $SourceHash}
        if ($FinalHash) {(Get-FileHash -LiteralPath $Sentinel).Hash | Should -BeExactly $FinalHash}
        if ($null -ne $Owner) {Remove-WvcTestRoot $Owner}
    }

    It 'compresses <Case> and reads exact UTF-8 tags with safe publication' -Skip:(-not $MetadataToolsAvailable) -TestCases @(
        @{Case='Finnish/German';Name=('M'+[char]0x00e4+'ki Gr'+[char]0x00f6+[char]0x00df+'e 29.02.2024 - CamA');Band=('M'+[char]0x00e4+'ki Gr'+[char]0x00f6+[char]0x00df+'e');Date='2024-02-29';Status='Parsed';Inherit=$true},
        @{Case='CJK/Cyrillic';Name=([string][char]0x6771+[char]0x4eac+' '+[char]0x041c+[char]0x0438+[char]0x0440+' 29022024');Band=([string][char]0x6771+[char]0x4eac+' '+[char]0x041c+[char]0x0438+[char]0x0440);Date='2024-02-29';Status='Parsed';Inherit=$true},
        @{Case='literal punctuation fallback';Name='Band & [A] !NAME! %PATH% $(echo literal); 29022024 CamA';Band='Band & [A] !NAME! %PATH% $(echo literal);';Date='2024-02-29';Status='Fallback';Inherit=$true},
        @{Case='31 February';Name='Band 31022024';Band='';Date='';Status='InvalidDate';Inherit=$true},
        @{Case='two dates';Name='Band 29022024 - take 01.03.2024';Band='';Date='';Status='Ambiguous';Inherit=$true},
        @{Case='blank artist';Name=' 29022024 - CamA';Band='';Date='';Status='MissingBand';Inherit=$true},
        @{Case='unrelated long serial';Name='Camera serial 123456789';Band='';Date='';Status='NoDate';Inherit=$true},
        @{Case='invalid leap without source interview tags';Name='Band 29022023';Band='';Date='';Status='InvalidDate';Inherit=$false}
    ) {
        param($Case,$Name,$Band,$Date,$Status,$Inherit)
        $script:Source=Join-Path $Owner.Path ($Name+'.mp4')
        $script:Sentinel=Join-Path $Output ($Name+'.mp4')
        [IO.File]::WriteAllText($Sentinel,'existing final sentinel')
        $script:FinalHash=(Get-FileHash -LiteralPath $Sentinel).Hash
        $copyright='Synthetic test '+[char]0x00a9+' '+[char]0x00e4+[char]0x6771
        $sourceArtist='Source '+[char]0x00e4+[char]0x6771
        $sourceComment='Source comment '+[char]0x00df+[char]0x041c
        $arguments=@('-hide_banner','-nostdin','-v','error','-n','-f','lavfi','-i','testsrc2=size=160x120:rate=24:duration=0.5',
            '-f','lavfi','-i','sine=frequency=440:sample_rate=48000:duration=0.5',
            '-map','0:v:0','-map','1:a:0','-c:v','libx264','-preset','veryfast','-crf','18','-pix_fmt','yuv420p','-c:a','aac',
            '-metadata','title=Source title','-metadata',('copyright='+$copyright),'-metadata','private_test_tag=synthetic marker',
            '-metadata:s:a:0','language=deu','-movflags','+use_metadata_tags')
        if ($Inherit) {$arguments+=@('-metadata',('artist='+$sourceArtist),'-metadata','date=1999-12-31','-metadata',('comment='+$sourceComment))}
        $arguments+=$Source
        $generated=Invoke-WvcTestProcess $MetadataEncoder $arguments
        $generated.ExitCode | Should -Be 0 -Because $generated.StdErr
        $script:SourceHash=(Get-FileHash -LiteralPath $Source).Hash
        $sourceInspection=Get-MediaInspection $MetadataProbe $Source
        $sourceInspection.Succeeded | Should -BeTrue -Because $sourceInspection.Reason
        $sourceTags=($sourceInspection.Native.StdOut | ConvertFrom-Json).format.tags
        $sourceTags.title | Should -BeExactly 'Source title'
        $sourceTags.copyright | Should -BeExactly $copyright
        $sourceTags.private_test_tag | Should -BeExactly 'synthetic marker'
        $sourceAudio=@($sourceInspection.Streams | Where-Object CodecType -eq 'audio')
        $sourceAudio[0].Language | Should -BeExactly 'deu'
        if ($Inherit) {
            $sourceTags.artist | Should -BeExactly $sourceArtist
            $sourceTags.date | Should -BeExactly '1999-12-31'
            $sourceTags.comment | Should -BeExactly $sourceComment
        }
        $meta=Parse-MetadataFromName ([IO.Path]::GetFileName($Source))
        $meta.ParseStatus | Should -BeExactly $Status
        try {$job=Compress-One $MetadataEncoder $MetadataProbe $Source $Output 22}
        catch {
            if ($_.Exception.Data.Contains('WvcAbortBatch')) {$script:WvcProcessCleanupFailed=$true}
            throw
        }
        $job.Outcome | Should -BeExactly 'Completed' -Because $job.Reason
        $job.Diagnostics.Encode.ExitCode | Should -Be 0
        $job.Diagnostics.Validation.Succeeded | Should -BeTrue
        $job.OutputPath | Should -Not -BeExactly $Sentinel
        @((Get-ChildItem -LiteralPath $Output -File -Filter '*.mp4')).Count | Should -Be 2
        @((Get-ChildItem -LiteralPath $Output -Filter '*.partial.mp4' -Recurse)).Count | Should -Be 0
        $tags=($job.Diagnostics.Validation.Inspection.Native.StdOut | ConvertFrom-Json).format.tags
        $tags.title | Should -BeExactly $Name
        $tags.copyright | Should -BeExactly $copyright
        # Standard MP4 muxing retains supported tags; arbitrary mdta source keys
        # are not promised or requested via use_metadata_tags in the application.
        $tags.PSObject.Properties.Name | Should -Not -Contain 'private_test_tag'
        if ($Date) {
            $tags.artist | Should -BeExactly $Band
            $tags.date | Should -BeExactly $Date
            $tags.comment | Should -BeExactly ('Interview date '+$meta.DateHuman+'; Band: '+$Band)
        } elseif ($Inherit) {
            $tags.artist | Should -BeExactly $sourceArtist
            $tags.date | Should -BeExactly '1999-12-31'
            $tags.comment | Should -BeExactly $sourceComment
        } else {
            foreach ($key in @('artist','date','comment')) {$tags.PSObject.Properties.Name | Should -Not -Contain $key}
        }
        if ($Status -ne 'Parsed') {
            foreach ($warning in $meta.Warnings) {$job.Diagnostics.Warnings | Should -Contain $warning}
        }
        $audio=@($job.Diagnostics.Validation.Inspection.Streams | Where-Object CodecType -eq 'audio')
        $audio[0].Language | Should -BeExactly 'deu'
    }
}
