#!/usr/bin/env bash
# Agente: Claude Code (installer nativo oficial, se autoactualiza).
# Subcomandos: install (build) | init (arranque, idempotente) | bin
set -Eeuo pipefail

INSTALL_URL="https://claude.ai/install.sh"

install_agent() {
  local tmp
  tmp="$(mktemp)"
  # shellcheck disable=SC2064  # se expande ahora a propósito: tmp es local
  trap "rm -f '$tmp'" EXIT
  # Se descarga completo antes de ejecutar: evita correr un script truncado.
  curl -fsSL "$INSTALL_URL" -o "$tmp"
  bash "$tmp"
  hash -r
  claude --version
}

# ~/.claude.json es un archivo suelto (el volumen cubre solo ~/.claude), por
# eso se persiste dentro del volumen y se enlaza. Se reconcilia en cada
# arranque porque Claude puede reemplazar el link con un rename atómico.
init_agent() {
  command -v claude >/dev/null 2>&1 || return 0

  local link="$HOME/.claude.json"
  local store="$HOME/.claude/.claude.json"

  mkdir -p "$HOME/.claude"

  if [[ -f "$link" && ! -L "$link" ]]; then
    if [[ ! -e "$store" || "$link" -nt "$store" ]]; then
      mv -f "$link" "$store"
    else
      rm -f "$link"
    fi
  fi
  ln -sfn "$store" "$link"
}

case "${1:-}" in
  install) install_agent ;;
  init) init_agent ;;
  bin) echo "claude" ;;
  *) echo "uso: ${0##*/} install|init|bin" >&2; exit 2 ;;
esac
