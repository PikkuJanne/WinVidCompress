param([Parameter(Mandatory=$true)][string]$Destination)
$ErrorActionPreference='Stop'
# Synthetic FTYP/probe bytes exercise process and filesystem boundaries, not media integrity.
$code=@'
using System;
using System.IO;
using System.Text;
using System.Threading;
public static class WvcSafetyFixture {
    public static int Main(string[] args) {
        string fault=Environment.GetEnvironmentVariable("WVC_SAFETY_FAULT");
        string path=args[args.Length-1];
        if (Array.IndexOf(args,"-show_streams")>=0) {
            bool output=Path.GetFileName(path)=="encode.partial.mp4";
            if (fault==(output?"output-probe":"source-probe")) {
                Console.Error.WriteLine("injected "+fault+" diagnostic"); return 17;
            }
            Console.WriteLine("{\"streams\":[{\"index\":3,\"codec_type\":\"video\",\"codec_name\":\"h264\",\"pix_fmt\":\"yuv420p\",\"width\":320,\"height\":240,\"duration\":\"1\",\"nb_frames\":\"24\"}],\"format\":{\"duration\":\"1\",\"format_name\":\"mov,mp4,m4a,3gp,3g2,mj2\"}}"); return 0;
        }
        if (Array.IndexOf(args,"-n")<0 || Array.IndexOf(args,"-y")>=0) return 19;
        string id=Environment.GetEnvironmentVariable("WVC_SAFETY_ID") ?? "single";
        using(var stream=new FileStream(path,FileMode.CreateNew,FileAccess.Write,FileShare.None)) {
            byte[] header=new byte[] {0,0,0,16,102,116,121,112,105,115,111,109,0,0,0,0};
            stream.Write(header,0,header.Length);
            byte[] payload=Encoding.UTF8.GetBytes("synthetic payload "+id); stream.Write(payload,0,payload.Length);
        }
        if (fault=="encode") { Console.Error.WriteLine("injected encode diagnostic"); return 17; }
        string barrier=Environment.GetEnvironmentVariable("WVC_SAFETY_BARRIER");
        if (!String.IsNullOrEmpty(barrier)) {
            File.WriteAllText(Path.Combine(barrier,id+".target"),path);
            File.WriteAllText(Path.Combine(barrier,id+".encode-ready"),"ready");
            for(int i=0;i<1000;i++) {
                if(Directory.GetFiles(barrier,"*.encode-ready").Length==2) return 0;
                Thread.Sleep(10);
            }
            Console.Error.WriteLine("encoder barrier timeout"); return 18;
        }
        return 0;
    }
}
'@
Add-Type -TypeDefinition $code -OutputAssembly $Destination -OutputType ConsoleApplication
