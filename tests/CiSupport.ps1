# Developer-only CI policy. Dot-sourcing performs no download or test execution.
Set-StrictMode -Version Latest

function Assert-WvcCiArchive([string]$Path, $Pin) {
    if ($Pin.Algorithm -notin @('SHA256','SHA512') -or
        $Pin.Hash -cnotmatch '^[a-f0-9]+$' -or $Pin.Hash.Length -ne $(if($Pin.Algorithm -eq 'SHA256'){64}else{128})) { throw 'Invalid dependency digest pin.' }
    if ((Get-FileHash -LiteralPath $Path -Algorithm $Pin.Algorithm).Hash -ine $Pin.Hash) { throw 'Dependency archive digest mismatch.' }
}

function Assert-WvcCiZipPaths([string]$ArchivePath,[string]$Destination) {
    Add-Type -AssemblyName System.IO.Compression,System.IO.Compression.FileSystem
    $root=[IO.Path]::GetFullPath($Destination).TrimEnd('\','/')+'\'
    $zip=[IO.Compression.ZipFile]::OpenRead($ArchivePath)
    $seen=New-Object 'Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $size=[long]0
    try {
        foreach($entry in $zip.Entries) {
            $name=$entry.FullName.Replace('/','\')
            $parts=@($name.TrimEnd('\').Split('\'))
            if (-not $name -or [IO.Path]::IsPathRooted($name) -or @($parts | Where-Object {$_ -in @('','.','..') -or $_ -match '[:<>"|?*\x00-\x1f]' -or $_ -match '[. ]$' -or $_ -match '^(CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(\.|$)'}).Count) { throw 'Unsafe archive entry.' }
            $full=[IO.Path]::GetFullPath((Join-Path $Destination $name))
            if (-not $full.StartsWith($root,[StringComparison]::OrdinalIgnoreCase) -or -not $seen.Add($full.TrimEnd('\'))) { throw 'Archive path escaped destination or aliases another entry.' }
            $size+=$entry.Length
            if ($size -gt 2147483648) { throw 'Dependency expanded-size limit exceeded.' }
        }
        if ($seen.Count -eq 0) { throw 'Empty dependency archive.' }
    } finally { $zip.Dispose() }
}

function Get-WvcCiChangedPaths([string]$Repository,[string]$BaseCommit) {
    if ($BaseCommit -cnotmatch '^[a-f0-9]{40}$') { throw 'Static base must be a full commit SHA.' }
    $resolved=(& git -C $Repository rev-parse --verify ($BaseCommit+'^{commit}') | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or $resolved -cne $BaseCommit) { throw 'Static base is not available locally.' }
    $names=@(& git -C $Repository -c core.quotepath=false diff --name-only --diff-filter=ACMR $BaseCommit HEAD --)
    if ($LASTEXITCODE -ne 0) { throw 'Changed-file discovery failed.' }
    $prefix=[IO.Path]::GetFullPath($Repository).TrimEnd('\','/')+'\'
    foreach($name in $names) {
        if ([IO.Path]::GetExtension($name) -notin @('.ps1','.psm1','.psd1')) { continue }
        $full=[IO.Path]::GetFullPath((Join-Path $Repository $name))
        if (-not $full.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase) -or -not [IO.File]::Exists($full)) { throw 'Changed PowerShell file is outside the checkout or missing.' }
        $full
    }
}

function Invoke-WvcCiAnalysis([string[]]$Paths,[string]$ModuleRoot) {
    $pins=Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Dependencies.psd1')
    Import-Module (Join-Path $ModuleRoot ('PSScriptAnalyzer/'+$pins.PSScriptAnalyzer+'/PSScriptAnalyzer.psd1')) -ErrorAction Stop
    if ((Get-Module PSScriptAnalyzer).Version -ne [version]$pins.PSScriptAnalyzer) { throw 'Unexpected analyzer version.' }
    $rules=@('PSAvoidUsingInvokeExpression','PSAvoidUsingPlainTextForPassword','PSAvoidUsingConvertToSecureStringWithPlainText','PSAvoidUsingUsernameAndPasswordParams')
    $count=0
    foreach($path in @($Paths | Sort-Object -Unique)) {
        if (-not [IO.File]::Exists($path)) { throw 'Static input file is missing.' }
        $tokens=$null; $errors=$null
        [void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
        $count+=@($errors).Count
        $count+=@(Invoke-ScriptAnalyzer -Path $path -Severity Error).Count
        $count+=@(Invoke-ScriptAnalyzer -Path $path -IncludeRule $rules -Severity Warning,Error).Count
    }
    [pscustomobject]@{SchemaVersion=1;AnalyzedFiles=@($Paths | Sort-Object -Unique).Count;DiagnosticCount=$count;Policy='ErrorsAndSelectedSafetyRules';Passed=($count -eq 0)}
}

function ConvertTo-WvcCiSummary($Report,[int]$NativeExit,[string]$ExpectedHead,
    [ValidateSet('WindowsPowerShell','PowerShell7')][string]$HostName,$Static) {
    if ($ExpectedHead -cnotmatch '^[a-f0-9]{40}$' -or $Report.SourceCommit -cne $ExpectedHead -or $Report.Dirty -ne $false) { throw 'CI source identity mismatch.' }
    $issues=New-Object 'Collections.Generic.List[string]'
    if ($NativeExit -ne 0 -or $Report.ExitCode -ne $NativeExit -or $Report.Status -ne 'Passed') { $issues.Add('TestExecutionFailed') }
    $counts=(Get-WvcTierSummary 'Targeted' @($Report.Cases)).Counts
    foreach($state in @('Passed','Failed','Skipped','NotRun')) { if($Report.Counts.$state -ne $counts.$state) {throw 'CI case count mismatch.'} }
    if ($counts.Passed -lt 1 -or $counts.Failed -or $counts.Skipped -or $counts.NotRun) {$issues.Add('FailedOrIncompleteTests')}
    $hosts=@($Report.Hosts)
    if ($hosts.Count -ne 1 -or $hosts[0].Version -cnotmatch '^\d+\.\d+\.\d+(\.\d+)?$') { throw 'CI host report is invalid.' }
    $hostVersion=[version]$hosts[0].Version
    if (($HostName -eq 'WindowsPowerShell' -and ($hostVersion.Major -ne 5 -or $hostVersion.Minor -ne 1 -or $hosts[0].Edition -ne 'Desktop')) -or
        ($HostName -eq 'PowerShell7' -and ($hostVersion -lt [version]'7.4' -or $hostVersion.Major -ne 7 -or $hosts[0].Edition -ne 'Core'))) {$issues.Add('WrongHost')}
    $native=New-Object 'Collections.Generic.List[object]'
    foreach($name in @('FFmpeg','FFprobe')) {
        $tools=@($Report.NativeTools | Where-Object Name -eq $name)
        if ($tools.Count -ne 1 -or -not $tools[0].Available) {$issues.Add('RequiredNativeToolMissing');continue}
        $match=[regex]::Match([string]$tools[0].Version,('^'+$name.ToLowerInvariant()+' version ([A-Za-z0-9._+\-]{1,160})(?:\s|$)'))
        if(-not $match.Success) {throw 'Invalid native version token.'}
        $native.Add([pscustomobject]@{Name=$name;Version=$match.Groups[1].Value})
    }
    $pins=Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Dependencies.psd1')
    if ($Report.Dependencies.Pester -ne $pins.Pester -or $Report.Dependencies.PSScriptAnalyzer -ne $pins.PSScriptAnalyzer) {$issues.Add('WrongDeveloperDependencies')}
    if ($Static.SchemaVersion -ne 1 -or $Static.DiagnosticCount -lt 0 -or $Static.AnalyzedFiles -lt 0 -or -not $Static.Passed -or $Static.DiagnosticCount -ne 0) {$issues.Add('StaticPolicyFailed')}
    $index=0
    $cases=@($Report.Cases | ForEach-Object {
        if($_.Status -notin @('Passed','Failed','Skipped','NotRun')) {throw 'Invalid CI case status.'}
        $index++; [pscustomobject]@{Id=('case-{0:D4}' -f $index);Status=$_.Status}
    })
    [pscustomobject][ordered]@{SchemaVersion=1;SourceCommit=$ExpectedHead;HostName=$HostName;
        Host=[pscustomobject]@{Version=$hostVersion.ToString();Edition=$(if($HostName -eq 'WindowsPowerShell'){'Desktop'}else{'Core'})};
        WindowsVersion=[Environment]::OSVersion.Version.ToString();
        RunnerImage=[pscustomobject]@{Name=$(if($env:ImageOS -cmatch '^win\d{2}$'){$env:ImageOS}else{$null});Version=$(if($env:ImageVersion -cmatch '^\d{8}\.\d+\.\d+$'){$env:ImageVersion}else{$null})};
        NativeTools=$native.ToArray();
        Dependencies=[pscustomobject]@{Pester=$pins.Pester;PSScriptAnalyzer=$pins.PSScriptAnalyzer};
        Status=$(if($issues.Count){'Failed'}else{'Passed'});ExitCode=$(if($issues.Count){1}else{0});
        Counts=$counts;Static=[pscustomobject]@{AnalyzedFiles=[int]$Static.AnalyzedFiles;DiagnosticCount=[int]$Static.DiagnosticCount;Policy='ErrorsAndSelectedSafetyRules'};
        Issues=$issues.ToArray();Cases=$cases;ReleaseAcceptance=$false}
}
