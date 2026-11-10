# ARCA-01 e Terra — rc5

Recursos procedurais criados para LAST SIGNAL: EARTH_404 em 10/11/2026.

- `scripts/environments/ark_ship.gd`: nave construída em geometria 3D por GDScript, compartilhada pelo porto, pela doca e pelo epílogo. Não depende de modelo ou textura externa.
- `earth_surface.png`: mapa estilizado de 1024 × 512, com polígonos aproximados de continentes, variação de relevo e oceanos, desertos e calotas. Não é cartografia exata nem fotografia de satélite.
- `earth_clouds.png`: textura transparente de 1024 × 512, gerada por ruído esférico e aplicada em uma camada independente.
- Geração reproduzível: `flatpak run org.godotengine.Godot --headless --path . --script res://tools/generate_earth.gd`.
- `scripts/environments/earth_globe.gd`: esfera iluminada, rotação lenta, nuvens e halo atmosférico. Sem shaders personalizados ou serviços externos.

As artes e o protagonista fornecidos pelo responsável não foram substituídos. Estes recursos não utilizam arquivos de terceiros nem imagens geradas por IA. Podem ser utilizados, alterados e distribuídos como parte deste projeto.
