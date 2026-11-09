# Origem e licença dos novos recursos sonoros

Identificador: **LicenseRef-LastSignal-Original**.

Os recursos em `ambience/`, `sfx/` e `ui/` foram produzidos originalmente para LAST SIGNAL: EARTH_404 nesta implementação, por processamento procedural em GDScript. Não são gravações de campo, Foley gravado, instrumentos acústicos gravados, falas humanas ou material de bibliotecas externas.

Processo: ruídos coloridos filtrados em múltiplas bandas; excitação granular e ressonadores modais amortecidos para impactos; camadas de fluxo, vibração, pressão e variações lentas para ambientes; sobreposição de dois segundos para loops; remoção de DC e ajuste de RMS/pico. Seeds determinísticas e parâmetros estão em `tools/build_audio_library.gd`. Conversão Vorbis por FFmpeg, sem incorporar qualquer amostra de terceiros.

É permitido utilizar, modificar, incorporar e redistribuir estes novos arquivos sonoros no jogo e em seus derivados, inclusive comercialmente, sem atribuição obrigatória. Fornecidos sem garantia de adequação estética, naturalidade ou exclusividade jurídica. Esta autorização não se estende ao personagem, vídeo, imagens, Godot, FFmpeg nem a outros recursos preexistentes, cujas condições permanecem inalteradas.

`outputs/AUDIO_ANALISE_FONTES.json` registra o método e a seed de cada fonte; `outputs/AUDIO_ANALISE_DISTRIBUICAO.json` registra medições dos arquivos decodificados e seus SHA-256. Não houve download de áudio nem extração de falas ou música do vídeo do personagem.

Não há faixas musicais ou vozes finais neste pacote. As pastas `music/` e `voices/` contêm apenas instruções, não arquivos silenciosos apresentados como conteúdo pronto. Os barramentos e controles estão preparados para material autorizado futuro. Nenhum diálogo foi substituído por TTS.

Os antigos tons de demonstração em `assets/processados/audio_demo` e `assets/processados/audio_estacoes` são históricos e não são reproduzidos pelo novo sistema.
