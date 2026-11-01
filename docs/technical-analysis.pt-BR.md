# Análise técnica da instalação GOG

[English](technical-analysis.md) | **Português** | [Español](technical-analysis.es.md)

Observações feitas na build GOG 2.1.0.34, em um único PC com três monitores.

## Configuração

O `swat.exe` importa `DDRAW.dll` e chama `DirectDrawCreate`. O `Swat.cfg` começa com `res=640 480`
e `adapter=primary`. A GOG marca o executável com `DWM8And16BitMitigation WINXPSP2 HIGHDPIAWARE
RUNASADMIN`. Essas flags não foram alteradas.

## Reprodução sem a correção

Layout dos monitores antes de abrir o jogo:

| Monitor | Modo | Posição |
| --- | --- | --- |
| DISPLAY1 | 1920x1080 | -1920,0 |
| DISPLAY2 (principal) | 2560x1080 | 0,0 |
| DISPLAY3 | 1920x1080 | 2560,0 |

O que o monitor registrou durante a sessão:

```text
WINDOWS: [Swat3Window] 'SWAT' 0,0 2560x1080 fg=True
MODES: DISPLAY1=1920x1080 pos=-1920,0 ; DISPLAY2*=640x480 pos=0,0 ; DISPLAY3=1920x1080 pos=640,0
WINDOWS: [Swat3Window] 'SWAT' 640,0 1920x1080 fg=True
t=3.1s cursor=320,240 clip=-1920,0..2560,1080
```

Três fatos explicam os sintomas:

1. **Resolução errada.** O monitor principal cai para 640x480.
2. **Monitor errado.** O Windows move o DISPLAY3 de x=2560 para x=640 para fechar o espaço. A janela
   do jogo termina em 640,0 com 1920x1080, exatamente o DISPLAY3. Uma captura mostrou o desktop no
   monitor principal e uma área preta no DISPLAY3.
3. **Cliques trocam a tela.** O cursor ficou no monitor principal, em 320,240, e o retângulo de
   confinamento cobria todo o desktop. O jogo estava em outro monitor, então o cursor não estava
   sobre ele. Um clique ali vai para outra janela e o jogo perde o foco. Esta etapa é uma inferência
   a partir do log e do sintoma relatado: nenhum clique foi rastreado.

## Com o dgVoodoo2

Mesma abertura, com `DDraw.dll`, `D3DImm.dll` e `dgVoodoo.conf` ao lado do `swat.exe`:

```text
WINDOWS: [Swat3Window] 'SWAT' 0,0 2560x1080 fg=True
MODES: DISPLAY1=1920x1080 pos=-1920,0 ; DISPLAY2*=2560x1080 pos=0,0 ; DISPLAY3=1920x1080 pos=2560,0
t=21.6s cursor=639,479 clip=0,0..640,480
```

- Nenhum monitor mudou de modo ou posição durante a sessão.
- O cursor fica confinado ao jogo: 640x480 e 800x600 nos menus, centro da tela em uma missão.
- Os cliques do mouse funcionaram nos menus e em uma missão.

## Configurações alteradas

No `dgVoodoo.conf`, a partir dos padrões da versão 2.87.6:

| Configuração | Valor | Motivo |
| --- | --- | --- |
| `FullscreenAttributes` | `fake` | Janela em tela cheia: é o que evita a troca de modo |
| `ScalingMode` | `stretched_ar` | Mantém os menus 4:3 sem distorção |
| `ExtraEnumeratedResolutions` | `max` | Oferece a resolução do desktop ao jogo |
| `SystemHookFlags` | `gdi,cursor` | Desenha conteúdo GDI e evita cursor duplo |
| `VRAM` | `1024` | Mais memória de vídeo para resoluções altas |
| `dgVoodooWatermark` | `false` | Remove o logo da tela |

No `Swat.cfg`: `res=<largura> <altura>` e uma linha `display_mode=<largura> <altura> 2 1`
correspondente. O jogo manteve os dois valores depois de uma saída limpa.

## Atalhos

Os atalhos no `Swat.cfg` têm o formato `<código virtual de tecla do Windows>=<ação>`, por exemplo
`87=up` para W. Os nomes das ações vêm do `swat.exe`, e o significado, da folha de referência na
pasta `FAQs` do jogo. O `apply-modern-controls.ps1` mantém uma tecla por ação, como no padrão.

## Limites dos testes

A flag `RUNASADMIN` da GOG faz toda abertura mostrar o UAC. Input sintético de um script sem elevação
não chega a um jogo elevado, então os testes de menu e missão foram jogados à mão. Um monitor sem
elevação também não consegue listar os módulos do jogo.

O PC usa o DisplayFusion, que gerencia janelas entre monitores. O papel dele não foi isolado.

## Alternativas não testadas

O `swat.exe` também contém as opções `-window`, `-fullscreen` e `-screensize`. Elas não foram
necessárias e não foram testadas. O mod da comunidade
[Last Resort](https://www.moddb.com/addons/last-resort-v073) também oferece resoluções maiores e
também não foi testado.
