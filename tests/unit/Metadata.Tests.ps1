BeforeAll {
    $script:SavedAppData=$env:APPDATA
    $env:APPDATA=Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
}
AfterAll { $env:APPDATA=$SavedAppData }

Describe 'Invariant filename interview metadata [WVC-M3-03-A01/A04]' {
    It 'validates <Token> using the Gregorian calendar under <Culture>' -TestCases @(
        foreach ($culture in @('fi-FI','de-DE','en-US','ar-SA')) {
            foreach ($token in @('29022024','29.02.2024','29-02-2024','29022000')) {
                @{Token=$token;Culture=$culture;ISO=$(if ($token -eq '29022000') {'2000-02-29'} else {'2024-02-29'})}
            }
        }
    ) {
        param($Token,$Culture,$ISO)
        $saved=[Threading.Thread]::CurrentThread.CurrentCulture
        try {
            [Threading.Thread]::CurrentThread.CurrentCulture=[Globalization.CultureInfo]::GetCultureInfo($Culture)
            $meta=Parse-MetadataFromName ('Band Name '+$Token+' - CamA.mov')
            $meta.Band | Should -BeExactly 'Band Name'
            $meta.DateISO | Should -BeExactly $ISO
            $meta.DateHuman | Should -BeExactly ('29.02.'+$ISO.Substring(0,4))
            $meta.ParseStatus | Should -BeExactly 'Parsed'
            @($meta.Warnings).Count | Should -Be 0
        } finally { [Threading.Thread]::CurrentThread.CurrentCulture=$saved }
    }

    It 'omits the entire interview tuple for <Name> (<Status>)' -TestCases @(
        @{Name='Band 29022023.mov';Status='InvalidDate'},
        @{Name='Band 29021900.mov';Status='InvalidDate'},
        @{Name='Band 31022024.mov';Status='InvalidDate'},
        @{Name='Band 31.04.2024.mov';Status='InvalidDate'},
        @{Name='Band 01132024.mov';Status='InvalidDate'},
        @{Name='Band 01002024.mov';Status='InvalidDate'},
        @{Name='Band 00012024.mov';Status='InvalidDate'},
        @{Name='Band 32012024.mov';Status='InvalidDate'},
        @{Name='Band 01010000.mov';Status='InvalidDate'},
        @{Name='Band serial 12345678 CamA.mov';Status='InvalidDate'},
        @{Name='29022024.mov';Status='MissingBand'},
        @{Name='   29.02.2024 - CamA.mov';Status='MissingBand'},
        @{Name='Band 29.02-2024.mov';Status='NoDate'},
        @{Name='Band 29-02.2024.mov';Status='NoDate'},
        @{Name='Band serial 123456789.mov';Status='NoDate'},
        @{Name='Band camera29022024.mov';Status='NoDate'},
        @{Name='Band 29022024CamA.mov';Status='NoDate'},
        @{Name='Band 29022024 - copy 01032024.mov';Status='Ambiguous'},
        @{Name='Band 29022024 - copy 29.02.2024.mov';Status='Ambiguous'},
        @{Name='Band 31022024 - copy 29-02-2024.mov';Status='Ambiguous'},
        @{Name='Band 29.02.2024 - copy 01-03-2024.mov';Status='Ambiguous'},
        @{Name='Untitled clip.mov';Status='NoDate'},
        @{Name='Band 29.02.2024 CamA.mov';Status='UnsupportedPattern'}
    ) {
        param($Name,$Status)
        $meta=Parse-MetadataFromName $Name
        $meta.Title | Should -BeExactly ([IO.Path]::GetFileNameWithoutExtension($Name))
        $meta.ParseStatus | Should -BeExactly $Status
        $meta.Band | Should -BeExactly ''
        $meta.DateISO | Should -BeExactly ''
        $meta.DateHuman | Should -BeExactly ''
        @($meta.Warnings).Count | Should -Be 1
        $meta.Warnings[0] | Should -Match 'Filename-derived artist/date/comment omitted'
    }

    It 'retains the compact fallback and discloses its unlabelled-token ambiguity' {
        $meta=Parse-MetadataFromName 'Band 29092025 CamA.mov'
        $meta.ParseStatus | Should -BeExactly 'Fallback'
        $meta.Band | Should -BeExactly 'Band'
        $meta.DateISO | Should -BeExactly '2025-09-29'
        $meta.Warnings[0] | Should -Match 'unlabelled.*number'
    }

    It 'keeps a calendar-valid standalone number as a disclosed legacy fallback' {
        $meta=Parse-MetadataFromName 'Camera serial 01012025 take.mov'
        $meta.DateISO | Should -BeExactly '2025-01-01'
        $meta.ParseStatus | Should -BeExactly 'Fallback'
        @($meta.Warnings).Count | Should -Be 1
    }

    It 'preserves Unicode and shell-looking artist/title as literal tokens' {
        $band='M'+[char]0x00e4+'ki & Gr'+[char]0x00f6+'sse '+[char]0x6771+[char]0x4eac+' $(throw ''executed'') %PATH% !NAME! [A]'
        $name=$band+' 29.02.2024 - CamA.mov'
        $meta=Parse-MetadataFromName $name
        $meta.Band | Should -BeExactly $band
        $meta.Title | Should -BeExactly ([IO.Path]::GetFileNameWithoutExtension($name))
        $plan=Get-StreamPlan (ConvertFrom-ProbeJson '{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":160,"height":120}]}')
        $tokens=@(Get-EncodeArguments 'source.mov' 'output.mp4' $plan 22 $meta)
        $tokens | Should -Contain ('artist='+$band)
        $tokens | Should -Contain ('comment=Interview date 29.02.2024; Band: '+$band)
        $tokens | Should -Contain ('title='+$meta.Title)
    }

    It 'generates only title on invalid date without clearing inherited source tags' {
        $plan=Get-StreamPlan (ConvertFrom-ProbeJson '{"streams":[{"index":0,"codec_type":"video","codec_name":"h264","width":160,"height":120}]}')
        $tokens=@(Get-EncodeArguments 'source.mov' 'output.mp4' $plan 22 (Parse-MetadataFromName 'Band 31022024.mov'))
        $values=@(for ($i=0;$i -lt $tokens.Count;$i++) { if ($tokens[$i] -eq '-metadata') {$tokens[$i+1]} })
        $values.Count | Should -Be 1
        $values[0] | Should -BeExactly 'title=Band 31022024'
        $tokens | Should -Not -Contain '-map_metadata'
    }
}
