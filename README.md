# SWAT 3 on Windows 11

**English** | [Português](README.pt-BR.md) | [Español](README.es.md)

Fix for **SWAT 3: Tactical Game of the Year Edition** (GOG) on Windows 11: wrong monitor, wrong
resolution, and clicks that throw you out of the game. Includes a modern WASD layout.

This repository **does not contain game files** or dgVoodoo2. You need your own copy of the game.

Author: [agentkyo](https://github.com/agentkyo)

## The problem

With more than one monitor, the game opens on the wrong screen, in the wrong resolution, and
clicking anywhere switches screens. The menu can't be used.

The game asks Windows to change the primary monitor to 640x480. Windows then moves the other
monitors, and the game ends up on a different screen from the mouse. The cursor is also free to
leave the game. Details are in [`docs/technical-analysis.md`](docs/technical-analysis.md).

## The fix

[dgVoodoo2](https://github.com/dege-diosg/dgVoodoo2) replaces the game's DirectDraw layer. The
game renders in a window the size of the primary monitor, Windows never changes video mode, and
the cursor stays inside the game.

1. Close the game.
2. Open PowerShell 7 in this folder and run:

   ```powershell
   pwsh -NoProfile -File .\tools\install-fix.ps1
   ```

3. Open the game normally through GOG Galaxy.

The script finds the game through the GOG registry key, downloads dgVoodoo2 2.87.6 from its
official release, checks the SHA-256, and sets the 3D resolution to that of your primary monitor.
It backs up `Swat.cfg` first.

Options: `-GamePath`, to point to another folder; `-Width` and `-Height`, to choose the
resolution. If you get "Access denied", run PowerShell as administrator.

To undo everything:

```powershell
pwsh -NoProfile -File .\tools\uninstall-fix.ps1
```

## What to expect

- **Menus are 4:3**, centered with black bars. They are fixed at 640x480 and 800x600.
- **Missions fill the screen** at your native resolution, including ultrawide.
- **A UAC prompt appears on launch.** GOG marks the game to run as administrator.

## Modern controls (WASD)

```powershell
pwsh -NoProfile -File .\tools\apply-modern-controls.ps1
```

| Action | Original | Modern |
| --- | --- | --- |
| Move / strafe | Arrow keys | **W A S D** |
| Run | Right mouse | **Shift** |
| Scope | N | **Right mouse** |
| Hold to crouch | / | **Ctrl** |
| Crouch/stand toggle | A | **C** |
| Hold to lean left / right | Z / X | **Q / E** |
| Use door or object | U | **F** |
| Flashlight | F | **T** |
| Flashbang | F3 | **G** |
| Half / full throw (hold, with left mouse) | Shift / Ctrl | **Z / X** |
| Show/hide text dialogue | D | **H** |
| Crouch / stand | C / S | **,** / **.** |

Everything else keeps its default key, such as R to reload, M for the command menu, middle mouse
for compliance, F1/F2 for weapons, and the keypad for fixed leans.

To go back to the previous keys:

```powershell
pwsh -NoProfile -File .\tools\apply-modern-controls.ps1 -Restore
```

## Current status

Tested on one PC:

| Item | Result |
| --- | --- |
| Launch with UAC, correct monitor | OK |
| Monitors keep their layout and resolution | OK |
| Menu with mouse | OK |
| Mission at 2560x1080 | OK |
| WASD layout in a mission | OK |
| Long sessions, full campaign | Not tested yet |
| Intro videos | Not tested yet |
| Multiplayer | Not tested yet |
| Single-monitor PCs | Not tested yet |

Environment: Windows 11 Pro build 26300, GeForce RTX 4070 Ti, three monitors (1920x1080,
2560x1080 primary, 1920x1080) at 180 Hz, GOG build 2.1.0.34, dgVoodoo2 2.87.6.

## Contents

- [`docs/technical-analysis.md`](docs/technical-analysis.md): diagnosis and evidence.
- [`tools/install-fix.ps1`](tools/install-fix.ps1): installs and configures the fix.
- [`tools/uninstall-fix.ps1`](tools/uninstall-fix.ps1): removes the fix.
- [`tools/apply-modern-controls.ps1`](tools/apply-modern-controls.ps1): applies or restores the
  WASD layout.
- [`tools/monitor.ps1`](tools/monitor.ps1): logs windows, the video mode of each monitor, cursor
  limits and screenshots while the game runs.

## Using the monitor

```powershell
pwsh -NoProfile -File .\tools\monitor.ps1 -OutDir .\run1 -MaxSeconds 60
```

The output contains screenshots of all your monitors, so review it before sharing. Run it from an
elevated PowerShell to also log the game's loaded modules.

## Disclaimer

Fan project, not affiliated with GOG, Sierra or the game's rights holders. dgVoodoo2 is the work
of its author and is downloaded from its official repository.
