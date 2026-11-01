#!/usr/bin/env bash
# ============================================================
#  ai-sandbox :: bootstrap Linux/macOS
#  Clona el repo y abre VS Code. No hace falta WSL: el filesystem
#  nativo de Linux/macOS ya es ext4/APFS, sin el problema de 9p
#  que sufre Windows.
#
#  Este script es un bootstrap: puede vivir en cualquier lado
#  (no necesita el repo clonado de antemano). Ejecutalo con:
#    bash run.sh [--name <nombre>]
#
#  --name define el directorio (~/<nombre>) y el nombre de la
#  instancia (container + volúmenes de persistencia). Permite
#  tener varias instancias aisladas. Default: ai-sandbox.
# ============================================================
set -euo pipefail

# ---- Config (editá si hace falta) ---------------------------
TARGET_DIR="ai-sandbox"
REPO_URL="https://github.com/bruaguspons/ai-sandbox.git"
# ---------------------------------------------------------------

while [ $# -gt 0 ]; do
  case "$1" in
    -n|--name)
      [ $# -ge 2 ] || { echo "[ERROR] Falta el valor de $1."; exit 1; }
      TARGET_DIR="$2"; shift 2 ;;
    -h|--help)
      echo "Uso: bash run.sh [--name <nombre>]"; exit 0 ;;
    *)
      echo "[ERROR] Argumento desconocido: $1"; exit 1 ;;
  esac
done

# Debe ser un nombre de proyecto Compose válido
if ! [[ "$TARGET_DIR" =~ ^[a-z0-9][a-z0-9_-]*$ ]]; then
  echo "[ERROR] Nombre inválido: '$TARGET_DIR'. Usá [a-z0-9_-], empezando con letra o dígito."
  exit 1
fi

echo
echo "=== ai-sandbox :: setup Linux/macOS ==="
echo

# ---- 1. git -----------------------------------------------
echo "[1/4] Verificando git..."
if ! command -v git >/dev/null 2>&1; then
  echo "[ERROR] No se encontró 'git'. Instalalo y reintentá."
  echo "        Debian/Ubuntu: sudo apt-get install -y git"
  echo "        macOS:         brew install git"
  exit 1
fi
echo "      OK."

# ---- 2. docker ----------------------------------------------
echo "[2/4] Verificando docker..."
if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] No se encontró 'docker'. Instalá Docker Desktop o Docker Engine y reintentá."
  echo "        https://docs.docker.com/engine/install/"
  exit 1
fi
echo "      OK."

# ---- 3. Clonar el repo en el home ($HOME) --------------------
echo "[3/4] Clonando repo en ~/${TARGET_DIR} ..."
if [ -d "$HOME/${TARGET_DIR}" ]; then
  echo "      Ya existe, salteando clone."
else
  git clone "$REPO_URL" "$HOME/${TARGET_DIR}"
  rm -rf "$HOME/${TARGET_DIR}/.git"
  echo "      .git eliminado (proyecto desvinculado del remoto)."
fi

# Persistir el nombre de la instancia en .env (lo lee docker compose)
ENV_FILE="$HOME/${TARGET_DIR}/.env"
if [ ! -f "$ENV_FILE" ]; then
  cp "$HOME/${TARGET_DIR}/.env.example" "$ENV_FILE" 2>/dev/null || : > "$ENV_FILE"
fi
{ grep -v '^SANDBOX_NAME=' "$ENV_FILE" || true; echo "SANDBOX_NAME=${TARGET_DIR}"; } > "$ENV_FILE.tmp"
mv "$ENV_FILE.tmp" "$ENV_FILE"
echo "      Instancia: ${TARGET_DIR} (SANDBOX_NAME en .env)."

# ---- 4. Abrir VS Code -----------------------------------------
echo "[4/4] Abriendo VS Code..."
if command -v code >/dev/null 2>&1; then
  code "$HOME/${TARGET_DIR}"
else
  echo "[!] No encontré 'code' en el PATH."
  echo "    Instalá VS Code (con la opción 'Shell Command: Install code command in PATH'"
  echo "    desde la Command Palette) o abrí la carpeta a mano:"
  echo "      $HOME/${TARGET_DIR}"
fi

echo
echo "Casi listo. Último paso (manual, en VS Code):"
echo "  Cuando VS Code abra la carpeta, aceptá \"Reopen in Container\"."
echo
echo "Listo."
