# Technical analysis of the GOG install

**English** | [Português](technical-analysis.pt-BR.md) | [Español](technical-analysis.es.md)

Observations from GOG build 2.1.0.34 on one PC with three monitors.

## Setup

`swat.exe` imports `DDRAW.dll` and calls `DirectDrawCreate`. `Swat.cfg` starts with `res=640 480`
and `adapter=primary`. GOG marks the executable with `DWM8And16BitMitigation WINXPSP2 HIGHDPIAWARE
RUNASADMIN`. These flags were not changed.

## Reproduction without the fix

Monitor layout before launch:

| Monitor | Mode | Position |
| --- | --- | --- |
| DISPLAY1 | 1920x1080 | -1920,0 |
| DISPLAY2 (primary) | 2560x1080 | 0,0 |
| DISPLAY3 | 1920x1080 | 2560,0 |

What the monitor logged during the session:

```text
WINDOWS: [Swat3Window] 'SWAT' 0,0 2560x1080 fg=True
MODES: DISPLAY1=1920x1080 pos=-1920,0 ; DISPLAY2*=640x480 pos=0,0 ; DISPLAY3=1920x1080 pos=640,0
WINDOWS: [Swat3Window] 'SWAT' 640,0 1920x1080 fg=True
t=3.1s cursor=320,240 clip=-1920,0..2560,1080
```

Three facts explain the symptoms:

1. **Wrong resolution.** The primary monitor drops to 640x480.
2. **Wrong monitor.** Windows moves DISPLAY3 from x=2560 to x=640 to close the gap. The game window
   ends up at 640,0 with 1920x1080, which is exactly DISPLAY3. A screenshot showed the desktop on the
   primary monitor and a black area on DISPLAY3.
3. **Clicks change the screen.** The cursor stayed on the primary monitor, at 320,240, and the clip
   rectangle covered the whole desktop. The game was on another monitor, so the cursor was not over
   it. A click there goes to another window and the game loses focus. This step is an inference from
   the log and the reported symptom: no click was traced.

## With dgVoodoo2

Same launch, with `DDraw.dll`, `D3DImm.dll` and `dgVoodoo.conf` next to `swat.exe`:

```text
WINDOWS: [Swat3Window] 'SWAT' 0,0 2560x1080 fg=True
MODES: DISPLAY1=1920x1080 pos=-1920,0 ; DISPLAY2*=2560x1080 pos=0,0 ; DISPLAY3=1920x1080 pos=2560,0
t=21.6s cursor=639,479 clip=0,0..640,480
```

- No monitor changed mode or position during the session.
- The cursor is confined to the game: 640x480 and 800x600 in the menus, screen center in a mission.
- Mouse clicks worked in the menus and in a mission.

## Settings changed

In `dgVoodoo.conf`, starting from the 2.87.6 defaults:

| Setting | Value | Reason |
| --- | --- | --- |
| `FullscreenAttributes` | `fake` | Fullscreen window: this is what avoids the mode change |
| `ScalingMode` | `stretched_ar` | Keeps the 4:3 menus undistorted |
| `ExtraEnumeratedResolutions` | `max` | Offers the desktop resolution to the game |
| `SystemHookFlags` | `gdi,cursor` | Draws GDI content and avoids a double cursor |
| `VRAM` | `1024` | More video memory for high resolutions |
| `dgVoodooWatermark` | `false` | Removes the on-screen logo |

In `Swat.cfg`: `res=<width> <height>` and a matching `display_mode=<width> <height> 2 1` line. The
game kept both values after a clean exit.

## Key bindings

Bindings in `Swat.cfg` are `<Windows virtual key code>=<action>`, for example `87=up` for W. Action
names come from `swat.exe` and their meaning from the reference sheet in the game's `FAQs` folder.
`apply-modern-controls.ps1` keeps one key per action, as in the defaults.

## Testing limits

GOG's `RUNASADMIN` flag makes every launch show UAC. Synthetic input from a non-elevated script does
not reach an elevated game, so the menu and mission tests were played by hand. A non-elevated monitor
also can't list the game's modules.

The PC runs DisplayFusion, which manages windows across monitors. Its role was not isolated.

## Untested alternatives

`swat.exe` also contains the `-window`, `-fullscreen` and `-screensize` options. They were not needed
and were not tested. The community
[Last Resort](https://www.moddb.com/addons/last-resort-v073) mod also offers higher resolutions, and
was not tested either.
