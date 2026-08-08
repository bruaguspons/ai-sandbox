# claude-docker

Entorno de desarrollo containerizado para usar **Claude Code** desde Docker + Dev Containers. Incluye Node.js, Python, Go, Bun y herramientas de red/sistema preinstaladas. La configuración de Claude Code persiste entre rebuilds del container.

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (o Docker Engine en Linux)
- [VS Code](https://code.visualstudio.com/) con la extensión [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Cuenta de Anthropic con acceso a Claude Code
- **En Windows: WSL2 con una distro real (Ubuntu) + integración de Docker Desktop habilitada.** Ver la sección de abajo — no es opcional en la práctica.

---

## ⚠️ Windows: cloná el proyecto DENTRO de WSL2 (sumamente recomendado)

Si estás en Windows, **cloná este repo dentro del filesystem de la distro WSL (`~/`), no en `C:\`**. Esto es lo más importante de todo el setup.

### Por qué

Cuando Docker Desktop (backend WSL2) monta una ruta de Windows como `C:\...\claude-docker\workspaces`, lo hace a través de **9p**, un filesystem de red que es brutalmente lento para el patrón de muchos archivos chicos que usan `tsc`, `vitest`, `pnpm`, `eslint`, etc. Medido sobre un proyecto real: la misma suite de checks tarda **~5 min 33 s sobre 9p contra ~37 s sobre el filesystem nativo de Linux (ext4)** — cerca de **9x más rápido**. En lecturas puras de archivos la diferencia llega a **75x**.

No es problema de las herramientas: cambiarlas no arregla nada porque todas se sientan sobre el mismo mount. Lo que arregla es **mover el árbol al filesystem de Linux**.

Como en este proyecto el `docker-compose.yml` usa rutas **relativas** (`./workspaces`, `context: .`), no hace falta editar ningún archivo: alcanza con clonar todo el repo dentro de WSL y abrirlo desde ahí. Las rutas resuelven solas contra ext4.

### Opción rápida: `run-wsl.bat`

En la raíz del repo hay un script **`run-wsl.bat`** que automatiza casi todo el setup en Windows. Corrélo con doble clic o desde `cmd`/PowerShell y hace:

1. Verifica que WSL esté disponible; si falta la distro, la instala (`wsl --install -d Ubuntu`).
2. Verifica `git` dentro de la distro y lo instala si hace falta.
3. Chequea que `docker` esté disponible dentro de WSL.
4. Clona el repo en `~/claude-docker` (ext4).
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
   git clone https://github.com/bruaguspons/claude-docker.git
   cd claude-docker
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
\\wsl.localhost\Ubuntu\home\<tu-usuario>\claude-docker
```
Pero para trabajar conviene **siempre** VS Code con Remote-WSL (`code .` desde la distro): entrar por la ruta UNC reintroduce una capa de acceso lenta.

---

## Inicio rápido

> **Windows:** seguí primero la sección de WSL2 de arriba (o corré `run-wsl.bat`) y cloná el repo dentro de la distro. Los pasos siguientes asumen que ya estás parado en el proyecto (en Linux/WSL o en macOS).

### Con VS Code (recomendado)

1. Clonar el repositorio:
   ```bash
   git clone <repo-url>
   cd claude-docker
   ```

2. Abrir en VS Code:
   ```bash
   code .
   ```

3. Cuando VS Code detecte el devcontainer, hacer clic en **"Reopen in Container"**.

4. La primera vez construye la imagen (~2-3 min). Las siguientes son instantáneas.

5. Dentro del container, autenticarse en Claude Code:
   ```bash
   claude
   ```

### Solo con Docker Compose (sin VS Code)

```bash
# Construir e iniciar el container
docker compose up -d

# Abrir una shell dentro del container
docker compose exec devcontainer bash

# Autenticarse en Claude Code
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

# Detener y eliminar volúmenes (¡borra configuración de Claude!)
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

# Ver volúmenes creados por este proyecto
docker volume ls | grep claude-docker

# Eliminar solo el volumen de configuración de Claude
docker volume rm claude-docker_claude-config

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

# Verificar que Claude Code está disponible
docker compose exec devcontainer claude --version

# En Windows/WSL: confirmar que /workspaces NO está sobre 9p
docker compose exec devcontainer findmnt -T /workspaces -o TARGET,SOURCE,FSTYPE
```

---

## Estructura del proyecto

```
claude-docker/
├── .devcontainer/
│   ├── Dockerfile          # Imagen base Ubuntu 24.04 + herramientas
│   └── devcontainer.json   # Config de VS Code (extensiones, puertos, settings)
├── docker-compose.yml      # Servicio, volúmenes y capacidades del container
├── run-wsl.bat             # Bootstrap Windows: setup WSL2 + clona el repo + abre VS Code
├── workspaces/             # Directorio para clonar proyectos (ignorado por git)
└── README.md
```

### Volúmenes persistentes

| Volumen | Ruta en container | Propósito |
|---------|-------------------|-----------|
| `claude-config` | `/root/.claude` | Configuración, memoria y autenticación de Claude Code |
| `shell-history` | `/root/.shell_history` | Historial de bash/zsh |

> La configuración de Claude Code **sobrevive rebuilds** gracias al volumen `claude-config`. Solo se pierde si ejecutás `docker compose down -v`.

---

## Herramientas incluidas

| Herramienta | Versión | Uso |
|-------------|---------|-----|
| Claude Code | latest | IA asistente de código |
| Node.js | LTS (vía nvm) | JavaScript/TypeScript |
| Bun | latest | Runtime JS alternativo + package manager |
| Go | sistema | Desarrollo en Go |
| Python 3 | sistema | Scripts y automatización |
| ripgrep | sistema | Búsqueda rápida en código |
| fd | sistema | Búsqueda de archivos |
| jq | sistema | Procesamiento de JSON |

### Herramientas opcionales (comentadas en Dockerfile)

Descomentar en `.devcontainer/Dockerfile` para habilitar:

- `shellcheck` — validación de scripts de shell
- `yq` — procesamiento de YAML/TOML (como jq para YAML)
- `sd` — reemplazo moderno de sed
- `difftastic` — diff estructural por AST
- `ast-grep` — búsqueda y refactor por patrones de AST
- `scc` — contador de líneas de código por lenguaje
- `hyperfine` — benchmarking de comandos
- `watchexec` — ejecutar comandos al detectar cambios

---

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

El directorio `workspaces/` está pensado para clonar proyectos en los que trabajar con Claude Code. Su contenido está ignorado por git — cada desarrollador mantiene sus propios proyectos localmente.

```bash
cd workspaces/
git clone <mi-proyecto>
cd mi-proyecto
claude
```

> **Windows:** cloná tus proyectos acá dentro **estando en WSL** (el repo completo vive en `~/claude-docker` en la distro). Si el árbol está sobre 9p, cada `pnpm install`, `typecheck` y `test` se vuelve varias veces más lento.