param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Compile under Windows PowerShell 5.1.' }
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'EnvironmentTestSupport.ps1')
$code=@'
using System;
using System.Diagnostics;
using System.IO;
using System.Threading;
public static class WvcCancelFixture {
    public static int Main(string[] args) {
        if (WvcEnvironmentResponder.Respond(args)) return 0;
        if (Array.IndexOf(args,"-show_streams") >= 0) {
            Console.WriteLine("{\"streams\":[{\"index\":0,\"codec_type\":\"video\",\"codec_name\":\"h264\",\"pix_fmt\":\"yuv420p\",\"width\":320,\"height\":240,\"duration\":\"30\",\"nb_frames\":\"720\"}],\"format\":{\"duration\":\"30\",\"format_name\":\"mov,mp4,m4a,3gp,3g2,mj2\"}}"); return 0;
        }
        if (Array.IndexOf(args,"-stdin") < 0) return 19;
        // A broken test seam must not leave a native fixture running forever.
        int watchdogSeconds=15;
        if (Environment.GetEnvironmentVariable("WVC_CANCEL_WATCHDOG") == "120") watchdogSeconds=120;
        Thread watchdog=new Thread(delegate() { Thread.Sleep(watchdogSeconds*1000); Environment.Exit(99); });
        watchdog.IsBackground=true; watchdog.Start();
        if (Array.IndexOf(args,"-n") >= 0) {
            using (var stream=new FileStream(args[args.Length-1],FileMode.CreateNew,FileAccess.Write,FileShare.Read)) {
                byte[] header=new byte[] {0,0,0,16,102,116,121,112,105,115,111,109,0,0,0,0};
                stream.Write(header,0,header.Length); stream.WriteByte(42);
            }
        }
        string marker=Environment.GetEnvironmentVariable("WVC_CANCEL_MARKER");
        if (!String.IsNullOrEmpty(marker)) File.AppendAllText(marker,Process.GetCurrentProcess().Id+Environment.NewLine);
        Console.Error.WriteLine("owned cancel fixture ready");
        Console.WriteLine("out_time_us=1000000\nspeed=1.0x\nprogress=continue"); Console.Out.Flush();
        if (Environment.GetEnvironmentVariable("WVC_CANCEL_MODE") == "Ignore") { Thread.Sleep(30000); return 20; }
        if (Console.In.Read() == 'q') { Console.Error.WriteLine("private graceful q received"); return 0; }
        return 21;
    }
}
'@
Add-Type -TypeDefinition ($code+(Get-WvcEnvironmentResponderSource)) -OutputAssembly $Destination -OutputType ConsoleApplication
