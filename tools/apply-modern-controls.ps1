param(
    [string]$GamePath,
    [switch]$Restore
)
# Applies a WASD layout to the key bindings in Swat.cfg, or restores the previous ones.
# Bindings are stored as "<Windows virtual key code>=<action>", one per line.
$ErrorActionPreference = 'Stop'
if (-not $GamePath) {
    $GamePath = (Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games\1207658946' -ErrorAction SilentlyContinue).PATH
    if (-not $GamePath) { $GamePath = 'C:\Program Files (x86)\GOG Galaxy\Games\SWAT 3' }
}
$cfgPath = Join-Path $GamePath 'Swat.cfg'
if (-not (Test-Path -LiteralPath $cfgPath)) { throw "Swat.cfg not found in: $GamePath (use -GamePath, or open the game once)" }
if (Get-Process -Name swat -ErrorAction SilentlyContinue) { throw 'Close the game first: it rewrites Swat.cfg on exit.' }

$backupDir = Join-Path $GamePath 'swat3-fix-backup'
$backup = Join-Path $backupDir 'Swat.cfg.controls'
$keyLine = '^\d+=\w+$'
$lines = [IO.File]::ReadAllLines($cfgPath)

if ($Restore) {
    if (-not (Test-Path -LiteralPath $backup)) { throw "No saved key bindings found: $backup" }
    $saved = [IO.File]::ReadAllLines($backup) | Where-Object { $_ -match $keyLine }
    $other = $lines | Where-Object { $_ -notmatch $keyLine }
    [IO.File]::WriteAllLines($cfgPath, [string[]]($other + $saved))
    Remove-Item -LiteralPath $backup -Force
    Write-Output 'Previous key bindings restored.'
    return
}

$layout = [ordered]@{
    up = 87            # W
    down = 83          # S
    left = 65          # A
    right = 68         # D
    movefast = 16      # Shift
    tempcrouch = 17    # Ctrl (hold)
    crsttoggle = 67    # C
    templeanleft = 81  # Q (hold)
    templeanright = 69 # E (hold)
    usegeneric = 70    # F
    flashlight = 84    # T
    flashbang = 71     # G
    zoom = 2           # Right mouse button
    halfthrow = 90     # Z
    fullthrow = 88     # X
    toggledialog = 72  # H
    crouch = 188       # ,
    stand = 190        # .
}

if (-not (Test-Path -LiteralPath $backup)) {
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    Copy-Item -LiteralPath $cfgPath -Destination $backup
}

$taken = @{}
foreach ($action in $layout.Keys) { $taken[[string]$layout[$action]] = $action }
$output = foreach ($line in $lines) {
    if ($line -notmatch $keyLine) { $line; continue }
    $code, $action = $line -split '=', 2
    if ($layout.Contains($action)) {
        "$($layout[$action])=$action"
    } elseif ($taken.ContainsKey($code)) {
        Write-Warning "Key $code was bound to '$action' and now does '$($taken[$code])'. Rebind '$action' in Options if you use it."
    } else {
        $line
    }
}
[IO.File]::WriteAllLines($cfgPath, [string[]]$output)
Write-Output 'Modern WASD layout applied.'
