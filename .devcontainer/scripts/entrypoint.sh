#!/usr/bin/env bash
# Entrypoint: reconcilia el estado de cada agente (init) y delega en el CMD.
# Un fallo de init nunca debe impedir que el container arranque.
set -uo pipefail

AGENTS_DIR="${AI_SANDBOX_AGENTS_DIR:-/opt/ai-sandbox/agents}"

for script in "$AGENTS_DIR"/*.sh; do
  [[ -e "$script" ]] || continue
  bash "$script" init || echo "WARN: falló init de '${script##*/}' (se ignora)." >&2
done

exec "$@"
