#!/usr/bin/env bash
# Dispatcher de build: instala los agentes listados en AGENTS.
# Valida TODOS los nombres antes de instalar cualquiera.
# Uso: AGENTS="claude,codex" install-agents.sh   (o: install-agents.sh "claude,codex")
set -Eeuo pipefail

AGENTS_DIR="${AI_SANDBOX_AGENTS_DIR:-/opt/ai-sandbox/agents}"
RAW="${1:-${AGENTS:-}}"

# Rutas persistidas por volúmenes: un binario ahí quedaría tapado en runtime.
PERSISTED=(
  "$HOME/.claude"
  "$HOME/.codex"
  "$HOME/.config/opencode"
  "$HOME/.local/share/opencode"
)

available() {
  local f names=()
  for f in "$AGENTS_DIR"/*.sh; do
    [[ -e "$f" ]] || continue
    f="${f##*/}"
    names+=("${f%.sh}")
  done
  local out="" n
  for n in "${names[@]}"; do out+="${out:+, }$n"; done
  echo "$out"
}

fail_unknown() {
  echo "ERROR: agente desconocido '$1'. Disponibles: $(available)" >&2
  exit 1
}

# Normaliza: separa por coma, recorta espacios, minúsculas, descarta vacíos y duplicados.
declare -a requested=()
declare -A seen=()
IFS=',' read -r -a parts <<< "$RAW"
for part in "${parts[@]}"; do
  name="${part//[[:space:]]/}"
  name="${name,,}"
  [[ -n "$name" ]] || continue
  [[ -z "${seen[$name]:-}" ]] || continue
  seen[$name]=1
  requested+=("$name")
done

if (( ${#requested[@]} == 0 )); then
  echo "AGENTS vacío: no se instala ningún agente."
  exit 0
fi

# Validación previa: regex (evita path traversal) + existencia del script.
for name in "${requested[@]}"; do
  [[ "$name" =~ ^[a-z0-9-]+$ ]] || fail_unknown "$name"
  [[ -f "$AGENTS_DIR/$name.sh" ]] || fail_unknown "$name"
done

for name in "${requested[@]}"; do
  script="$AGENTS_DIR/$name.sh"
  echo "==> Instalando agente: $name"
  bash "$script" install

  hash -r
  bin_name="$(bash "$script" bin)"
  bin_path="$(command -v "$bin_name" || true)"
  if [[ -z "$bin_path" ]]; then
    echo "ERROR: '$bin_name' no quedó en el PATH tras instalar '$name'." >&2
    exit 1
  fi
  real="$(readlink -f "$bin_path")"
  for dir in "${PERSISTED[@]}"; do
    if [[ "$real" == "$dir" || "$real" == "$dir"/* ]]; then
      echo "ERROR: '$bin_name' se instaló en '$real', ruta tapada por un volumen persistente." >&2
      exit 1
    fi
  done
done
