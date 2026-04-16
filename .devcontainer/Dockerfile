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
    # build tools (necesarios para compilar algunos paquetes npm)
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# ─── CLI tools recomendadas para Claude Code ─────────────────────────────────
# shellcheck  — valida scripts de shell generados por IA
# yq          — como jq pero para YAML/TOML/XML (docker-compose, k8s, etc.)
# sd          — reemplazo moderno de sed con regex PCRE
# difftastic  — diff estructural por AST (no por líneas)
# ast-grep    — búsqueda y refactor por patrones de AST
# scc         — cuenta líneas de código por lenguaje
# hyperfine   — benchmarking de comandos con estadísticas
# watchexec   — ejecuta comandos al detectar cambios en archivos
# RUN apt-get update && apt-get install -y shellcheck \
#     && rm -rf /var/lib/apt/lists/*

# RUN wget -qO /usr/local/bin/yq \
#     https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
#     && chmod +x /usr/local/bin/yq

# RUN curl -fsSL https://github.com/chmln/sd/releases/latest/download/sd-x86_64-unknown-linux-musl.tar.gz \
#     | tar xz --wildcards --strip-components=1 -C /usr/local/bin '*/sd' \
#     && chmod +x /usr/local/bin/sd

# RUN curl -fsSL https://github.com/Wilfred/difftastic/releases/latest/download/difft-x86_64-unknown-linux-gnu.tar.gz \
#     | tar xz -C /usr/local/bin \
#     && chmod +x /usr/local/bin/difft

# RUN curl -fsSL https://github.com/ast-grep/ast-grep/releases/latest/download/app-x86_64-unknown-linux-musl.tar.gz \
#     | tar xz -C /usr/local/bin \
#     && chmod +x /usr/local/bin/sg

# RUN curl -fsSL https://github.com/boyter/scc/releases/latest/download/scc_Linux_x86_64.tar.gz \
#     | tar xz -C /usr/local/bin scc \
#     && chmod +x /usr/local/bin/scc

# RUN curl -fsSL https://github.com/sharkdp/hyperfine/releases/latest/download/hyperfine-x86_64-unknown-linux-musl.tar.gz \
#     | tar xz --strip-components=1 -C /usr/local/bin --wildcards '*/hyperfine' \
#     && chmod +x /usr/local/bin/hyperfine

# RUN curl -fsSL https://github.com/watchexec/watchexec/releases/latest/download/watchexec-2.2.0-x86_64-unknown-linux-musl.tar.xz \
#     | tar xJ --strip-components=1 -C /usr/local/bin --wildcards '*/watchexec' \
#     && chmod +x /usr/local/bin/watchexec

# ─── Node via nvm ─────────────────────────────────────────────────────────────
ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install --lts \
    && nvm use --lts \
    && nvm alias default lts/*

# ─── Claude Code + Bun ────────────────────────────────────────────────────────
RUN . "$NVM_DIR/nvm.sh" && npm install -g @anthropic-ai/claude-code
RUN curl -fsSL https://bun.sh/install | bash

# ─── Homebrew (Linuxbrew) ─────────────────────────────────────────────────────
# RUN useradd -m -s /bin/bash linuxbrew \
#     && echo 'linuxbrew ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
# USER linuxbrew
# RUN NONINTERACTIVE=1 /bin/bash -c \
#     "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
# USER root
# ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
# ENV HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
# RUN echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /root/.bashrc \
#     && echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /root/.profile

# ─── PATH persistente ─────────────────────────────────────────────────────────
ENV PATH="/root/.bun/bin:$PATH"
RUN echo '. "$NVM_DIR/nvm.sh"' >> /root/.bashrc \
    && echo '. "$NVM_DIR/nvm.sh"' >> /root/.profile

WORKDIR /root

USER root