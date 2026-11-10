# Nova Éden — combate e redução de fechaduras

Relatório histórico da rc3. A revisão atual de cenário, arsenal e dificuldade está em `NOVA_EDEN_RC4.md`.

## Revisão 1.1.0-rc3 · 09/11/2026

Solicitação mais recente do responsável: combate físico e violência contra soldados humanos do exército de Nova Éden na saída da cidade, não drones nem uma sequência de chaves. Os modificadores passam a ter aplicação localizada. O projeto permanece Godot 4.7.2, exclusivamente GDScript.

## Combate inicial

- Três soldados humanos da NEXUS, com uniforme, capacete, cassetete, vida, colisão, aproximação, aviso de ataque, golpe, reação e queda.
- F golpeia; pode ser mantido pressionado. O ataque exige proximidade e direção correta, com intervalo de 0,5 segundo. Não é interação E em um terminal.
- O protagonista tem 6 pontos de vida; cada soldado suporta 3 golpes. Há dano dos dois lados, breve proteção após sofrer dano, impacto visual e som de pancada sintetizado em GDScript. Sem sangue ou gore.
- Amarelo avisa a área do ataque; vermelho marca o golpe. Recuar ou saltar permite esquivar. Golpear interrompe brevemente o soldado.
- Derrotar o esquadrão libera a saída com animação. Sem bateria, credencial, chave ou painel para abrir a porta.
- Vida esgotada apresenta a queda do protagonista e opções de retomar o combate, reiniciar a jornada ou voltar ao menu. Checkpoints preservam soldados já derrotados e restauram a vida na retomada.
- No toque, GOLPE substitui GAIA somente em Nova Éden. A perspectiva digital continua sendo ensinada no laboratório.
- A arena inicial fica no térreo; passarelas decorativas não escondem o protagonista ou os soldados. Escadas e elevadores continuam nas regiões posteriores.

A primeira briga permite **sair da cidade artificial para o Recife, ainda na Terra**. A NEXUS também controla as partidas do planeta; a decisão Terra/Marte acontece depois, no porto. GAIA continua apoiando a recuperação da Terra; o bloqueio antes de embarcar para Marte foi preservado.

## Apenas dois puzzles de abertura

1. Laboratório: tutorial de cooperação corpo/GAIA para abrir a passagem.
2. Caminho de Marte: superar a contenção de embarque antes de partir da Terra.

Removidos os objetos e comandos de fechadura extra de Nova Éden, Recife, Capibaribe, Banco Verde, Atmos e recepção NEXUS. Na água, ligar a bomba libera a passagem; na estufa, a irrigação disponibiliza as sementes; na torre, circulação correta libera o acesso. As mudanças têm efeito nos objetos e colisões, não apenas no texto. Os três desafios ambientais permanecem distintos.

No NEXUS, Voss libera o acesso após o diálogo. Não há mais sequência obrigatória de condutores, sala inferior, travas e autorização de porta. O diagnóstico GAIA é opcional.

## Salvamentos e preservação

Novo arquivo: `user://last_signal_restored_v6.json`. Arquivos v1–v5 continuam intactos. Validadores antigos foram preservados.

- v5 com saída inicial já conquistada preserva essa passagem, sem inventar uma briga anterior ou exibir soldados derrotados retroativamente.
- v5 ainda preso à coleta inicial descarta somente bateria/credencial/soquete obsoletos dessa fase e retorna a uma posição segura para o novo confronto.
- Demais regiões, decisões e finais são preservados. Estações antigas sincronizam passagens automáticas a partir dos sistemas ambientais já concluídos.
- Progresso do esquadrão é validado na ordem 0, 1, 3, 7. Um save novo não pode abrir a saída sem a vitória.

Backup anterior à alteração: `work/pre_combat_revision_20261109/`. A candidata rc2 completa permanece em `work/restoration_20261109_narrative_v5/`. Snapshot rc3: `work/combat_20261109_validated/`. O personagem e as artes originais não foram substituídos.

## Código principal

- `scripts/game/nova_combat.gd`: soldados, dano, alcance, recarga, impacto e queda.
- `scripts/game/nova_eden.gd`: ligação do combate à fase, HUD, checkpoint e saída.
- `scripts/ui/mobile_controls.gd`: botão GOLPE no toque.
- `scripts/core/journey.gd` e `restored_v5_validator.gd`: salvamento v6 e compatibilidade.
- `scripts/puzzles/` e `data/regions/`: passagens automáticas e remoção de fechaduras repetidas.

## Testes nativos

| Suíte | Verificações | Falhas |
|---|---:|---:|
| nova_combat_test | 86 | 0 |
| journey_test | 124 | 0 |
| flow_test | 200 | 0 |
| stations_test | 160 | 0 |
| station_interaction_test | 38 | 0 |
| demo_physics_test | 30 | 0 |
| demo_touch_test | 46 | 0 |
| restoration_gameplay_test | 67 | 0 |
| timeline_test | 54 | 0 |
| menu_test | 29 | 0 |
| scene_lifecycle_test | 12 | 0 |
| **Total** | **846** | **0** |

A suíte nova utiliza entrada F e toque, verifica dano no soldado e no protagonista, alcance, direção, recarga, interrupção, esquiva, derrota, checkpoint, vitória, migração v5 e a ausência de fechaduras extras. O fluxo completo percorre os dois finais. Também houve execução gráfica com 200 verificações e capturas reais em `outputs/qa/restoration/`.

Na Web, o fluxo exportado concluiu **200 verificações, zero falhas e console sem erros/avisos** (`outputs/qa/logs/web_rc3_combat.json`). Na build normal foram observados entrada na nova fase, acionamento de F, aproximação/ataques do soldado, perda de vida, derrota e retomada. Não equivale a um playtest humano integral. Houve lentidão/timeout do painel de navegador durante o carregamento; ao recuperar a mesma aba, o jogo carregou e não registrou erro no console.

Linux exportado iniciou em smoke test sem erro. O ZIP passou na verificação de integridade e contém `index.html` na raiz, com **46.327.067 bytes**.

- SHA-256 Web ZIP: `431eb8a5fb0d3f1e44dade9a3bf3c2a63c9b15cff01e86bc2e95dd317c341f6e`.
- SHA-256 Linux: `242243621c2a4f9e42cc98933a4cb0cbaae60e8d489d572ce419103def8ede1c`.

Resultados completos e hashes também ficam em `outputs/VALIDACAO_RESTAURACAO.log` e `outputs/BUILD_RESTAURACAO.sha256`.

## Entrega e limites

- Web: `outputs/web/index.html`.
- ZIP itch.io: `outputs/itch_io/LAST_SIGNAL_EARTH404_WEB.zip`, com `index.html` na raiz.
- Linux: `outputs/linux/LAST_SIGNAL_EARTH404.x86_64`.
- Branch `main`, HEAD `998387d`, sem commit, push ou publicação automática.
- Soldados são modelos procedurais estilizados; o golpe do protagonista utiliza pose/lunge procedural sobre o sprite preservado, não um novo ciclo de sprite desenhado pela equipe.
- Balanceamento humano, acabamento artístico e aparelhos móveis físicos continuam pendentes. Automação não substitui playtest humano.
- A exceção de combate foi implementada por solicitação expressa. Não se afirma mais que o jogo inteiro é pacífico; a equipe deve confirmar o enquadramento final das cartas com a organização da Jam.
