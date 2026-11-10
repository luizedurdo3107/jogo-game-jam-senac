# Restauração e QA — 09/11/2026

> Relatório histórico da rc2. A revisão atual, com combate contra soldados e menos fechaduras, está em `COMBATE_NOVA_EDEN.md`. Os hashes e as contagens deste relatório descrevem a candidata anterior preservada em backup.

## Situação da entrega

**1.1.0-rc2 — candidata jogável restaurada**, Godot 4.7.2, GDScript e Compatibility. Revisão solicitada pelo responsável: confronto ao tentar sair da Terra rumo a Marte, GAIA dedicada à recuperação da Terra e cronologia explícita. Não é uma certificação de arte final, de balanceamento humano ou de aparelhos móveis.

Branch: **main**. HEAD preservado: **998387d**. Nenhum commit, push ou publicação no itch.io foi feito nesta restauração. A aprovação do responsável continua necessária.

## Origem e segurança

Antes das alterações foram examinados `git status`, `git log --oneline --all --decorate -30`, `git reflog -30`, `git branch -a` e os backups locais.

- **c35d329**: última base 2.5D anterior à redução; contém Recife, Capibaribe, Banco Verde, Atmos e NEXUS, além do epílogo.
- **998387d**: redução para duas fases, preservada integralmente antes da recuperação.
- **work/pre_station_redesign/** e **work/pre_mobile_unification/**: narrativa e lógica legadas de Nova Éden e do laboratório.
- Não foram encontradas sete regiões 3D independentes no commit anterior. Nova Éden e laboratório foram adaptados para 3D reutilizando os scripts, puzzles, arte e infraestrutura existentes. Não são uma recuperação fictícia de cenas que não existiam.
- Backup anterior: `work/restoration_20261109_before/`, com projeto, artes, exportações, alterações não commitadas, `uncommitted.patch` e `history.bundle`.
- Backup da candidata restaurada rc1: `work/restoration_20261109_validated/`, mantido sem sobrescrita.
- Backup anterior à revisão narrativa: `work/pre_narrative_revision_20261109/`. Candidata rc2: `work/restoration_20261109_narrative_v5/`.
- As alterações pré-existentes em `project.godot` e `default_bus_layout.tres` foram preservadas no backup; não foram descartadas por checkout/reset.
- Nenhum reset destrutivo, limpeza forçada, exclusão de branch ou force push foi utilizado.

## Regiões e funcionalidades

| Área | Implementação jogável |
|---|---|
| Nova Éden | Lyra, bateria carregada visivelmente, credencial da técnica, porta animada, patrulha, rota superior e perseguição; captura animada com reinício ou nova tentativa |
| Recife Antigo | Nara, bomba comunitária, Marco Zero, fachadas históricas, passarela, túnel, memória local e drone desviável |
| Laboratório GAIA | Descoberta da IA, prioridade de preservação da vida, circuito superior, célula subterrânea, soquete físico, autorização digital e comporta |
| Capibaribe | Rede hídrica, drenagem, módulo físico, válvulas, pressão, bomba, reservatório e comporta |
| Banco Verde | Filtro, cápsulas saudáveis, temperatura, umidade, irrigação, estufa e cofre |
| Torre Atmos | Técnica, compartilhamento de ar, elevador de quatro níveis, escadas, manutenção de drone e sequência pré-filtro/carvão/turbina |
| NEXUS / Porto | Condutores, sala inferior, travas, autorização e painel protegido; decisão final independente da maioria dos recursos |

Todas têm geometria, colisões, objetos e transições reais. O protagonista continua sendo o sprite original sobre o plano lateral 3D.

A introdução usa seis ilustrações aprovadas, movimentos suaves, transições, legendas curtas, som ambiente e opção de pular; duração total de **42 segundos**.

As perspectivas mantêm regras diferentes: o corpo transporta, conversa e manipula mecanismos; GAIA revela redes, diagnósticos e memórias e autoriza circuitos. Há substituição de materiais, hologramas e escaneamento, não apenas um filtro de tela.

As cartas **Paz e Amor**, **Dois é Demais** e **Abra-te Sésamo** aparecem em resolução pacífica, cooperação físico-digital e desbloqueios visíveis.

## Finais

- **Terra:** ficar leva diretamente à sequência de recuperação de 24 segundos. GAIA apoia a comunidade, coerente com a missão apresentada no laboratório. Os recursos que permaneceram afetam a recuperação; não há confronto nesse caminho.
- **Marte:** antes de sair da Terra, GAIA bloqueia o embarque para proteger sua missão de recuperação. O jogador usa leitura e comandos locais do implante, não cooperação de GAIA para escapar: analisa a primeira trava, desliga-a fisicamente, desvia energia pela interface local e desativa a barreira. Pulsos têm aviso e podem ser evitados. Sem armas, eliminação ou destruição de GAIA. Só depois começa a sequência estilizada 3D de 36,5 segundos: embarque, decolagem, Terra distante, viagem, pouso, Auri fictícios e jardim compartilhado. GAIA fica na Terra ajudando a comunidade. Não existe confronto para sair de Marte.
- Os três destinos ambientais permanecem registrados. Escolher um final não reescreve os núcleos já distribuídos.

## Cronologia

- **Passado:** registros históricos de Capibaribe (2034), mangue (2061), Atmos (2112), Recife e equipe GAIA. Títulos e hologramas identificam arquivo consultivo, não viagem no tempo; fechar o registro remove a projeção e explicita o retorno ao presente.
- **Presente:** Recife, 2187. HUD, despertar de GAIA e conversas atuais usam essa identificação. Corrigido o tratamento incorreto de Voss e do diagnóstico NEXUS como memórias históricas.
- **Futuro:** possibilidades na escolha final, não profecias; as cinematográficas marcam dias, semanas ou meses depois. A chegada a Marte não parece instantânea.
- Q continua alternando corpo/análise do mesmo momento. O guia “Passado, presente e futuro” está disponível na pausa. Não foi adicionada uma mecânica de viagem temporal.

## Movimentação recebida

Vídeo preservado em `assets/originais/movimento_20261109/`. A caminhada usa os primeiros 12 quadros extraídos a 12 fps, com remoção do fundo claro conectado à borda, preservação dos detalhes claros internos, recorte comum e alinhamento dos pés.

Atlas, SpriteFrames e manifesto: `assets/processados/movimento_20261109/`. Importador: `tools/import_walk_motion.gd`. O áudio do vídeo não é usado.

O idle de oito quadros e o vídeo anterior continuam intactos. Saltos e escadas usam poses congeladas; não foi inventado um ciclo independente que o vídeo não contém.

SHA-256 do atlas anterior: `2821565f4fa6810c1cfdb32166fd175b72a3af5a02e34d8e55accba2b1c1f94b`.

SHA-256 do vídeo anterior: `a1e0cc3a18acfb111e8c0288ad3100c29076b31c6ac3a5fed39999ff75df8b59`.

SHA-256 do vídeo novo: `c54926498e45008038759d7b353b999d8ae02592828cc1f72cb7fabe4886b149`.

## Interface e áudio

Menu redesenhado: arte aprovada do Recife em tela cheia sem alteração do arquivo original, máscara de contraste em degradê, título com hierarquia própria, acentos ciano/magenta, movimento ambiente sutil, foco visível e composição adaptativa. Continuar usa o save real; nova jornada pede confirmação cancelável sem apagar o menu. Áudio e créditos funcionam. Sem dependência de fontes baixadas ou serviço externo. Backup do menu anterior: `work/pre_menu_redesign_20261109/`.

Objetivo curto no topo, interação separada na parte inferior, fontes maiores, escolhas mais curtas, contraste e modais com rolagem. Corrigida a largura dos botões em linhas da pausa, que podiam aparecer sem texto na Web. O HUD não disputa espaço com diálogos. Dicas de entrada permanecem disponíveis depois de fechar o diálogo; pistas das estações são graduais. Menu observado no navegador em 1280×720 e 844×390, sem erros no console da build normal.

Controles de toque são opcionais. O bloqueio por orientação aplica-se quando os controles de toque estão ativos, não a toda janela desktop estreita.

Foram preservados os 79 recursos sonoros procedurais originais, ambientes distintos, passos ligados à animação, mecanismos, elevadores, drones e alternância GAIA. Laboratório e Nova Éden utilizam seus perfis próprios. Há volumes independentes; não há TTS ou música de terceiros acrescentada.

## Persistência

Formato novo: `user://last_signal_restored_v5.json`. Validação de limites, dependências, escolhas, checkpoints e ordem dos circuitos finais; escrita por arquivo temporário e substituição atômica. Transições e decisão definitiva recusam avanço se a gravação falhar. Saves novos não podem saltar a contenção no caminho para Marte; a Terra não exige circuitos de fuga.

Na ausência de v5, são examinados v4, v3, v2 e v1, nessa ordem. Os arquivos anteriores não são sobrescritos. V4 preserva escolhas e progresso: o antigo confronto da Terra vira o final de restauração; um final de Marte já concluído continua concluído, com legenda de compatibilidade, sem inventar confronto retroativo. V3 preserva água e o tutorial antigo, agora localizado no laboratório, sem inventar decisões para solo/ar. V1/v2 preservam estações e três escolhas; um epílogo antigo volta ao porto para uma decisão explícita. Saves 2D não são importados.

Na conferência final há uma instância do editor Godot aberta desde antes da revisão. Ela não foi usada para salvar cenas, nem encerrada pelo agente. Importações, execução, capturas e exportações usam processos novos lendo o disco. **Não é possível certificar buffers não salvos dessa instância: recarregue arquivos externos ou reabra o projeto antes de salvar pelo editor.**

## Testes executados

Ambiente nativo: Godot 4.7.2 Flathub, Compatibility, Intel Iris Xe/Mesa. Todos os seguintes testes terminaram com zero falhas:

| Suíte | Verificações |
|---|---:|
| journey_test | 128 |
| flow_test | 192 |
| stations_test | 163 |
| station_interaction_test | 38 |
| demo_physics_test | 30 |
| demo_touch_test | 46 |
| restoration_gameplay_test | 62 |
| timeline_test | 57 |
| menu_test | 29 |
| scene_lifecycle_test | 12 |
| **Total nativo** | **757** |

`stations_test` percorre as três estações por movimento/escadas reais; `restoration_gameplay_test` percorre a fuga e o laboratório fisicamente, verifica o atlas, captura, pulsos do confronto na doca e portão de embarque animado. `flow_test` valida as cenas, todas as transições, interações, escolhas, dois finais, continuação e retorno ao menu, acionando métodos e botões pela automação. `timeline_test` distingue registros antigos de conversas atuais e verifica compatibilidade do final antigo. `menu_test` verifica quatro tamanhos lógicos, foco, continuação, reinício, cancelamento, áudio e créditos. Não confundir esse fluxo com um playtest manual completo.

Também foram executados o fluxo com renderização gráfica e capturas na Godot (192 verificações), o mesmo fluxo em janela 844×390 (192), o menu gráfico (29), importação do projeto, smoke test do executável Linux exportado, `git diff --check` e verificação de integridade do ZIP. Essas repetições não entram novamente no total nativo da tabela. A captura gráfica foi ajustada para não esperar um sinal de renderização que pode deixar de ocorrer com a janela oculta.

**Web:** servidor HTTP local, Chromium integrado, Compatibility/WebGL 2. Depois da correção de transição, **três execuções consecutivas terminaram com 192 verificações e zero falhas cada**, cobrindo sete regiões, três puzzles, perspectivas, dois finais, confronto apenas na saída para Marte, reinício e continuação. As três ficaram sem erros/avisos no console; registros em `outputs/qa/logs/web_round1.json`, `web_round2.json`, `web_round3.json` e `web_console_final.json`.

Na build normal foram conferidos menu redesenhado, confirmação e cancelamento de reinício, continuação depois de reabrir a página e guia cronológico com rolagem. A continuação recuperou o progresso de Nova Éden. Introdução e salto por teclado também foram observados durante a restauração. Foram observadas janelas desktop e estreitas; não são aparelhos móveis físicos.

Uma execução inicial com várias abas concorrentes apresentou aviso de sincronização IndexedDB e travamentos. Na revisão rc2, uma execução isolada também falhou na saída de Nova Éden com leitura de objeto nulo. A transição agora para as animações antes de liberar seus alvos, desativa o processamento da cena de saída e desconecta os sinais do mundo removido. Checkpoints e retorno ao menu usam o mesmo caminho adiado. A regressão de ciclo de vida verifica essa limpeza. Uma rede digital com menos de dois pontos também foi corrigida. Logs da falha foram preservados, sem esconder a ocorrência. Isso não garante persistência em todos os modos privados, origens ou configurações de navegador.

Capturas do navegador são JPEG com extensão correta. `outputs/.gdignore` impede que a Godot importe entregas e evidências como recursos de gameplay.

Logs nativos: `outputs/qa/logs/`. Capturas reais: `outputs/qa/restoration/`. **Automação e operação por agente não substituem playtest humano.**

## Exportações e Git

- Web normal: `outputs/web/index.html`, preset **Web**, thread única.
- ZIP itch.io: `outputs/itch_io/LAST_SIGNAL_EARTH404_WEB.zip`, **46.313.225 bytes**, com `index.html` na raiz, arquivos da engine e avisos legais; sem testes, backups, vídeos originais ou fontes do editor.
- SHA-256 do ZIP: `f8956cf59f9085726fccbb912896adda954cd3ebf8826ee6b874be7d029ba70e`.
- Linux x86_64: `outputs/linux/LAST_SIGNAL_EARTH404.x86_64`, PCK embutido, acompanhado dos avisos legais.
- SHA-256 Linux: `ae0aa958a8650ff6c656126e9c23c44965467f28b9be64ce61d5508f8cc9c8fb`.
- Lista completa de arquivos criados/modificados: `outputs/ARQUIVOS_RESTAURACAO.txt`.
- Núcleo das mudanças: `scripts/core/`, `scripts/game/`, `scripts/environments/`, `scripts/puzzles/`, `scripts/ui/`, `scripts/story/`, `scenes/regions/`, `scenes/story/`, `data/`, novo movimento em `assets/`, testes, importador, presets, README e este relatório.
- Os executáveis, ZIP e evidências de QA são locais e ignorados pelo Git. Nenhum deles foi enviado automaticamente a um serviço.

## Pendências antes de chamar de versão final

1. Playtest humano integral, avaliação do ritmo, dificuldade da fuga/confronto e legibilidade nas telas de apresentação.
2. Refinamento artístico: Nova Éden, laboratório e Marte ainda utilizam construção low-poly procedural; não têm a fidelidade pictórica das referências aprovadas. NPCs secundários continuam simplificados. As imagens não foram transformadas em cenários fotorrealistas.
3. Ciclos dedicados de salto/escada, música final e eventual dublagem humana dependem de materiais da equipe.
4. Android/iOS físicos, navegadores adicionais, sessão privada e validação na página real do itch.io ainda não foram certificados.
5. Confirmar os direitos das artes e os créditos finais da equipe antes da publicação pública.
6. Aprovar a candidata e só então autorizar o commit na main. A publicação no itch.io é uma etapa separada, ainda não realizada.
