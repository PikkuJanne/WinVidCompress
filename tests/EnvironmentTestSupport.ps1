# Shared native recorder responses for environment checks. Never real media tools.
function Get-WvcEnvironmentResponderSource {
@'
public static class WvcEnvironmentResponder {
    public static bool Respond(string[] args) {
        string tool = System.IO.Path.GetFileNameWithoutExtension(System.Environment.GetCommandLineArgs()[0]);
        if (args.Length == 1 && args[0] == "-version") {
            System.Console.WriteLine(tool + " version synthetic-m106\nconfiguration: synthetic recorder, no codecs");
            return true;
        }
        if (System.Array.IndexOf(args, "-encoders") >= 0) {
            System.Console.WriteLine(" V..... libx264 synthetic\n A..... aac synthetic"); return true;
        }
        if (System.Array.IndexOf(args, "muxer=mp4") >= 0) {
            System.Console.WriteLine("Muxer mp4 [synthetic]\n faststart synthetic"); return true;
        }
        if (System.Array.IndexOf(args, "filter=scale") >= 0) {
            System.Console.WriteLine("Filter scale\n synthetic"); return true;
        }
        if (System.Array.IndexOf(args, "-show_program_version") >= 0) {
            if (System.Array.IndexOf(args, "json") >= 0)
                System.Console.WriteLine("{\"program_version\":{\"version\":\"synthetic-m106\"}}");
            else System.Console.WriteLine("synthetic-m106");
            return true;
        }
        return false;
    }
}
'@
}
