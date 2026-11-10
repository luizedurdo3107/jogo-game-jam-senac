#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p outputs/pitch/contexto_edit
flatpak run org.godotengine.Godot --headless --path . --script res://tools/context_pitch.gd \
    > outputs/pitch/contexto_edit/preparacao.log 2>&1
if rg -n 'SCRIPT ERROR|^ERROR:' outputs/pitch/contexto_edit/preparacao.log; then
    exit 1
fi
bash outputs/pitch/contexto_edit/renderizar.sh > outputs/pitch/contexto_edit/edicao.log 2>&1
