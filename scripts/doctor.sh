#!/usr/bin/env bash
# Environment self-check. Reports what is present/missing and flags the
# common pitfalls (software GL rendering, missing plugin, port in use).
set -uo pipefail
source "$(dirname "$0")/env.sh"

ok()   { printf '  [ ok ] %s\n' "$*"; }
warn() { printf '  [warn] %s\n' "$*"; }
bad()  { printf '  [FAIL] %s\n' "$*"; }

echo "== Python / uv =="
if command -v uv >/dev/null 2>&1; then ok "uv $(uv --version | awk '{print $2}')"; else bad "uv not installed"; fi
if [[ -x "$REPO_ROOT/.venv/bin/python" ]]; then ok ".venv present"; else bad ".venv missing (run 'make setup')"; fi
if uv run --quiet python -c "import pymavlink, MAVProxy, serial, lxml; import em" 2>/dev/null; then
    ok "core Python deps import (empy 3.3.4)"
else
    bad "core Python deps do not import (run 'make setup')"
fi

echo "== Submodules =="
[[ -x "$AP_ROOT/waf" ]]                && ok "ardupilot @ $(git -C "$AP_ROOT" rev-parse --short HEAD)"       || bad "ardupilot submodule missing"
[[ -f "$GZ_PLUGIN_ROOT/CMakeLists.txt" ]] && ok "ardupilot_gazebo @ $(git -C "$GZ_PLUGIN_ROOT" rev-parse --short HEAD)" || bad "ardupilot_gazebo submodule missing"

echo "== Builds =="
[[ -x "$AP_ROOT/build/sitl/bin/arducopter" ]] && ok "SITL binary present" || warn "SITL not built (run 'make sitl')"
if compgen -G "$GZ_PLUGIN_BUILD/*.so" >/dev/null; then
    ok "Gazebo plugins built: $(cd "$GZ_PLUGIN_BUILD" && ls ./*.so | tr '\n' ' ')"
else
    warn "Gazebo plugins not built (run 'make plugin')"
fi

echo "== Interceptor assets =="
[[ -f "$REPO_ROOT/config/worlds/intercept.sdf" ]] && ok "intercept.sdf present" || bad "config/worlds/intercept.sdf missing"
[[ -f "$REPO_ROOT/config/models/target_iris/model.sdf" ]] && ok "target_iris model present" || bad "config/models/target_iris missing"
if uv run --quiet python -c "from interfaces import contract" 2>/dev/null; then
    ok "interfaces.contract importable (v$(uv run --quiet python -c 'from interfaces import contract; print(contract.CONTRACT_VERSION)' 2>/dev/null))"
else
    bad "interfaces.contract does not import"
fi

echo "== Gazebo =="
if command -v gz >/dev/null 2>&1; then
    ok "gz found: $(gz sim --versions 2>/dev/null | tail -1)"
    # Renderer check: llvmpipe == software rendering (slow camera).
    renderer=""
    for c in glxinfo eglinfo; do
        if command -v "$c" >/dev/null 2>&1; then
            renderer="$("$c" -B 2>/dev/null | grep -iE 'renderer|device' | head -1)"
            [[ -n "$renderer" ]] && break
        fi
    done
    if [[ "$renderer" == *llvmpipe* || "$renderer" == *softpipe* ]]; then
        warn "software GL renderer detected: $renderer  (camera/sensors will be slow)"
    elif [[ -n "$renderer" ]]; then
        ok "GL renderer: $renderer"
    else
        warn "could not determine GL renderer (install mesa-utils for glxinfo)"
    fi
else
    warn "gz not found - install Gazebo Harmonic (see docs/setup-linux.md)"
fi

echo "== Camera streaming =="
if command -v gst-inspect-1.0 >/dev/null 2>&1; then
    if gst-inspect-1.0 nvh264enc >/dev/null 2>&1; then ok "nvh264enc available (hardware encoding)"; else warn "nvh264enc not found (will use software x264)"; fi
else
    warn "gst-inspect-1.0 not found (gstreamer tools missing)"
fi
if command -v ss >/dev/null 2>&1; then
    if ss -lun 2>/dev/null | grep -q ':5600 '; then warn "udp :5600 already in use"; else ok "udp :5600 free"; fi
fi

echo
echo "Doctor finished."
