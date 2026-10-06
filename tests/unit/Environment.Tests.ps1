BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
    $script:OriginalEnvironment = @{
        APPDATA = $env:APPDATA; PATH = $env:PATH; FFREPORT = $env:FFREPORT
        WVC_ENV_FIXTURE_MODE = $env:WVC_ENV_FIXTURE_MODE; WVC_ENV_FIXTURE_LOG = $env:WVC_ENV_FIXTURE_LOG
        WVC_ENV_CHILD_PID = $env:WVC_ENV_CHILD_PID
    }
    $env:APPDATA = Join-Path $TestDrive 'appdata'
    . (Join-Path $RepoRoot 'WinVidCompress.ps1')
    $script:Bin = Join-Path $TestDrive 'bin ! & [literal]'
    $script:Adjacent = Join-Path $TestDrive 'adjacent'
    [void][IO.Directory]::CreateDirectory($Bin)
    [void][IO.Directory]::CreateDirectory($Adjacent)
    $script:PS51 = Join-Path $env:SystemRoot 'System32/WindowsPowerShell/v1.0/powershell.exe'
    $compile = Invoke-WvcTestProcess $PS51 @('-NoProfile','-NonInteractive','-File',
        (Join-Path $PSScriptRoot 'New-EnvironmentFixture.ps1'),'-Destination',(Join-Path $TestDrive 'fixture.exe'))
    if ($compile.ExitCode -ne 0) { throw "Fixture compilation failed: $($compile.StdErr)" }
    Copy-Item -LiteralPath (Join-Path $TestDrive 'fixture.exe') -Destination (Join-Path $Bin 'ffmpeg.exe')
    Copy-Item -LiteralPath (Join-Path $Bin 'ffmpeg.exe') -Destination (Join-Path $Bin 'ffprobe.exe')
    Copy-Item -LiteralPath (Join-Path $Bin 'ffmpeg.exe') -Destination (Join-Path $Adjacent 'ffmpeg.exe')
    Copy-Item -LiteralPath (Join-Path $RepoRoot 'WinVidCompress.ps1') -Destination (Join-Path $Adjacent 'WinVidCompress.ps1')
    $script:Tokens = $null; $script:ParseErrors = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $RepoRoot 'WinVidCompress.ps1'), [ref]$Tokens, [ref]$ParseErrors)
    # Exercise the entry helper; executable exits belong in child-process tests.
    $script:Main = { Invoke-WinVidCompress -Paths $Path -CheckEnvironment:$CheckEnvironment }
}

AfterAll {
    foreach ($key in $OriginalEnvironment.Keys) { [Environment]::SetEnvironmentVariable($key, $OriginalEnvironment[$key], 'Process') }
}

Describe 'Environment diagnostics [WVC-M1-06]' {
    BeforeEach {
        $env:PATH = $Bin
        $env:WVC_ENV_FIXTURE_MODE = ''
        $env:WVC_ENV_FIXTURE_LOG = ''
        $env:FFREPORT = ''
        $ConfigDir = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        $ConfigPath = Join-Path $ConfigDir 'config.json'
        $script:Output = Join-Path $TestDrive ([guid]::NewGuid().ToString('N'))
        [void][IO.Directory]::CreateDirectory($Output)
        $script:Encoder = Join-Path $Bin 'ffmpeg.exe'
        $script:Probe = Join-Path $Bin 'ffprobe.exe'
        $CheckEnvironment = $false
        $Path = @('must never be processed.mov')
        Mock Write-Host {}
    }

    It 'selects PATH application before an adjacent application and returns its absolute path' {
        . (Join-Path $Adjacent 'WinVidCompress.ps1')
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly $Encoder
    }

    It 'falls back to the adjacent application when PATH has none' {
        . (Join-Path $Adjacent 'WinVidCompress.ps1')
        $env:PATH = $Output
        Ensure-Tool 'ffmpeg.exe' | Should -BeExactly (Join-Path $Adjacent 'ffmpeg.exe')
    }

    It 'rejects a missing application clearly' {
        $env:PATH = $Output
        { Ensure-Tool 'wvc-missing.exe' } | Should -Throw '*not found*PATH or next to this script*'
    }

    It 'refuses a <Kind> shadow without invoking it' -TestCases @(
        @{ Kind = 'Function' }, @{ Kind = 'Alias' }
    ) {
        param($Kind)
        Mock Get-Command { [pscustomobject]@{ CommandType = $Kind } } -ParameterFilter { $Name -eq 'ffmpeg.exe' }
        { Ensure-Tool 'ffmpeg.exe' } | Should -Throw '*not an application*'
    }

    It 'diagnoses an unreadable application' {
        $handle = [IO.File]::Open($Encoder, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::None)
        try { { Ensure-Tool 'ffmpeg.exe' } | Should -Throw '*cannot be read*' }
        finally { $handle.Dispose() }
    }

    It 'rejects a non-executable file before processing' {
        $invalid = Join-Path $Output 'ffmpeg.exe'
        [IO.File]::WriteAllText($invalid, 'not an executable')
        Mock Ensure-Tool { if ($exe -eq 'ffmpeg.exe') { $invalid } else { $Probe } }
        Mock Load-Config { throw 'Must not load config' }
        Mock Process-Paths { throw 'Must not process media' }
        $run=& $Main
        $run.ExitCode | Should -Be 2
        $run.Reason | Should -BeLike '*Environment check failed*'
        Should -Invoke Process-Paths -Times 0 -Exactly
        Should -Invoke Load-Config -Times 0 -Exactly
    }

    It 'fails before processing for <Mode>' -TestCases @(
        @{ Mode = 'wrong'; Error = '*Wrong tool*' },
        @{ Mode = 'failure'; Error = '*Exit code 17*fixture exit diagnostic*' },
        @{ Mode = 'no-x264'; Error = '*Required encoder*libx264*' },
        @{ Mode = 'no-aac'; Error = '*Required encoder*aac*' },
        @{ Mode = 'no-mp4'; Error = '*MP4 muxer/faststart*' },
        @{ Mode = 'no-scale'; Error = '*scale filter*' },
        @{ Mode = 'no-probe'; Error = '*Exit code 18*Unsupported writer*' },
        @{ Mode = 'bad-json'; Error = '*JSON/program inspection failed*' }
    ) {
        param($Mode,$Error)
        $env:WVC_ENV_FIXTURE_MODE = $Mode
        Mock Load-Config { throw 'Must not load config' }
        Mock Process-Paths { throw 'Must not process media' }
        $run=& $Main
        $run.ExitCode | Should -Be 2
        $run.Reason | Should -BeLike $Error
        Should -Invoke Process-Paths -Times 0 -Exactly
        Should -Invoke Load-Config -Times 0 -Exactly
    }

    It 'identifies a swapped probe executable' {
        { Get-ToolEnvironment $Encoder $Encoder } | Should -Throw '*expected ffprobe version*'
    }

    It 'bounds a hung check and stops the owned process' {
        $env:WVC_ENV_FIXTURE_MODE = 'hang'
        $watch = [Diagnostics.Stopwatch]::StartNew()
        { Get-ToolEnvironment $Encoder $Probe 300 } | Should -Throw '*Timed out after 300 ms*timeout diagnostic*'
        $watch.Elapsed.TotalSeconds | Should -BeLessThan 5
        @(Get-Process | Where-Object { $_.ProcessName -eq 'ffmpeg' -and $_.Path -eq $Encoder }).Count | Should -Be 0
    }

    It 'drains simultaneous large stdout/stderr without treating stderr as failure' {
        $env:WVC_ENV_FIXTURE_MODE = 'flood'
        $call = Invoke-EnvironmentCall $Encoder @('flood') 5000
        $call.ExitCode | Should -Be 0
        $call.StdOut.Length | Should -BeGreaterThan 100000
        $call.StdErr.Length | Should -BeGreaterThan 100000
    }

    It 'bounds pipe draining when an exited parent leaves inherited handles open' {
        $env:WVC_ENV_FIXTURE_MODE = 'pipes'
        $env:WVC_ENV_CHILD_PID = Join-Path $Output 'child.pid'
        $watch = [Diagnostics.Stopwatch]::StartNew()
        try {
            { Invoke-EnvironmentCall $Encoder @('pipes') 1000 } | Should -Throw '*Timed out draining diagnostics*'
            $watch.Elapsed.TotalSeconds | Should -BeLessThan 5
        } finally {
            if (Test-Path -LiteralPath $env:WVC_ENV_CHILD_PID) {
                $child = Get-Process -Id ([int][IO.File]::ReadAllText($env:WVC_ENV_CHILD_PID)) -ErrorAction SilentlyContinue
                if ($null -ne $child) {
                    if ($child.Path -ne $Encoder) { throw 'Refusing to stop a process outside the owned fixture.' }
                    $child.Kill()
                    if (-not $child.WaitForExit(2000)) { throw 'Owned fixture child cleanup failed.' }
                    $child.Dispose()
                }
            }
            $env:WVC_ENV_CHILD_PID = ''
        }
    }

    It 'keeps an existing doctor config byte-identical, including unknown keys' {
        [void][IO.Directory]::CreateDirectory($ConfigDir)
        $text = [pscustomobject]@{ OutputDir = $Output; Future = [pscustomobject]@{ Value = 'preserve' } } | ConvertTo-Json
        [IO.File]::WriteAllText($ConfigPath, $text)
        $before = (Get-FileHash -LiteralPath $ConfigPath).Hash
        $CheckEnvironment = $true
        & $Main
        (Get-FileHash -LiteralPath $ConfigPath).Hash | Should -BeExactly $before
        @(Get-ChildItem -LiteralPath $ConfigDir -Force).Count | Should -Be 1
        @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 0
    }

    It 'round-trips argument values on this supported host without shell evaluation' {
        $env:WVC_ENV_FIXTURE_MODE = 'argv'
        $values = @('', 'trailing space ', 'D:\folder\', 'a\"b', 'x & !NAME! %PATH% [x]', [string][char]0x4e2d)
        $call = Invoke-EnvironmentCall $Encoder $values
        $actual = @($call.StdOut.TrimEnd("`r","`n") -split '\r?\n' | ForEach-Object {
            [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($_))
        })
        $actual.Count | Should -Be $values.Count
        for ($i = 0; $i -lt $values.Count; $i++) { $actual[$i] | Should -BeExactly $values[$i] }
    }

    It 'records build details/capabilities and clears FFREPORT only in child environments' {
        $env:FFREPORT = 'file=must-not-create.log'
        $tools = Get-ToolEnvironment $Encoder $Probe
        $tools.FFmpeg | Should -BeExactly $Encoder
        $tools.FFprobe | Should -BeExactly $Probe
        $tools.FFmpegBuild | Should -BeLike '*configuration: synthetic recorder*'
        $tools.Calls.Count | Should -Be 7
        $env:FFREPORT | Should -BeExactly 'file=must-not-create.log'
        Test-Path -LiteralPath (Join-Path $RepoRoot 'must-not-create.log') | Should -BeFalse
    }

    It 'prints exact tool paths and capacity concerns without claiming an output size' {
        $tools = Get-ToolEnvironment $Encoder $Probe
        Write-EnvironmentReport $tools ([pscustomobject]@{ Destination = $Output; AvailableBytes = 10 })
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -ceq "FFmpeg: $Encoder" }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -ceq "FFprobe: $Probe" }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'Capacity concern:*' }
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'Output size is not guaranteed*' }
    }

    It 'reports unknown capacity as advisory' {
        Write-EnvironmentReport (Get-ToolEnvironment $Encoder $Probe) ([pscustomobject]@{ Destination = $Output; AvailableBytes = $null })
        Should -Invoke Write-Host -Times 1 -Exactly -ParameterFilter { $Object -like 'Available capacity: unknown*' }
    }

    It 'checks actual destination writing and leaves every existing file untouched' {
        $sentinel = Join-Path $Output 'existing.mp4'
        [IO.File]::WriteAllText($sentinel, 'existing final sentinel')
        $before = (Get-FileHash -LiteralPath $sentinel).Hash
        (Get-OutputEnvironment $Output).Destination | Should -BeExactly $Output
        @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 1
        (Get-FileHash -LiteralPath $sentinel).Hash | Should -BeExactly $before
    }

    It 'leaves absent config absent during doctor and never dispatches conversion/menu' {
        Mock Get-DefaultOutputDir { $Output }
        Mock Load-Config { throw 'Must not persist config' }
        Mock Process-Paths { throw 'Must not process media' }
        Mock Run-TUI { throw 'Must not show menu' }
        $CheckEnvironment = $true
        & $Main
        Test-Path -LiteralPath $ConfigDir | Should -BeFalse
        @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 0
        Should -Invoke Process-Paths -Times 0 -Exactly
        Should -Invoke Run-TUI -Times 0 -Exactly
        Should -Invoke Load-Config -Times 0 -Exactly
    }

    It 'preserves saved <Case> config bytes and directory contents on doctor failure' -TestCases @(
        @{ Case = 'malformed'; Value = '{broken'; Error = '*' },
        @{ Case = 'offline'; Value = '{"OutputDir":"Z:\\wvc-offline"}'; Error = '*unavailable*' },
        @{ Case = 'offline UNC'; Value = '{"OutputDir":"\\\\wvc-offline.invalid\\share\\output"}'; Error = '*unavailable*' }
    ) {
        param($Case,$Value,$Error)
        [void][IO.Directory]::CreateDirectory($ConfigDir)
        [IO.File]::WriteAllText($ConfigPath, $Value)
        $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ConfigPath))
        Mock Get-Item { throw 'Offline test destination' } -ParameterFilter { $LiteralPath -like '*wvc-offline*' }
        $CheckEnvironment = $true
        $run=& $Main
        $run.ExitCode | Should -Be 2
        $run.Reason | Should -BeLike $Error
        [Convert]::ToBase64String([IO.File]::ReadAllBytes($ConfigPath)) | Should -BeExactly $before
        @(Get-ChildItem -LiteralPath $ConfigDir -Force).Count | Should -Be 1
    }

    It 'diagnoses a real write-denied directory and preserves preferences' {
        [void][IO.Directory]::CreateDirectory($ConfigDir)
        [IO.File]::WriteAllText($ConfigPath, ([pscustomobject]@{ OutputDir = $Output } | ConvertTo-Json))
        $before = [Convert]::ToBase64String([IO.File]::ReadAllBytes($ConfigPath))
        $acl = Get-Acl -LiteralPath $Output
        $denied = Get-Acl -LiteralPath $Output
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent().User
        $rule = New-Object Security.AccessControl.FileSystemAccessRule($identity, 'CreateFiles', 'Deny')
        [void]$denied.AddAccessRule($rule)
        Set-Acl -LiteralPath $Output -AclObject $denied
        try {
            Assert-OutputDirectory $Output # Enumeration succeeds; real write must fail.
            Mock Process-Paths { throw 'Must not process' }
            $CheckEnvironment = $true
            $run=& $Main
            $run.ExitCode | Should -Be 2
            $run.Reason | Should -BeLike '*cannot safely create/write/remove*'
            [Convert]::ToBase64String([IO.File]::ReadAllBytes($ConfigPath)) | Should -BeExactly $before
            @(Get-ChildItem -LiteralPath $ConfigDir -Force).Count | Should -Be 1
            @(Get-ChildItem -LiteralPath $Output -Force).Count | Should -Be 0
            Should -Invoke Process-Paths -Times 0 -Exactly
            # Menu selection must also refuse to save an unwritable preference.
            $active = [pscustomobject]@{ OutputDir = (Join-Path $TestDrive 'previous-output') }
            $previous = $active.OutputDir
            $choices = New-Object 'Collections.Generic.Queue[string]'
            foreach ($choice in @('1','4')) { $choices.Enqueue($choice) }
            Mock Read-Host { $choices.Dequeue() }
            Mock Prompt-Path { $Output }
            Mock Save-Config { throw 'Must not save rejected output' }
            Run-TUI $Encoder $Probe $active
            $active.OutputDir | Should -BeExactly $previous
            [Convert]::ToBase64String([IO.File]::ReadAllBytes($ConfigPath)) | Should -BeExactly $before
            Should -Invoke Save-Config -Times 0 -Exactly
        } finally { Set-Acl -LiteralPath $Output -AclObject $acl }
    }

    It 'rechecks an unavailable destination before freezing or encoding a menu batch' {
        $missing = Join-Path $Output 'missing'
        Mock Get-InputQueue { throw 'Must not scan' }
        Mock Compress-One { throw 'Must not encode' }
        $run=Process-Paths @('source.mov') $Encoder $Probe ([pscustomobject]@{ OutputDir = $missing })
        $run.ExitCode | Should -Be 2
        $run.Reason | Should -BeLike '*unavailable*'
        Should -Invoke Get-InputQueue -Times 0 -Exactly
        Should -Invoke Compress-One -Times 0 -Exactly
    }
}
