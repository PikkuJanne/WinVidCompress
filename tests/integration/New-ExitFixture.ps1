param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Compile the exit fixture under Windows PowerShell 5.1.' }
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'EnvironmentTestSupport.ps1')
$code=@'
using System;
using System.IO;
public static class WvcExitFixture {
    public static int Main(string[] args) {
        if (WvcEnvironmentResponder.Respond(args)) return 0;
        if (Array.IndexOf(args,"-show_streams") >= 0) {
            Console.WriteLine("{\"streams\":[{\"index\":3,\"codec_type\":\"video\",\"codec_name\":\"h264\",\"width\":320,\"height\":240,\"duration\":\"1\",\"nb_frames\":\"24\"}],\"format\":{\"duration\":\"1\",\"format_name\":\"mov,mp4,m4a,3gp,3g2,mj2\"}}");
            return 0;
        }
        int inputIndex=Array.IndexOf(args,"-i");
        if (inputIndex < 0 || inputIndex+1 >= args.Length || Array.IndexOf(args,"-n") < 0) return 19;
        if (Path.GetFileName(args[inputIndex+1]).StartsWith("fail",StringComparison.OrdinalIgnoreCase)) {
            Console.Error.WriteLine("synthetic native encode failure"); return 17;
        }
        try {
            using (var stream=new FileStream(args[args.Length-1],FileMode.CreateNew,FileAccess.Write,FileShare.None)) {
                byte[] header=new byte[] {0,0,0,16,102,116,121,112,105,115,111,109,0,0,0,0};
                stream.Write(header,0,header.Length);
                stream.WriteByte(42);
            }
            return 0;
        } catch (IOException error) { Console.Error.WriteLine(error.Message); return 18; }
    }
}
'@
Add-Type -TypeDefinition ($code+(Get-WvcEnvironmentResponderSource)) -OutputAssembly $Destination -OutputType ConsoleApplication
