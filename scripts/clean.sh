#!/usr/bin/env bash
# Remove build artifacts (keeps the uv environment and submodule checkouts).
set -euo pipefail
source "$(dirname "$0")/env.sh"

echo ">> cleaning SITL build"
if [[ -x "$AP_ROOT/waf" ]]; then
    ( cd "$AP_ROOT" && ./waf distclean >/dev/null 2>&1 || true )
fi

echo ">> removing Gazebo plugin build"
rm -rf "$GZ_PLUGIN_BUILD"

echo ">> done. (uv environment left intact; use 'rm -rf .venv' to remove it)"
