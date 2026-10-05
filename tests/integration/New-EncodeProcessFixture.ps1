param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference = 'Stop'
# Compile with Windows PowerShell 5.1; no downloaded executable or media.
$source = @'
using System;
using System.Diagnostics;
using System.IO;
using System.Text;
using System.Threading;
public static class WvcEncodeProcessFixture {
    public static int Main(string[] args) {
        Console.OutputEncoding = new UTF8Encoding(false);
        string mode = args.Length == 0 ? "argv" : args[0];
        string pid = Environment.GetEnvironmentVariable("WVC_ENCODE_PID");
        if (!String.IsNullOrEmpty(pid)) File.WriteAllText(pid, Process.GetCurrentProcess().Id.ToString());
        if (mode == "hold") { Console.Error.Write("owned process ready\n"); Thread.Sleep(4000); return 0; }
        if (mode == "inherit") {
            var child = Process.Start(new ProcessStartInfo {
                FileName = Process.GetCurrentProcess().MainModule.FileName,
                Arguments = "hold", UseShellExecute = false, CreateNoWindow = true
            });
            File.WriteAllText(Environment.GetEnvironmentVariable("WVC_ENCODE_CHILD_PID"), child.Id.ToString());
            child.Dispose(); return 0;
        }
        if (mode == "fail") return 17;
        if (mode == "stdin") { Console.Write(Console.In.Read() == -1 ? "EOF" : "INPUT CONSUMED"); return 0; }
        if (mode == "report") { Console.Write(Environment.GetEnvironmentVariable("FFREPORT") ?? "ABSENT"); return 0; }
        if (mode == "flood") {
            Thread output = new Thread(delegate() {
                for (int i=0; i<256; i++) Console.Write(new string('O', 4096));
                Console.Write("STDOUT END " + (char)0x00E4);
            });
            output.Start();
            for (int i=0; i<256; i++) Console.Error.Write(new string('E', 4096));
            Console.Error.Write("STDERR END " + (char)0x00F6);
            output.Join(); return 0;
        }
        if (mode == "warning") { Console.Error.Write("benign native warning"); return 0; }
        foreach (string value in args) Console.WriteLine(Convert.ToBase64String(Encoding.UTF8.GetBytes(value)));
        return 0;
    }
}
'@
# Add-Type resolves wildcard syntax in -OutputAssembly. Compile to an owned plain
# name, then promote literally without clobbering the requested executable.
$temporary = Join-Path ([IO.Path]::GetDirectoryName($Destination)) ('wvc-recorder-' + [guid]::NewGuid().ToString('N') + '.exe')
Add-Type -TypeDefinition $source -Language CSharp -OutputAssembly $temporary -OutputType ConsoleApplication
[IO.File]::Move($temporary,$Destination)
