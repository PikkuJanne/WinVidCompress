param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference = 'Stop'
$code = @'
using System;
using System.IO;
using System.Text;
using System.Threading;
public static class WvcCollisionFixture {
    public static int Main(string[] args) {
        if (Path.GetFileName(Environment.GetCommandLineArgs()[0]) == "probe.exe") {
            Console.WriteLine("{\"streams\":[{\"index\":3,\"codec_type\":\"video\",\"codec_name\":\"h264\",\"width\":320,\"height\":240}]}");
            return 0;
        }
        string id = Environment.GetEnvironmentVariable("WVC_COLLISION_ID");
        string barrier = Environment.GetEnvironmentVariable("WVC_COLLISION_BARRIER");
        string output = args[args.Length-1];
        try {
            if (Array.IndexOf(args,"-n") < 0 || Array.IndexOf(args,"-y") >= 0) return 19;
            using (var stream = new FileStream(output,FileMode.CreateNew,FileAccess.Write,FileShare.None)) {
                byte[] data = Encoding.UTF8.GetBytes("synthetic payload " + id);
                stream.Write(data,0,data.Length);
            }
            File.WriteAllText(Path.Combine(barrier,id+".target"),output,Encoding.UTF8);
            using (var ready = new FileStream(Path.Combine(barrier,id+".ready"),FileMode.CreateNew)) { }
            for (int i=0; i<1000; i++) {
                if (Directory.GetFiles(barrier,"*.ready").Length == 2) return 0;
                Thread.Sleep(10);
            }
            Console.Error.WriteLine("Synthetic barrier timed out"); return 18;
        } catch (IOException error) { Console.Error.WriteLine(error.Message); return 17; }
    }
}
'@
Add-Type -TypeDefinition $code -OutputAssembly $Destination -OutputType ConsoleApplication
