PROMPT MESTRE PARA CODEX — LAST SIGNAL: EARTH_404

    Cole todo este documento no Codex dentro da pasta do projeto. Antes de executar, coloque os materiais já produzidos pela equipe em assets/originais/ e os documentos narrativos em docs/. O Codex deve usar os arquivos locais reais; ele não tem acesso automático aos anexos de uma conversa do ChatGPT.

    Status editorial: esta é uma especificação inicial executável, pois os materiais recebidos apresentam divergências de nomes, protagonista e perspectiva. Não substituir silenciosamente decisões ainda pendentes.

PAPEL E MISSÃO

Você é um desenvolvedor sênior de Godot Engine 4.x, GDScript 2.0, arquitetura de jogos 2D, design de níveis, acessibilidade e QA de Game Jam. Trabalhe DIRETAMENTE nos arquivos do workspace do VS Code, com código e cenas Godot reais. A meta é entregar um jogo offline, funcional, de aproximadamente 10 a 15 minutos, contendo começo, meio e fim. Não entregue apenas documentação, mockups ou conceitos. Não use Unity, Unreal, Phaser, HTML/CSS/JS, C#/.NET, plugins de terceiros, IA generativa em tempo real nem serviços externos.

Nome de trabalho: LAST SIGNAL: EARTH_404.
Tema: “O amanhã começa hoje” — sustentabilidade e futuro do planeta.
Contexto: Recife ficcional, ano 2187, após colapso ambiental; megacidade isolada Nova Éden e corporação NEXUS; GAIA é uma inteligência artificial ligada à restauração ambiental; três instalações controlam água, solo/sementes e ar; uma nave ARCA-01 pode abandonar a Terra.

Referência narrativa prioritária (PROVISÓRIA): LAST SIGNAL: EARTH_404 — História, cenários e cartas da Game Jam (bíblia narrativa de 06/11/2026). Ela detalha Kairo, Lyra, GAIA, Nara e Helena Voss. O GDD anterior usa o nome GAIA, protagonista Lívia e origem da IA como memória humana transferida. Registre as divergências em docs/DECISOES_PENDENTES.md; para permitir implementar sem bloquear, use Kairo como player_name provisório em dados, sem embutir o nome nos scripts. A animação recebida mostra um personagem de cabelo vermelho, mas não há confirmação de que seja Kairo ou Lívia: utilize o recurso como protagonista_provisorio e registre esta pendência, sem inventar identidade. Estruture diálogos e retratos para futuras trocas de identidade sem reescrever a lógica.

Perspectiva: a bíblia narrativa menciona top-down, mas os recursos de arte fornecidos (personagem de perfil e fachada frontal com chão) favorecem exploração 2D lateral. Adote visão lateral como escolha técnica PROVISÓRIA para aproveitar a arte, sem gravidade/plataformas excessivas: aventura narrativa, exploração horizontal e puzzles de interação. Não transformar em jogo de combate ou plataforma difícil. Deixe observação em docs/DECISOES_PENDENTES.md. Caso o projeto já existente tenha câmera consolidada aprovada pela equipe, preserve-a e documente por que se mantém.
PRIMEIRO PASSO: AUDITORIA OBRIGATÓRIA DO WORKSPACE

    Liste todos os arquivos atuais, identifique project.godot, cenas .tscn, scripts .gd, imagens, vídeos, áudio, fontes e licenças. Não sobrescreva trabalho existente sem analisá-lo.
    Leia docs/ (se existir), em particular o GDD e a bíblia narrativa; extraia mecânicas, personagens, missões e exigências das três cartas.
    Inspecione dimensões, transparência, direção do movimento, resolução e escala dos assets. Crie docs/INVENTARIO_ASSETS.md com: arquivo original, dimensão, função sugerida, restrições, status de processamento e cena de uso. Não declare que existe um sprite, retrato, som ou cenário que não existe.
    Preserve os originais em assets/originais/. Coloque derivados técnicos em assets/processados/; não edite destrutivamente a arte da equipe.
    Se houver ffmpeg/Python disponível, analise vídeos de animação e só extraia quadros quando houver qualidade suficiente. Um vídeo de exemplo enviado pela equipe tem aproximadamente 0,8 s, 368×368 px, 10 fps e fundo preto; pode render apenas poucos quadros. Não assuma 8 direções, corridas, pulos nem sprite sheet. Se a remoção do fundo preto degradar bordas/contornos, mantenha os originais e use placeholder temporário identificado; relate o problema.
    Um cenário recebido tem 635×583 px com edificações roxas, calçada cinza e céu escuro. Ao importar, recorte apenas margens/interface não pertencentes à arte, se existirem, sem cortar a cena. Use-o como elemento visual de fundo, não como uma geometria de colisão pronta.
    Faça um diagnóstico rápido dos comandos Godot disponíveis no ambiente: godot, godot4 ou Flatpak org.godotengine.Godot. Verifique versão realmente instalada. Se nenhum funcionar, implemente o projeto e explique como executar os testes localmente; nunca afirme que testou sem executar.
    Se já houver repositório Git, examine git status e a branch antes de modificar. Não apague arquivos nem faça alterações fora da pasta do jogo. Use commits pequenos quando apropriado e não dê push sem solicitação.

CARTAS OBRIGATÓRIAS — DEVEM SER MECÂNICAS TESTÁVEIS

Carta 2, Paz e Amor: todos os conflitos são resolvidos sem violência. Nenhum botão de ataque, armas, barra de vida, morte deliberada de personagens ou destruição de drones. Drones de vigilância podem ser desviados por bloqueio de sinal, distração ambiental, terminal de manutenção ou ajuda de NPCs. Captura pelo drone retorna ao checkpoint seguro, com feedback e sem punição excessiva.

Carta 3, Dois é Demais: duas perspectivas realmente diferentes:

    Kairo / mundo físico: move baterias, coleta itens, aciona alavancas e válvulas, conversa, passa por portas abertas.
    GAIA / camada de análise, memórias e circuitos: revela infraestrutura oculta e registros, diagnostica contaminação, permite interagir com terminais virtuais compatíveis. Não desloca objetos físicos nem atravessa portas como personagem separado.
    Alternar com Q. Mostrar sobreposição visual distinta, ícone/rótulo textual da visão ativa e objetos com propriedades diferentes em cada modo. O cenário físico mantém a mesma posição; a visão GAIA não é viagem temporal e não modifica o passado.
    Exigir participação das duas visões em pelo menos três puzzles, e não só alterar a cor da tela.

Carta 5, Abra-te Sésamo: abertura física/virtual de portas, comportas, cofres ou painéis. Em fases principais deve existir pelo menos um desbloqueio observável; o clímax abre um painel protegido no Complexo NEXUS. Preferir estados visuais claros: trancado → energizado → autorizado → aberto.

Regra: no tutorial da Nova Éden, duas cartas já aparecem (resolução pacífica e desbloqueio); após a ativação de GAIA, os níveis precisam combinar as três sempre que possível. Sem combate em momento algum.
ARQUITETURA GODOT — MODULAR E PEQUENA

Use recursos nativos da Godot 4.x e GDScript 2.0; renderer Compatibility se for adequado ao hardware. Exemplo de estrutura, ajustável ao que já existir:
project.godot
assets/
  originais/                    # não alterar destrutivamente
  processados/                  # sprites/quadros derivados
  audio/
docs/
  GDD.md
  HISTORIA.md
  INVENTARIO_ASSETS.md
  DECISOES_PENDENTES.md
  PROGRESSO.md
  TESTES.md
  COMO_EXECUTAR.md
scenes/
  menus/main_menu.tscn
  ui/dialogue_panel.tscn
  ui/hud.tscn
  ui/pause_menu.tscn
  characters/player.tscn
  characters/npc.tscn
  interactables/door.tscn
  interactables/terminal.tscn
  interactables/valve.tscn
  interactables/battery.tscn
  interactables/drone.tscn
  levels/nova_eden.tscn
  levels/ruinas_laboratorio.tscn
  levels/estacoes_ambientais.tscn
  levels/complexo_nexus.tscn
  endings/ending_a.tscn
  endings/ending_b.tscn
scripts/
  autoload/game_state.gd
  autoload/scene_router.gd
  player/player_controller.gd
  systems/interactable.gd
  systems/dialogue_manager.gd
  systems/perspective_manager.gd
  systems/puzzle_controller.gd
  systems/drone_patrol.gd
  systems/save_manager.gd
  ui/*.gd
 data/
  dialogue/
  puzzles/

Na prática, evite classes vazias e burocracia arquitetural: crie somente as cenas, scripts e dados necessários. Use CharacterBody2D, CollisionShape2D, AnimatedSprite2D/`Sprite2D`, Camera2D, Area2D, CanvasLayer, Control, AudioStreamPlayer, sinais e recursos Godot. Utilize TileMapLayer apenas se houver tiles adequados; se só houver pintura de fundo, construa colisores simples com StaticBody2D ou CollisionPolygon2D. Não inventar sistemas externos ou APIs.

Configuração sugerida: resolução lógica 640×360, janela inicial 1280×720, escalonamento apropriado para pixel art, preservação de proporção e textura por nearest quando adequado. Interface deve ser legível; se o material não for pixel art puro, ajuste importações por asset para não degradar a arte. Não fazer zoom excessivo ou distorções.
MECÂNICAS ESSENCIAIS

Movimentação lateral: A/D ou setas; velocidade ajustável; física simples e previsível; Space para pular somente se o level design exigir; E para interagir; Q alternar GAIA após desbloqueio; Tab consultar objetivo; Esc pausa; interfaces de diálogo acessíveis por teclado. Jogador deve ter idle, walk ou as animações efetivamente disponíveis. Se não houver frames suficientes, usar uma imagem estática com movimentação funcional e registrar a limitação. Espelhamento horizontal só se visualmente aceitável. Nunca reutilizar o vídeo completo como Sprite2D com fundo preto evidente.

Sistema de interação: base reusável, raio de proximidade, destaque do objeto e texto como [E] Examinar terminal. Interações impossíveis devem explicar motivo (por exemplo, “Falta energia”, “Somente GAIA identifica este circuito”).

Diálogos: caixa no rodapé, nome do falante, textos curtos em PT-BR, próxima fala, escolhas de 2–3 opções com consequência clara, possibilidade de usar teclado. Reaproveitar diálogos escritos na bíblia narrativa quando couber, sem criar dezenas de cutscenes longas. Falas em arquivos editáveis, não embutidas em scripts.

Puzzles: máquinas de estado simples; entradas e saídas observáveis. Introduzir mecanismo → pista na visão GAIA → ação física → desbloqueio → confirmação audiovisual/textual. Não depender de tentativa e erro sem feedback. Evitar softlocks (bateria presa, porta trancada sem item recuperável, drone bloqueando permanentemente).

Drones: patrulha lenta e previsível em rotas curtas, cone de visão opcional, feedback antes da detecção, desvio por sinal/terminal, retorno a checkpoint. Não implementar combate.

HUD: objetivo atual, ícone + texto do modo ativo, dica contextual, indicador discreto de estação restaurada/reservada e feedback de checkpoint. Não colocar barras de moralidade nem sistemas de XP.

Salvamento: salvar flags narrativas, estação atual, escolha de núcleos, posição segura ou checkpoint, desbloqueio de GAIA. Usar user:// com validação básica e valores padrão; não serializar referências a nodes. Novo jogo e continuar somente se save válido.

Configurações: controles explícitos no menu de ajuda, ajuste de volume de áudio, pausa e reinício. Legibilidade com contraste suficiente, símbolos além de cores, diálogos com legendas. Remapeamento de teclas é desejável, mas secundário à versão jogável.

Fome: o GDD inicial menciona comida e debuff, mas a bíblia narrativa não faz disso o foco. Não implementar na primeira versão; adicionar à lista de possibilidades futuras para não comprometer o escopo de Game Jam.
ESTRUTURA JOGÁVEL (10 A 15 MINUTOS)

NÃO FAZER sete mapas enormes. Construir quatro áreas compactas, com subáreas para os eventos da história. Navegação sempre clara, pequenos espaços significativos, transições estáveis e checkpoint no início de cada seção.
1. NOVA ÉDEN — INTRODUÇÃO (1–2 min)

    Contexto: Setor Inferior sob cúpula artificial; Lyra precisa de um filtro respiratório, e energia foi desviada pela NEXUS.
    Jogador fala com Lyra (por rádio ou retrato; se não houver arte, caixa textual), obtém bateria/módulo, conversa pacificamente com funcionária de manutenção e encontra passe/credencial.
    Puzzle: restaurar energia da porta de manutenção e ABRI-LA.
    Saída revela céu real avermelhado, em contraste com a cúpula.
    Tutorial: mover, interagir, opções de diálogo e objetivo.

2. RUÍNAS DO RECIFE + LABORATÓRIO GAIA (2–3 min)

    Referências locais: ponte/Capibaribe, ruínas do Recife Antigo, água escura, vegetação sobrevivente; usar o cenário roxo/cinza enviado quando se encaixar, sem redesenhá-lo à força.
    Nara teme a NEXUS e bloqueia passagem: resolver de forma pacífica reparando/distribuindo água. Encontrar pequena árvore e registro fotográfico de Recife.
    Drone de observação cria desafio de evitar ou redirecionar, sem atacar.
    Laboratório: usar bateria em núcleo; despertar GAIA; breve revelação do Projeto Êxodo.
    Tutorial Q: GAIA revela circuito oculto → Kairo reposiciona bateria → GAIA autoriza terminal → Kairo abre porta. É o primeiro puzzle explícito das duas perspectivas.

3. INSTALAÇÕES AMBIENTAIS — TRÊS MICROMISSÕES (aprox. 6 min)

    Estação Capibaribe / água: GAIA revela conexões de três tubos; jogador ajusta fisicamente registros/válvulas e bateria; abre comporta e decide RESTAURAR água comunitária ou RESERVAR núcleo para Êxodo. Drone pode ser redirecionado por terminal.
    Banco Verde / solo: GAIA identifica canais e cápsulas contaminadas; Kairo movimenta filtro e aciona duas válvulas; abre cofre de sementes; escolhe manter estufa ou reservar núcleo.
    Torre Atmos / ar: GAIA mostra sequência dos filtros; Kairo aciona dutos/módulo; negocia com técnica da NEXUS fornecendo ar à equipe; abre controle da torre e escolhe restaurar ar ou reservar núcleo.
    Cada micromissão DEVE exigir as duas perspectivas e um desbloqueio visível. Reutilizar infraestrutura de código (válvula/porta/terminal/bateria), com parâmetros de nível diferentes.
    Escolhas mudam ao menos um detalhe visual ou textual local: água menos escura, pequeno broto, redução parcial de névoa, comentários de Nara/Lyra. Jamais mostrar Terra integralmente recuperada em segundos.

4. COMPLEXO NEXUS / PORTO — CLÍMAX (2–3 min)

    Porto com sinais de ARCA-01; Helena Voss argumenta racionalmente a favor de evacuação, GAIA admite incerteza de restauração, Lyra pede para não decidir isoladamente.
    Nada de boss fight. Jogador evita vigilância, chega ao painel de roteamento, abre travas físicas com Kairo e revela circuitos/fluxos ocultos com GAIA.
    Painel final representa os três núcleos com texto/ícones (ÁGUA, SOLO, AR) e destinos escolhidos.
    Dois finais completos, com tela própria e epílogo narrativo:
        A — A primeira primavera: ao menos 2 dos 3 núcleos foram usados para restaurar; pequenas melhorias ambientais, comunidade segue trabalhando e Lyra ainda precisa de tratamento.
        B — O último adeus: ao menos 2 dos 3 núcleos foram reservados para Êxodo; Kairo e Lyra partem; os moradores ficam e o problema ambiental permanece.
    Final C — Uma chance compartilhada: apenas extensão opcional quando tudo estiver estável; não sacrificar A/B para fazê-lo.
    Tela de encerramento com reiniciar e voltar ao menu.

DADOS E ESTADOS

Centralize a progressão em GameState ou equivalente. Use valores serializáveis com nomes legíveis, por exemplo:
var player_name: String = "Kairo" # nome provisório, configurável
var gaia_unlocked := false
var nara_helped := false
var station_choices := {
    "water": "PENDING",  # RESTORE / EXODUS
    "soil": "PENDING",
    "air": "PENDING"
}
var current_level := "nova_eden"
var checkpoint_id := "start"

Adapte ao padrão do projeto, sem criar dependências circulares. O final pode ser inferido pela contagem RESTORE >= 2 ou EXODUS >= 2. Testar explicitamente todas as oito combinações das três escolhas, inclusive nenhum estado pendente no clímax. O nome ou aparência do protagonista nunca devem determinar regras de puzzles.
IDENTIDADE VISUAL E MATERIAL DA EQUIPE

    Preservar a arte recebida: fachadas destruídas com roxo/acinzentado/preto e personagem 2D de cabelo vermelho em perfil, caso seja o sprite provisório aprovado.
    Não substituir por ícones genéricos, gradientes extravagantes, neon excessivo, personagens gerados aleatoriamente ou uma estética desconectada.
    Foco em atmosfera: ruínas, sinais discretos de tecnologia, telas de energia, tubulações, silhuetas e pequenas zonas de vida.
    Se um asset não existir, produza um placeholder técnico mínimo com rótulo claro e registre-o. Não criar falsos assets “finalizados”. Não baixar artes de terceiros sem licença ou autorização.
    Usar parallax apenas se houver camadas separadas; não tentar separar magicamente uma pintura achatada em elementos reais.
    Não distorcer a proporção de sprites; colisões no pé/chão e em objetos interativos, não em fachadas de fundo.
    Camada GAIA: contornos e circuitos legíveis, cores frias, terminal destacado e texto descritivo. A camada normal preserva a paleta original.
    Áudio com AudioStreamPlayer quando disponível; se não houver arquivos de áudio, deixar os nós e referências opcionais sem quebrar o jogo.

ORDEM DE EXECUÇÃO — NÃO GASTAR A JAM EM UM ESQUELETO GIGANTE

Milestone 0 — Inspecionar: inventário, divergências, repositório e testabilidade Godot.

Milestone 1 — Vertical slice jogável: criar project.godot, cena inicial, menu, personagem movendo, interações, uma porta e diálogo; depois habilitar GAIA e resolver um puzzle de duas perspectivas no laboratório. Executar e corrigir antes de expandir. Esta fase deve ser suficiente para demonstrar a base do jogo.

Milestone 2 — Loop narrativo completo: completar as três instalações com recursos reusáveis, sistema de escolhas e todos os caminhos até os dois finais. Priorizar cenas compactas e funcionais sobre acabamento sofisticado.

Milestone 3 — Polimento e QA: importar melhor a arte, completar feedback audiovisual, pausas, checkpoints, legibilidade e testes de regressão; preparar exportação apenas após a build rodar.

Durante cada milestone, altere arquivos concretos e informe quais cenas podem ser abertas e testadas. Não fique apenas descrevendo futuros passos. Não interrompa a execução por pequenas dúvidas: tome decisões reversíveis e registre-as em docs/DECISOES_PENDENTES.md.
TESTES OBRIGATÓRIOS

    O projeto abre na Godot 4.x e possui main_scene definida. Não deve mostrar erros de parsing, cena inexistente, sinal desconectado ou textura com caminho quebrado.
    CharacterBody2D move, colide e interage; personagem nunca cai fora dos cenários nem fica preso.
    A visão GAIA é desbloqueada no laboratório e altera interações — não só o visual.
    Pelo menos três puzzles exigem Kairo e GAIA com tarefas diferentes.
    O jogo é concluível sem combate nem dano causado a inimigos/drones.
    Portas, válvulas e painéis mostram feedback de estado e permitem recuperação de falha.
    Diálogos não podem se sobrepor ao menu de pausa nem permitir movimentação acidental quando bloqueados.
    Retorno a checkpoint funciona após drone detectar protagonista, sem prender jogador.
    As oito combinações RESTORE/`EXODUS` levam corretamente ao final A ou B; transições completas funcionam.
    Novo jogo, Continuar quando válido, Pausar, Sair e Reiniciar funcionam.
    Recursos ausentes têm fallback explícito, e nenhuma cena trava devido a áudio, sprite ou retrato opcional.
    Registrar bugs reais e correções em docs/TESTES.md, com evidência de comandos executados. Não inventar execução ou sucesso.

Se existir binário godot ou godot4, comandos de verificação compatíveis com a CLI são, a partir da raiz do projeto:
godot --version
godot --headless --path . --import
godot --headless --path . --quit-after 60

Se a instalação for Flatpak, avalie equivalente via flatpak run org.godotengine.Godot --headless --path <caminho-absoluto-do-projeto> ... e possíveis permissões de acesso à partição do projeto. Não faça suposições: verifique a CLI real e os logs. Para exportar, confirme templates e configure presets adequados; não informe que existe build executável se não houver arquivo gerado.
ENTREGA NO WORKSPACE

No fim, deixe um projeto Godot que possa ser aberto e jogado, mais:

    README.md: conceito, controles, requisitos, setup e como executar.
    docs/INVENTARIO_ASSETS.md: o que foi usado e o que ainda falta.
    docs/DECISOES_PENDENTES.md: Lívia versus Kairo; GAIA versus LAST SIGNAL; natureza da IA; top-down versus lateral; identificação do personagem do vídeo; outros conflitos encontrados.
    docs/PROGRESSO.md: implementado, parcial e não implementado, por prioridade.
    docs/TESTES.md: testes realmente realizados e pendências.
    docs/COMO_EXECUTAR.md: passos específicos do ambiente detectado e caminhos de projeto.
    .gitignore adequado para Godot, ignorando artefatos temporários como .godot/ sem ignorar os arquivos fonte da equipe.

Ao terminar, apresente resumo curto com: (1) arquivos/cenas principais alterados, (2) como abrir e jogar, (3) comandos realmente testados e resultados, (4) funcionalidades pendentes, (5) perguntas editoriais a confirmar. Não envie ZIP. Trabalhe na pasta atual do VS Code.
INSTRUÇÃO FINAL

Comece agora pela auditoria do projeto e pela vertical slice funcional. Priorize uma experiência coesa e jogável sobre volume de funcionalidades. A história de Recife, o cuidado ambiental, a parceria física/digital e as três cartas da Game Jam devem aparecer nas ações do jogador. Use a documentação como base narrativa, preserve arte original, evite preenchimento inventado e produza código Godot GDScript utilizável.
