BeforeAll {
    $script:OriginalToolEnvironment = @{ APPDATA=$env:APPDATA; PATH=$env:PATH; FFMPEG=$env:FFMPEG }
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'WinVidCompress.ps1')
    function New-DiscoveryTool([string]$Directory,[string]$Name='ffmpeg.exe') {
        [void][IO.Directory]::CreateDirectory($Directory)
        $tool = Join-Path $Directory $Name
        [IO.File]::WriteAllText($tool,'Resolver-only sentinel; must never be executed.')
        $tool
    }
}

AfterAll {
    foreach ($key in $OriginalToolEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($key,$OriginalToolEnvironment[$key],'Process')
    }
}

Describe 'Scoped executable discovery [WVC-HOTFIX-1.0.1]' {
    BeforeEach {
        $script:DiscoveryRoot = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $script:EmptyPath = Join-Path $DiscoveryRoot 'empty'
        $script:AppDirectory = Join-Path $DiscoveryRoot 'application'
        [void][IO.Directory]::CreateDirectory($EmptyPath)
        [void][IO.Directory]::CreateDirectory($AppDirectory)
        $script:ApplicationPath = Join-Path $AppDirectory 'WinVidCompress.ps1'
        [IO.File]::WriteAllText($ApplicationPath,'# isolated application location')
        $env:PATH = $EmptyPath
        $env:FFMPEG = $null
        $script:ScopeValues = @{}
        $script:ToolDiscovery = @{}
        Mock Get-ToolEnvironmentVariable {
            param($Name,$Scope)
            $ScopeValues[($Scope+':'+$Name)]
        }
        Mock Invoke-EnvironmentCall { throw 'Discovery must not probe native tools.' }
    }

    It 'preserves inherited process PATH before all lower-priority sources' {
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'process path')
        $env:PATH = Split-Path -Parent $expected
        [void](New-DiscoveryTool $AppDirectory)
        $ScopeValues['Process:FFMPEG'] = Split-Path -Parent (New-DiscoveryTool (Join-Path $DiscoveryRoot 'hint'))
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'Process PATH'
        Should -Invoke Get-ToolEnvironmentVariable -Times 0 -Exactly
        Should -Invoke Invoke-EnvironmentCall -Times 0 -Exactly
    }

    It 'uses the application directory from an unrelated working directory before hints' {
        $expected = New-DiscoveryTool $AppDirectory
        $ScopeValues['Process:FFMPEG'] = Split-Path -Parent (New-DiscoveryTool (Join-Path $DiscoveryRoot 'hint'))
        Push-Location $EmptyPath
        try { Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected }
        finally { Pop-Location }
        $ToolDiscovery['ffmpeg.exe'].Path | Should -BeExactly $expected
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'Script directory'
    }

    It 'selects FFMPEG from <Scope> scope with exact provenance' -TestCases @(
        @{Scope='Process'}, @{Scope='User'}, @{Scope='Machine'}
    ) {
        param($Scope)
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'installation with spaces')
        $ScopeValues[($Scope+':FFMPEG')] = Split-Path -Parent $expected
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly ('FFMPEG ('+$Scope+')')
        Should -Invoke Invoke-EnvironmentCall -Times 0 -Exactly
    }

    It 'preserves Process then User then Machine FFMPEG ordering' {
        $process = New-DiscoveryTool (Join-Path $DiscoveryRoot 'process hint')
        $user = New-DiscoveryTool (Join-Path $DiscoveryRoot 'user hint')
        $machine = New-DiscoveryTool (Join-Path $DiscoveryRoot 'machine hint')
        $ScopeValues['Process:FFMPEG'] = Split-Path -Parent $process
        $ScopeValues['User:FFMPEG'] = Split-Path -Parent $user
        $ScopeValues['Machine:FFMPEG'] = Split-Path -Parent $machine
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $process
        $ScopeValues['Process:FFMPEG'] = Join-Path $DiscoveryRoot 'stale'
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $user
        $ScopeValues['User:FFMPEG'] = Join-Path $DiscoveryRoot 'also stale'
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $machine
    }

    It 'accepts a <Form> FFMPEG hint for both tools' -TestCases @(
        @{Form='bin'}, @{Form='root'}, @{Form='exe'}, @{Form='quoted bin'}, @{Form='trailing separator'}
    ) {
        param($Form)
        $root = Join-Path $DiscoveryRoot 'media tools'
        $bin = Join-Path $root 'bin'
        $encoder = New-DiscoveryTool $bin
        $probe = New-DiscoveryTool $bin 'ffprobe.exe'
        $hint = switch ($Form) {
            'bin' { $bin }
            'root' { $root }
            'exe' { $encoder }
            'quoted bin' { '  "'+$bin+'"  ' }
            'trailing separator' { $bin+'\' }
        }
        $ScopeValues['Process:FFMPEG'] = $hint
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $encoder
        Ensure-Tool 'ffprobe.exe' | Should -BeExactly $probe
        $ToolDiscovery['ffprobe.exe'].Source | Should -BeExactly 'FFMPEG (Process)'
    }

    It 'continues past a stale Process hint to persisted PATH' {
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'persisted installation')
        $ScopeValues['Process:FFMPEG'] = Join-Path $DiscoveryRoot 'uninstalled'
        $ScopeValues['User:PATH'] = Split-Path -Parent $expected
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'PATH (User)'
    }

    It 'selects persisted <Scope> PATH in listed entry order' -TestCases @(
        @{Scope='Machine'}, @{Scope='User'}
    ) {
        param($Scope)
        $first = New-DiscoveryTool (Join-Path $DiscoveryRoot 'first')
        $second = New-DiscoveryTool (Join-Path $DiscoveryRoot 'second')
        $ScopeValues[($Scope+':PATH')] = (Join-Path $DiscoveryRoot 'absent')+';'+(Split-Path -Parent $first)+';'+(Split-Path -Parent $second)
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $first
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly ('PATH ('+$Scope+')')
    }

    It 'selects Machine persisted PATH before User persisted PATH' {
        $machine = New-DiscoveryTool (Join-Path $DiscoveryRoot 'machine path')
        $user = New-DiscoveryTool (Join-Path $DiscoveryRoot 'user path')
        $ScopeValues['Machine:PATH'] = Split-Path -Parent $machine
        $ScopeValues['User:PATH'] = Split-Path -Parent $user
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $machine
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'PATH (Machine)'
    }

    It 'expands a quoted persisted User PATH reference to a User variable' {
        $root = Join-Path $DiscoveryRoot 'user installation'
        $expected = New-DiscoveryTool (Join-Path $root 'bin')
        $ScopeValues['User:TOOLS_ROOT'] = $root
        $ScopeValues['User:PATH'] = '  "%TOOLS_ROOT%\bin"  '
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'PATH (User)'
    }

    It 'expands FFMPEG within persisted PATH even when its direct hint has no tools' {
        $root = Join-Path $DiscoveryRoot 'tool parent'
        $expected = New-DiscoveryTool (Join-Path $root 'custom bin')
        $ScopeValues['User:FFMPEG'] = $root
        $ScopeValues['User:PATH'] = '%FFMPEG%\custom bin'
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'PATH (User)'
    }

    It 'uses scope-aware expansion rather than a stale Process value in User PATH' {
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'correct user tools')
        $ScopeValues['Process:TOOLS'] = Join-Path $DiscoveryRoot 'stale process tools'
        $ScopeValues['User:TOOLS'] = Split-Path -Parent $expected
        $ScopeValues['User:PATH'] = '%TOOLS%'
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'PATH (User)'
    }

    It 'allows User expansion to fall back to a Machine variable' {
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'machine variable')
        $ScopeValues['Machine:TOOLS'] = Split-Path -Parent $expected
        $ScopeValues['User:PATH'] = '%TOOLS%'
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
    }

    It 'does not expand a Machine PATH using a User-only variable' {
        $wrong = New-DiscoveryTool (Join-Path $DiscoveryRoot 'user variable')
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'concrete user path')
        $ScopeValues['User:TOOLS'] = Split-Path -Parent $wrong
        $ScopeValues['Machine:PATH'] = '%TOOLS%'
        $ScopeValues['User:PATH'] = Split-Path -Parent $expected
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
    }

    It 'expands bounded nested variables and ignores cyclic references' {
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'expanded tools')
        $ScopeValues['Process:FFMPEG'] = '%LOOP_A%'
        $ScopeValues['Process:LOOP_A'] = '%LOOP_B%'
        $ScopeValues['Process:LOOP_B'] = '%LOOP_A%'
        $ScopeValues['User:PATH'] = '%FIRST%'
        $ScopeValues['User:FIRST'] = '%SECOND%'
        $ScopeValues['User:SECOND'] = Split-Path -Parent $expected
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'PATH (User)'
    }

    It 'expands a Windows login variable synthesized only in the process environment' {
        $root = Join-Path $DiscoveryRoot 'login profile'
        $expected = New-DiscoveryTool (Join-Path $root 'codec tools')
        $ScopeValues['Process:LOCALAPPDATA'] = $root
        $ScopeValues['User:PATH'] = '%LOCALAPPDATA%\codec tools'
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'PATH (User)'
    }

    It 'ignores a <Kind> hint and proceeds to a valid later path' -TestCases @(
        @{Kind='empty';Value=''}, @{Kind='whitespace';Value='   '},
        @{Kind='unresolved';Value='%WVC_NO_SUCH_VARIABLE%'},
        @{Kind='relative';Value='relative\bin'}, @{Kind='drive relative';Value='C:relative'},
        @{Kind='malformed';Value='C:\invalid*folder'}, @{Kind='shell expression';Value='& whoami.exe'}
    ) {
        param($Kind,$Value)
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'valid fallback')
        $ScopeValues['Process:FFMPEG'] = $Value
        $ScopeValues['User:PATH'] = Split-Path -Parent $expected
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
        Should -Invoke Invoke-EnvironmentCall -Times 0 -Exactly
    }

    It 'ignores empty and repeated case-insensitive persisted PATH entries' {
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'later tools')
        $absent = Join-Path $DiscoveryRoot 'absent'
        $ScopeValues['Machine:PATH'] = ';'+$absent+';'+$absent.ToUpperInvariant()+';;'+(Split-Path -Parent $expected)+';'
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'PATH (Machine)'
    }

    It 'checks a repeated candidate only once across scopes and case variants' {
        $directory = Join-Path $DiscoveryRoot 'missing tools'
        $candidate = Join-Path $directory 'ffmpeg.exe'
        $ScopeValues['Process:FFMPEG'] = $directory
        $ScopeValues['User:FFMPEG'] = $directory.ToUpperInvariant()
        $ScopeValues['Machine:PATH'] = $directory+';'+$directory.ToUpperInvariant()
        Mock Test-Path { $false }
        { Ensure-Tool 'ffmpeg.exe' } | Should -Throw '*ffmpeg.exe*not found*'
        Should -Invoke Test-Path -Times 1 -Exactly -ParameterFilter { $LiteralPath -ieq $candidate }
    }

    It 'continues to lower scopes when an optional scoped read is denied' {
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'accessible user tools')
        $ScopeValues['User:FFMPEG'] = Split-Path -Parent $expected
        Mock Get-ToolEnvironmentVariable { throw 'Synthetic scope read denied.' } -ParameterFilter {
            $Name -eq 'FFMPEG' -and $Scope -eq 'Process'
        }
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'FFMPEG (User)'
    }

    It 'continues past an inaccessible optional hint to an accessible later location' {
        $locked = New-DiscoveryTool (Join-Path $DiscoveryRoot 'locked hint')
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'accessible hint')
        $ScopeValues['Process:FFMPEG'] = $locked
        $ScopeValues['User:FFMPEG'] = Split-Path -Parent $expected
        $handle = [IO.File]::Open($locked,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None)
        try { Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected }
        finally { $handle.Dispose() }
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'FFMPEG (User)'
    }

    It 'supports split installations without inferring a mandatory pair directory' {
        $encoder = New-DiscoveryTool (Join-Path $DiscoveryRoot 'encoder')
        $probe = New-DiscoveryTool (Join-Path $DiscoveryRoot 'probe') 'ffprobe.exe'
        $ScopeValues['Process:FFMPEG'] = $encoder
        $ScopeValues['User:PATH'] = Split-Path -Parent $probe
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $encoder
        Ensure-Tool 'ffprobe.exe' | Should -BeExactly $probe
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'FFMPEG (Process)'
        $ToolDiscovery['ffprobe.exe'].Source | Should -BeExactly 'PATH (User)'
    }

    It 'never discovers a tool implicitly from the current directory' {
        $cwd = Join-Path $DiscoveryRoot 'untrusted current directory'
        [void](New-DiscoveryTool $cwd)
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'trusted hint')
        $ScopeValues['User:FFMPEG'] = Split-Path -Parent $expected
        Push-Location $cwd
        try { Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected }
        finally { Pop-Location }
        $ToolDiscovery['ffmpeg.exe'].Source | Should -BeExactly 'FFMPEG (User)'
    }

    It 'ignores a relative process PATH component even when Get-Command finds it' {
        $cwd = Join-Path $DiscoveryRoot 'working'
        $relative = Join-Path $cwd 'relative tools'
        [void](New-DiscoveryTool $relative)
        $expected = New-DiscoveryTool (Join-Path $DiscoveryRoot 'absolute tools')
        $env:PATH = '.\relative tools'
        $ScopeValues['User:FFMPEG'] = Split-Path -Parent $expected
        Push-Location $cwd
        try { Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $expected }
        finally { Pop-Location }
    }

    It 'refuses a <Kind> shell shadow before trying hints' -TestCases @(
        @{Kind='Function'}, @{Kind='Alias'}
    ) {
        param($Kind)
        $ScopeValues['User:FFMPEG'] = Split-Path -Parent (New-DiscoveryTool (Join-Path $DiscoveryRoot 'unused hint'))
        Mock Get-Command { [pscustomobject]@{CommandType=$Kind} } -ParameterFilter { $Name -eq 'ffmpeg.exe' }
        { Ensure-Tool 'ffmpeg.exe' } | Should -Throw '*not an application*'
        Should -Invoke Invoke-EnvironmentCall -Times 0 -Exactly
    }

    It 'reports the genuinely missing tool by name' {
        { Ensure-Tool 'ffmpeg.exe' } | Should -Throw '*ffmpeg.exe*not found*'
        Should -Invoke Invoke-EnvironmentCall -Times 0 -Exactly
    }

    It 'reports FFprobe missing independently after resolving FFmpeg' {
        $encoder = New-DiscoveryTool (Join-Path $DiscoveryRoot 'encoder only')
        $ScopeValues['Process:FFMPEG'] = $encoder
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $encoder
        { Ensure-Tool 'ffprobe.exe' } | Should -Throw '*ffprobe.exe*not found*'
    }

    It 'distinguishes an inaccessible selected executable from not found' {
        $encoder = New-DiscoveryTool (Join-Path $DiscoveryRoot 'locked executable')
        $ScopeValues['Process:FFMPEG'] = $encoder
        $handle = [IO.File]::Open($encoder,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::None)
        try { { Ensure-Tool 'ffmpeg.exe' } | Should -Throw '*ffmpeg.exe*cannot be read*' }
        finally { $handle.Dispose() }
    }
}
