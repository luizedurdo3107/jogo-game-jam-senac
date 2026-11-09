# CODEX — REDESIGN DAS ESTAÇÕES E DIFERENCIAÇÃO COMPLETA ENTRE GAIA E MUNDO FÍSICO

Atue como Lead Game Designer, Level Designer, Technical Artist e desenvolvedor sênior em Godot 4 e GDScript.

Sua missão é corrigir dois problemas importantes de LAST SIGNAL: EARTH_404:

1. As estações ambientais estão visualmente e mecanicamente parecidas.
2. A perspectiva GAIA está praticamente igual à perspectiva física.

Quero alterações reais nas cenas, na programação, na direção artística e nas mecânicas. Não quero apenas relatórios ou mudanças superficiais de cores.

Projeto:

`/home/luizeduardo/Documents/Codex/2026-11-08/chat-x20`

Preserve a versão 2.5D, o personagem original, a história, os sistemas funcionais e os dois finais.

## 1. Cada estação precisa parecer um lugar diferente

### ESTAÇÃO CAPIBARIBE — ÁGUA

**Identidade:** instalação hidráulica parcialmente submersa, conectada ao Rio Capibaribe.

Visual:
- Água contaminada ocupando parte do cenário.
- Reservatórios e canais.
- Bombas industriais.
- Tubulações grandes.
- Plataformas suspensas.
- Comportas.
- Passarelas enferrujadas.
- Pontes e prédios do Recife ao fundo.
- Iluminação azul-escura e ciano.

Jogabilidade:
- Redirecionar água.
- Controlar válvulas.
- Equilibrar pressão.
- Ativar bombas.
- Subir ou baixar o nível da água em áreas específicas.

**Puzzle principal:** identificar o fluxo correto da água, alimentar uma bomba e abrir uma comporta.

Na perspectiva física, o protagonista opera válvulas e desloca módulos.

Na visão GAIA, o jogador visualiza fluxos internos, pressão, contaminação e conexões ocultas.

Após restaurar a estação, a água deve apresentar uma melhoria visual localizada.

### BANCO VERDE — SOLO E VIDA

**Identidade:** estufa biotecnológica abandonada, com vegetação tropical e sistemas de preservação de sementes.

Visual:
- Estufas de vidro rachado.
- Grandes raízes.
- Plantas em diferentes estágios.
- Manguezais experimentais.
- Cápsulas biológicas.
- Jardins suspensos.
- Iluminação verde e âmbar.
- Solo contaminado.
- Laboratórios de sementes.

Jogabilidade:
- Reativar irrigação.
- Posicionar filtros.
- Identificar sementes viáveis.
- Controlar temperatura e umidade.
- Restaurar o acesso ao cofre biológico.

**Puzzle principal:** identificar condições adequadas para recuperar sementes e abrir o cofre de preservação.

Na perspectiva física, o jogador transporta filtros, manipula válvulas e acessa salas.

Na visão GAIA, visualiza umidade, contaminação, viabilidade das cápsulas e redes de irrigação.

Após restaurar a estação, pequenas plantas devem começar a reagir.

Não transforme o ambiente em uma floresta instantânea.

### TORRE ATMOS — AR

**Identidade:** torre industrial vertical de filtragem atmosférica.

Visual:
- Vários andares.
- Ventiladores gigantes.
- Dutos de ar.
- Turbinas.
- Elevadores.
- Passarelas externas.
- Névoa.
- Luzes âmbar de emergência.
- Horizonte poluído de Recife.
- Porto visível ao fundo.

Jogabilidade:
- Exploração vertical.
- Elevadores e passarelas.
- Controle de ventilação.
- Recalibração de filtros.
- Redirecionamento pacífico de drones.

**Puzzle principal:** organizar a sequência de filtragem, liberar os dutos e restabelecer a circulação de ar.

Na perspectiva física, o jogador acessa andares, manipula mecanismos e negocia com uma técnica.

Na visão GAIA, identifica partículas, qualidade do ar, circulação interna e conexões digitais dos filtros.

Após restaurar a torre, parte da névoa deve se dissipar.

## 2. GAIA e mundo físico devem parecer experiências diferentes

A visão GAIA não pode ser apenas a mesma imagem com um filtro ciano.

Quero uma transformação visual e funcional do ambiente.

### MUNDO FÍSICO

O mundo físico representa Recife em 2187.

Deve apresentar:
- Texturas e materiais reais.
- Ferrugem, umidade, rachaduras e vegetação.
- Iluminação ambiental.
- NPCs.
- Objetos físicos.
- Plataformas e arquitetura.
- Equipamentos industriais.

O protagonista pode:
- Caminhar e saltar.
- Mover objetos.
- Transportar baterias.
- Conversar.
- Acionar válvulas.
- Abrir portas já desbloqueadas.
- Manipular mecanismos físicos.

### VISÃO GAIA — CAMADA DIGITAL

Ao ativar GAIA, transforme visualmente o cenário em uma representação tecnológica de análise ambiental.

Implemente:
- Escurecimento controlado dos materiais físicos.
- Contornos luminosos nos objetos relevantes.
- Circuitos holográficos suspensos.
- Linhas de energia animadas.
- Grades e diagramas digitais.
- Dados ambientais próximos aos equipamentos.
- Registros históricos projetados.
- Animações de escaneamento.
- Elementos ocultos que surgem apenas nesse modo.
- Alterações perceptíveis nos sons e na iluminação.

Use recursos apropriados da Godot, como materiais alternativos, objetos exclusivos por modo, efeitos de transição, shaders compatíveis e indicadores tridimensionais.

Não comprometa a legibilidade dos ambientes.

## 3. A visão GAIA precisa ter jogabilidade própria

Não quero que o jogador apenas ative GAIA, veja uma pista e volte imediatamente.

Implemente um sistema de interação digital.

Na visão GAIA, permita:
- Selecionar circuitos.
- Redirecionar energia.
- Analisar sistemas ambientais.
- Desbloquear terminais digitais.
- Reconstruir informações históricas.
- Identificar conexões invisíveis.
- Ativar dispositivos de controle remoto autorizados.
- Localizar falhas nas estações.

O modo GAIA não pode:
- Transportar objetos físicos.
- Mover baterias.
- Conversar diretamente com moradores como se fosse o protagonista.
- Atravessar ou abrir fisicamente portas.
- Resolver todos os problemas automaticamente.

Crie feedback visual para ações permitidas e bloqueadas.

## 4. Puzzles combinando as perspectivas

Cada estação deve exigir alternância real entre mundo físico e GAIA.

Exemplo — Capibaribe:

1. O protagonista encontra uma comporta bloqueada.
2. GAIA revela três canais de água.
3. O jogador identifica a conexão correta.
4. Volta ao mundo físico.
5. Ajusta duas válvulas.
6. GAIA analisa a pressão.
7. O jogador ativa digitalmente o controlador.
8. Volta ao físico para ligar a bomba.
9. A comporta se abre e o reservatório começa a receber água.

O resultado deve ser visivelmente diferente do puzzle do Banco Verde e da Torre Atmos.

Os puzzles precisam ser solucionáveis com pistas claras e feedback compreensível.

## 5. Adicionar memórias do passado

A visão GAIA também deve revelar o Recife antes do colapso.

Em locais específicos, implemente projeções de memória ambiental.

Exemplos:
- Capibaribe com água menos contaminada.
- Manguezais preservados.
- Ruas históricas do Recife Antigo.
- Áreas verdes anteriores à destruição.
- Instalações funcionando antes do abandono.

Essas memórias não são viagens no tempo.

O jogador observa registros históricos reconstruídos digitalmente, mas não pode alterar o passado.

As memórias devem ajudar a compreender o colapso ambiental e oferecer pistas para os puzzles.

## 6. Interface específica de cada perspectiva

### Interface física

Minimalista:
- Objetivo atual.
- Interação disponível.
- Informações essenciais.
- Indicador discreto da perspectiva.

### Interface GAIA

Interface de diagnóstico:
- Nome do sistema analisado.
- Estado da conexão.
- Dados ambientais.
- Circuitos disponíveis.
- Indicadores de falha.
- Ação digital possível.

Não exiba painéis gigantes ocupando a tela.

No desktop, o jogador deve utilizar Q para alternar e E para interagir.

Preserve controles touchscreen apenas quando apropriados.

## 7. Requisitos de implementação

- Godot 4.7.2.
- GDScript.
- Cenários 2.5D.
- Preservação dos recursos originais.
- Reutilização de componentes quando apropriado.
- Arquitetura modular.
- Estados persistentes.
- Compatibilidade com salvamento e checkpoints.
- Preservação dos finais.
- Sem combate.
- Sem serviços externos obrigatórios.

Crie um controlador central de perspectivas para definir quais objetos, materiais e interações estão ativos em cada modo.

Os sistemas de água, solo e ar devem compartilhar apenas a infraestrutura técnica necessária, mas possuir mecânicas, propriedades e feedback específicos.

Não implemente três puzzles idênticos alterando somente nomes e cores.

## 8. Ordem de execução

1. Analise a implementação atual das três estações e das perspectivas.
2. Identifique os recursos e scripts existentes.
3. Preserve o estado funcional do projeto.
4. Redesenhe a Estação Capibaribe.
5. Implemente a visão GAIA avançada no cenário.
6. Valide a alternância e o puzzle.
7. Desenvolva Banco Verde com mecânicas próprias.
8. Desenvolva Torre Atmos com exploração vertical.
9. Integre consequências ambientais e decisões.
10. Execute testes completos.

Não recrie o projeto do zero.

## 9. Critérios de aceite

A implementação somente estará concluída quando:

- As três estações forem visualmente distintas.
- Os três puzzles tiverem soluções e mecânicas diferentes.
- A visão GAIA modificar claramente a aparência do cenário.
- O modo GAIA permitir interações digitais exclusivas.
- O mundo físico permitir ações que GAIA não consegue executar.
- As perspectivas precisarem trabalhar juntas.
- As memórias do passado forem apresentadas como registros, sem alterar acontecimentos históricos.
- As mudanças ambientais forem perceptíveis.
- Os dois finais continuarem acessíveis.
- Os checkpoints e salvamentos funcionarem.
- Não houver softlocks nos puzzles.

Capture imagens reais da Godot mostrando cada estação no mundo físico e na visão GAIA, totalizando pelo menos seis capturas.

Apresente uma demonstração de um puzzle que exige alternância entre perspectivas.

## 10. Regra final

Não quero uma implementação superficial.

**As três estações precisam parecer três experiências diferentes:**

Capibaribe deve transmitir a força da água e da infraestrutura hidráulica.

Banco Verde deve transmitir a fragilidade da vida e a recuperação ecológica.

Torre Atmos deve transmitir altura, ventilação, maquinário e poluição atmosférica.

**A visão GAIA deve parecer que o jogador está enxergando a estrutura digital invisível do mundo**, enquanto o modo físico representa a realidade material de Recife.

Execute essas mudanças diretamente no projeto existente, teste o resultado e entregue evidências concretas.

Se não conseguir concluir tudo na execução atual, finalize primeiro um puzzle e sua dupla perspectiva com qualidade, documentando as partes pendentes sem declarar o trabalho inteiro concluído.