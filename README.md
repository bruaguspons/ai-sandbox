# ai-sandbox

Sandbox de desarrollo containerizado (Docker + Dev Containers) para trabajar con agentes de IA de terminal: **Claude Code**, **Codex** y **OpenCode**. Vos elegís cuáles instalar; por defecto no se instala ninguno. Incluye Python, Go y herramientas de red/sistema, y los runtimes (Node, Bun, pnpm, Rust) llegan vía `devsync`. La configuración y el login de cada agente persisten entre rebuilds.

## Agentes de IA

Se eligen con la variable `AGENTS` (lista separada por comas) al construir la imagen. Se toma del entorno o de un archivo `.env`:

```bash
cp .env.example .env     # editá AGENTS=...
docker compose up -d --build
```

| Agente | Valor en `AGENTS` | Login |
|--------|-------------------|-------|
| Claude Code | `claude` | `claude` y seguí el flujo del navegador |
| Codex | `codex` | `codex login --device-auth`, o abrí el link con el puerto `localhost:1455` redirigido, o exportá `OPENAI_API_KEY` |
| OpenCode | `opencode` | `opencode auth login` |

- `AGENTS=` (vacío) construye un container completo, sin agentes. Para el comportamiento anterior del repo: `AGENTS=claude`.
- Se toleran espacios y mayúsculas (`" Claude, codex,"`). Un nombre desconocido falla el build y lista los disponibles.
- Se instala siempre la última versión de cada agente (sin pinning), por lo que el build necesita red.
- Cambiar `AGENTS` solo reconstruye la capa de agentes; apt y `devsync` quedan en caché.

### Agregar un agente

1. Crear `.devcontainer/agents/<nombre>.sh` con los subcomandos `install`, `init` (idempotente, no fatal) y `bin` (nombre del binario). Usá `claude.sh` como modelo.
2. Si guarda estado, agregar sus volúmenes en `docker-compose.yml`.
3. Agregar una fila a la tabla de arriba y a `.env.example`.

El binario no puede instalarse bajo una ruta persistida por volumen (el build lo verifica), porque el volumen lo taparía.

### Notas

- **Skills de `devsync`**: se instalan solo para Claude Code; Codex y OpenCode no las reciben.
- **VS Code**: se incluyen las extensiones de Claude Code y Codex. OpenCode no tiene extensión con ID verificado y se usa desde la terminal.
- **Migración desde `claude-docker`**: el proyecto de Compose pasó a llamarse `ai-sandbox`, así que los volúmenes nuevos empiezan vacíos y hay que volver a loguearse. El volumen viejo `claude-docker_claude-config` queda huérfano (no se migra ni se borra); eliminalo con `docker volume rm claude-docker_claude-config` cuando ya no lo necesites.

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (o Docker Engine en Linux)
- [VS Code](https://code.visualstudio.com/) con la extensión [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Cuenta del agente que elijas (Anthropic, OpenAI u otro proveedor de OpenCode)
- **En Windows: WSL2 con una distro real (Ubuntu) + integración de Docker Desktop habilitada.** Ver la sección de abajo — no es opcional en la práctica.

---

## ⚠️ Windows: cloná el proyecto DENTRO de WSL2 (sumamente recomendado)

Si estás en Windows, **cloná este repo dentro del filesystem de la distro WSL (`~/`), no en `C:\`**. Esto es lo más importante de todo el setup.

### Por qué

Cuando Docker Desktop (backend WSL2) monta una ruta de Windows como `C:\...\ai-sandbox\workspaces`, lo hace a través de **9p**, un filesystem de red que es brutalmente lento para el patrón de muchos archivos chicos que usan `tsc`, `vitest`, `pnpm`, `eslint`, etc. Medido sobre un proyecto real: la misma suite de checks tarda **~5 min 33 s sobre 9p contra ~37 s sobre el filesystem nativo de Linux (ext4)** — cerca de **9x más rápido**. En lecturas puras de archivos la diferencia llega a **75x**.

No es problema de las herramientas: cambiarlas no arregla nada porque todas se sientan sobre el mismo mount. Lo que arregla es **mover el árbol al filesystem de Linux**.

Como en este proyecto el `docker-compose.yml` usa rutas **relativas** (`./workspaces`, `context: .`), no hace falta editar ningún archivo: alcanza con clonar todo el repo dentro de WSL y abrirlo desde ahí. Las rutas resuelven solas contra ext4.

### Opción rápida: `run-wsl.bat`

En la raíz del repo hay un script **`run-wsl.bat`** que automatiza casi todo el setup en Windows. Corrélo con doble clic o desde `cmd`/PowerShell y hace:

1. Verifica que WSL esté disponible; si falta la distro, la instala (`wsl --install -d Ubuntu`).
2. Verifica `git` dentro de la distro y lo instala si hace falta.
3. Chequea que `docker` esté disponible dentro de WSL.
4. Clona el repo en `~/ai-sandbox` (ext4).
5. Abre VS Code conectado a WSL apuntando a esa carpeta.

Los **dos pasos que no puede automatizar** (son de interfaz gráfica) quedan a tu cargo, y el script se frena y te avisa cuándo:

- Habilitar **WSL Integration** en Docker Desktop (Settings → Resources → WSL Integration).
- Aceptar **"Reopen in Container"** en VS Code.

Si preferís hacerlo a mano —o entender qué hace cada paso— seguí las instrucciones de abajo.

### Pasos (manual)

1. **Instalar una distro WSL** (PowerShell, una sola vez):
   ```powershell
   wsl --install -d Ubuntu
   ```
   Verificá que quedó instalada:
   ```powershell
   wsl -l -v
   ```

2. **Habilitar la integración en Docker Desktop:**
   Settings → Resources → **WSL Integration** → activá el toggle de tu distro (Ubuntu). Sin esto, `docker` no está disponible adentro de la distro.

3. **Entrar a la distro:**
   ```powershell
   wsl -d Ubuntu
   ```

4. **Clonar el repo dentro del filesystem de Linux** (en tu home, NO en `/mnt/c`):
   ```bash
   cd ~
   git clone https://github.com/bruaguspons/ai-sandbox.git
   cd ai-sandbox
   ```

5. **Abrir VS Code conectado a WSL** (desde adentro de la distro):
   ```bash
   code .
   ```
   Esto levanta VS Code usando la extensión **Remote - WSL**, con el proyecto viviendo en Linux.

6. **Reopen in Container** cuando VS Code lo ofrezca. La Dev Containers corre el compose desde el contexto WSL y el mount queda sobre ext4.

7. **Verificar que NO estás sobre 9p** (dentro del container):
   ```bash
   findmnt -T /workspaces -o TARGET,SOURCE,FSTYPE
   ```
   El `FSTYPE` **no** debe decir `9p`. Si dice `9p`, abriste el proyecto desde el lado Windows — cerrá y repetí desde el paso 5.

> **NO clones en `/mnt/c/...`.** Esa ruta es el filesystem de Windows visto desde WSL: sigue siendo 9p y no ganás nada. El árbol tiene que estar en `~/` (o cualquier ruta nativa de la distro).

### Editar desde Windows

El proyecto es accesible desde el Explorador y desde VS Code de Windows en:
```
\\wsl.localhost\Ubuntu\home\<tu-usuario>\ai-sandbox
```
Pero para trabajar conviene **siempre** VS Code con Remote-WSL (`code .` desde la distro): entrar por la ruta UNC reintroduce una capa de acceso lenta.

---

## Inicio rápido

### Scripts de bootstrap (recomendado)

Estos scripts viven en la raíz del repo y son autocontenidos: no hace falta tener el repo clonado antes de correrlos. Clonan (si no existe ya) y abren VS Code — el único paso manual que queda es aceptar **"Reopen in Container"**.

| Script | Plataforma | Qué hace |
|--------|------------|----------|
| `run-wsl.bat` | Windows (recomendado) | Instala/verifica WSL2 + Ubuntu, clona el repo **dentro de la distro** (`~/ai-sandbox`, ext4) y abre VS Code con Remote-WSL. Evita el problema de 9p — ver sección de arriba. |
| `run.bat` | Windows sin WSL | Clona el repo directo en `%USERPROFILE%\ai-sandbox` (filesystem de Windows) y abre VS Code. Más simple, pero el mount de `workspaces/` queda sobre 9p — no recomendado para proyectos grandes. |
| `run.sh` | Linux / macOS | Clona el repo en `~/ai-sandbox` y abre VS Code. No aplica el problema de 9p (ext4/APFS nativos). |

Los tres verifican `git`/`docker` antes de clonar, y si el repo ya existe en destino, saltean el clone.

#### Varias instancias: `--name`

Los tres aceptan `--name <nombre>` (o `-n`). Ese nombre se usa como directorio de clone (`~/<nombre>`) y se escribe como `SANDBOX_NAME` en el `.env`, que define el nombre del proyecto Compose: el container queda como `<nombre>-devcontainer-1` y los volúmenes de persistencia como `<nombre>_claude-config`, `<nombre>_shell-history`, etc. Así podés tener instancias con login, config e historial aislados.

```bash
bash run.sh --name trabajo      # Linux/macOS
run-wsl.bat --name trabajo      # Windows (WSL)
```

Sin `--name` se usa `ai-sandbox` (comportamiento anterior, mismos volúmenes). Nombre válido: `[a-z0-9_-]`, empezando con letra o dígito. Sin los scripts, setealo a mano en `.env` (`SANDBOX_NAME=trabajo`).

> **Windows:** si preferís no usar `run-wsl.bat`, seguí primero la sección de WSL2 de arriba y cloná el repo dentro de la distro. Los pasos manuales de abajo asumen que ya estás parado en el proyecto (en Linux/WSL o en macOS).

### Con VS Code (recomendado)

1. Clonar el repositorio:
   ```bash
   git clone <repo-url>
   cd ai-sandbox
   ```

2. Abrir en VS Code:
   ```bash
   code .
   ```

3. Cuando VS Code detecte el devcontainer, hacer clic en **"Reopen in Container"**.

4. La primera vez construye la imagen (~2-3 min). Las siguientes son instantáneas.

5. Dentro del container, autenticarse en el agente elegido (ver tabla de arriba), por ejemplo `claude`.

### Solo con Docker Compose (sin VS Code)

```bash
# Construir e iniciar el container
docker compose up -d

# Abrir una shell dentro del container
docker compose exec devcontainer bash

# Autenticarse en el agente elegido (ejemplo)
claude
```

---

## Comandos útiles

### Gestión del container

```bash
# Iniciar el container en segundo plano
docker compose up -d

# Ver logs del container
docker compose logs -f

# Abrir una shell interactiva
docker compose exec devcontainer bash

# Detener el container
docker compose down

# Detener y eliminar volúmenes (¡borra el login de todos los agentes!)
docker compose down -v
```

### Rebuilds

```bash
# Reconstruir la imagen (sin cache)
docker compose build --no-cache

# Reconstruir e iniciar
docker compose up -d --build

# Desde VS Code: Ctrl+Shift+P → "Dev Containers: Rebuild Container"
```

### Limpieza

```bash
# Eliminar imágenes huérfanas
docker image prune

# Ver volúmenes creados por este proyecto (o por tu SANDBOX_NAME)
docker volume ls | grep ai-sandbox

# Eliminar solo el volumen de configuración de Claude
docker volume rm ai-sandbox_claude-config

# Limpieza general del sistema Docker
docker system prune
```

### Debug y diagnóstico

```bash
# Ver procesos dentro del container
docker compose exec devcontainer ps aux

# Ver uso de recursos
docker stats

# Inspeccionar la red del container
docker compose exec devcontainer ss -tlnp

# Verificar un agente instalado
docker compose exec devcontainer claude --version

# En Windows/WSL: confirmar que /workspaces NO está sobre 9p
docker compose exec devcontainer findmnt -T /workspaces -o TARGET,SOURCE,FSTYPE
```

---

## Estructura del proyecto

```
ai-sandbox/
├── .devcontainer/
│   ├── Dockerfile          # Imagen base Ubuntu 24.04 + herramientas + agentes (AGENTS)
│   ├── devcontainer.json   # Config de VS Code (extensiones, puertos, settings)
│   ├── agents/             # Un script por agente: install | init | bin
│   └── scripts/            # install-agents (build), entrypoint, post-start
├── docker-compose.yml      # Servicio, volúmenes y capacidades del container
├── .env.example            # Plantilla de AGENTS, SANDBOX_NAME (copiar a .env)
├── run.sh                  # Bootstrap Linux/macOS: clona el repo + abre VS Code
├── run.bat                 # Bootstrap Windows sin WSL: clona el repo + abre VS Code
├── run-wsl.bat             # Bootstrap Windows: setup WSL2 + clona el repo + abre VS Code
├── workspaces/             # Directorio para clonar proyectos (ignorado por git)
└── README.md
```

### Volúmenes persistentes

| Volumen | Ruta en container | Propósito |
|---------|-------------------|-----------|
| `claude-config` | `/root/.claude` | Configuración, memoria y login de Claude Code (incluye `.claude.json`, enlazado desde `~/.claude.json`) |
| `codex-config` | `/root/.codex` | Configuración y login de Codex |
| `opencode-config` / `opencode-data` | `/root/.config/opencode`, `/root/.local/share/opencode` | Configuración y credenciales de OpenCode |
| `shell-history` | `/root/.shell_history` | Historial de bash/zsh |

> La configuración de los agentes **sobrevive rebuilds** gracias a estos volúmenes. Solo se pierde si ejecutás `docker compose down -v`.

---

## Herramientas incluidas

Instaladas directo por el Dockerfile (apt), independientes de `devsync`. Los agentes de IA son opt-in (ver arriba):

| Herramienta | Versión | Uso |
|-------------|---------|-----|
| Go | sistema | Desarrollo en Go |
| Python 3 | sistema | Scripts y automatización |
| ripgrep | sistema | Búsqueda rápida en código |
| fd | sistema | Búsqueda de archivos |
| jq | sistema | Procesamiento de JSON |

El resto (Node.js, Bun, pnpm, Rust, y CLIs como `yq`/`sd`/`difftastic`/`ast-grep`/`scc`/`hyperfine`/`watchexec`) se instalan vía `devsync` a partir del `mise.toml` de [`bruaguspons/devsync`](https://github.com/bruaguspons/devsync) — ver la sección de arriba. Para agregar o actualizar una versión, el cambio va ahí, no en este repo.

---

## Herramientas y skills (`devsync`)

Este repo **no declara** sus propios tools ni skills — eso vive en [`bruaguspons/devsync`](https://github.com/bruaguspons/devsync), un proyecto Go separado (extraído de acá) que expone un CLI, `devsync`, con su propio `mise.toml` y `skills/` como fuente de verdad. `ai-sandbox` solo lo consume:

- **Build de la imagen**: el Dockerfile instala el binario publicado y lo corre en modo no interactivo:
  ```bash
  curl -fsSL https://raw.githubusercontent.com/bruaguspons/devsync/main/install.sh | bash
  devsync -yes
  ```
  `-yes` aplica todos los cambios pendientes sin el select/confirm interactivo — necesario porque un `RUN` de Docker no tiene TTY.
- **Container ya corriendo**: `devcontainer.json` → `postStartCommand` (`ai-sandbox-post-start`) corre los instaladores de `devsync`, `tools` y `fjm` en cada arranque, para tener siempre los binarios al día (un fallo solo avisa con un WARN y nunca impide el arranque), e imprime la versión de cada agente instalado (sin agentes sale igual con 0) — pero **no aplica cambios**, solo lo deja instalado. Para sincronizar de verdad lo que se haya agregado después en el `mise.toml`/`skills/` de `devsync` (sin rebuildear la imagen), corré manualmente dentro del container:
  ```bash
  devsync
  ```
  Te muestra un diff combinado `[tool]`/`[skill]` entre el estado local y lo declarado, con selección y confirmación antes de aplicar nada. Si ya está todo al día, no muestra nada para elegir.

Para agregar o cambiar un tool/skill del entorno, el cambio va en el repo `devsync`, no acá.

### CLIs preinstalados

La imagen trae `tools`, `devsync` y `fjm` ([`bruaguspons/tools`](https://github.com/bruaguspons/tools), [`devsync`](https://github.com/bruaguspons/devsync), [`fjm`](https://github.com/bruaguspons/fjm)) instalados en el build, en una capa posterior a devsync (cambiar `AGENTS` no la invalida). `fjm` está en el `PATH` (`/root/.local/share/fjm`) y `.bashrc`/`.zshrc` activan su hook con `fjm env --use-on-cd`. En cada arranque se actualizan los tres; si una actualización falla, solo se avisa.

## Configuración avanzada

### Habilitar Docker-in-Docker

Descomentar en `docker-compose.yml`:
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock
```

### Habilitar caché de paquetes npm/bun

Descomentar en `docker-compose.yml`:
```yaml
volumes:
  - npm-cache:/root/.npm
  - bun-cache:/root/.bun/install/cache
```

### Cambiar a red bridge (aislamiento)

En `docker-compose.yml`, reemplazar:
```yaml
network_mode: host
```
por:
```yaml
ports:
  - "3000:3000"
  - "8080:8080"
```

---

## Uso de `workspaces/`

El directorio `workspaces/` está pensado para clonar proyectos en los que trabajar con tus agentes. Su contenido está ignorado por git — cada desarrollador mantiene sus propios proyectos localmente.

```bash
cd workspaces/
git clone <mi-proyecto>
cd mi-proyecto
claude
```

> **Windows:** cloná tus proyectos acá dentro **estando en WSL** (el repo completo vive en `~/ai-sandbox` en la distro). Si el árbol está sobre 9p, cada `pnpm install`, `typecheck` y `test` se vuelve varias veces más lento.