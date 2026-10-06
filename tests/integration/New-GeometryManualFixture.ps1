[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$ReportPath,[string]$FFmpeg,[string]$FFprobe)
$ErrorActionPreference='Stop'
$repoRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'TestSupport.ps1')
$encoder=Resolve-WvcTestExecutable $FFmpeg 'ffmpeg.exe'
$probe=Resolve-WvcTestExecutable $FFprobe 'ffprobe.exe'
if (-not $encoder -or -not $probe) { throw 'Existing FFmpeg and FFprobe are required; nothing is downloaded.' }
$owner=New-WvcTestRoot
$savedAppData=$env:APPDATA
$savedFfreport=$env:FFREPORT
$prepared=$false
try {
    $env:APPDATA=Join-Path $owner.Path 'appdata'
    $env:FFREPORT=$null
    . (Join-Path $repoRoot 'WinVidCompress.ps1')
    $output=Join-Path $owner.Path 'output'
    [void][IO.Directory]::CreateDirectory($output)
    $font=(Join-Path $env:SystemRoot 'Fonts/arial.ttf').Replace('\','/').Replace(':','\:')
    $panels=@();$samples=@()
    foreach ($case in @(
        @{Name='SD';W=640;H=480;R=0;Sar='1/1'},
        @{Name='Portrait';W=1080;H=1920;R=0;Sar='1/1'},
        @{Name='Rotation90';W=1920;H=1080;R=90;Sar='1/1'},
        @{Name='Rotation180';W=640;H=480;R=180;Sar='1/1'},
        @{Name='Rotation270';W=640;H=480;R=270;Sar='1/1'},
        @{Name='AnamorphicOdd';W=641;H=479;R=0;Sar='16/15'}
    )) {
        $base=Join-Path $owner.Path ($case.Name+'-base.mp4')
        $source=Join-Path $owner.Path ($case.Name+'.mp4')
        $pattern="color=c=black:s=64x64:r=24:d=1,format=yuv444p,scale=$($case.W):$($case.H),"+
            'drawbox=x=0:y=0:w=iw/2:h=ih/2:color=red:t=fill,'+
            'drawbox=x=iw/2:y=0:w=iw/2:h=ih/2:color=lime:t=fill,'+
            'drawbox=x=0:y=ih/2:w=iw/2:h=ih/2:color=blue:t=fill,'+
            "drawbox=x=iw/2:y=ih/2:w=iw/2:h=ih/2:color=yellow:t=fill,setsar=$($case.Sar)"
        $generated=Invoke-WvcTestProcess $encoder @('-hide_banner','-nostdin','-v','error','-n','-f','lavfi','-i',$pattern,
            '-c:v','libx264','-preset','ultrafast','-crf','0','-pix_fmt','yuv444p',$base)
        if ($generated.ExitCode -ne 0) { throw $generated.StdErr }
        $rotated=Invoke-WvcTestProcess $encoder @('-hide_banner','-nostdin','-v','error','-n','-display_rotation:v:0',"$($case.R)",'-i',$base,'-c','copy',$source)
        if ($rotated.ExitCode -ne 0) { throw $rotated.StdErr }
        $sourceHash=(Get-FileHash -LiteralPath $source).Hash
        $job=Compress-One $encoder $probe $source $output 22
        if ($job.Outcome -ne 'Completed') { throw $job.Reason }
        if ((Get-FileHash -LiteralPath $source).Hash -ne $sourceHash) { throw 'Owned source changed.' }
        foreach ($side in @(@{Name='SOURCE';Path=$source},@{Name='OUTPUT';Path=$job.OutputPath})) {
            $panel=Join-Path $owner.Path ($case.Name+'-'+$side.Name+'.png')
            # Render each file's display aspect into the same review canvas; bars show its full extent.
            $filter="scale=trunc(iw*sar):ih,setsar=1,scale=320:200:force_original_aspect_ratio=decrease,"+
                "pad=320:240:(ow-iw)/2:20+(200-ih)/2:color=black,drawtext=fontfile='$font':"+
                "text='$($case.Name) $($side.Name)':fontsize=15:fontcolor=white:x=8:y=4"
            $rendered=Invoke-WvcTestProcess $encoder @('-hide_banner','-nostdin','-v','error','-n','-i',$side.Path,'-frames:v','1','-vf',$filter,$panel)
            if ($rendered.ExitCode -ne 0) { throw $rendered.StdErr }
            $panels+=$panel
        }
        $samples+=[pscustomobject]@{Name=$case.Name;SourceHash=$sourceHash;OutputHash=(Get-FileHash -LiteralPath $job.OutputPath).Hash;
            Width=$job.Diagnostics.Validation.Inspection.PrimaryVideo.Width;Height=$job.Diagnostics.Validation.Inspection.PrimaryVideo.Height}
    }
    $sheet=Join-Path $owner.Path 'geometry-comparison.png'
    $arguments=@('-hide_banner','-nostdin','-v','error','-n')
    foreach ($panel in $panels) { $arguments+=@('-i',$panel) }
    $layout=(0..11 | ForEach-Object {"$((($_ % 2)*320))_$(([int][Math]::Floor($_/2.0)*240))"}) -join '|'
    $arguments+=@('-filter_complex',"xstack=inputs=12:layout=$layout",'-frames:v','1',$sheet)
    $stacked=Invoke-WvcTestProcess $encoder $arguments
    if ($stacked.ExitCode -ne 0) { throw $stacked.StdErr }
    $sourceCommit=(& git -C $repoRoot rev-parse HEAD).Trim()
    $dirty=[bool](& git -C $repoRoot status --porcelain)
    $record=[pscustomobject]@{SchemaVersion=1;Owner=$owner;SourceCommit=$sourceCommit;SourceTreeDirty=$dirty;
        ApplicationHash=(Get-FileHash (Join-Path $repoRoot 'WinVidCompress.ps1')).Hash;ComparisonPath=$sheet;
        ComparisonHash=(Get-FileHash -LiteralPath $sheet).Hash;Samples=$samples;OwnerObservation='NotRun'}
    Write-WvcTestJson $ReportPath $record
    $prepared=$true
    Write-Output $sheet
} catch {
    if ($_.Exception.Data.Contains('WvcAbortBatch')) { $script:WvcProcessCleanupFailed=$true }
    throw
} finally {
    $env:APPDATA=$savedAppData
    $env:FFREPORT=$savedFfreport
    # Retain the successful owned kit until the owner has viewed it.
    if (-not $prepared -and -not (Get-Variable WvcProcessCleanupFailed -Scope Script -ErrorAction SilentlyContinue)) { Remove-WvcTestRoot $owner }
}
