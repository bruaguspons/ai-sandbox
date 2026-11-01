#!/usr/bin/env bash
# postStartCommand: actualiza devsync, tools y fjm e informa versiones de los agentes
# presentes. Siempre sale con 0: un agente ausente no es un error.
set -uo pipefail

AGENTS_DIR="${AI_SANDBOX_AGENTS_DIR:-/opt/ai-sandbox/agents}"

# Re-ejecuta el instalador de un CLI para actualizarlo. Un fallo solo avisa.
update_tool() {
  local name="$1" url="$2"
  shift 2
  if ! curl -fsSL "$url" | bash -s -- "$@"; then
    echo "WARN: no se pudo actualizar $name (se ignora)." >&2
  fi
}

update_tool devsync https://raw.githubusercontent.com/bruaguspons/devsync/main/install.sh
update_tool tools https://raw.githubusercontent.com/bruaguspons/tools/main/install.sh
update_tool fjm https://raw.githubusercontent.com/bruaguspons/fjm/main/.ci/install.sh --skip-shell

for script in "$AGENTS_DIR"/*.sh; do
  [[ -e "$script" ]] || continue
  bin_name="$(bash "$script" bin 2>/dev/null)" || continue
  if command -v "$bin_name" >/dev/null 2>&1; then
    echo "$bin_name: $("$bin_name" --version 2>&1 | head -n1)"
  fi
done

exit 0
