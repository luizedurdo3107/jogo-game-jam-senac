# Nova Éden — cidade, arsenal e dificuldade

## Revisão 1.1.0-rc4 · 09/11/2026

Alteração direta no projeto Godot 4.7.2, exclusivamente GDScript. A solicitação mais recente pede cidade futurista, soldados com aparência de personagens, combate mais difícil e um puzzle para obter uma arma. As sete regiões, finais e exceção de combate humano da rc3 permanecem.

## Visual jogável

- Nova Éden agora tem panorama próprio de megacidade sob um domo, avenida escura com juntas e balizamento néon, fachadas baixas, sinalização, purificadores de oxigênio e veículos aéreos em movimento.
- Arsenal, console, porta deslizante, bastão, postes, luzes, fachadas e rua são geometria 3D. Solo, soldados e portão têm colisões reais. O panorama é uma camada de cenário, não a fase inteira disfarçada de imagem.
- Câmera mais próxima, instruções menores e HUD de dificuldade, vida e fôlego.
- Soldados usam atlas transparente ilustrado: guarda, deslocamento, preparação e ataque. O capitão tem roupa, rosto, cores, arma e resistência distintos. Caem ao ser derrotados e deixam de bloquear a rota.
- Protagonista original e seus 12 quadros de caminhada preservados. O ataque usa movimento procedural do sprite e bastão 3D, não um novo ciclo desenhado do protagonista.
- As duas artes suplementares foram geradas com ImageGen integrado. Prompts completos, arquivos e distinção das artes originais estão em `assets/processados/nova_eden_rc4/PROVENIENCIA.md`. As quatro poses não são apresentadas como animação fluida completa.

## Arsenal

1. Encontre o armário iluminado na avenida e interaja com E.
2. A etiqueta sugere a ordem dos relés: respirar, defesa e carga. Os botões aparecem fora de ordem; uma tentativa incorreta reinicia a sequência e permite tentar novamente.
3. Ao concluir, a porta abre em animação. É preciso pressionar E de novo para recolher o bastão.
4. O bastão sai da vitrine e aparece na mão. F passa a atingir as armaduras.

Socos não causam dano aos soldados. O arsenal fica antes da zona de patrulha e não exige GAIA, que só aparece no laboratório. Não há munição finita nem recurso que possa causar softlock.

O pedido acrescenta uma abertura às duas anteriores: agora há **três** na campanha (arsenal, tutorial do laboratório e contenção de embarque). A limitação antiga de duas não é mais declarada atendida. Nenhuma fechadura extra foi adicionada a Recife, estações ou NEXUS.

## Combate

| Regra | Padrão | Difícil, inicial |
|---|---|---|
| Vida máxima do protagonista | 6 | 4 |
| Resistência dos soldados / capitão | 3 / 3 / 4 | 4 / 4 / 6 |
| Pressão | um ativo por vez | dois simultâneos na arena |
| Aproximação | 2,65 unidades/s | 3,5 unidades/s |
| Aviso principal | 0,68 s | 0,44 s |
| Capitão | bloqueio frontal na preparação | bloqueio e dois golpes por combo |
| Recuperação de fôlego | 2,6/s | 1,9/s |

F custa 2 dos 6 pontos de fôlego. Regeneração começa após 0,8 s sem golpe válido; tentar sem fôlego não causa dano. Golpes não reiniciam o ataque inimigo e o atordoamento dura apenas 0,12 s, impedindo travar um soldado indefinidamente. Ataques exigem alcance, direção e altura corretos. Amarelo avisa, vermelho golpeia; salto ou recuo permitem esquiva. O capitão fica vulnerável após a preparação e o combo.

Troque a dificuldade na pausa. Alterar durante a luta não cura o jogador nem recupera todo o esquadrão. Antes do primeiro confronto e sem dano, a vida acompanha a escolha do modo. A retomada após derrota repõe a vida, mas preserva inimigos já derrotados e o bastão.

## Persistência e preservação

- Extensão aditiva do save v6: `nova_armory`, `nova_weapon`, `nova_difficulty`. Arma sem arsenal aberto é um estado inválido.
- Máscara de derrotados permite vencer os soldados fora de ordem. O portão só abre ao derrotar os três.
- Save rc3 com vitória parcial recebe arma e arsenal aberto; ninguém precisa repetir soldados já derrotados. Save antigo sem vitória e com posição avançada retorna à área segura. Saída previamente conquistada continua liberada.
- Backups anteriores preservados; cópia imediatamente anterior em `work/pre_nova_city_rc4/`. Não houve reset, limpeza destrutiva, commit nem push. Branch `main`, base `998387d`.

## Validação

Resultados finais de execução, exportação e hashes ficam em `outputs/VALIDACAO_RESTAURACAO.log` e `outputs/BUILD_RESTAURACAO.sha256`. Evidências visuais ficam em `outputs/qa/restoration/`.

Onze suítes nativas: **882 verificações, zero falhas**. Combate/arsenal: 77; jornada: 124; fluxo: 230; estações: 160; interação: 38; física: 30; toque: 46; restauração: 82; linha do tempo: 54; menu: 29; ciclo de vida: 12. O fluxo gráfico também concluiu 230 verificações sem falhas e gerou capturas reais.

Fluxo Web exportado: **230 verificações, zero falhas**, console sem erros/avisos (`outputs/qa/logs/web_rc4_city.json`). Exportações Web e Linux concluídas; executável Linux iniciou em smoke test. ZIP validado, `index.html` na raiz, 49.879.159 bytes.

- SHA-256 ZIP Web: `abc82ba9f1540205f441ee7e4f5b57a54440346dc94a7e6244ebb36b7857b1bc`.
- SHA-256 Linux: `35bd15b03d9162dfc234139d2d1a065a1be05c531d2dd96191c21d1f7704235d`.
- Build normal: `outputs/web/index.html`; Linux: `outputs/linux/LAST_SIGNAL_EARTH404.x86_64`; pacote: `outputs/itch_io/LAST_SIGNAL_EARTH404_WEB.zip`.

Na build normal Web também foram operados menu, continuação, pausa, seletor de toque, movimento pelo controle virtual, os três relés por cliques e coleta do bastão com E. A porta abriu visivelmente e o HUD passou de sem arma para bastão. Console limpo. Os controles foram restaurados para automático; a partida de teste ficou com o arsenal resolvido, sem derrotar soldados. Para experimentar o puzzle desde o início, use Nova jornada. A operação por agente não equivale a playtest humano ou validação em aparelho móvel físico.

`nova_combat_test` cobre relé errado/correto, botão real da interface, retomada parcial, abertura animada, coleta separada, F e toque, alcance/direção, fôlego, regeneração, dano, esquiva, pressão de dupla, troca de dificuldade, bloqueio, combo, derrota, persistência, máscara fora de ordem e compatibilidade. Uma simulação mantém F pressionado sem esquivar: ela deve perder no Difícil, não liberar a saída.

O fluxo completo valida as sete regiões e os dois finais. A rotina de vitória da suíte usa posicionamento e invulnerabilidade de fixture para isolar progressão: **não prova balanceamento humano nem habilidade de um jogador**. A simulação de spam, testes isolados de dano e observação gráfica complementam essa rotina. Nenhum teste automatizado é descrito como playtest humano.

## Limites

Revisão humana de arte, equilíbrio fino, controles em aparelhos móveis físicos e elegibilidade da violência para as cartas da Jam permanecem pendentes. A build Web é local; não há publicação externa automática. O combate é estilizado, sem sangue ou gore.
