# LAST SIGNAL: EARTH_404 — apoio ao pitch de 5 minutos

## Como apresentar

Abra `outputs/pitch/LAST_SIGNAL_EARTH404_PITCH_59s.mp4` antes de começar. O vídeo tem legendas em português e áudio do jogo, sem narração artificial. Reserve o minuto entre 1:00 e 2:00 da apresentação para exibi-lo. Fale antes e depois, ou mantenha o som baixo se preferir comentar por cima.

| Tempo do pitch | O que comunicar |
|---|---|
| 0:00–0:30 | **Gancho:** “Se você pudesse abandonar um planeta em colapso, escolheria partir ou tentar recuperá-lo?” Apresente o título e a proposta: aventura cyberpunk 2.5D ambientada no Recife. |
| 0:30–1:00 | **Contexto:** Recife, 2187. A NEXUS controla recursos e Nova Éden. O protagonista foge da cidade e encontra GAIA, criada para ajudar a recuperar a Terra. |
| 1:00–2:00 | **Exiba o vídeo de 59 segundos.** Ele mostra a build real, não apenas concept arts: arsenal, combate, exploração, duas perspectivas, estações e a decisão final. |
| 2:00–3:15 | **Gameplay:** explique que o corpo manipula mecanismos e GAIA revela conexões. Use a água como exemplo: conectar uma rota limpa, ajustar válvulas e ligar a bomba. Sementes exigem condições de germinação; ar envolve filtros e exploração vertical. São desafios diferentes, não a mesma fechadura repetida. |
| 3:15–4:15 | **Diferenciais e execução:** identidade recifense, recursos ambientais com destinos registrados e uma decisão pessoal entre Terra e Marte. Sete regiões compactas; Godot 4, GDScript, geometria 2.5D, exportações Web e Linux. Mostre o que está funcionando, sem prometer uma versão mobile já homologada. |
| 4:15–5:00 | **Fechamento:** os dois caminhos têm conclusão cinematográfica. GAIA ajuda quem fica; partir exige superar a contenção. Retome a pergunta inicial e convide a banca a jogar. |

## Ordem do vídeo

| Vídeo | Conteúdo |
|---|---|
| 0:00–0:04 | Título e menu. |
| 0:04–0:15 | Nova Éden: movimento, relés do arsenal, bastão e confronto. |
| 0:15–0:21 | Exploração do Recife Antigo. |
| 0:21–0:29 | Laboratório e alternância corpo/GAIA. |
| 0:29–0:34 | Capibaribe: bomba e reservatório. |
| 0:34–0:39 | Banco Verde: irrigação e recuperação das plantas. |
| 0:39–0:44 | Torre Atmos: elevador e circulação de ar. |
| 0:44–0:50 | NEXUS: escolha entre Terra e Marte. |
| 0:50–0:56 | Breves imagens dos caminhos de encerramento, sem revelar o primeiro contato. |
| 0:56–0:59 | Título e chamada final. |

## Transparência

- Montagem de capturas reais da Godot, com sequência automatizada e estados preparados para mostrar momentos das fases. Não é uma partida humana contínua nem um teste de habilidade.
- A gravação não altera o save, preferências ou áudio persistente do jogador. Não há imagens de desktop, dados pessoais ou serviços externos na gravação.
- Protagonista e conceitos fornecidos foram preservados; o panorama novo de Nova Éden e os sprites dos soldados são complementos gerados com ImageGen. Não atribua esses complementos a um ilustrador da equipe.
- Os finais são cinematográficos. Marte não é anunciado como uma fase longa explorável.
- Playtest humano, equilíbrio fino e aparelhos móveis físicos ainda exigem validação. As cartas e regras da Jam devem ser conferidas pela equipe, principalmente a exceção de combate humano; não declare conformidade automática.

## Reprodução e geração

Captura: `tools/pitch_capture.tscn` e `tools/pitch_capture.gd`. A ferramenta é excluída das exportações normais e não altera o gameplay da build rc4.

```sh
mkdir -p outputs/pitch
flatpak run org.godotengine.Godot --path . --resolution 1280x720 --fixed-fps 30 --disable-vsync --write-movie outputs/pitch/captura_bruta.avi --quit-after 2250 res://tools/pitch_capture.tscn
bash outputs/pitch/renderizar.sh
```

O AVI bruto contém também pequenos intervalos de preparação entre cenas. O arquivo final corta esses intervalos, adiciona legendas e limita o resultado a 59 segundos. `planos.json` registra os frames usados; `renderizar.sh` e os filtros em `clipes/` mantêm a edição reproduzível. A renderização é sequencial e usa duas threads para evitar picos de memória. Para gerar novamente somente os arquivos de edição, use `flatpak run org.godotengine.Godot --headless --path . res://tools/pitch_capture.tscn -- --edit-only`.

Capturas e vídeos ficam ignorados pelo Git para não incluir binários grandes no histórico.
