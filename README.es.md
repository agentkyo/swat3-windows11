# SWAT 3 en Windows 11

[English](README.md) | [Português](README.pt-BR.md) | **Español**

Solución para **SWAT 3: Tactical Game of the Year Edition** (GOG) en Windows 11: monitor
incorrecto, resolución incorrecta y clics que te sacan del juego. Incluye un esquema moderno WASD.

Este repositorio **no contiene archivos del juego** ni dgVoodoo2. Necesitas tu propia copia del
juego.

Autor: [agentkyo](https://github.com/agentkyo)

## El problema

Con más de un monitor, el juego se abre en la pantalla incorrecta, en la resolución incorrecta, y
cualquier clic cambia de pantalla. No se puede usar el menú.

El juego le pide a Windows cambiar el monitor principal a 640x480. Windows entonces mueve los
otros monitores, y el juego termina en una pantalla distinta a la del ratón. El cursor también
queda libre para salir del juego. Los detalles están en
[`docs/technical-analysis.es.md`](docs/technical-analysis.es.md).

## La solución

[dgVoodoo2](https://github.com/dege-diosg/dgVoodoo2) reemplaza la capa DirectDraw del juego. El
juego pasa a renderizar en una ventana del tamaño del monitor principal, Windows no cambia el modo
de vídeo y el cursor se queda dentro del juego.

1. Cierra el juego.
2. Abre PowerShell 7 en esta carpeta y ejecuta:

   ```powershell
   pwsh -NoProfile -File .\tools\install-fix.ps1
   ```

3. Abre el juego normalmente desde GOG Galaxy.

El script encuentra el juego mediante la clave de GOG en el registro, descarga dgVoodoo2 2.87.6 de
la versión oficial, comprueba el SHA-256 y ajusta la resolución 3D a la de tu monitor principal.
Antes guarda una copia de `Swat.cfg`.

Opciones: `-GamePath`, para indicar otra carpeta; `-Width` y `-Height`, para elegir la resolución.
Si aparece "Access denied", ejecuta PowerShell como administrador.

Para deshacerlo todo:

```powershell
pwsh -NoProfile -File .\tools\uninstall-fix.ps1
```

## Qué esperar

- **Los menús quedan en 4:3**, centrados con bandas negras. Son fijos en 640x480 y 800x600.
- **Las misiones llenan la pantalla** en la resolución nativa, también en ultrawide.
- **UAC aparece al abrir.** GOG marca el juego para ejecutarse como administrador.

## Controles modernos (WASD)

```powershell
pwsh -NoProfile -File .\tools\apply-modern-controls.ps1
```

| Acción | Original | Moderno |
| --- | --- | --- |
| Moverse / strafe | Flechas | **W A S D** |
| Correr | Botón derecho | **Shift** |
| Mira telescópica | N | **Botón derecho** |
| Agacharse manteniendo | / | **Ctrl** |
| Alternar agacharse/levantarse | A | **C** |
| Inclinarse manteniendo, izquierda / derecha | Z / X | **Q / E** |
| Usar puerta u objeto | U | **F** |
| Linterna | F | **T** |
| Granada aturdidora | F3 | **G** |
| Lanzamiento medio / fuerte (mantén, con el botón izquierdo) | Shift / Ctrl | **Z / X** |
| Mostrar/ocultar diálogos de texto | D | **H** |
| Agacharse / levantarse | C / S | **,** / **.** |

El resto mantiene su tecla por defecto, como R para recargar, M para el menú de órdenes, botón
central para ordenar la rendición, F1/F2 para las armas y el teclado numérico para las
inclinaciones fijas.

Para volver a las teclas anteriores:

```powershell
pwsh -NoProfile -File .\tools\apply-modern-controls.ps1 -Restore
```

## Estado actual

Probado en un solo PC:

| Elemento | Resultado |
| --- | --- |
| Apertura con UAC, monitor correcto | OK |
| Los monitores mantienen posición y resolución | OK |
| Menú con el ratón | OK |
| Misión en 2560x1080 | OK |
| Esquema WASD en misión | OK |
| Sesiones largas, campaña completa | Aún sin probar |
| Vídeos de apertura | Aún sin probar |
| Multijugador | Aún sin probar |
| PC con un solo monitor | Aún sin probar |

Entorno: Windows 11 Pro build 26300, GeForce RTX 4070 Ti, tres monitores (1920x1080, 2560x1080
principal, 1920x1080) a 180 Hz, GOG build 2.1.0.34, dgVoodoo2 2.87.6.

## Contenido

- [`docs/technical-analysis.es.md`](docs/technical-analysis.es.md): diagnóstico y evidencias.
- [`tools/install-fix.ps1`](tools/install-fix.ps1): instala y configura la solución.
- [`tools/uninstall-fix.ps1`](tools/uninstall-fix.ps1): elimina la solución.
- [`tools/apply-modern-controls.ps1`](tools/apply-modern-controls.ps1): aplica o restaura el esquema
  WASD.
- [`tools/monitor.ps1`](tools/monitor.ps1): registra ventanas, modo de vídeo de cada monitor,
  límites del cursor y capturas de pantalla mientras se ejecuta el juego.

## Uso del monitor

```powershell
pwsh -NoProfile -File .\tools\monitor.ps1 -OutDir .\run1 -MaxSeconds 60
```

La salida contiene capturas de todos los monitores, así que revísala antes de compartirla.
Ejecútalo en un PowerShell elevado para registrar también los módulos cargados por el juego.

## Aviso

Proyecto de fan, sin relación con GOG, Sierra ni los titulares de los derechos del juego. dgVoodoo2
es obra de su autor y se descarga de su repositorio oficial.
