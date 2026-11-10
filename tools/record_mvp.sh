#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
root="$PWD"
capture="$root/work/mvp_capture_1080"
mkdir -p "$capture" outputs/pitch/capturas outputs/pitch/mvp_edit
cp project.godot "$capture/project.godot"
cp tools/mvp_capture_override.cfg "$capture/override.cfg"
for folder in assets data scenes scripts tools outputs .godot; do
    ln -sfn "$root/$folder" "$capture/$folder"
done
ln -sfn "$root/default_bus_layout.tres" "$capture/default_bus_layout.tres"
flatpak run org.godotengine.Godot --path "$capture" --resolution 1920x1080 \
    --position 0,0 --fixed-fps 30 --disable-vsync \
    --write-movie "$root/outputs/pitch/mvp_bruta.avi" --quit-after 2400 \
    res://tools/mvp_capture.tscn > outputs/pitch/mvp_edit/captura.log 2>&1
if rg -n 'SCRIPT ERROR|^ERROR:' outputs/pitch/mvp_edit/captura.log; then
    exit 1
fi
rg -q 'MVP CAPTURE COMPLETE' outputs/pitch/mvp_edit/captura.log
bash outputs/pitch/mvp_edit/renderizar.sh > outputs/pitch/mvp_edit/edicao.log 2>&1
