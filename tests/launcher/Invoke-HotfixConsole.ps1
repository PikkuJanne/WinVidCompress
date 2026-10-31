# Developer-only hidden native-console driver. Invoked in an isolated PS5.1 child.
[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$BatPath,
    [Parameter(Mandatory=$true)][string]$WorkingDirectory,
    [Parameter(Mandatory=$true)][string]$TranscriptPath,
    [Parameter(Mandatory=$true)][string]$MarkerPath)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$env:WVC_PROOF_BAT=$BatPath
$env:WVC_PROOF_QUIT_MARKER=$MarkerPath
$driver=@'
using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading;

public static class WvcHiddenConsole {
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    struct STARTUPINFO {
        public int cb; public string reserved, desktop, title;
        public int x,y,xSize,ySize,xCountChars,yCountChars,fillAttribute,flags;
        public short showWindow,reservedBytes; public IntPtr reservedData,input,output,error;
    }
    [StructLayout(LayoutKind.Sequential)] struct PROCESS_INFORMATION {
        public IntPtr process,thread; public uint processId,threadId;
    }
    [StructLayout(LayoutKind.Sequential)] struct COORD {
        public short X,Y; public COORD(short x,short y) {X=x;Y=y;}
    }
    [StructLayout(LayoutKind.Sequential)] struct RECT {public short Left,Top,Right,Bottom;}
    [StructLayout(LayoutKind.Sequential)] struct SCREEN_INFO {
        public COORD Size,CursorPosition; public short Attributes;
        public RECT Window; public COORD MaximumWindowSize;
    }
    [StructLayout(LayoutKind.Explicit,CharSet=CharSet.Unicode,Size=20)] struct INPUT_RECORD {
        [FieldOffset(0)] public ushort EventType;
        [FieldOffset(4),MarshalAs(UnmanagedType.Bool)] public bool KeyDown;
        [FieldOffset(8)] public ushort RepeatCount;
        [FieldOffset(10)] public ushort VirtualKeyCode;
        [FieldOffset(12)] public ushort VirtualScanCode;
        [FieldOffset(14)] public char UnicodeChar;
        [FieldOffset(16)] public uint ControlKeyState;
    }
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
    static extern bool CreateProcess(string application,StringBuilder command,IntPtr processAttributes,
        IntPtr threadAttributes,bool inherit,uint flags,IntPtr environment,string directory,
        ref STARTUPINFO startup,out PROCESS_INFORMATION info);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool AttachConsole(uint processId);
    [DllImport("kernel32.dll")] static extern bool FreeConsole();
    [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int identifier);
    [DllImport("kernel32.dll")] static extern bool SetStdHandle(int identifier,IntPtr handle);
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
    static extern IntPtr CreateFile(string name,uint access,uint share,IntPtr security,uint creation,uint flags,IntPtr template);
    [DllImport("kernel32.dll",SetLastError=true)] static extern bool GetConsoleScreenBufferInfo(IntPtr output,out SCREEN_INFO info);
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
    static extern bool ReadConsoleOutputCharacter(IntPtr output,StringBuilder text,uint length,COORD coordinate,out uint read);
    [DllImport("kernel32.dll",CharSet=CharSet.Unicode,SetLastError=true)]
    static extern bool WriteConsoleInput(IntPtr input,INPUT_RECORD[] records,uint count,out uint written);
    [DllImport("user32.dll",CharSet=CharSet.Unicode)] static extern short VkKeyScan(char character);
    [DllImport("kernel32.dll")] static extern uint WaitForSingleObject(IntPtr handle,uint milliseconds);
    [DllImport("kernel32.dll")] static extern bool GetExitCodeProcess(IntPtr process,out uint exitCode);
    [DllImport("kernel32.dll")] static extern bool CloseHandle(IntPtr handle);

    static string Screen(IntPtr output) {
        SCREEN_INFO info;
        if(!GetConsoleScreenBufferInfo(output,out info)) throw new Win32Exception();
        int usedRows=Math.Min((int)info.Size.Y,(int)info.CursorPosition.Y+2);
        uint length=(uint)Math.Min(2000000,(int)info.Size.X*usedRows);
        var text=new StringBuilder((int)length); uint read;
        if(!ReadConsoleOutputCharacter(output,text,length,new COORD(0,0),out read)) throw new Win32Exception();
        return text.ToString();
    }
    static void Type(IntPtr input,string text) {
        var records=new INPUT_RECORD[text.Length*2];
        for(int i=0;i<text.Length;i++) {
            ushort key=text[i]=='\r'?(ushort)13:(ushort)(VkKeyScan(text[i])&255);
            records[2*i]=new INPUT_RECORD {EventType=1,KeyDown=true,RepeatCount=1,VirtualKeyCode=key,UnicodeChar=text[i]};
            records[2*i+1]=records[2*i];records[2*i+1].KeyDown=false;
        }
        uint written;
        if(!WriteConsoleInput(input,records,(uint)records.Length,out written) || written!=records.Length) throw new Win32Exception();
    }
    static void Stop(uint id) {
        var start=new ProcessStartInfo(Path.Combine(Environment.GetEnvironmentVariable("SystemRoot"),"System32\\taskkill.exe"),"/PID "+id+" /T /F");
        start.UseShellExecute=false;start.CreateNoWindow=true;start.RedirectStandardOutput=true;start.RedirectStandardError=true;
        using(var process=Process.Start(start)) {
            var stdout=process.StandardOutput.ReadToEndAsync();var stderr=process.StandardError.ReadToEndAsync();
            if(!process.WaitForExit(5000)) throw new InvalidOperationException("Owned console process cleanup timed out.");
            stdout.Wait(1000);stderr.Wait(1000);
        }
    }
    public static int Run(string directory,string transcript,string marker) {
        var originalInput=GetStdHandle(-10);var originalOutput=GetStdHandle(-11);var originalError=GetStdHandle(-12);
        var info=new PROCESS_INFORMATION();IntPtr input=IntPtr.Zero,output=IntPtr.Zero;bool started=false,attached=false;
        string lastScreen="";var clock=Stopwatch.StartNew();string phase="startup";
        try {
            string command=Path.Combine(Environment.GetEnvironmentVariable("SystemRoot"),"System32\\cmd.exe");
            var startup=new STARTUPINFO();startup.cb=Marshal.SizeOf(startup);
            // CREATE_NEW_CONSOLE plus SW_HIDE provides real console handles with
            // no visible window; redirected pipes cannot drive Read-Host reliably.
            startup.flags=1;startup.showWindow=0;
            var arguments=new StringBuilder("\""+command+"\" /d /v:off /s /c \"\"%WVC_PROOF_BAT%\"\"");
            if(!CreateProcess(command,arguments,IntPtr.Zero,IntPtr.Zero,false,0x10,IntPtr.Zero,directory,ref startup,out info)) throw new Win32Exception();
            started=true;FreeConsole();
            while(clock.ElapsedMilliseconds<5000 && !(attached=AttachConsole(info.processId))) Thread.Sleep(25);
            if(!attached) throw new InvalidOperationException("Could not attach hidden fixture console.");
            input=CreateFile("CONIN$",0xC0000000,3,IntPtr.Zero,3,0,IntPtr.Zero);
            output=CreateFile("CONOUT$",0xC0000000,3,IntPtr.Zero,3,0,IntPtr.Zero);
            if(input==new IntPtr(-1)||output==new IntPtr(-1)) throw new Win32Exception();
            bool quitSent=false,markerSent=false,exitSent=false;
            while(clock.ElapsedMilliseconds<40000) {
                lastScreen=Screen(output);
                if(!quitSent && lastScreen.Contains("Select [1-4]")) {Type(input,"4\r");quitSent=true;phase="quit";}
                if(quitSent && !markerSent && lastScreen.Contains("PS ")) {
                    Type(input,"[IO.File]::WriteAllText($env:WVC_PROOF_QUIT_MARKER,'returned'); Write-Output 'WVC_PROOF_AFTER_QUIT'\r");
                    markerSent=true;phase="retained-prompt";
                }
                if(markerSent && !exitSent && File.Exists(marker)) {Type(input,"exit 0\r");exitSent=true;phase="exit";}
                if(WaitForSingleObject(info.process,0)==0) {
                    uint code;GetExitCodeProcess(info.process,out code);
                    if(!quitSent||!markerSent||!exitSent||!File.Exists(marker)) throw new InvalidOperationException("Hidden console ended before retained-prompt proof.");
                    File.WriteAllText(transcript,lastScreen,Encoding.UTF8);return (int)code;
                }
                Thread.Sleep(50);
            }
            throw new InvalidOperationException("Hidden console deadline at "+phase+".");
        } finally {
            if(output!=IntPtr.Zero&&output!=new IntPtr(-1)) {
                try{lastScreen=Screen(output);}catch{}
                File.WriteAllText(transcript,lastScreen,Encoding.UTF8);CloseHandle(output);
            }
            if(input!=IntPtr.Zero&&input!=new IntPtr(-1)) CloseHandle(input);
            if(attached) FreeConsole();
            SetStdHandle(-10,originalInput);SetStdHandle(-11,originalOutput);SetStdHandle(-12,originalError);
            if(started&&WaitForSingleObject(info.process,0)!=0) Stop(info.processId);
            if(info.thread!=IntPtr.Zero) CloseHandle(info.thread);
            if(info.process!=IntPtr.Zero) CloseHandle(info.process);
        }
    }
}
'@
try {
    Add-Type -TypeDefinition $driver -Language CSharp
    $code=[WvcHiddenConsole]::Run($WorkingDirectory,$TranscriptPath,$MarkerPath)
    if($code -ne 0) {throw 'Actual BAT hidden console returned a nonzero exit.'}
    if(-not (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {throw 'Retained prompt marker is missing.'}
    [Console]::WriteLine('WVC_PROOF_AFTER_QUIT')
    exit 0
} catch {
    [Console]::Error.WriteLine(('Hidden console proof failed: '+$_.Exception.Message))
    exit 1
}
