# SWAT 3 no Windows 11

[English](README.md) | **Português** | [Español](README.es.md)

Correção para **SWAT 3: Tactical Game of the Year Edition** (GOG) no Windows 11: monitor errado,
resolução errada e cliques que tiram você do jogo. Inclui um layout moderno em WASD.

Este repositório **não contém arquivos do jogo** nem o dgVoodoo2. Você precisa da sua própria
cópia do jogo.

Autor: [agentkyo](https://github.com/agentkyo)

## O problema

Com mais de um monitor, o jogo abre na tela errada, na resolução errada, e qualquer clique troca
de tela. Não dá para usar o menu.

O jogo pede ao Windows para mudar o monitor principal para 640x480. O Windows então move os
outros monitores, e o jogo acaba em uma tela diferente da do mouse. O cursor também fica livre
para sair do jogo. Os detalhes estão em
[`docs/technical-analysis.pt-BR.md`](docs/technical-analysis.pt-BR.md).

## A correção

O [dgVoodoo2](https://github.com/dege-diosg/dgVoodoo2) substitui a camada DirectDraw do jogo. O
jogo passa a renderizar em uma janela do tamanho do monitor principal, o Windows não troca o modo
de vídeo e o cursor fica dentro do jogo.

1. Feche o jogo.
2. Abra o PowerShell 7 nesta pasta e rode:

   ```powershell
   pwsh -NoProfile -File .\tools\install-fix.ps1
   ```

3. Abra o jogo normalmente pelo GOG Galaxy.

O script encontra o jogo pela chave da GOG no registro, baixa o dgVoodoo2 2.87.6 da versão oficial,
confere o SHA-256 e ajusta a resolução 3D para a do seu monitor principal. Antes disso, ele guarda
uma cópia do `Swat.cfg`.

Opções: `-GamePath`, para indicar outra pasta; `-Width` e `-Height`, para escolher a resolução. Se
aparecer "Access denied", rode o PowerShell como administrador.

Para desfazer tudo:

```powershell
pwsh -NoProfile -File .\tools\uninstall-fix.ps1
```

## O que esperar

- **Os menus ficam em 4:3**, centralizados com faixas pretas. Eles são fixos em 640x480 e 800x600.
- **As missões preenchem a tela** na resolução nativa, inclusive em ultrawide.
- **O UAC aparece ao abrir.** A GOG marca o jogo para rodar como administrador.

## Controles modernos (WASD)

```powershell
pwsh -NoProfile -File .\tools\apply-modern-controls.ps1
```

| Ação | Original | Moderno |
| --- | --- | --- |
| Andar / strafe | Setas | **W A S D** |
| Correr | Botão direito | **Shift** |
| Mira telescópica | N | **Botão direito** |
| Agachar segurando | / | **Ctrl** |
| Alternar agachar/levantar | A | **C** |
| Inclinar segurando, esquerda / direita | Z / X | **Q / E** |
| Usar porta ou objeto | U | **F** |
| Lanterna | F | **T** |
| Granada de luz | F3 | **G** |
| Arremesso médio / forte (segure, com o botão esquerdo) | Shift / Ctrl | **Z / X** |
| Mostrar/ocultar diálogos em texto | D | **H** |
| Agachar / levantar | C / S | **,** / **.** |

O restante continua na tecla padrão, como R para recarregar, M para o menu de comandos, botão do
meio para ordenar rendição, F1/F2 para as armas e o teclado numérico para as inclinações fixas.

Para voltar às teclas anteriores:

```powershell
pwsh -NoProfile -File .\tools\apply-modern-controls.ps1 -Restore
```

## Estado atual

Testado em um único PC:

| Item | Resultado |
| --- | --- |
| Abertura com UAC, monitor correto | OK |
| Monitores mantêm posição e resolução | OK |
| Menu com o mouse | OK |
| Missão em 2560x1080 | OK |
| Layout WASD em missão | OK |
| Sessões longas, campanha completa | Ainda não testado |
| Vídeos de abertura | Ainda não testado |
| Multiplayer | Ainda não testado |
| PCs com um só monitor | Ainda não testado |

Ambiente: Windows 11 Pro build 26300, GeForce RTX 4070 Ti, três monitores (1920x1080, 2560x1080
principal, 1920x1080) a 180 Hz, GOG build 2.1.0.34, dgVoodoo2 2.87.6.

## Conteúdo

- [`docs/technical-analysis.pt-BR.md`](docs/technical-analysis.pt-BR.md): diagnóstico e evidências.
- [`tools/install-fix.ps1`](tools/install-fix.ps1): instala e configura a correção.
- [`tools/uninstall-fix.ps1`](tools/uninstall-fix.ps1): remove a correção.
- [`tools/apply-modern-controls.ps1`](tools/apply-modern-controls.ps1): aplica ou restaura o layout
  WASD.
- [`tools/monitor.ps1`](tools/monitor.ps1): registra janelas, modo de vídeo de cada monitor, limites
  do cursor e capturas de tela durante a execução do jogo.

## Uso do monitor

```powershell
pwsh -NoProfile -File .\tools\monitor.ps1 -OutDir .\run1 -MaxSeconds 60
```

A saída contém capturas de todos os monitores, então revise antes de compartilhar. Rode em um
PowerShell elevado para registrar também os módulos carregados pelo jogo.

## Aviso

Projeto de fã, sem vínculo com a GOG, a Sierra ou os detentores dos direitos do jogo. O dgVoodoo2 é
obra do seu autor e é baixado do repositório oficial.
