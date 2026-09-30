#!/usr/bin/env bash
set -e

echo "============================================="
echo " Sub-Routine Headless Asset Pipeline Runner "
echo "============================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Checking textures in asset_pipeline/raw_textures..."
mkdir -p "$ROOT_DIR/godot_project/assets/textures"
mkdir -p "$ROOT_DIR/godot_project/assets/models"

if [ -d "$ROOT_DIR/asset_pipeline/raw_textures" ]; then
    cp "$ROOT_DIR/asset_pipeline/raw_textures"/*.jpg "$ROOT_DIR/godot_project/assets/textures/" 2>/dev/null || true
    echo "[Asset Pipeline] Textures synced to godot_project/assets/textures/"
fi

BLENDER_BIN=""
if command -v blender &>/dev/null; then
    BLENDER_BIN="blender"
elif [ -x "/home/chriswinters/bin/blender" ]; then
    BLENDER_BIN="/home/chriswinters/bin/blender"
elif [ -x "$HOME/bin/blender" ]; then
    BLENDER_BIN="$HOME/bin/blender"
fi

if [ -n "$BLENDER_BIN" ]; then
    echo "[Asset Pipeline] Blender detected at $BLENDER_BIN. Executing headless Blender pipeline..."
    "$BLENDER_BIN" -b -P "$SCRIPT_DIR/scripts/headless_blender_pipeline.py"
else
    echo "[Asset Pipeline] Headless Blender binary not in PATH. Running standalone procedural mesh pipeline..."
    python3 "$SCRIPT_DIR/scripts/procedural_mesh_generator.py"
fi

echo "Verifying generated GLB models in godot_project/assets/models:"
ls -lh "$ROOT_DIR/godot_project/assets/models"

echo "============================================="
echo " Asset Pipeline Complete! "
echo "============================================="
