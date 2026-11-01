FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# ─── Dependencias del sistema ────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    # base
    git \
    curl \
    wget \
    sudo \
    ca-certificates \
    unzip \
    xz-utils \
    # shell / navegación
    zsh \
    bash-completion \
    # búsqueda y texto
    ripgrep \
    fd-find \
    jq \
    tree \
    # lenguajes
    python3 \
    python3-pip \
    golang-go \
    # herramientas de red / puertos
    iproute2 \
    net-tools \
    netcat-openbsd \
    lsof \
    iputils-ping \
    dnsutils \
    # proceso / sistema
    procps \
    htop \
    strace \
    # build tools (necesarios para compilar algunos paquetes npm nativos)
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# ─── mise: runtime que devsync usa para instalar/gestionar versiones de CLIs ──
ENV PATH="/root/.local/bin:/root/.local/share/mise/shims:$PATH"
RUN curl -fsSL https://mise.run | sh

# ─── devsync (github.com/bruaguspons/devsync): instala el binario publicado
# y aplica, en modo no interactivo, los tools/skills declarados en su propio
# mise.toml/skills/ — misma lógica que el sync en runtime (ver README), sin
# duplicarla acá. ──────────────────────────────────────────────────────────
RUN curl -fsSL https://raw.githubusercontent.com/bruaguspons/devsync/main/install.sh | bash \
    && devsync -yes

# ─── tools y fjm (github.com/bruaguspons/{tools,fjm}): CLIs preinstalados.
# fjm va con --skip-shell: en el build $SHELL no está seteado y su
# instalador falla; la integración con la shell se agrega más abajo.
# `test -x` hace fallar el build si un instalador falló en silencio. ─────────
ENV PATH="/root/.local/share/fjm:$PATH"
RUN curl -fsSL https://raw.githubusercontent.com/bruaguspons/tools/main/install.sh | bash \
    && curl -fsSL https://raw.githubusercontent.com/bruaguspons/fjm/main/.ci/install.sh | bash -s -- --skip-shell \
    && test -x /root/.local/bin/tools \
    && test -x /root/.local/share/fjm/fjm

# ─── Agentes de IA (opt-in) ──────────────────────────────────────────────────
# Van DESPUÉS de devsync para que cambiar AGENTS no invalide las capas de
# apt/mise/devsync. Vacío por defecto: no se instala ningún agente.
# Soportados: ver .devcontainer/agents/*.sh
COPY .devcontainer/agents/ /opt/ai-sandbox/agents/
COPY .devcontainer/scripts/install-agents.sh /usr/local/bin/ai-sandbox-install-agents
COPY .devcontainer/scripts/entrypoint.sh /usr/local/bin/ai-sandbox-entrypoint
COPY .devcontainer/scripts/post-start.sh /usr/local/bin/ai-sandbox-post-start
ENV PATH="/root/.opencode/bin:$PATH"
ARG AGENTS=""
RUN chmod +x /opt/ai-sandbox/agents/*.sh /usr/local/bin/ai-sandbox-* \
    && ai-sandbox-install-agents

# PATH también para shells de login (docker exec -l, tareas de VS Code)
RUN printf '%s\n' 'export PATH="/root/.local/bin:/root/.local/share/fjm:/root/.opencode/bin:$PATH"' \
    > /etc/profile.d/ai-sandbox-path.sh

# Activación en shells interactivas (completions + auto-reshim)
RUN echo 'eval "$(mise activate bash)"' >> /root/.bashrc \
    && echo 'eval "$(mise activate zsh)"'  >> /root/.zshrc \
    && echo 'if command -v fjm >/dev/null 2>&1; then eval "$(fjm env --use-on-cd --shell bash)"; fi' >> /root/.bashrc \
    && echo 'if command -v fjm >/dev/null 2>&1; then eval "$(fjm env --use-on-cd --shell zsh)"; fi' >> /root/.zshrc

WORKDIR /root

USER root

ENTRYPOINT ["ai-sandbox-entrypoint"]
CMD ["sleep", "infinity"]
