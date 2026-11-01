#!/usr/bin/env bash
# Agente: OpenAI Codex CLI (installer oficial).
# Subcomandos: install (build) | init (arranque, idempotente) | bin
set -Eeuo pipefail

INSTALL_URL="https://chatgpt.com/codex/install.sh"
KEY="cli_auth_credentials_store"
PACKAGES_HOME="/opt/codex"

install_agent() {
  local tmp
  tmp="$(mktemp)"
  # shellcheck disable=SC2064  # se expande ahora a propósito: tmp es local
  trap "rm -f '$tmp'" EXIT
  curl -fsSL "$INSTALL_URL" -o "$tmp"
  # El installer guarda los paquetes en $CODEX_HOME/packages (default ~/.codex)
  # y enlaza ~/.local/bin/codex hacia ahí. ~/.codex es un volumen y taparía el
  # binario, así que los paquetes van fuera; config y auth siguen en ~/.codex.
  CODEX_HOME="$PACKAGES_HOME" bash "$tmp"
  hash -r
  codex --version
}

# Escribir la config en build no sirve: el volumen ~/.codex la tapa.
# Por eso se asegura en cada arranque, solo si codex está instalado.
init_agent() {
  command -v codex >/dev/null 2>&1 || return 0

  local dir="$HOME/.codex"
  local cfg="$dir/config.toml"
  local tmp

  mkdir -p "$dir"

  if [[ ! -s "$cfg" ]]; then
    printf '%s = "file"\n' "$KEY" > "$cfg"
    return 0
  fi

  if grep -Eq "^[[:space:]]*${KEY}[[:space:]]*=" "$cfg"; then
    return 0
  fi

  # Las claves de nivel superior deben ir antes de cualquier [tabla]:
  # por eso se antepone en vez de agregar al final.
  tmp="$(mktemp "$dir/.config.toml.XXXXXX")"
  # shellcheck disable=SC2064  # se expande ahora a propósito: tmp es local
  trap "rm -f '$tmp'" EXIT
  { printf '%s = "file"\n' "$KEY"; cat "$cfg"; } > "$tmp"
  mv -f "$tmp" "$cfg"
}

case "${1:-}" in
  install) install_agent ;;
  init) init_agent ;;
  bin) echo "codex" ;;
  *) echo "uso: ${0##*/} install|init|bin" >&2; exit 2 ;;
esac
