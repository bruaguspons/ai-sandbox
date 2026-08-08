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

# ─── mise: gestiona runtimes y CLIs de forma declarativa ─────────────────────
ENV PATH="/root/.local/bin:/root/.local/share/mise/shims:$PATH"
RUN curl -fsSL https://mise.run | sh

COPY mise.toml /root/.config/mise/config.toml
RUN mise install

# ─── Claude Code (installer nativo oficial: no depende de node, se autoactualiza) ──
RUN curl -fsSL https://claude.ai/install.sh | bash

# Activación en shells interactivas (completions + auto-reshim)
RUN echo 'eval "$(mise activate bash)"' >> /root/.bashrc \
    && echo 'eval "$(mise activate zsh)"'  >> /root/.zshrc

WORKDIR /root

USER root