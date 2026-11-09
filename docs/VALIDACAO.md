# Validação da consolidação 2.5D/mobile

Ambiente: Godot 4.7.2 Flathub, Compatibility, Intel Iris Xe/Mesa. Web: Chromium do navegador integrado, WebGL 2, viewport 844×390. Não é um celular físico.

## Regressões

```sh
for suite in journey_test flow_test stations_test station_interaction_test demo_physics_test demo_touch_test; do
  godot --headless --path . --fixed-fps 60 "res://tests/$suite.tscn" || exit 1
done
```

Os nomes `demo_physics_test` e `demo_touch_test` são nomes históricos dos testes, não modos de jogo. Ambos instanciam o mesmo Recife usado pela jornada atual.

| Suíte | Verificações | Escopo |
|---|---:|---|
| journey_test | 924 | percurso real do Recife e NEXUS, oito combinações, dois finais 3D, validação/migração/round-trip de saves, catálogo sonoro |
| flow_test | 51 | mudanças reais entre todas as regiões, final e menu |
| stations_test | 163 | resolução por movimento/escadas/elevador dos três puzzles ambientais |
| station_interaction_test | 38 | botões de configuração, modais, materiais GAIA e recuperação de erros |
| demo_physics_test | 30 | colisões, salto, elevador, pausa, drone pacífico e áudio local |
| demo_touch_test | 46 | eventos sintéticos, dois dedos simultâneos, arraste, foco, rotação e disposição dos botões |

Resultado: **1.252 verificações, zero falhas**. Arquivos de execução consolidados em `outputs/VALIDACAO_MOBILE.log`.

## Capturas reais

```sh
godot --path . --fixed-fps 60 res://tests/mobile_capture.tscn
```

Grava menu, Recife, NEXUS físico/digital e epílogo em `outputs/`. O utilitário prepara estados de teste sem alterar o save do jogador. O resultado não constitui teste de hardware mobile.

## Exportação

Único preset de distribuição: `Web Mobile`. O arquivo `project.godot` aponta somente para o menu unificado, sem overrides para versões antigas. Os seis cenários de jogo são Node3D; interfaces são Control/CanvasLayer.

Exportação Web release concluída. No navegador integrado, o menu iniciou a jornada, os controles virtuais foram ativados pela pausa, o retorno em paisagem e o bloqueio em retrato foram conferidos. O build final foi aberto novamente em 844×390; console sem erros/avisos em `outputs/MOBILE_WEB_CONSOLE.json`. Isso não substitui a execução completa em celulares físicos.

Também foi reconstruída uma cópia limpa dos arquivos preparados para o commit, sem `.godot/`, backups ou exports anteriores: importação e as 51 verificações de fluxo passaram novamente.

Os testes não escrevem no save normal. Os testes de persistência usam caminho aleatório e removem apenas o arquivo temporário que criaram. Preferências de toque não são gravadas pelos testes sintéticos. A migração da campanha 2D não é suportada; somente o antigo save 2.5D das estações é importado.

## Checklist em celulares físicos (pendente)

1. Hospedar a pasta Web completa em HTTPS e abrir no Chrome Android e Safari iOS.
2. Iniciar, mover + saltar com dois dedos, subir/descer e alternar GAIA.
3. Interagir, rolar diálogos e resolver os puzzles sem teclado.
4. Girar para retrato e retornar à paisagem: nenhuma ação deve ficar presa.
5. Minimizar/reabrir, pausar, ajustar seis volumes e recarregar.
6. Confirmar Continue, checkpoints, três decisões e ambos os finais.
7. Avaliar recortes/notch, texto, áudio após gesto e estabilidade durante toda a jornada.
8. Medir FPS/consumo no aparelho; a meta de 30 FPS ainda não está certificada.

Limites conhecidos: música e dublagem humana não fornecidas; identidade visual low-poly; oito quadros do personagem reaproveitados para movimento, sem novas animações dedicadas; Nova Éden/laboratório sem cenas 3D independentes. A versão Web é um jogo para navegador, não um APK.
