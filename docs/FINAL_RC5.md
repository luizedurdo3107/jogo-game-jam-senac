# Final de partida, ARCA-01 e Terra — 1.1.0-rc5

Revisão de 10/11/2026, Godot 4.7.2 e GDScript. Inclui a jornada restaurada e as alterações rc1–rc4 que ainda estavam locais. O responsável solicitou commit e envio à `main` após a validação. Artes e personagem originais preservados; backup anterior em `work/pre_departure_rc5/`.

## O que existia e o que foi acrescentado

O final mostrado no vídeo anterior tinha **contenção ambiental**, com três travas e pulsos no chão. Não havia uma batalha contra personagens nessa etapa. A luta humana então existente era apenas a fuga inicial de Nova Éden.

Agora, escolher **partir da Terra rumo a Marte**, no NEXUS, abre a doca bloqueada pela guarnição de Nova Éden:

1. Dois soldados e um comandante humano impedem o embarque. São atores com colisão, aproximação, poses de preparação/ataque, vida, dano, bloqueio, atordoamento e queda.
2. O jogador usa o bastão, com F ou GOLPE no touch. Recuar e saltar evitam ataques; o fôlego limita spam. Se o save antigo não tiver arma, há equipamento na doca, sem outro puzzle de arsenal.
3. No Difícil, Kairo tem 4 de vida, os adversários têm 4/5/8 e há pressão de dupla e combo de dois golpes. No Padrão, são 6 de vida e adversários com 3/3/6, um ativo por vez. A dificuldade pode ser trocada na pausa, sem curar o jogador ferido.
4. Vencida a guarnição, os controles de toque voltam de GOLPE para análise local. O protagonista desliga a contenção com Q/E e confirma o embarque depois da passagem física.
5. Não é possível acionar os painéis nem embarcar antes da vitória. Vida zerada abre retomada; soldados já vencidos e travas já desligadas permanecem no checkpoint.

**GAIA não é a adversária humana e não ajuda a fuga.** Sua prioridade continua sendo recuperar a Terra; ela mantém a suspensão do embarque, sem atacar pessoas. A violência da batalha é contra o exército. Ficar na Terra continua levando diretamente ao final de recuperação, sem esse combate. Diálogo de confirmação, introdução da doca, ajuda e epílogo foram atualizados para explicar essa distinção.

## Nave e planeta

- A ARCA-01 agora é um modelo procedural compartilhado pelo porto, pela doca e pelo epílogo, com fuselagem afilada, cockpit, asas, aletas, janelas, painéis e identificação.
- Dois propulsores com quatro camadas visuais de plasma animado, além do trem de pouso recolhido durante o voo. A câmera do próprio jogo acompanha a decolagem, sem depender do script de captura.
- A Terra não usa mais pequenas esferas como continentes. Há superfície de 1024 × 512 com oceanos, massas continentais estilizadas, desertos e calotas; nuvens transparentes em esfera separada; rotação lenta e halo atmosférico que acompanha a escala do planeta.
- Céu escuro, iluminação lateral e enquadramento mantêm nave e globo visíveis. A tomada da Terra dura seis segundos. Pular a cinemática não deixa o protagonista aparecendo no espaço.
- Tudo é geometria, materiais padrão e geração de imagens por GDScript, sem shader personalizado, imagem de satélite, modelo baixado ou serviço externo. Proveniência em `assets/processados/arca_rc5/PROVENIENCIA.md`.

## Saves e compatibilidade

Extensão aditiva da versão 6, sem sobrescrever arquivos v1–v5:

- `departure_started`: a nova decisão de Marte exige combate militar.
- `departure_security`: máscara de inimigos vencidos, incluindo vitórias fora de ordem.
- `departure_legacy_clear`: compatibilidade com uma doca antiga já totalmente liberada.

Uma nova rota não chega ao epílogo apenas desligando os circuitos: `complete_boss()` também exige a vitória militar. Finais antigos permanecem concluídos, sem inventar combate retroativo. Saves rc4 com todas as travas desligadas mantêm essa passagem; progressos técnicos parciais são preservados, mas enfrentam a guarnição. Um checkpoint antigo avançado sem vitória militar volta à área segura antes da arena.

## Validação e limites

Suítes em `tests/`: combate inicial, jornada/migração, fluxo das sete regiões e dois finais, estações, interação, física, toque, restauração, linha do tempo, menu, ciclo de vida e `departure_test`.

O novo teste cobre bloqueio do embarque, coleta de arma, vida e derrota, pausa, dificuldade, touch GOLPE, vitória e persistência em arquivo, retorno à análise local, contenção, abertura física, final de Marte, nave, nuvens, afastamento da Terra, salto de cinemáticas, rota pacífica e compatibilidade com doca já liberada. Logs da revisão em `outputs/qa/rc5/`, fora do Git.

Resultados finais: **12 suítes, 1.067 verificações e zero falhas**. A execução gráfica do fluxo completo concluiu 266 verificações; a nova suíte gráfica de partida concluiu 112. A exportação WebGL da suíte de partida também concluiu **112 verificações, zero falhas**, sem erros no console. Exportações de produção Web e Linux concluídas; executável Linux iniciou em smoke test. Os seis arquivos do baseline anterior de saves/preferências mantiveram seus hashes. Metadados e hashes locais: `outputs/qa/rc5/VALIDACAO_RC5.json` e `outputs/qa/rc5/BUILD_RC5.sha256`.

Os testes de progressão usam posicionamento e invulnerabilidade de fixture para isolar etapas. **Não são playtest humano nem prova de equilíbrio.** Separadamente, a tomada aprovada para o vídeo vence os três adversários no Difícil por comandos de movimento e F, sem alterar vida, dano ou invulnerabilidade; Kairo termina com 2/4 de vida. O registro distingue captura automatizada de uma gravação manual contínua de tela.

O balanço humano, celulares físicos, projetor e upload no Canva continuam pendentes. A arte é estilizada, não uma reprodução fotorrealista das referências. Não houve publicação automática em itch.io ou outra hospedagem de jogo.

## Vídeo atualizado

`outputs/pitch/LAST_SIGNAL_RC5_COMBATE_E_FUGA_60S.mp4`: 60 segundos, 1080p, 30 FPS, H.264/AAC. Preserva o contexto das fases e agora mostra a batalha final, a nova nave e a Terra redesenhada.

- 00:00–00:08: combate inicial.
- 00:08–00:33: saída da cidade e conclusões de Recife, laboratório, Capibaribe, Banco Verde e Atmos.
- 00:33–00:37: decisão real atualizada no NEXUS.
- 00:37–00:45: soldados e comandante na doca, com golpes e vitória.
- 00:45–00:47: contenção desligada após a batalha.
- 00:47–00:54: embarque e decolagem.
- 00:54–01:00: Terra ficando distante.

As primeiras fases reutilizam os originais aprovados. NEXUS, guarnição completa e epílogo são uma nova captura nativa da rc5. É uma montagem com checkpoints, sem aceleração, interfaces falsas ou concept art apresentada como gameplay. Áudio original; sem TTS. Os cortes anteriores ficam preservados.

Reprodução da edição, com as capturas anteriores já disponíveis:

```sh
bash tools/record_departure.sh
```

As ferramentas de captura antigas continuam como alternativas históricas; a rc5 usa `record_departure.sh`. Binários, vídeos, capturas e backups locais são ignorados pelo Git. O envio ao GitHub contém código, dados, artes do jogo, testes, documentação e ferramentas, não os vídeos de apresentação ou binários gerados.
