# LAST SIGNAL: EARTH_404 — Campanha Curta 2.5D Mobile

Aventura narrativa sem combate, feita em **Godot 4 / GDScript**. Recife, 2187: o corpo manipula equipamentos, enquanto GAIA revela circuitos, diagnósticos e memórias.

Esta é a **única versão ativa do projeto**. O menu, o salvamento e a exportação não oferecem mais o jogo 2D, uma prova de conceito ou demos separadas.

## Jornada

**Duas fases jogáveis: Recife Antigo → Estação Capibaribe → final.**

- Cenários com geometria e colisões 3D, câmera lateral e personagem original em AnimatedSprite3D.
- Recife: descoberta de GAIA, circuito superior, célula subterrânea e abertura da passagem.
- Capibaribe: drenagem, transporte de módulo, duas válvulas e pressão segura.
- No Capibaribe, escolha restaurar a água da comunidade ou reservar o núcleo para a ARCA-01.
- O transmissor no fim da segunda fase abre uma confirmação e leva diretamente ao epílogo. Não exige Banco Verde, Atmos ou NEXUS.
- A escolha da água determina um dos dois desfechos completos, com narrativa de encerramento e botão de retorno ao menu.
- Checkpoints, progresso técnico, volumes e preferências de toque locais ao dispositivo.

## Jogar / editar

Abra `project.godot` com **Godot 4.7.2**, versão usada nos testes, e pressione **F5** para iniciar a jornada pelo menu.

Cena inicial: `scenes/ui/main_menu.tscn`.

No terminal:

```sh
godot --path .
```

Neste computador a instalação disponível é Flatpak: substitua `godot` por `flatpak run org.godotengine.Godot`.

### Controles

| Ação | Teclado | Celular |
|---|---|---|
| Mover | A/D ou setas | esquerda / direita |
| Escadas | W/S ou cima/baixo | subir / descer |
| Saltar | Espaço | saltar |
| Interagir | E | agir |
| Corpo / GAIA | Q | GAIA |
| Ajuda | Tab, J ou M | ? |
| Pausa | Esc | pausa |

Use o celular na horizontal. Toques simultâneos são suportados. O jogo libera os botões ao perder foco, abrir diálogos ou girar para retrato. Se a detecção automática falhar, selecione **Pausa → Toque: sempre visível**. A escolha fica salva.

Em retrato, a jogabilidade aguarda a rotação; menus continuam acessíveis. Diálogos extensos têm rolagem. Os finais mantêm o botão de retorno visível.

## Exportar para navegador mobile

Instale os templates de exportação da mesma versão da Godot.

```sh
mkdir -p outputs/web
godot --headless --path . --export-release "Web Mobile" outputs/web/index.html
python3 -m http.server 8000 --bind 0.0.0.0 --directory outputs/web
```

Abra `http://localhost:8000` no computador. Para acesso pelo celular, publique **todos** os arquivos de `outputs/web/` em uma hospedagem estática HTTPS, com MIME `application/wasm` para o WASM. Não abra `index.html` como arquivo local. HTTP em IP de rede não substitui HTTPS para os recursos seguros do navegador.

O preset é **Compatibility / WebGL 2 / thread única**, com renderização 3D reduzida no Web. Não há APK, backend, login, IA remota ou dependência de serviços externos durante a partida carregada. A primeira carga requer rede ou servidor local.

Os binários exportados ficam fora do Git; este repositório contém o projeto-fonte e os recursos necessários para reconstruí-los. Não foi criado ZIP. O commit no GitHub não publica automaticamente um site.

## Organização

| Diretório | Conteúdo |
|---|---|
| `scenes/regions/` | duas fases 2.5D e epílogo |
| `scenes/ui/` | único menu inicial |
| `scripts/core/` | sessão, jornada/salvamento e navegação |
| `scripts/game/` | personagem, perspectivas e controle dos cenários |
| `scripts/environments/` | construção dos ambientes 3D |
| `scripts/puzzles/` | regras do puzzle Capibaribe |
| `scripts/ui/` | HUDs, toque, créditos e tema |
| `scripts/audio/` | mixagem, ambiente, fontes e passos |
| `data/regions/` | interações e configuração das regiões |
| `data/story/` | decisões e finais |
| `assets/` | artes originais, referências e recursos de execução |
| `tests/` | regressões da jornada 2.5D/mobile |
| `tools/` | importação, análise sonora e shell Web |
| `outputs/` | evidências de validação e exportações locais ignoradas |

A versão 2D anterior e materiais de trabalho foram preservados **somente no backup local ignorado** `work/legacy_source/` e `work/pre_mobile_unification/`. A antiga campanha de cinco fases também está preservada no histórico Git e em `work/short_campaign_before/`. Esses backups não fazem parte do projeto ativo, exportação ou commit. Os documentos históricos em `docs/especificacoes/` são referências de escopo, não descrições do estado atual.

## Salvamento

A campanha curta usa `user://last_signal_short_v3.json`, validado e gravado por substituição atômica. Na ausência dele, importa `last_signal_mobile_v2.json` ou `stations_25d_v1.json`, sem sobrescrever esses arquivos.

A migração conserva o progresso do Recife e do Capibaribe e o destino da água. Quem estava no Banco Verde, Atmos, NEXUS ou em um final antigo retorna ao Capibaribe para conferir e transmitir o sinal: as fases removidas deixam de ser pré-requisitos. O antigo final por maioria de três núcleos não é reinterpretado silenciosamente; a nova conclusão só aparece após confirmação, baseada na escolha da água. O save 2D não é lido nem sobrescrito.

**Nova jornada** pede confirmação quando há progresso válido. **Continuar** volta à região/etapa salva, inclusive ao epílogo.

## Testes e limites

Veja `docs/VALIDACAO.md` para comandos, resultados e verificação manual em celulares. As capturas em `outputs/SHORT_25D_*.png` são da execução real da Godot/navegador, não imagens promocionais.

Esta edição reduz a aventura de cinco para **duas fases exploráveis e um epílogo**, mantendo um começo, puzzle e encerramento. Banco Verde, Atmos e NEXUS não estão no roteiro nem na exportação de cenas. **Nova Éden e o laboratório GAIA não são fases 3D independentes** nesta edição. A apresentação é low-poly, orientada pelas referências, não uma reprodução fotorrealista das imagens. O personagem conserva os oito quadros fornecidos; não foram inventados ciclos dedicados adicionais. Música final e dublagem humana permanecem pendentes. Não há garantia de 30 FPS em aparelhos físicos nem validação universal de Android/iOS.

## Créditos e direitos

Godot Engine e seus componentes: avisos em `LICENSES/` e `THIRD_PARTY_NOTICES.txt`. Personagem e referências foram fornecidos pelo responsável pelo projeto; os originais são preservados, sem presumir uma nova licença de redistribuição. O áudio procedural original e suas origens estão documentados em `assets/audio/ORIGEM_E_LICENCA.md`. A licença da engine não licencia automaticamente as artes ou o jogo.
