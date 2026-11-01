param(
    [string]$GamePath,
    [int]$Width,
    [int]$Height,
    [string]$DgVoodooZip
)
# Installs dgVoodoo2 next to swat.exe and sets the game to the primary monitor's resolution.
# dgVoodoo2 is not redistributed here: it is downloaded from its official GitHub release.
$ErrorActionPreference = 'Stop'
$version = '2.87.6'
$url = 'https://github.com/dege-diosg/dgVoodoo2/releases/download/2.87.6/dgVoodoo2_87_6.zip'
$sha256 = '9AFA493396FEEC7108F42A2D97661EEF96BBAAC5ADDF0DFB5CFBC3001CD76A0A'

if (-not $GamePath) {
    $GamePath = (Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games\1207658946' -ErrorAction SilentlyContinue).PATH
    if (-not $GamePath) { $GamePath = 'C:\Program Files (x86)\GOG Galaxy\Games\SWAT 3' }
}
$exe = Join-Path $GamePath 'swat.exe'
$cfgPath = Join-Path $GamePath 'Swat.cfg'
if (-not (Test-Path -LiteralPath $exe)) { throw "swat.exe not found in: $GamePath (use -GamePath)" }
if (-not (Test-Path -LiteralPath $cfgPath)) { throw 'Swat.cfg not found. Open the game once, close it, and run this script again.' }
if (Get-Process -Name swat -ErrorAction SilentlyContinue) { throw 'Close the game first: it rewrites Swat.cfg on exit.' }

if (-not $Width -or -not $Height) {
    Add-Type -Namespace Swat3Fix -Name Native -MemberDefinition '[DllImport("user32.dll")] public static extern bool SetProcessDPIAware();'
    [Swat3Fix.Native]::SetProcessDPIAware() | Out-Null
    Add-Type -AssemblyName System.Windows.Forms
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $Width = $bounds.Width
    $Height = $bounds.Height
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ("swat3-fix-" + [guid]::NewGuid())
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    if ($DgVoodooZip) {
        $zip = $DgVoodooZip
    } else {
        $zip = Join-Path $temp 'dgVoodoo2.zip'
        Write-Output "Downloading dgVoodoo2 $version..."
        Invoke-WebRequest -Uri $url -OutFile $zip
    }
    $hash = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
    if ($hash -ne $sha256) { throw "dgVoodoo2 archive has an unexpected SHA-256: $hash" }

    $extracted = Join-Path $temp 'x'
    Expand-Archive -LiteralPath $zip -DestinationPath $extracted

    # Keep the user's original config once, so uninstall-fix.ps1 can restore it.
    $backupDir = Join-Path $GamePath 'swat3-fix-backup'
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    $backup = Join-Path $backupDir 'Swat.cfg'
    if (-not (Test-Path -LiteralPath $backup)) { Copy-Item -LiteralPath $cfgPath -Destination $backup }

    Copy-Item -LiteralPath (Join-Path $extracted 'MS\x86\DDraw.dll'), (Join-Path $extracted 'MS\x86\D3DImm.dll') -Destination $GamePath -Force

    $settings = [ordered]@{
        ScalingMode                = 'stretched_ar'   # keep 4:3 menus undistorted
        FullscreenAttributes       = 'fake'           # never change the Windows video mode
        CaptureMouse               = 'true'           # keep the cursor inside the game
        SystemHookFlags            = 'gdi,cursor'
        VRAM                       = '1024'
        dgVoodooWatermark          = 'false'
        ExtraEnumeratedResolutions = 'max'            # offer the desktop resolution to the game
    }
    $conf = Get-Content -LiteralPath (Join-Path $extracted 'dgVoodoo.conf') -Raw
    foreach ($key in $settings.Keys) {
        $conf = [regex]::Replace($conf, "(?m)^($key\s*=).*$", "`$1 $($settings[$key])")
    }
    [IO.File]::WriteAllText((Join-Path $GamePath 'dgVoodoo.conf'), $conf)

    $mode = "display_mode=$Width $Height 2 1"
    $lines = [IO.File]::ReadAllLines($cfgPath) | ForEach-Object { $_ -replace '^res=.*$', "res=$Width $Height" }
    $output = New-Object System.Collections.Generic.List[string]
    $added = $lines -contains $mode
    foreach ($line in $lines) {
        if (-not $added -and $line -notmatch '^display_mode=' -and $output.Count -and $output[$output.Count - 1] -match '^display_mode=') {
            $output.Add($mode)
            $added = $true
        }
        $output.Add($line)
    }
    if (-not $added) { $output.Add($mode) }
    [IO.File]::WriteAllLines($cfgPath, [string[]]$output)

    Write-Output "Done: dgVoodoo2 $version installed, 3D resolution set to ${Width}x${Height}."
    Write-Output "Your original Swat.cfg is in: $backupDir"
} catch [UnauthorizedAccessException] {
    throw 'Access denied to the game folder. Run this script from an elevated PowerShell.'
} finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
