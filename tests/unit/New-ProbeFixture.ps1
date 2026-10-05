param([Parameter(Mandatory = $true)][string]$Destination)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Compile native fixtures under Windows PowerShell 5.1.' }
$code = @'
using System;
using System.IO;
using System.Text;
using System.Threading;
public static class WvcProbeFixture {
    public static int Main(string[] args) {
        Console.OutputEncoding = new UTF8Encoding(false);
        Console.InputEncoding = new UTF8Encoding(false);
        string record = Environment.GetEnvironmentVariable("WVC_PROBE_ARGV");
        if (!String.IsNullOrEmpty(record)) {
            using (var writer = new StreamWriter(record, true, Encoding.UTF8)) {
                writer.WriteLine("CALL");
                foreach (var arg in args) writer.WriteLine(Convert.ToBase64String(Encoding.UTF8.GetBytes(arg)));
            }
        }
        Console.Error.WriteLine("synthetic probe diagnostic");
        string mode = Environment.GetEnvironmentVariable("WVC_PROBE_MODE");
        if (mode == "hang") { Thread.Sleep(20000); return 0; }
        if (mode == "fail") return 23;
        Console.Write(File.ReadAllText(Environment.GetEnvironmentVariable("WVC_PROBE_JSON"), Encoding.UTF8));
        return 0;
    }
}
'@
Add-Type -TypeDefinition $code -OutputAssembly $Destination -OutputType ConsoleApplication
