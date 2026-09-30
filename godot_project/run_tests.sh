#!/usr/bin/env bash
set -e

echo "============================================="
echo " Sub-Routine Headless GDUnit4 CLI Test Suite "
echo "============================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

GODOT_BIN=""
if command -v godot &>/dev/null; then
    GODOT_BIN="godot"
elif [ -x "$HOME/.local/bin/godot" ]; then
    GODOT_BIN="$HOME/.local/bin/godot"
elif [ -x "/home/chriswinters/.local/bin/godot" ]; then
    GODOT_BIN="/home/chriswinters/.local/bin/godot"
fi

if [ -n "$GODOT_BIN" ]; then
    echo "[TDD Runner] Godot binary detected ($($GODOT_BIN --version 2>/dev/null || true)). Running in-engine GDUnit4 CLI runner..."
    "$GODOT_BIN" --headless --path "$SCRIPT_DIR" -s "res://tests/gdunit4_cli_runner.gd" || exit 1
else
    echo "[TDD Runner] Godot CLI not in PATH. Running Headless TDD test harness..."
    python3 "$ROOT_DIR/asset_pipeline/scripts/run_headless_tests.py" || exit 1
fi

echo "============================================="
echo " TDD Suite Completed Successfully (Exit: 0)  "
echo "============================================="
