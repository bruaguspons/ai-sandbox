#!/usr/bin/env bash
# Agente: OpenCode (installer V2). El binario queda en ~/.opencode/bin,
# que el Dockerfile agrega al PATH.
# Subcomandos: install (build) | init (arranque, idempotente) | bin
set -Eeuo pipefail

INSTALL_URL="https://opencode.ai/v2/install"

install_agent() {
  local tmp
  tmp="$(mktemp)"
  # shellcheck disable=SC2064  # se expande ahora a propósito: tmp es local
  trap "rm -f '$tmp'" EXIT
  curl -fsSL "$INSTALL_URL" -o "$tmp"
  bash "$tmp"
  export PATH="$HOME/.opencode/bin:$PATH"
  hash -r
  opencode --version
}

# Sin estado que reconciliar al arrancar.
init_agent() { :; }

case "${1:-}" in
  install) install_agent ;;
  init) init_agent ;;
  bin) echo "opencode" ;;
  *) echo "uso: ${0##*/} install|init|bin" >&2; exit 2 ;;
esac
