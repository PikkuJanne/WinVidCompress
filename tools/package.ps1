<#
.SYNOPSIS
Build or verify a local tool-only candidate from clean Git HEAD.
.DESCRIPTION
Developer-only. Reads a fixed allowlist as binary Git blobs, preserves runtime
bytes, redirects excluded documentation links to the exact source commit, and
writes sorted ZIP entries with fixed metadata. Never publishes or downloads.
Existing artifacts are refused; failed owned staging is retained for inspection.
.PARAMETER RepositoryPath
Clean repository root. Defaults to the parent of this tools directory.
.PARAMETER OutputDirectory
Existing absolute local directory, outside the repository or under .test-results.
.PARAMETER ExpectedCommit
Optional full SHA guard; must equal the current clean HEAD.
.PARAMETER VerifyDirectory
Verify an existing candidate's ZIP, manifest, provenance and checksum sidecars.
#>
[CmdletBinding(DefaultParameterSetName='Build')]
param(
    [Parameter(ParameterSetName='Build')][string]$RepositoryPath,
    [Parameter(ParameterSetName='Build')][string]$OutputDirectory,
    [Parameter(ParameterSetName='Build')][string]$ExpectedCommit,
    [Parameter(Mandatory=$true,ParameterSetName='Verify')][string]$VerifyDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression,System.IO.Compression.FileSystem

function Get-WvcPackagePaths {
    [string[]]$paths=@('WinVidCompress.ps1','WinVidCompress.bat','README.md','LICENSE','VERSION','CHANGELOG.md','SECURITY.md','THIRD_PARTY_NOTICES.md',
        'docs/user/REFERENCE.md','docs/user/TROUBLESHOOTING.md','docs/user/VERIFICATION.md')
    [Array]::Sort($paths,[StringComparer]::Ordinal)
    $paths
}
function Get-WvcPackageHash([byte[]]$Bytes) {
    $hash=[Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($hash.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant() }
    finally { $hash.Dispose() }
}
function ConvertTo-WvcPackageJson($Value) {
    $text=($Value | ConvertTo-Json -Depth 20 -Compress).Replace("`r`n","`n")+"`n"
    ,([Text.UTF8Encoding]::new($false).GetBytes($text))
}
function Invoke-WvcPackageGit([string]$Root,[string[]]$Arguments) {
    $git=Get-Command git.exe -ErrorAction Stop | Select-Object -First 1
    if ($git.CommandType -ne 'Application') { throw 'Git must resolve to an application.' }
    $start=New-Object Diagnostics.ProcessStartInfo
    $start.FileName=$git.Source
    $tokens=@('-C',$Root)+$Arguments
    $start.Arguments=($tokens | ForEach-Object {
        '"'+([regex]::Replace([regex]::Replace($_,'(\\*)"','$1$1\"'),'(\\+)$','$1$1'))+'"'
    }) -join ' '
    $start.UseShellExecute=$false; $start.CreateNoWindow=$true
    $start.RedirectStandardOutput=$true; $start.RedirectStandardError=$true
    $process=New-Object Diagnostics.Process; $process.StartInfo=$start
    $memory=New-Object IO.MemoryStream
    try {
        [void]$process.Start()
        $errorTask=$process.StandardError.ReadToEndAsync()
        $copyTask=$process.StandardOutput.BaseStream.CopyToAsync($memory)
        if (-not $process.WaitForExit(30000)) { $process.Kill(); throw 'Local Git read timed out.' }
        if (-not $copyTask.Wait(5000) -or -not $errorTask.Wait(5000)) { throw 'Local Git pipe drain timed out.' }
        if ($process.ExitCode -ne 0) { throw ('Git read failed: '+$errorTask.Result.Trim()) }
        [pscustomobject]@{Bytes=$memory.ToArray();Text=[Text.Encoding]::UTF8.GetString($memory.ToArray())}
    } finally { $memory.Dispose(); $process.Dispose() }
}
function Assert-WvcPackageDirectory([string]$Path) {
    if ($Path -notmatch '^[A-Za-z]:[\\/]' -or $Path.Substring(2).Contains(':')) { throw 'Use an absolute local drive directory.' }
    $full=[IO.Path]::GetFullPath($Path)
    $item=Get-Item -LiteralPath $full -Force -ErrorAction Stop
    if (-not $item.PSIsContainer -or $item.PSProvider.Name -ne 'FileSystem') { throw 'Expected an existing filesystem directory.' }
    $ancestor=$full
    while ($ancestor) {
        if ((Get-Item -LiteralPath $ancestor -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Package directories cannot cross reparse points.' }
        $ancestor=[IO.Path]::GetDirectoryName($ancestor)
    }
    if ($full -eq [IO.Path]::GetPathRoot($full)) { $full } else { $full.TrimEnd('\') }
}
function Assert-WvcPackageVersion([string]$Version) {
    if ($Version.Length -gt 64 -or $Version -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-[0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*)?$') {
        throw 'VERSION must contain one portable semantic candidate version.'
    }
}
function Convert-WvcPackageLinks([string]$Text,[string]$Document,[string]$Commit,$Tree,[string[]]$Included) {
    $virtualRoot='C:\wvc-package-docs\'
    $parent=[IO.Path]::GetDirectoryName($Document.Replace('/','\'))
    $base=if ($parent) { Join-Path $virtualRoot $parent } else { $virtualRoot }
    [regex]::Replace($Text,'(?<!!)\[[^\]]*\]\((?<target>[^)]+)\)',[Text.RegularExpressions.MatchEvaluator]{
        param($match)
        $target=$match.Groups['target'].Value
        if ($target -match '^(https?://|#)') { return $match.Value }
        $pieces=$target -split '#',2
        $relative=[Uri]::UnescapeDataString($pieces[0])
        if ($relative -match '^[/\\]|[:?*\x00-\x1f]') { throw 'Nonportable local documentation link.' }
        $resolved=[IO.Path]::GetFullPath((Join-Path $base $relative))
        if (-not $resolved.StartsWith($virtualRoot,[StringComparison]::OrdinalIgnoreCase)) { throw 'Documentation link escapes source root.' }
        $sourcePath=$resolved.Substring($virtualRoot.Length).Replace('\','/')
        if (-not $Tree.ContainsKey($sourcePath)) { throw ('Missing source documentation link: '+$sourcePath) }
        if ($sourcePath -cin $Included) { return $match.Value }
        $url='https://github.com/PikkuJanne/WinVidCompress/blob/'+$Commit+'/'+(($sourcePath -split '/' | ForEach-Object {[Uri]::EscapeDataString($_)}) -join '/')
        if ($pieces.Count -eq 2) { $url+='#'+$pieces[1] }
        $match.Value.Replace($target,$url)
    })
}
function Write-WvcPackageBytes([string]$Path,[byte[]]$Bytes) {
    $stream=[IO.File]::Open($Path,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)
    try { $stream.Write($Bytes,0,$Bytes.Length) } finally { $stream.Dispose() }
}
function Test-WvcPackage([string]$Directory) {
    $root=Assert-WvcPackageDirectory $Directory
    $report=Get-Content -LiteralPath (Join-Path $root 'build.json') -Raw | ConvertFrom-Json
    Assert-WvcPackageVersion $report.PackageVersion
    if ($report.SchemaVersion -ne 1 -or $report.SourceCommit -cnotmatch '^[a-f0-9]{40}$' -or $report.Candidate -ne $true) { throw 'Invalid build provenance.' }
    $zipName='WinVidCompress-'+$report.PackageVersion+'.zip'
    $zipPath=Join-Path $root $zipName
    $zipHash=(Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $expected=$zipHash+'  '+$zipName+"`n"
    if ([IO.File]::ReadAllText(($zipPath+'.sha256')).Replace("`r`n","`n") -cne $expected -or $report.ZipSHA256 -cne $zipHash) { throw 'ZIP checksum mismatch.' }
    $manifestBytes=[IO.File]::ReadAllBytes((Join-Path $root 'manifest.json'))
    if ((Get-WvcPackageHash $manifestBytes) -cne $report.ManifestSHA256) { throw 'Manifest checksum mismatch.' }
    $manifest=[Text.Encoding]::UTF8.GetString($manifestBytes) | ConvertFrom-Json
    if ($manifest.SourceCommit -cne $report.SourceCommit -or $manifest.PackageVersion -cne $report.PackageVersion -or $manifest.ExcludedSelf -cne 'MANIFEST.json') { throw 'Manifest provenance mismatch.' }
    [string[]]$expectedNames=@(Get-WvcPackagePaths)+@('PACKAGE.json','MANIFEST.json')
    [Array]::Sort($expectedNames,[StringComparer]::Ordinal)
    $archive=[IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $names=@($archive.Entries | ForEach-Object FullName)
        if (($names -join "`n") -cne ($expectedNames -join "`n")) { throw 'ZIP allowlist/order mismatch.' }
        $rows=@($manifest.Files)
        if (($rows.Path -join "`n") -cne ((@($expectedNames | Where-Object {$_ -ne 'MANIFEST.json'})) -join "`n")) { throw 'Manifest allowlist/order mismatch.' }
        foreach ($entry in $archive.Entries) {
            if ($entry.LastWriteTime.DateTime -ne [datetime]'1980-01-01T00:00:00' -or $entry.ExternalAttributes -ne 0) { throw 'ZIP metadata is not normalized.' }
            $memory=New-Object IO.MemoryStream; $stream=$entry.Open()
            try { $stream.CopyTo($memory); $bytes=$memory.ToArray() } finally {$stream.Dispose();$memory.Dispose()}
            if ($entry.FullName -eq 'MANIFEST.json') {
                if ((Get-WvcPackageHash $bytes) -cne $report.ManifestSHA256) { throw 'Internal manifest mismatch.' }
            } else {
                $row=@($rows | Where-Object Path -CEQ $entry.FullName)[0]
                if ($row.Bytes -ne $bytes.Length -or $row.SHA256 -cne (Get-WvcPackageHash $bytes)) { throw ('Entry checksum mismatch: '+$entry.FullName) }
                if ($entry.FullName -eq 'PACKAGE.json') {
                    $package=[Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json
                    if ($package.SourceCommit -cne $report.SourceCommit -or $package.PackageVersion -cne $report.PackageVersion -or $package.Candidate -ne $true) { throw 'Internal package provenance mismatch.' }
                }
            }
        }
    } finally { $archive.Dispose() }
    [pscustomobject]@{Passed=$true;SourceCommit=$report.SourceCommit;PackageVersion=$report.PackageVersion;ZipSHA256=$zipHash;Files=$expectedNames.Count}
}
function New-WvcPackage([string]$Repository,[string]$Destination,[string]$ExpectedHead) {
    $repo=Assert-WvcPackageDirectory $Repository
    $top=(Invoke-WvcPackageGit $repo @('rev-parse','--show-toplevel')).Text.Trim().Replace('/','\')
    if (-not [StringComparer]::OrdinalIgnoreCase.Equals($top,$repo)) { throw 'RepositoryPath must be the Git root.' }
    if ((Invoke-WvcPackageGit $repo @('status','--porcelain','--untracked-files=all')).Text.Trim()) { throw 'Package only a clean tracked checkout.' }
    $commit=(Invoke-WvcPackageGit $repo @('rev-parse','HEAD')).Text.Trim()
    if ($commit -cnotmatch '^[a-f0-9]{40}$' -or ($ExpectedHead -and $ExpectedHead -cne $commit)) { throw 'ExpectedCommit must match the full current HEAD.' }
    foreach ($gitArguments in @(@('remote','get-url','--all','origin'),@('remote','get-url','--push','--all','origin'))) {
        if ((Invoke-WvcPackageGit $repo $gitArguments).Text.Trim() -cnotin @('https://github.com/PikkuJanne/WinVidCompress.git','git@github.com:PikkuJanne/WinVidCompress.git')) { throw 'Unexpected origin identity or multiple destinations.' }
    }
    $output=Assert-WvcPackageDirectory $Destination
    $repoPrefix=$repo+'\';$ignoredPrefix=Join-Path $repo '.test-results\'
    if (($output+'\').StartsWith($repoPrefix,[StringComparison]::OrdinalIgnoreCase) -and -not ($output+'\').StartsWith($ignoredPrefix,[StringComparison]::OrdinalIgnoreCase)) { throw 'In-repository artifacts must stay under ignored .test-results.' }
    $tree=New-Object 'Collections.Generic.Dictionary[string,object]' ([StringComparer]::Ordinal)
    foreach ($line in ((Invoke-WvcPackageGit $repo @('ls-tree','-r','--full-tree',$commit)).Text -split "`n")) {
        if ($line.TrimEnd("`r") -match '^(?<mode>[0-9]{6}) blob (?<blob>[a-f0-9]{40})\t(?<name>.+)$') {
            $tree.Add($Matches.name,[pscustomobject]@{Mode=$Matches.mode;Blob=$Matches.blob})
        }
    }
    $included=@(Get-WvcPackagePaths)
    $files=New-Object 'Collections.Generic.Dictionary[string,object]' ([StringComparer]::Ordinal)
    foreach ($path in $included+@('docs/releases/TESTED_ENVIRONMENT.json')) {
        if (-not $tree.ContainsKey($path) -or $tree[$path].Mode -cnotin @('100644','100755')) { throw ('Missing/nonregular allowlisted source: '+$path) }
        $bytes=(Invoke-WvcPackageGit $repo @('cat-file','blob',$tree[$path].Blob)).Bytes
        $files.Add($path,[pscustomobject]@{Bytes=$bytes;SourceBlob=$tree[$path].Blob;Transform='none'})
    }
    $version=[Text.Encoding]::UTF8.GetString($files['VERSION'].Bytes).Trim()
    Assert-WvcPackageVersion $version
    $tested=[Text.Encoding]::UTF8.GetString($files['docs/releases/TESTED_ENVIRONMENT.json'].Bytes) | ConvertFrom-Json
    if ($tested.SchemaVersion -ne 1 -or $tested.ApplicationSHA256 -cne (Get-WvcPackageHash $files['WinVidCompress.ps1'].Bytes) -or $tested.LauncherSHA256 -cne (Get-WvcPackageHash $files['WinVidCompress.bat'].Bytes)) { throw 'Tracked tested-environment record does not match runtime bytes.' }
    $files.Remove('docs/releases/TESTED_ENVIRONMENT.json') | Out-Null
    foreach ($path in @($included | Where-Object {$_ -like '*.md'})) {
        $text=[Text.UTF8Encoding]::new($false,$true).GetString($files[$path].Bytes)
        $rewritten=Convert-WvcPackageLinks $text $path $commit $tree $included
        if ($rewritten -cne $text) { $files[$path].Bytes=[Text.Encoding]::UTF8.GetBytes($rewritten.Replace("`r`n","`n"));$files[$path].Transform='excluded-links-to-source-commit' }
    }
    $package=[ordered]@{SchemaVersion=1;PackageVersion=$version;Candidate=$true;SourceCommit=$commit;SourceUrl=('https://github.com/PikkuJanne/WinVidCompress/tree/'+$commit);
        DependenciesBundled=$false;RuntimeTestEvidence=$tested;Profile='libx264/veryfast/CRF22;AAC160k;MP4+faststart;oriented-height1080;no crop/upscale';PackagingFormat=1}
    $files.Add('PACKAGE.json',[pscustomobject]@{Bytes=(ConvertTo-WvcPackageJson $package);SourceBlob=$null;Transform='generated-provenance'})
    [string[]]$names=@($files.Keys);[Array]::Sort($names,[StringComparer]::Ordinal)
    $rows=@(foreach ($path in $names) { [ordered]@{Path=$path;Bytes=$files[$path].Bytes.Length;SHA256=(Get-WvcPackageHash $files[$path].Bytes);SourceBlob=$files[$path].SourceBlob;Transform=$files[$path].Transform} })
    $manifest=ConvertTo-WvcPackageJson ([ordered]@{SchemaVersion=1;PackageVersion=$version;SourceCommit=$commit;HashAlgorithm='SHA256';ExcludedSelf='MANIFEST.json';Files=$rows})
    $files.Add('MANIFEST.json',[pscustomobject]@{Bytes=$manifest})
    [string[]]$names=@($files.Keys);[Array]::Sort($names,[StringComparer]::Ordinal)
    $candidate=Join-Path $output ('WinVidCompress-'+$version+'-'+$commit.Substring(0,12))
    if (Test-Path -LiteralPath $candidate) { throw 'Candidate destination already exists; use a fresh output directory.' }
    $stage=Join-Path $output ('.wvc-package-'+[guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $stage -ErrorAction Stop)
    try {
        Write-WvcPackageBytes (Join-Path $stage '.wvc-package-owner') ([Text.Encoding]::UTF8.GetBytes([IO.Path]::GetFileName($stage)))
        $zipName='WinVidCompress-'+$version+'.zip';$zipPath=Join-Path $stage $zipName
        $stream=[IO.File]::Open($zipPath,[IO.FileMode]::CreateNew,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $archive=New-Object IO.Compression.ZipArchive($stream,[IO.Compression.ZipArchiveMode]::Create,$false,([Text.UTF8Encoding]::new($false)))
        try {
            foreach ($path in $names) {
                $entry=$archive.CreateEntry($path,[IO.Compression.CompressionLevel]::NoCompression)
                $entry.LastWriteTime=[datetimeoffset]'1980-01-01T00:00:00+00:00';$entry.ExternalAttributes=0
                $entryStream=$entry.Open()
                try { $entryStream.Write($files[$path].Bytes,0,$files[$path].Bytes.Length) } finally { $entryStream.Dispose() }
            }
        } finally { $archive.Dispose();$stream.Dispose() }
        $zipHash=(Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
        Write-WvcPackageBytes ($zipPath+'.sha256') ([Text.Encoding]::UTF8.GetBytes($zipHash+'  '+$zipName+"`n"))
        Write-WvcPackageBytes (Join-Path $stage 'manifest.json') $manifest
        $report=[ordered]@{SchemaVersion=1;PackageVersion=$version;Candidate=$true;SourceCommit=$commit;ZipSHA256=$zipHash;ManifestSHA256=(Get-WvcPackageHash $manifest);
            BuilderPowerShell=$PSVersionTable.PSVersion.ToString();BuilderEdition=$PSVersionTable.PSEdition;BuilderDotNet=[Environment]::Version.ToString();Compression='NoCompression';EntryTimestamp='1980-01-01T00:00:00Z';Files=$names.Count}
        Write-WvcPackageBytes (Join-Path $stage 'build.json') (ConvertTo-WvcPackageJson $report)
        [void](Test-WvcPackage $stage)
        [void](Assert-WvcPackageDirectory $output)
        if ((Invoke-WvcPackageGit $repo @('rev-parse','HEAD')).Text.Trim() -cne $commit -or (Invoke-WvcPackageGit $repo @('status','--porcelain','--untracked-files=all')).Text.Trim()) { throw 'Source checkout changed during packaging.' }
        [IO.Directory]::Move($stage,$candidate)
        [pscustomobject]@{Directory=$candidate;PackageVersion=$version;SourceCommit=$commit;ZipSHA256=$zipHash;Files=$names.Count}
    } catch { throw ("Package failed; owned staging '$stage' retained. "+$_.Exception.Message) }
}

if ($MyInvocation.InvocationName -eq '.') { return }
try {
    if ($PSCmdlet.ParameterSetName -eq 'Verify') { Test-WvcPackage $VerifyDirectory | ConvertTo-Json }
    else {
        if (-not $RepositoryPath) { $RepositoryPath=Split-Path -Parent $PSScriptRoot }
        if (-not $OutputDirectory) { $OutputDirectory=Join-Path $RepositoryPath '.test-results/packages' }
        New-WvcPackage $RepositoryPath $OutputDirectory $ExpectedCommit | ConvertTo-Json
    }
} catch { [Console]::Error.WriteLine($_.Exception.Message);exit 1 }
