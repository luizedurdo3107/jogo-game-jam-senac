#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD"
capture="$root/work/departure_capture_1080"
mkdir -p "$capture" outputs/pitch/departure_edit
cp project.godot "$capture/project.godot"
cp tools/mvp_capture_override.cfg "$capture/override.cfg"
for folder in assets data scenes scripts tools outputs .godot; do
    ln -sfn "$root/$folder" "$capture/$folder"
done
ln -sfn "$root/default_bus_layout.tres" "$capture/default_bus_layout.tres"
flatpak run org.godotengine.Godot --path "$capture" --resolution 1920x1080 \
    --position 0,0 --fixed-fps 30 --disable-vsync \
    --write-movie "$root/outputs/pitch/departure_bruta.avi" --quit-after 6000 \
    res://tools/departure_capture.tscn > outputs/pitch/departure_edit/captura.log 2>&1
if rg -n 'SCRIPT ERROR|^ERROR:' outputs/pitch/departure_edit/captura.log; then
    exit 1
fi
rg -q 'DEPARTURE CAPTURE COMPLETE' outputs/pitch/departure_edit/captura.log
bash outputs/pitch/departure_edit/extrair.sh > outputs/pitch/departure_edit/extracao.log 2>&1
flatpak run org.godotengine.Godot --headless --path . --script res://tools/final_pitch_edit.gd \
    > outputs/pitch/departure_edit/preparacao.log 2>&1
if rg -n 'SCRIPT ERROR|^ERROR:' outputs/pitch/departure_edit/preparacao.log; then
    exit 1
fi
bash outputs/pitch/rc5_edit/renderizar.sh > outputs/pitch/rc5_edit/edicao.log 2>&1
