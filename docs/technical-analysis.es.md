# Análisis técnico de la instalación de GOG

[English](technical-analysis.md) | [Português](technical-analysis.pt-BR.md) | **Español**

Observaciones hechas en la build GOG 2.1.0.34, en un solo PC con tres monitores.

## Configuración

`swat.exe` importa `DDRAW.dll` y llama a `DirectDrawCreate`. `Swat.cfg` empieza con `res=640 480` y
`adapter=primary`. GOG marca el ejecutable con `DWM8And16BitMitigation WINXPSP2 HIGHDPIAWARE
RUNASADMIN`. Estas flags no se modificaron.

## Reproducción sin la solución

Disposición de los monitores antes de abrir el juego:

| Monitor | Modo | Posición |
| --- | --- | --- |
| DISPLAY1 | 1920x1080 | -1920,0 |
| DISPLAY2 (principal) | 2560x1080 | 0,0 |
| DISPLAY3 | 1920x1080 | 2560,0 |

Lo que registró el monitor durante la sesión:

```text
WINDOWS: [Swat3Window] 'SWAT' 0,0 2560x1080 fg=True
MODES: DISPLAY1=1920x1080 pos=-1920,0 ; DISPLAY2*=640x480 pos=0,0 ; DISPLAY3=1920x1080 pos=640,0
WINDOWS: [Swat3Window] 'SWAT' 640,0 1920x1080 fg=True
t=3.1s cursor=320,240 clip=-1920,0..2560,1080
```

Tres hechos explican los síntomas:

1. **Resolución incorrecta.** El monitor principal baja a 640x480.
2. **Monitor incorrecto.** Windows mueve DISPLAY3 de x=2560 a x=640 para cerrar el hueco. La ventana
   del juego termina en 640,0 con 1920x1080, exactamente DISPLAY3. Una captura mostró el escritorio
   en el monitor principal y un área negra en DISPLAY3.
3. **Los clics cambian de pantalla.** El cursor se quedó en el monitor principal, en 320,240, y el
   rectángulo de confinamiento cubría todo el escritorio. El juego estaba en otro monitor, así que el
   cursor no estaba sobre él. Un clic ahí va a otra ventana y el juego pierde el foco. Este paso es
   una inferencia a partir del registro y del síntoma informado: no se rastreó ningún clic.

## Con dgVoodoo2

Misma apertura, con `DDraw.dll`, `D3DImm.dll` y `dgVoodoo.conf` junto a `swat.exe`:

```text
WINDOWS: [Swat3Window] 'SWAT' 0,0 2560x1080 fg=True
MODES: DISPLAY1=1920x1080 pos=-1920,0 ; DISPLAY2*=2560x1080 pos=0,0 ; DISPLAY3=1920x1080 pos=2560,0
t=21.6s cursor=639,479 clip=0,0..640,480
```

- Ningún monitor cambió de modo o posición durante la sesión.
- El cursor queda confinado al juego: 640x480 y 800x600 en los menús, centro de la pantalla en una
  misión.
- Los clics del ratón funcionaron en los menús y en una misión.

## Ajustes modificados

En `dgVoodoo.conf`, a partir de los valores por defecto de la versión 2.87.6:

| Ajuste | Valor | Motivo |
| --- | --- | --- |
| `FullscreenAttributes` | `fake` | Ventana a pantalla completa: es lo que evita el cambio de modo |
| `ScalingMode` | `stretched_ar` | Mantiene los menús 4:3 sin distorsión |
| `ExtraEnumeratedResolutions` | `max` | Ofrece la resolución del escritorio al juego |
| `SystemHookFlags` | `gdi,cursor` | Dibuja contenido GDI y evita el cursor doble |
| `VRAM` | `1024` | Más memoria de vídeo para resoluciones altas |
| `dgVoodooWatermark` | `false` | Elimina el logo de la pantalla |

En `Swat.cfg`: `res=<ancho> <alto>` y una línea `display_mode=<ancho> <alto> 2 1` equivalente. El
juego conservó ambos valores después de una salida limpia.

## Teclas

Las teclas en `Swat.cfg` tienen el formato `<código virtual de tecla de Windows>=<acción>`, por
ejemplo `87=up` para W. Los nombres de las acciones vienen de `swat.exe`, y su significado, de la hoja
de referencia en la carpeta `FAQs` del juego. `apply-modern-controls.ps1` mantiene una tecla por
acción, como por defecto.

## Límites de las pruebas

La flag `RUNASADMIN` de GOG hace que cada apertura muestre UAC. La entrada sintética de un script sin
elevación no llega a un juego elevado, así que las pruebas de menú y misión se jugaron a mano. Un
monitor sin elevación tampoco puede listar los módulos del juego.

El PC usa DisplayFusion, que gestiona ventanas entre monitores. Su papel no se aisló.

## Alternativas no probadas

`swat.exe` también contiene las opciones `-window`, `-fullscreen` y `-screensize`. No hicieron falta y
no se probaron. El mod de la comunidad
[Last Resort](https://www.moddb.com/addons/last-resort-v073) también ofrece resoluciones mayores y
tampoco se probó.
