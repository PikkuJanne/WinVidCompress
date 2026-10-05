param([Parameter(Mandatory = $true)][string]$Destination)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Desktop') { throw 'Compile native fixtures under Windows PowerShell 5.1.' }
$code = @'
using System;
using System.IO;
using System.Text;
public static class WvcStreamFixture {
    public static int Main(string[] args) {
        using (var writer = new StreamWriter(Environment.GetEnvironmentVariable("WVC_STREAM_ARGV"), true, Encoding.UTF8)) {
            writer.WriteLine("CALL");
            foreach (var arg in args) writer.WriteLine(Convert.ToBase64String(Encoding.UTF8.GetBytes(arg)));
        }
        return 0;
    }
}
'@
Add-Type -TypeDefinition $code -OutputAssembly $Destination -OutputType ConsoleApplication
