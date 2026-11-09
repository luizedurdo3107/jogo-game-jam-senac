# Derivados técnicos

O personagem fornecido pelo usuário está integrado em `protagonista_provisorio/`:

- `personagem.png`: sprite sheet RGBA de 664×216, com 8 células de 83×216.
- `sprite_frames.tres`: SpriteFrames com os oito quadros a 10 fps, atribuído ao AnimatedSprite2D de `scenes/characters/player.tscn`.
- `importacao.json`: medidas, origem, hash do vídeo e parâmetros de processamento.

Somente o fundo quase preto conectado às bordas foi removido. Detalhes escuros fechados foram preservados. O recorte é comum e os pés foram alinhados verticalmente, sem redimensionar os pixels do original.

O vídeo não fornece um ciclo dedicado de caminhada: `idle` e `walk` usam o mesmo movimento curto disponível. A silhueta geométrica gerada por `player_controller.gd` é apenas o fallback caso uma cena não tenha SpriteFrames atribuído.
