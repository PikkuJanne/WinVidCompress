# Short synthetic colour sources; caller owns/isolation-checks the destination tree.
function New-ColourSample([string]$Encoder,[string]$SourcePath,[string]$Pixels='yuv420p10le',
    [string]$Range='tv',[string]$Transfer='bt709',[string]$Primaries='bt709',[string]$Matrix='bt709',
    [ValidateSet('Ramp','Bars')][string]$Pattern='Ramp',[switch]$Untagged) {
    if ($Pattern -eq 'Ramp') {
        $depth=8
        if ($Pixels -match 'p(10|12)le$') {$depth=[int]$Matches[1]}
        $factor=[Math]::Pow(2,$depth-8)
        $black=16*$factor;$span=219*$factor;$neutral=128*$factor
        if ($Range -eq 'pc') {$black=0;$span=[Math]::Pow(2,$depth)-1}
        $patternText="nullsrc=s=640x360:r=24:d=0.25,format=$Pixels,"+
            "geq=lum='$black+$span*X/(W-1)':cb='$neutral':cr='$neutral'"
    } else {
        $patternText="smptehdbars=s=640x360:r=24:d=0.25,scale=in_range=tv:out_range=$Range,format=$Pixels"
    }
    # Fixtures contain constructed values, not real HDR. Attach their intentional frame tags.
    if (-not $Untagged) {$patternText+=",setparams=range=$Range`:color_primaries=$Primaries`:color_trc=$Transfer`:colorspace=$Matrix"}
    $arguments=@('-hide_banner','-nostdin','-v','error','-n','-f','lavfi','-i',$patternText,
        '-c:v','libx264','-preset','ultrafast','-crf','0','-pix_fmt',$Pixels)
    if (-not $Untagged) {$arguments+=@('-color_range',$Range,'-color_primaries',$Primaries,'-color_trc',$Transfer,'-colorspace',$Matrix)}
    $arguments+=$SourcePath
    $native=Invoke-WvcTestProcess $Encoder $arguments
    if ($native.ExitCode -ne 0) {throw ('Colour fixture generation failed: '+$native.StdErr)}
}

function Get-ColourLuma([string]$Encoder,[string]$InputPath,[string]$RawPath) {
    $native=Invoke-WvcTestProcess $Encoder @('-hide_banner','-nostdin','-v','error','-n','-i',$InputPath,
        '-map','0:v:0','-frames:v','1','-pix_fmt','yuv420p','-f','rawvideo',$RawPath)
    if ($native.ExitCode -ne 0) {throw ('Colour sample decode failed: '+$native.StdErr)}
    $bytes=[IO.File]::ReadAllBytes($RawPath)
    if ($bytes.Length -ne 640*360*3/2) {throw 'Unexpected decoded colour fixture byte count.'}
    return ,$bytes
}
