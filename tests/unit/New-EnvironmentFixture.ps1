param([Parameter(Mandatory = $true)][string]$Destination)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Compile native fixtures under Windows PowerShell 5.1.' }
. (Join-Path (Split-Path -Parent $PSScriptRoot) 'EnvironmentTestSupport.ps1')
$code = @'
using System;
using System.IO;
using System.Threading;
public static class WvcEnvironmentFixture {
    public static int Main(string[] args) {
        if (args.Length == 1 && args[0] == "fixture-child") { Thread.Sleep(20000); return 0; }
        string mode = Environment.GetEnvironmentVariable("WVC_ENV_FIXTURE_MODE");
        string log = Environment.GetEnvironmentVariable("WVC_ENV_FIXTURE_LOG");
        if (!String.IsNullOrEmpty(log)) File.AppendAllText(log, String.Join("|", args) + "\n");
        if (!String.IsNullOrEmpty(Environment.GetEnvironmentVariable("FFREPORT"))) return 19;
        if (mode == "pipes") {
            var start = new System.Diagnostics.ProcessStartInfo(System.Diagnostics.Process.GetCurrentProcess().MainModule.FileName, "fixture-child");
            start.UseShellExecute = false;
            using (var child = System.Diagnostics.Process.Start(start))
                File.WriteAllText(Environment.GetEnvironmentVariable("WVC_ENV_CHILD_PID"), child.Id.ToString());
            return 0;
        }
        if (mode == "hang") { Console.Error.WriteLine("timeout diagnostic"); Thread.Sleep(20000); return 0; }
        if (mode == "failure") { Console.Error.WriteLine("fixture exit diagnostic"); return 17; }
        if (mode == "wrong") { Console.WriteLine("wrongtool version 1"); return 0; }
        if (mode == "flood") {
            for (int i=0; i<10000; i++) { Console.WriteLine("stdout line"); Console.Error.WriteLine("stderr line"); }
            return 0;
        }
        if (mode == "argv") {
            foreach (string arg in args) Console.WriteLine(Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(arg)));
            return 0;
        }
        if (Array.IndexOf(args, "-encoders") >= 0 && (mode == "no-x264" || mode == "no-aac")) {
            Console.WriteLine(mode == "no-x264" ? " V..... libx264rgb near-match\n A..... aac ok" : " V..... libx264 ok\n A..... aac_at near-match"); return 0;
        }
        if (Array.IndexOf(args, "muxer=mp4") >= 0 && mode == "no-mp4") { Console.WriteLine("Unknown muxer 'mp4'"); return 0; }
        if (Array.IndexOf(args, "filter=scale") >= 0 && mode == "no-scale") { Console.WriteLine("Unknown filter 'scale'"); return 0; }
        if (Array.IndexOf(args, "-show_program_version") >= 0 && mode == "no-probe") { Console.Error.WriteLine("Unsupported writer"); return 18; }
        if (Array.IndexOf(args, "json") >= 0 && mode == "bad-json") { Console.WriteLine("{}"); return 0; }
        if (WvcEnvironmentResponder.Respond(args)) return 0;
        Console.Error.WriteLine("Unexpected media processing in environment fixture"); return 20;
    }
}
'@
Add-Type -TypeDefinition ($code + (Get-WvcEnvironmentResponderSource)) -OutputAssembly $Destination -OutputType ConsoleApplication
