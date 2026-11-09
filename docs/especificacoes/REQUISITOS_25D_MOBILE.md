# CODEX — LAST SIGNAL: EARTH_404
## Migração para 2.5D, redesign de Recife e demonstração jogável para celulares

Você é um Lead Game Developer, Technical Artist, Level Designer e especialista sênior em Godot 4, GDScript, otimização mobile e publicação de jogos HTML5.

Sua missão é evoluir **LAST SIGNAL: EARTH_404** para uma experiência cyberpunk 2.5D, com cenários tridimensionais, personagem original, exploração não linear e uma demonstração acessível por QR Code durante a apresentação da Game Jam.

**Projeto original:**

`/home/luizeduardo/Documents/Codex/2026-11-08/chat-x20`

O jogo já contém movimentação, personagem animado com oito quadros, puzzles, diálogos, alternância entre protagonista e GAIA, drones pacíficos, decisões ambientais, salvamento e dois finais.

Preserve essas funcionalidades.

## 1. Objetivo do desenvolvimento

Quero entregar duas experiências que compartilhem a mesma identidade visual, mecânicas e recursos:

**Experiência A — Jogo principal**

Uma aventura cyberpunk 2.5D com sete cenários, exploração ambiental, plataformas, diferentes alturas, puzzles e dois finais.

**Experiência B — Demo Mobile da Game Jam**

Uma demonstração curta que qualquer pessoa consiga acessar pelo navegador do celular, sem precisar instalar aplicativos ou criar conta.

A demonstração deve utilizar um trecho real do jogo principal, e não uma aplicação independente com mecânicas falsas.

Use preferencialmente o mesmo projeto Godot, reutilizando cenas, scripts e dados. Permita selecionar um modo de demonstração por meio de uma cena inicial, configuração ou parâmetro apropriado.

## 2. Arquitetura 2.5D

Quero uma implementação 2.5D real, combinando geometria tridimensional com movimentação lateral.

Utilize, conforme apropriado:

- Node3D para organização dos cenários.
- CharacterBody3D para movimentação e colisões do personagem.
- Sprite3D ou AnimatedSprite3D para preservar os sprites originais.
- MeshInstance3D para arquitetura e estruturas.
- StaticBody3D e CollisionShape3D para colisões.
- Camera3D com enquadramento lateral.
- DirectionalLight3D e OmniLight3D para iluminação compatível.
- AnimationPlayer para eventos e animações.
- Control para HUD e interfaces.

Escolha câmera ortográfica ou perspectiva de baixa distorção conforme os testes visuais.

A movimentação deverá permanecer predominantemente em um plano lateral, sem movimento livre de profundidade.

O mundo terá profundidade tridimensional real, com elementos posicionados em diferentes distâncias da câmera.

Implemente camadas de cenário, estruturas volumétricas e objetos que criem sensação de escala.

Não basta aplicar parallax sobre imagens 2D e declarar que o jogo está em 2.5D.

Preserve a identidade e a animação do personagem recentemente integrado. Não substitua o protagonista por um personagem genérico.

## 3. Segurança da migração

Antes de modificar o projeto:

1. Inspecione sua estrutura.
2. Registre os sistemas existentes.
3. Confirme o estado do Git.
4. Preserve as alterações locais.
5. Crie uma branch de desenvolvimento para a versão 2.5D.
6. Faça uma prova de conceito isolada antes de migrar todas as regiões.

Não apague nem sobrescreva a versão 2D funcional.

Migre os sistemas de forma progressiva.

Sempre que for necessário adaptar uma mecânica originalmente baseada em Node2D para Node3D, preserve sua lógica de negócio e suas condições narrativas.

Não faça uma conversão automática superficial.

## 4. Direção artística: Recife cyberpunk de 2187

Utilize as imagens de referência aprovadas pela equipe.

Quero que os ambientes sejam reconhecíveis como Recife mesmo após o colapso ambiental.

Características centrais:

- Fachadas históricas do Recife Antigo.
- Sobrados inspirados na Rua do Bom Jesus.
- Marco Zero e sua composição urbana.
- Pontes inspiradas na Maurício de Nassau e na Buarque de Macedo.
- Rio Capibaribe.
- Torre Malakoff.
- Manguezais.
- Porto do Recife.
- Ruínas, prédios alagados e arquitetura industrial.
- Estruturas futuristas construídas sobre edificações antigas.
- Domínio visual da corporação NEXUS.

A paleta deve manter roxo profundo, azul-escuro, ciano, âmbar, ferrugem e verdes discretos.

Misture arquitetura real reinterpretada, tecnologia decadente, água contaminada e iluminação cinematográfica.

Não quero cidades cyberpunk genéricas ou uma combinação indiscriminada de luzes neon.

### Regiões obrigatórias

**Nova Éden:** megacidade artificial, cúpula, setores inferiores, passarelas, publicidade da NEXUS e prédios em diferentes alturas.

**Ruínas do Recife Antigo:** Marco Zero, fachadas históricas, pontes, rios, ruas alagadas, interiores e caminhos alternativos.

**Laboratório GAIA:** instalações de pesquisa, hologramas, cápsulas biológicas, circuitos e salas subterrâneas.

**Estação Capibaribe:** canais, reservatórios, bombas, válvulas e comportas ao lado do rio.

**Banco Verde:** estufas, armazenamento de sementes, irrigação e recuperação ambiental.

**Torre Atmos:** estrutura de filtragem vertical com elevadores, turbinas e vista para Recife.

**Complexo NEXUS:** porto industrial, guindastes, contêineres, instalações corporativas e ARCA-01.

Crie ambientes exploráveis, não apenas imagens bonitas.

## 5. Level design robusto

Os mapas não podem funcionar como corredores retos.

Implemente:

- Diferentes alturas.
- Plataformas acessíveis.
- Escadas e elevadores.
- Caminhos alternativos.
- Salas e ambientes internos.
- Passagens desbloqueáveis.
- Atalhos.
- Áreas opcionais.
- Objetos interativos.
- Puzzles integrados à arquitetura.

O jogador deverá explorar, investigar e descobrir como chegar aos objetivos.

Evite transformar o jogo em plataforma de precisão. O foco continua sendo aventura narrativa e puzzles.

## 6. Mecânicas fundamentais

Preserve as três cartas obrigatórias da Game Jam.

**Paz e Amor**

Não implementar combate. Os conflitos são resolvidos com diálogo, investigação, distração de drones e restauração de sistemas.

**Dois é Demais**

O jogador alterna entre o mundo físico e a análise de GAIA.

No modo GAIA, circuitos, registros, pontos de energia e objetos ocultos tornam-se visíveis.

A alternância deve modificar verdadeiramente os puzzles e as possibilidades de interação.

**Abra-te Sésamo**

As fases contêm portas, comportas, arquivos e mecanismos que precisam ser desbloqueados mediante exploração e resolução de puzzles.

Não permita que todos os obstáculos sejam resolvidos simplesmente pressionando o botão de interação.

## 7. Criar a demonstração mobile

Desenvolva um modo chamado:

**LAST SIGNAL: EARTH_404 — Demo Game Jam**

Duração-alvo: 2 a 3 minutos.

Fluxo proposto:

**Etapa 1 — Introdução**

Tela inicial com nome do jogo, botão Jogar e instruções simples.

Explique brevemente que o mundo está em colapso e que o jogador explorará Recife em 2187.

**Etapa 2 — Exploração**

O jogador controla o protagonista em um pequeno trecho 2.5D do Recife Antigo.

O cenário deve conter fachadas históricas, um trecho de ponte, o Capibaribe e tecnologia da NEXUS.

**Etapa 3 — Descoberta de GAIA**

O jogador encontra um terminal antigo que ativa a visão GAIA.

Uma breve transição mostra circuitos ocultos.

**Etapa 4 — Puzzle**

O jogador precisa encontrar uma fonte de energia, ativar um terminal e abrir uma comporta ou passagem.

O puzzle deve exigir ao menos uma alternância de perspectiva.

**Etapa 5 — Decisão final**

Apresente uma escolha narrativa:

- Restaurar o sistema ambiental para beneficiar os moradores.
- Reservar a energia para uma evacuação futura.

A decisão deve provocar um efeito visual curto no ambiente.

**Etapa 6 — Encerramento**

Mostre uma mensagem de encerramento relacionada à escolha, seguida da opção de jogar novamente.

O jogador deve conseguir concluir a demo sem conhecer previamente o jogo.

## 8. Controles touchscreen

Implemente controles próprios para celular.

O usuário deve conseguir jogar sem teclado ou controle físico.

Controles mínimos:

- Movimento para esquerda.
- Movimento para direita.
- Saltar.
- Interagir.
- Alternar GAIA.
- Objetivo/ajuda.
- Pausar.

Requisitos:

- Botões grandes e bem espaçados.
- Suporte a múltiplos toques simultâneos.
- Controles responsivos.
- Feedback visual ao pressionar.
- Layout adaptado a diferentes resoluções.
- Suporte a áreas seguras da tela.
- Interface prioritariamente em orientação paisagem.
- Botões que não cubram o protagonista ou elementos essenciais.

Use as ações existentes do Input Map e controles virtuais compatíveis com a Godot.

Mantenha suporte a teclado no computador.

O jogo deverá detectar adequadamente o contexto touchscreen e exibir a interface correspondente, mantendo uma opção de ajuste manual caso a detecção falhe.

## 9. Interface mobile

Crie uma interface cyberpunk limpa e funcional.

Quero:
- Tela inicial adaptada ao celular.
- Botões de tamanho confortável.
- Diálogos legíveis.
- Textos curtos.
- Objetivos claros.
- Interface GAIA simplificada.
- Barra ou painel de missão discreto.
- Indicadores visuais que não dependam apenas de cores.

Não sobrecarregue a tela com elementos.

O jogador precisa conseguir enxergar os cenários e identificar os objetos importantes.

## 10. Desempenho e exportação Web

Esta é uma das partes mais importantes.

A versão mobile deve funcionar no navegador por meio de exportação HTML5 da Godot.

Utilize o renderizador **Compatibility**, compatível com a exportação Web da Godot 4.

Prefira a exportação em thread única.

Não utilize recursos exclusivos dos renderizadores Forward+ ou Mobile na versão Web.

Otimize:

- Quantidade de polígonos.
- Materiais.
- Texturas.
- Iluminação.
- Sombras.
- Partículas.
- Efeitos de pós-processamento.
- Consumo de memória.
- Quantidade de objetos simultâneos.
- Tamanho do download inicial.

Priorize modelos low-poly estilizados com texturas coerentes.

Use lightmaps ou iluminação simplificada quando forem apropriados e compatíveis.

Implemente um perfil gráfico reduzido para dispositivos móveis.

Meta inicial de desempenho: aproximadamente 30 FPS em aparelhos intermediários de referência, a confirmar por testes reais.

Não declare compatibilidade universal sem testes.

## 11. Publicação e QR Code

Prepare o jogo para hospedagem estática.

Requisitos:

1. Exportar a versão Web.
2. Gerar um `index.html` funcional.
3. Organizar os arquivos de exportação.
4. Testar a execução usando servidor HTTP local.
5. Preparar publicação em serviço compatível com jogos HTML5, como itch.io.
6. Gerar instruções de implantação.
7. Quando existir uma URL pública válida, gerar um QR Code apontando para ela.

Não invente uma URL pública.

Não declare o jogo publicado antes de confirmar a publicação.

O público deve conseguir abrir a demo usando um navegador moderno, sem precisar instalar um APK.

Se a hospedagem exigir alguma configuração específica, documente-a.

## 12. Experiência durante a apresentação

A demo será usada diante de uma plateia da Game Jam.

Portanto:

- Não exigir cadastro.
- Não exigir login.
- Não depender de backend.
- Não depender de IA externa.
- Não exigir conexão com serviços de terceiros durante a jogabilidade.
- Permitir que vários visitantes joguem independentemente.
- Não implementar multiplayer.
- Não compartilhar o estado de uma partida com outra.
- Manter carregamento simples e rápido.
- Permitir reiniciar a experiência facilmente.

O acesso inicial à página dependerá da rede, mas o jogo deverá funcionar sem requisições externas obrigatórias após carregar seus próprios arquivos.

Prepare também uma versão local para demonstração caso a internet do evento falhe.

## 13. Testes obrigatórios

Execute verificações em desktop e, quando disponíveis, em dispositivos móveis reais.

Teste:

- Inicialização.
- Carregamento das cenas.
- Movimento.
- Saltos.
- Colisões.
- Plataformas.
- Botões touchscreen.
- Toques simultâneos.
- Alternância GAIA.
- Interações.
- Puzzle.
- Escolha final.
- Reinício.
- Desempenho.
- Exportação Web.
- Áudio.
- Rotação de tela.
- Redimensionamento.

Valide especialmente Chrome no Android e Safari no iOS quando houver dispositivos disponíveis.

Caso não existam celulares acessíveis ao ambiente de execução, documente a limitação e forneça passos objetivos para testes manuais.

Não afirme que realizou testes físicos que não foram executados.

## 14. Ordem obrigatória de execução

**Fase 1 — Preservação**

Inspecione o projeto e crie uma branch para o desenvolvimento 2.5D.

**Fase 2 — Prova de conceito 2.5D**

Implemente um trecho real das Ruínas do Recife Antigo com personagem, câmera, colisões, profundidade e iluminação.

**Fase 3 — Teste Web**

Exporte essa primeira cena para navegador e valide se o renderizador, os modelos e os materiais são compatíveis.

Não avance para uma migração completa antes de confirmar a viabilidade técnica da exportação.

**Fase 4 — Demo Mobile**

Implemente os controles touchscreen e o fluxo completo de 2 a 3 minutos.

**Fase 5 — Expansão do jogo principal**

Após validar a prova de conceito, aplique o padrão 2.5D às demais áreas de maneira progressiva.

**Fase 6 — Polimento**

Melhore as animações, interfaces, ambientação e feedback das interações.

**Fase 7 — Entrega**

Execute regressões, gere capturas reais e documente a publicação.

## 15. Entregáveis

Quero receber:

1. Projeto Godot atualizado, com código GDScript.
2. Prova de conceito 2.5D funcional.
3. Cena mobile jogável.
4. Controles touchscreen.
5. Exportação HTML5, se tecnicamente validada.
6. Instruções para publicar o jogo.
7. Arquivos de apresentação da demo.
8. Documentação das alterações.
9. Capturas reais da Godot.
10. Relatório de testes e limitações.

Não quero apenas relatórios ou alterações superficiais.

Faça modificações efetivas nas cenas, scripts e recursos.

## 16. Critérios finais de sucesso

A entrega será considerada bem-sucedida quando:

- O personagem original funcionar no cenário 2.5D.
- Os ambientes apresentarem profundidade tridimensional.
- Recife for visualmente reconhecível.
- O jogador conseguir explorar e interagir.
- O modo GAIA modificar a jogabilidade.
- A demo puder ser concluída em poucos minutos.
- Existirem controles apropriados para toque.
- A versão Web funcionar em navegadores testados.
- Os sistemas originais permanecerem preservados.
- O desenvolvimento não comprometer a versão estável do jogo.

**Prioridade máxima: uma demonstração 2.5D realmente jogável, visualmente marcante e preparada para celular.**

Não sacrifique a estabilidade para aumentar a quantidade de funcionalidades.

Se o escopo completo não couber na execução, priorize a prova de conceito e a demo funcional, documentando as demais etapas ainda pendentes.

Nosso objetivo é criar uma experiência que o público possa jogar durante a Game Jam e que demonstre o potencial de LAST SIGNAL: EARTH_404.