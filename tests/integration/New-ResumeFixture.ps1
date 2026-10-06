param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Compile the resume fixture under PS5.1.' }
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'EnvironmentTestSupport.ps1')
$code=@'
using System;
using System.IO;
public static class WvcResumeFixture {
    public static int Main(string[] args) {
        if (WvcEnvironmentResponder.Respond(args)) return 0;
        if (Array.IndexOf(args,"-show_streams") >= 0) {
            string codec=Environment.GetEnvironmentVariable("WVC_RESUME_BAD_PROBE")==args[args.Length-1]?"hevc":"h264";
            Console.WriteLine("{\"streams\":[{\"index\":3,\"codec_type\":\"video\",\"codec_name\":\""+codec+"\",\"pix_fmt\":\"yuv420p\",\"width\":320,\"height\":240,\"duration\":\"1\",\"nb_frames\":\"24\"}],\"format\":{\"duration\":\"1\",\"format_name\":\"mov,mp4,m4a,3gp,3g2,mj2\"}}"); return 0;
        }
        int i=Array.IndexOf(args,"-i"); if (i<0 || Array.IndexOf(args,"-n")<0) return 19;
        string source=args[i+1], output=args[args.Length-1], record=Environment.GetEnvironmentVariable("WVC_RESUME_RECORD");
        if (!String.IsNullOrEmpty(record)) File.AppendAllText(record,Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(source))+"|"+Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(output))+Environment.NewLine);
        using (var stream=new FileStream(output,FileMode.CreateNew,FileAccess.Write,FileShare.None)) {
            byte[] header=new byte[] {0,0,0,16,102,116,121,112,105,115,111,109,0,0,0,0,42}; stream.Write(header,0,header.Length);
        }
        if (Path.GetFileName(source)==Environment.GetEnvironmentVariable("WVC_RESUME_FAIL")) { Console.Error.WriteLine("injected failure"); return 17; }
        if (Path.GetFileName(source)==Environment.GetEnvironmentVariable("WVC_RESUME_STOP")) {
            File.WriteAllText(record+".ready","ready");
            var read=Console.In.ReadLineAsync(); if (!read.Wait(15000)) return 18;
        }
        return 0;
    }
}
'@
Add-Type -TypeDefinition ($code+(Get-WvcEnvironmentResponderSource)) -OutputAssembly $Destination -OutputType ConsoleApplication
