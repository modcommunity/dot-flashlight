#!/usr/bin/env bash
# Render the flashlight demo to a PNG under Xvfb.
#
#   heavy -- tools/screenshot.sh <out.png> [compat|forward]
#
# compat is the Compatibility renderer (the default, what a browser draws); forward is Forward+ on software Vulkan.
set -uo pipefail
cd "$(dirname "$0")/.."
command -v Xvfb >/dev/null || { echo "Xvfb not installed" >&2; exit 3; }
[ $# -ge 1 ] || { sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
OUT="$(realpath -m "$1")"; MODE="${2:-compat}"
mkdir -p "$(dirname "$OUT")"
godot --headless --path . --import >/dev/null 2>&1
disp=$((90 + RANDOM % 8)); export DISPLAY=":$disp" LIBGL_ALWAYS_SOFTWARE=1
Xvfb ":$disp" -screen 0 1280x720x24 >/dev/null 2>&1 &
xpid=$!
sleep 2
if [ "$MODE" = forward ]; then R=(--rendering-method forward_plus --rendering-driver vulkan); else R=(--rendering-method gl_compatibility --rendering-driver opengl3); fi
timeout 120 godot --path . --resolution 1280x720 "${R[@]}" res://examples/flashlight_demo.tscn -- --shot "$OUT" --mode=$MODE
rc=$?
kill $xpid 2>/dev/null
exit $rc
