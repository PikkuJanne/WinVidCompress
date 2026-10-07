@{
    # Fixed accepted content; version URLs can be replaced upstream, so hashes are mandatory.
    Modules = @(
        @{ Name='Pester'; Version='5.7.1'; Algorithm='SHA512'
           Url='https://www.powershellgallery.com/api/v2/package/Pester/5.7.1'
           Hash='4d996a48dd94816d26b4e9e6935ae8e6ccbc19f8390ea3826345f121e1ce2ae7cce16369b517c190cead05ebff03123f8266abbd355604add5f129c24dcf2802' },
        @{ Name='PSScriptAnalyzer'; Version='1.24.0'; Algorithm='SHA512'
           Url='https://www.powershellgallery.com/api/v2/package/PSScriptAnalyzer/1.24.0'
           Hash='07cc95c221a4a4df4b53cabb701647801b412002a05be15ba5503f66d4870fae4ad455854d3ee74957de84a2f63aea32b9f3dff1535c6917c751307745bdd165' }
    )
    PowerShell = @{ Version='7.6.6'; Algorithm='SHA256'
        Url='https://github.com/PowerShell/PowerShell/releases/download/v7.6.6/PowerShell-7.6.6-win-x64.zip'
        Hash='02fe458be20493fbdf43f61ea20610b811ee6c738ab1676c61b9cfcd1a33c860' }
    FFmpeg = @{ Version='2026-10-04-git-a35c879992'; Algorithm='SHA256'
        Url='https://github.com/GyanD/codexffmpeg/releases/download/2026-10-04-git-a35c879992/ffmpeg-2026-10-04-git-a35c879992-essentials_build.zip'
        Hash='d5cee10a26cbb9c8cc937d91a92342c29a056497cd52ad5f6cad960d27cc41aa'
        Bin='ffmpeg-2026-10-04-git-a35c879992-essentials_build/bin'
        FFmpegHash='b6cc0d3390ae4969166895ee94657134a1de0c7790fa24ac0b4e315b8a667f83'
        FFprobeHash='aa14bea18d5b7e3834adade04c818bdf321e15a1fad1b99d29ad13181c975d1d' }
}
