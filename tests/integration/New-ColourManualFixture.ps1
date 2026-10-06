[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ReportPath,[string]$FFmpeg,[string]$FFprobe)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
. (Join-Path $PSScriptRoot 'ColourTestSupport.ps1')
$encoder=Resolve-WvcTestExecutable $FFmpeg 'ffmpeg.exe';$probe=Resolve-WvcTestExecutable $FFprobe 'ffprobe.exe'
if (-not $encoder -or -not $probe) {throw 'Existing FFmpeg/FFprobe are required; nothing is downloaded.'}
$owner=New-WvcTestRoot;$savedAppData=$env:APPDATA;$savedFfreport=$env:FFREPORT;$prepared=$false;$retainFailed=$false
try {
    $env:APPDATA=Join-Path $owner.Path 'appdata';$env:FFREPORT=$null
    . (Join-Path $repoRoot 'WinVidCompress.ps1')
    $output=Join-Path $owner.Path 'output';[void][IO.Directory]::CreateDirectory($output)
    $font=(Join-Path $env:SystemRoot 'Fonts/arial.ttf').Replace('\','/').Replace(':','\:')
    $panels=@();$samples=@()
    foreach ($case in @(
        @{Name='8bit 709 bars';Pixels='yuv420p';Range='tv';Pattern='Bars'},
        @{Name='10bit 709 bars';Pixels='yuv420p10le';Range='tv';Pattern='Bars'},
        @{Name='10bit limited ramp';Pixels='yuv420p10le';Range='tv';Pattern='Ramp'},
        @{Name='10bit full ramp';Pixels='yuv420p10le';Range='pc';Pattern='Ramp'}
    )) {
        $source=Join-Path $owner.Path ($case.Name+'.mkv')
        New-ColourSample $encoder $source $case.Pixels $case.Range -Pattern $case.Pattern
        $sourceHash=(Get-FileHash -LiteralPath $source).Hash
        $job=Compress-One $encoder $probe $source $output 22
        if ($job.Outcome -ne 'Completed') {throw $job.Reason}
        if ((Get-FileHash -LiteralPath $source).Hash -ne $sourceHash) {throw 'Owned source changed.'}
        foreach ($side in @(@{Name='SOURCE';Path=$source},@{Name='OUTPUT';Path=$job.OutputPath})) {
            $panel=Join-Path $owner.Path ($case.Name+'-'+$side.Name+'.png')
            $filter="scale=320:180,pad=320:200:0:20:color=black,drawtext=fontfile='$font':"+
                "text='$($case.Name) $($side.Name)':fontsize=14:fontcolor=white:x=6:y=3"
            $native=Invoke-WvcTestProcess $encoder @('-hide_banner','-nostdin','-v','error','-n','-i',$side.Path,
                '-frames:v','1','-vf',$filter,$panel)
            if ($native.ExitCode -ne 0) {throw $native.StdErr}
            $panels+=$panel
        }
        $samples+=[pscustomobject]@{Name=$case.Name;SourceHash=$sourceHash;OutputHash=(Get-FileHash -LiteralPath $job.OutputPath).Hash;
            SourcePath=$source;OutputPath=$job.OutputPath;Colour=$job.Diagnostics.Validation.Inspection.PrimaryVideo}
    }
    $sheet=Join-Path $owner.Path 'colour-comparison.png'
    $arguments=@('-hide_banner','-nostdin','-v','error','-n');foreach ($panel in $panels) {$arguments+=@('-i',$panel)}
    $layout=(0..7 | ForEach-Object {"$((($_ % 2)*320))_$(([int][Math]::Floor($_/2.0)*200))"}) -join '|'
    $arguments+=@('-filter_complex',"xstack=inputs=8:layout=$layout",'-frames:v','1',$sheet)
    $native=Invoke-WvcTestProcess $encoder $arguments
    if ($native.ExitCode -ne 0) {throw $native.StdErr}
    $sourceCommit=(& git -C $repoRoot rev-parse HEAD).Trim();$dirty=[bool](& git -C $repoRoot status --porcelain)
    Write-WvcTestJson $ReportPath ([pscustomobject]@{SchemaVersion=1;Owner=$owner;SourceCommit=$sourceCommit;SourceTreeDirty=$dirty;
        ApplicationHash=(Get-FileHash (Join-Path $repoRoot 'WinVidCompress.ps1')).Hash;ComparisonPath=$sheet;
        ComparisonHash=(Get-FileHash -LiteralPath $sheet).Hash;Samples=$samples;OwnerObservation='NotRun';
        Limitation='Synthetic FFmpeg-rendered stills; no display calibration, HDR conversion or general playback integrity claim.'})
    $prepared=$true;Write-Output $sheet
} catch {
    $retainFailed=$true
    if ($_.Exception.Data.Contains('WvcAbortBatch')) {$script:WvcProcessCleanupFailed=$true}
    try {[IO.File]::WriteAllText((Join-Path $owner.Path 'preparation-failure.txt'),$_.Exception.ToString())} catch {}
    Write-Warning ('Colour review preparation failed; owned diagnostics retained at '+$owner.Path)
    throw
} finally {
    $env:APPDATA=$savedAppData;$env:FFREPORT=$savedFfreport
    if (-not $prepared -and -not $retainFailed -and -not (Get-Variable WvcProcessCleanupFailed -Scope Script -ErrorAction SilentlyContinue)) {Remove-WvcTestRoot $owner}
}
