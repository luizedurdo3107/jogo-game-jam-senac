# LAST SIGNAL: EARTH_404 — Jornada restaurada 2.5D

Godot **4.7.2**, exclusivamente GDScript. Recife, 2187: sete regiões compactas, combates contra o exército na cidade e antes da partida para Marte, três desafios ambientais e dois finais. Edição **1.1.0-rc5**, candidata à apresentação, ainda dependente de playtest humano.

## Jogar

Abra `project.godot` na Godot 4.7.2 e pressione F5. A cena inicial é `scenes/ui/main_menu.tscn`.

```sh
flatpak run org.godotengine.Godot --path .
```

A/D ou setas: andar; Espaço: saltar/esquivar; F: golpear nos dois combates (pode segurar); W/S: escadas; E: interagir; Q: corpo/GAIA; Tab: pistas; Esc: pausa. A introdução pode ser pulada. Toque é opcional e configurável na pausa; durante as batalhas, GOLPE substitui GAIA e a análise retorna depois da vitória. Há violência estilizada contra soldados humanos, com dano e queda, sem sangue ou gore.

O menu usa a arte aprovada do Recife em tela cheia, iluminação ciano/magenta, animação ambiente discreta e navegação por teclado/toque. Continuar reconhece o progresso salvo; iniciar outra jornada pede confirmação. Áudio e créditos permanecem acessíveis.

## Progressão real

1. **Nova Éden:** avenida futurista 2.5D com skyline, néon e tráfego; soldados humanos ilustrados, com quatro poses e capitão distinto. Abra o arsenal seguindo a etiqueta dos relés, pegue o bastão com E e enfrente a patrulha com F. Fôlego limita ataques; recue ou salte para esquivar. Difícil é o padrão: 4 de vida, pressão de dupla, inimigos mais resistentes e combo do capitão. Padrão na pausa: 6 de vida e um inimigo ativo. Arma, dificuldade, relés e derrotados persistem; vencer abre a saída.
2. **Recife Antigo:** Nara, bomba comunitária, memória local, passarela, túnel, inspeção desviável e acesso ao laboratório.
3. **Laboratório GAIA:** origem e prioridade de preservação da IA; circuitos superiores, transporte físico de célula, autorização digital e comporta.
4. **Capibaribe:** escolher água tratada, drenar uma câmara, transportar módulo, ajustar válvulas e acionar bomba/comporta.
5. **Banco Verde:** filtro, seleção de sementes saudáveis, clima e irrigação da estufa.
6. **Torre Atmos:** cooperação com a técnica, elevador de quatro níveis e estágios de ventilação em ordem.
7. **NEXUS / Porto:** diálogo com Voss e decisão definitiva; não há outra sequência de condutores, travas ou autorização de porta.

As três alocações de recursos continuam registradas. **A maioria não escolhe mais o final pelo jogador.** Ficar na Terra inicia a recuperação com apoio de GAIA, sem confronto. Tentar sair da Terra rumo a Marte leva à doca bloqueada pelo **exército de Nova Éden**: enfrente dois soldados e o comandante usando o bastão. No Difícil, os inimigos têm 4/5/8 pontos de vida, pressão de dupla e combo do comandante; Kairo tem 4 de vida. Padrão oferece 6 de vida e inimigos com 3/3/6, selecionável na pausa. Inimigos vencidos persistem no checkpoint. Se um save antigo não tiver arma, há um bastão na doca, sem outro puzzle.

Depois da vitória militar, desligue a contenção de embarque pelos três comandos locais e confirme a partida. Não é possível embarcar apenas pulando os inimigos ou operando os painéis antes da luta. GAIA não é alvo nem controla os soldados: continua ajudando a recuperar a Terra, não a abandoná-la. Só depois vêm embarque, decolagem, travessia, chegada a Marte e primeiro contato amistoso com os Auri fictícios.

**ARCA-01 e espaço:** a nave agora compartilha o mesmo modelo no porto, na doca e no epílogo: fuselagem afilada, cockpit, asas, janelas, motores animados e trem de pouso recolhido durante o voo. A câmera acompanha a decolagem. A Terra tem oceanos, continentes estilizados, calotas, nuvens em rotação independente e halo atmosférico. São geometria e texturas procedurais em GDScript, não fotografias ou serviços externos. Artes originais preservadas.

**Passado, presente e futuro:** arquivos históricos têm identificação própria e são apenas consultados; a ação jogável acontece no Recife de 2187; os finais mostram consequências posteriores. Q muda a perspectiva do mesmo momento, não permite viagem no tempo. O guia está disponível na pausa. Diálogos ao vivo de Voss e GAIA não são tratados como memórias.

O pedido mais recente acrescenta **um puzzle de arsenal** à primeira fase. Agora são três desafios explícitos de abertura na campanha: arsenal, tutorial do laboratório e contenção antes de Marte. Não foram acrescentadas outras fechaduras. Recife e estações liberam as passagens automaticamente ao cumprir o objetivo ambiental.

Por solicitação expressa do responsável, a fuga inicial agora tem violência contra pessoas. Cooperação e resolução pacífica permanecem nas demais áreas; não se afirma mais ausência de combate no jogo inteiro. A elegibilidade dessa exceção para a carta Paz e Amor deve ser confirmada pela equipe com a organização da Jam.

## Origem e preservação

Base restaurada: commit `c35d329`, anterior à redução `998387d`. Essa base tinha **cinco regiões 3D**, não sete. Nova Éden e a parte narrativa do laboratório foram adaptadas dos backups legados, principalmente `work/pre_station_redesign/`, sem recriar o projeto.

Backup integral anterior à restauração: `work/restoration_20261109_before/`, incluindo alterações não commitadas e `history.bundle`. A candidata rc1 fica em `work/restoration_20261109_validated/`; a revisão narrativa rc2, em `work/restoration_20261109_narrative_v5/`. Diretórios `work/` são locais, ignorados e não entram nas exportações.

O personagem original e os vídeos são preservados. A caminhada usa 12 quadros extraídos do vídeo de 09/11 em `assets/processados/movimento_20261109/`; o idle anterior permanece intacto. Saltos e escadas utilizam poses: não há fonte para ciclos dedicados. O áudio do vídeo não é redistribuído no jogo.

## Salvamentos

Novo arquivo: `user://last_signal_restored_v6.json`, com validação de estados, limites, dependências, escolhas e checkpoints, gravado por substituição atômica. Os arquivos v1–v5 não são sobrescritos.

- v1/v2 preservam os três núcleos e progresso técnico; um final antigo retorna ao NEXUS para uma nova decisão explícita.
- v3 preserva água e progresso do antigo tutorial, agora no laboratório; Banco Verde e Atmos continuam pendentes.
- v4 preserva regiões, recursos e decisões. O antigo confronto da Terra dá lugar ao final de restauração; um final de Marte já concluído continua concluído, sem inventar um confronto retroativo. Novas partidas exigem superar a contenção antes de embarcar para Marte.
- v5 preserva regiões, decisões e uma saída de Nova Éden já conquistada, sem inventar uma briga retroativa. Se a saída ainda estava bloqueada, a coleta inicial obsoleta é descartada e o jogador começa o novo combate em posição segura. Soldados derrotados na v6 permanecem derrotados ao continuar.
- Arquivos corrompidos são recusados. Saves 2D não são importados.
- A rc4 estende o save v6 com arma, relés e dificuldade, sem trocar o arquivo. Partidas rc3 que já derrotaram algum soldado recebem o bastão para não perder progresso. Partidas sem vitória e com checkpoint avançado voltam à área segura do arsenal. Uma saída já conquistada não é bloqueada novamente.
- A rc5 acrescenta `departure_started`, `departure_security` e `departure_legacy_clear` à v6. Novas escolhas de Marte exigem a vitória militar. Finais anteriores e uma doca rc4 com todas as travas já desligadas não ganham combate retroativo; progresso técnico parcial permanece e passa a exigir a guarnição. Checkpoints antigos dentro da arena voltam à área segura se a nova luta ainda não começou.
- Cenas do editor não contêm o progresso do jogador. Uma Godot já aberta pode mostrar buffers antigos: recarregue arquivos externos antes de salvar.

## Exportação

```sh
mkdir -p outputs/web outputs/linux
flatpak run org.godotengine.Godot --headless --path . --export-release Web outputs/web/index.html
flatpak run org.godotengine.Godot --headless --path . --export-release Linux outputs/linux/LAST_SIGNAL_EARTH404.x86_64
python3 -m http.server 8086 --bind 0.0.0.0 --directory outputs
```

Web: `http://localhost:8086/web/index.html`. Compatibility/WebGL 2, thread única, sem backend ou serviços externos de jogabilidade. Não abra o HTML pelo gerenciador de arquivos.

Linux: `outputs/linux/LAST_SIGNAL_EARTH404.x86_64`. Binários, vídeos e capturas são entregas locais e ficam fora do Git. Pacotes ZIP de revisões anteriores não são atualizados nesta revisão; o código é trabalhado e enviado diretamente pelo repositório. Publicação em hospedagem externa não é automática.

## Testes e limites

Regressões em `tests/`: persistência/migração, cenas reais e dois finais, percurso físico nas três estações, interfaces, escadas/elevadores, toque sintético, caminhada, fuga/captura, confronto e distinção entre arquivos históricos e diálogos atuais (`timeline_test`). Exemplo:

```sh
flatpak run org.godotengine.Godot --headless --path . --fixed-fps 60 res://tests/flow_test.tscn
```

Revisão atual: `docs/FINAL_RC5.md`, incluindo o novo `departure_test`. Históricos: `docs/NOVA_EDEN_RC4.md`, `docs/COMBATE_NOVA_EDEN.md` e `docs/RESTAURACAO_E_QA.md`. Testes automatizados e operação por agente **não substituem playtest humano**. Não há certificação de Android/iOS físicos, nem garantia universal de desempenho. O panorama e atlas de Nova Éden são suplementares gerados por IA; as artes originais e o protagonista foram preservados. As quatro poses do soldado não constituem um ciclo de animação completo. Música final e dublagem humana não foram fornecidas. Sons procedurais originais, sem TTS, com volumes independentes.

## Organização e direitos

`scenes/regions/`: sete regiões, confronto e epílogo. `scenes/story/`: introdução. `scripts/`: gameplay, ambientes, puzzles, UI e áudio. `data/`: narrativa/configurações JSON. `assets/`: originais e recursos processados. `tools/`: importadores e shell Web. `outputs/`: entregas e evidências locais.

Godot e componentes: `LICENSES/` e `THIRD_PARTY_NOTICES.txt`. Artes e personagem foram fornecidos pelo responsável; a equipe deve confirmar os direitos para publicação. A licença da engine não licencia automaticamente o jogo. O envio desta revisão ao GitHub foi solicitado expressamente pelo responsável após a validação.
