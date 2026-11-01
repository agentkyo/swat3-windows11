param(
    [string]$GamePath
)
# Removes the dgVoodoo2 files and restores the Swat.cfg saved by install-fix.ps1.
$ErrorActionPreference = 'Stop'
if (-not $GamePath) {
    $GamePath = (Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\GOG.com\Games\1207658946' -ErrorAction SilentlyContinue).PATH
    if (-not $GamePath) { $GamePath = 'C:\Program Files (x86)\GOG Galaxy\Games\SWAT 3' }
}
if (-not (Test-Path -LiteralPath (Join-Path $GamePath 'swat.exe'))) { throw "swat.exe not found in: $GamePath (use -GamePath)" }
if (Get-Process -Name swat -ErrorAction SilentlyContinue) { throw 'Close the game first: it rewrites Swat.cfg on exit.' }

foreach ($file in 'DDraw.dll', 'D3DImm.dll', 'dgVoodoo.conf') {
    Remove-Item -LiteralPath (Join-Path $GamePath $file) -Force -ErrorAction SilentlyContinue
}
$backupDir = Join-Path $GamePath 'swat3-fix-backup'
$backup = Join-Path $backupDir 'Swat.cfg'
if (Test-Path -LiteralPath $backup) {
    Copy-Item -LiteralPath $backup -Destination (Join-Path $GamePath 'Swat.cfg') -Force
    Remove-Item -LiteralPath $backupDir -Recurse -Force
    Write-Output 'Fix removed and original Swat.cfg restored.'
} else {
    Write-Output 'Fix removed. No Swat.cfg backup was found, so Swat.cfg was left as it is.'
}
