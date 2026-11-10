# Validação da campanha curta 2.5D/mobile

Registro histórico da edição anterior, commit 998387d. A validação da jornada restaurada está em `RESTAURACAO_E_QA.md`; os resultados desta página não certificam a edição atual.

Ambiente: Godot 4.7.2 Flathub, Compatibility, Intel Iris Xe/Mesa. Web: Chromium do navegador integrado, WebGL 2, viewport 844×390. Não é um celular físico.

## Regressões

```sh
for suite in journey_test flow_test stations_test station_interaction_test demo_physics_test demo_touch_test; do
  godot --headless --path . --fixed-fps 60 "res://tests/$suite.tscn" || exit 1
done
```

Os nomes `demo_physics_test` e `demo_touch_test` são nomes históricos dos testes, não modos de jogo. Ambos instanciam o mesmo Recife usado pela jornada atual.

| Suíte | Verificações | Escopo |
|---|---:|---|
| journey_test | 366 | percurso real do Recife, duas decisões finais, migração v1/v2 → v3, round-trip, falha de gravação e catálogo sonoro |
| flow_test | 60 | Recife → Capibaribe → final → menu para ambos os desfechos, cancelamento e Continue após conclusão |
| stations_test | 138 | puzzle Capibaribe por deslocamento real, escadas e chegada ao transmissor para ambas as escolhas |
| station_interaction_test | 28 | botões de configuração e conclusão, foco, modais, materiais GAIA e recuperação de autorização |
| demo_physics_test | 30 | colisões, salto, elevador, pausa, drone pacífico e áudio local |
| demo_touch_test | 46 | eventos sintéticos, dois dedos simultâneos, arraste, foco, rotação e disposição dos botões |

Resultado: **668 verificações, zero falhas**. Arquivos de execução consolidados em `outputs/VALIDACAO_CAMPANHA_CURTA.log`.

## Capturas reais

```sh
godot --path . --fixed-fps 60 res://tests/mobile_capture.tscn
```

Grava menu, Recife, confirmação do transmissor e os dois desfechos em `outputs/`. O utilitário prepara estados de teste sem alterar o save do jogador. O resultado não constitui teste de hardware mobile.

## Exportação

Único preset de distribuição: `Web Mobile`. O arquivo `project.godot` aponta somente para o menu unificado, sem overrides para versões antigas. Os três cenários de jogo (duas fases + epílogo) são Node3D; interfaces são Control/CanvasLayer.

A exportação `Web Mobile` foi refeita com a campanha curta, substituindo o PCK anterior em `outputs/web/`. A validação visual atual usa a Godot nativa e os mesmos controles mobile. Os testes completos de percurso e transição são automatizados; não constituem uma sessão integral em celular físico.

Uma cópia limpa dos arquivos preparados para o commit também foi importada sem cache ou backups; as 60 verificações de fluxo entre cenas passaram nela. Os hashes da exportação local estão em `outputs/BUILD_WEB.sha256`.

As alterações locais preexistentes de `project.godot` e `default_bus_layout.tres` são preservadas, sem inclusão no commit desta tarefa.

Os testes não escrevem no save normal. Os testes de persistência usam caminho aleatório e removem apenas o arquivo temporário que criaram. Preferências de toque não são gravadas pelos testes sintéticos. A migração dos saves 2.5D v1/v2 é testada em diferentes fases e preserva somente o progresso pertinente ao Recife/Capibaribe. Os arquivos antigos não são sobrescritos; a confirmação final precisa ser feita na campanha curta. Saves inconsistentes são rejeitados.

## Checklist em celulares físicos (pendente)

1. Hospedar a pasta Web completa em HTTPS e abrir no Chrome Android e Safari iOS.
2. Iniciar, mover + saltar com dois dedos, subir/descer e alternar GAIA.
3. Interagir, rolar diálogos e resolver os puzzles sem teclado.
4. Girar para retrato e retornar à paisagem: nenhuma ação deve ficar presa.
5. Minimizar/reabrir, pausar, ajustar seis volumes e recarregar.
6. Confirmar Continue, checkpoints, a escolha da água, confirmação e ambos os finais.
7. Avaliar recortes/notch, texto, áudio após gesto e estabilidade durante toda a jornada.
8. Medir FPS/consumo no aparelho; a meta de 30 FPS ainda não está certificada.

Limites conhecidos: música e dublagem humana não fornecidas; identidade visual low-poly; oito quadros do personagem reaproveitados para movimento, sem novas animações dedicadas; Nova Éden/laboratório sem cenas 3D independentes. A versão Web é um jogo para navegador, não um APK.
