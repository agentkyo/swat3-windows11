param(
    [Parameter(Mandatory)][string]$OutDir,
    [string]$ProcessName = 'swat',
    [int]$MaxSeconds = 60,
    [int]$ScreenshotEvery = 5,
    [int]$WaitForStart = 60
)
# Logs the game's process, windows, per-monitor video modes, foreground changes
# and screenshots of the whole virtual desktop. It does not touch the game.
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type @'
using System; using System.Text; using System.Runtime.InteropServices;
public static class W {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
  [DllImport("user32.dll")] public static extern bool GetClipCursor(out RECT r);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L,T,R,B; }
  [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X,Y; }
  [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)] public struct DEVMODE {
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName;
    public ushort dmSpecVersion, dmDriverVersion, dmSize, dmDriverExtra; public uint dmFields;
    public int dmPositionX, dmPositionY; public uint dmDisplayOrientation, dmDisplayFixedOutput;
    public short dmColor, dmDuplex, dmYResolution, dmTTOption, dmCollate;
    [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmFormName;
    public ushort dmLogPixels; public uint dmBitsPerPel, dmPelsWidth, dmPelsHeight, dmDisplayFlags, dmDisplayFrequency;
    public uint dmICMMethod, dmICMIntent, dmMediaType, dmDitherType, dmReserved1, dmReserved2, dmPanningWidth, dmPanningHeight;
  }
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern bool EnumDisplaySettings(string d, int m, ref DEVMODE dm);
  public static string Mode(string d) {
    DEVMODE m = new DEVMODE(); m.dmSize = (ushort)Marshal.SizeOf(typeof(DEVMODE));
    if (!EnumDisplaySettings(d, -1, ref m)) return "?";
    return m.dmPelsWidth + "x" + m.dmPelsHeight + "x" + m.dmBitsPerPel + "@" + m.dmDisplayFrequency + " pos=" + m.dmPositionX + "," + m.dmPositionY;
  }
}
'@
[W]::SetProcessDPIAware() | Out-Null
New-Item -ItemType Directory -Force $OutDir | Out-Null
$log = Join-Path $OutDir 'monitor.log'
function L($m) { Add-Content $log ("{0:HH:mm:ss.f} {1}" -f (Get-Date), $m) }
function Modes { ([System.Windows.Forms.Screen]::AllScreens | ForEach-Object { "$($_.DeviceName -replace '\\\\\.\\','')$(if($_.Primary){'*'})=$([W]::Mode($_.DeviceName))" }) -join ' ; ' }
function Windows($procId) {
    $found = New-Object System.Collections.ArrayList
    $cb = [W+EnumProc]{ param($h, $l)
        $p = [uint32]0; [W]::GetWindowThreadProcessId($h, [ref]$p) | Out-Null
        if ($p -eq $procId -and [W]::IsWindowVisible($h)) {
            $t = New-Object Text.StringBuilder 256; [W]::GetWindowText($h, $t, 256) | Out-Null
            $c = New-Object Text.StringBuilder 256; [W]::GetClassName($h, $c, 256) | Out-Null
            $r = New-Object W+RECT; [W]::GetWindowRect($h, [ref]$r) | Out-Null
            [void]$found.Add("[$c] '$t' $($r.L),$($r.T) $($r.R-$r.L)x$($r.B-$r.T) fg=$([W]::GetForegroundWindow() -eq $h)")
        }
        $true }
    [W]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
    $found
}
function Shot($name) {
    try {
        $b = [System.Windows.Forms.SystemInformation]::VirtualScreen
        $bmp = New-Object Drawing.Bitmap $b.Width, $b.Height
        $g = [Drawing.Graphics]::FromImage($bmp)
        $g.CopyFromScreen($b.Location, [Drawing.Point]::Empty, $b.Size)
        $bmp.Save((Join-Path $OutDir $name), [Drawing.Imaging.ImageFormat]::Png)
        $g.Dispose(); $bmp.Dispose()
    } catch { L "screenshot failed: $($_.Exception.Message)" }
}

$start = Get-Date
L "monitor start; $(Modes)"
$p = $null
while (-not $p -and ((Get-Date) - $start).TotalSeconds -lt $WaitForStart) {
    $p = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $p) { Start-Sleep -Milliseconds 200 }
}
if (-not $p) { L "process $ProcessName never appeared"; exit 1 }
L "process appeared pid=$($p.Id)"
$null = $p.Handle
Start-Sleep -Seconds 3
try { L "MODULES: $(($p.Modules | ForEach-Object ModuleName | Where-Object { $_ -match '(?i)ddraw|d3d|dxgi|gog|swat|nvd3d|nvldumd|nvwgf' } | Sort-Object -Unique) -join ', ')" } catch { L "modules unavailable: $($_.Exception.Message)" }
$i = 0; $lastWin = ''; $lastMode = ''; $t0 = Get-Date
while (((Get-Date) - $t0).TotalSeconds -lt $MaxSeconds) {
    # swat.exe can hand over to a second swat.exe, so follow the process by name.
    if ($p.HasExited) {
        L "pid $($p.Id) exited"
        $p = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $p) { Start-Sleep -Seconds 2; $p = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue | Select-Object -First 1 }
        if (-not $p) { $p = $null; break }
        L "now following pid=$($p.Id)"; $null = $p.Handle
        Start-Sleep -Seconds 2
        try { L "MODULES: $(($p.Modules | ForEach-Object ModuleName | Where-Object { $_ -match '(?i)ddraw|d3d|dxgi|gog|swat|nvd3d|nvldumd|nvwgf' } | Sort-Object -Unique) -join ', ')" } catch { L "modules unavailable: $($_.Exception.Message)" }
    }
    $w = (Windows $p.Id) -join ' | '
    if ($w -ne $lastWin) { L "WINDOWS: $w"; $lastWin = $w }
    $mode = Modes
    if ($mode -ne $lastMode) { L "MODES: $mode"; $lastMode = $mode }
    $c = New-Object W+POINT; [W]::GetCursorPos([ref]$c) | Out-Null
    $clip = New-Object W+RECT; [W]::GetClipCursor([ref]$clip) | Out-Null
    L ("t={0,5:N1}s cursor={1},{2} clip={3},{4}..{5},{6} resp={7}" -f ((Get-Date) - $t0).TotalSeconds, $c.X, $c.Y, $clip.L, $clip.T, $clip.R, $clip.B, $p.Responding)
    if ($i % $ScreenshotEvery -eq 0) { Shot ("shot_{0:D4}.png" -f [int]((Get-Date) - $t0).TotalSeconds) }
    $i++
    Start-Sleep -Seconds 1
}
if (-not $p -or $p.HasExited) { L "process exited after $([int]((Get-Date) - $t0).TotalSeconds)s" } else { L 'time limit reached; process still alive' }
Shot 'final.png'
Get-WinEvent -FilterHashtable @{ LogName = 'Application'; StartTime = $start; ProviderName = 'Application Error', 'Windows Error Reporting', 'Application Hang' } -ErrorAction SilentlyContinue |
    ForEach-Object { L "EVENT $($_.TimeCreated.ToString('HH:mm:ss')) id=$($_.Id) $($_.ProviderName): $(($_.Message -replace '\s+', ' ').Substring(0, [math]::Min(300, $_.Message.Length)))" }
L 'monitor end'
