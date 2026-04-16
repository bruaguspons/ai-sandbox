# claude-docker

Entorno de desarrollo containerizado para usar **Claude Code** desde Docker + Dev Containers. Incluye Node.js, Python, Go, Bun y herramientas de red/sistema preinstaladas. La configuración de Claude Code persiste entre rebuilds del container.

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (o Docker Engine en Linux)
- [VS Code](https://code.visualstudio.com/) con la extensión [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- Cuenta de Anthropic con acceso a Claude Code

## Inicio rápido

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
```

---

## Estructura del proyecto

```
claude-docker/
├── .devcontainer/
│   ├── Dockerfile          # Imagen base Ubuntu 24.04 + herramientas
│   └── devcontainer.json   # Config de VS Code (extensiones, puertos, settings)
├── docker-compose.yml      # Servicio, volúmenes y capacidades del container
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
