FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Dependencias del sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    sudo \
    ca-certificates \
    ripgrep \
    fd-find \
    jq \
    tree \
    unzip \
    xz-utils \
    python3 \
    python3-pip \
    golang-go \
    && rm -rf /var/lib/apt/lists/*

# Node via nvm
ENV NVM_DIR=/root/.nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash \
    && . "$NVM_DIR/nvm.sh" \
    && nvm install lts \
    && nvm use lts \
    && nvm alias default lts

# Instalar Claude Code y Bun
RUN . "$NVM_DIR/nvm.sh" && npm install -g @anthropic-ai/claude-code
RUN curl -fsSL https://bun.sh/install | bash

# Exponer nvm y bun al PATH de forma persistente
ENV PATH="/root/.bun/bin:$PATH"
RUN echo '. "$NVM_DIR/nvm.sh"' >> /root/.bashrc \
    && echo '. "$NVM_DIR/nvm.sh"' >> /root/.profile

WORKDIR /root

USER root