# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.231.6/containers/python-3/.devcontainer/base.Dockerfile

# [Choice] Python version (use -bullseye variants on local arm64/Apple Silicon): 3, 3.10, 3.9, 3.8, 3.7, 3.6, 3-bullseye, 3.10-bullseye, 3.9-bullseye, 3.8-bullseye, 3.7-bullseye, 3.6-bullseye, 3-buster, 3.10-buster, 3.9-buster, 3.8-buster, 3.7-buster, 3.6-buster
ARG VARIANT="3.10-bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/python:0-${VARIANT}

# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="none"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi

# pip requirements rarely change
COPY packages/*.* /tmp/packages-tmp/
#Python Packages - .devcontainer packages
RUN set -ex \
    && pip3 --disable-pip-version-check \
            --no-cache-dir install -r /tmp/packages-tmp/requirements.txt

# OS packages
RUN set -x \
    && apt-get update \
    && apt-get upgrade -y \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
       zsh-autosuggestions \
       zsh-syntax-highlighting \
       pass gnupg2 \
    && apt-get autoremove -y  \
    && apt-get clean -y \
    && rm -r /var/cache/* /var/lib/apt/lists/*

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1

# aws-vault CLI
ENV AWS_VAULT_URL=github.com/99designs/aws-vault/releases/download
ENV AWS_VAULT_VERSION=v6.6.0
RUN set -ex \
    && curl -L -o /usr/local/bin/aws-vault \
        https://${AWS_VAULT_URL}/${AWS_VAULT_VERSION}/aws-vault-linux-amd64 \
    && chmod 755 /usr/local/bin/aws-vault

# cloud-nuke CLI
ENV CLOUD_NUKE_URL=github.com/gruntwork-io/cloud-nuke/releases/download
ENV CLOUD_NUKE_VERSION=v0.11.3
RUN set -ex \
    && curl -L -o /usr/local/bin/cloud-nuke \
        https://${CLOUD_NUKE_URL}/${CLOUD_NUKE_VERSION}/cloud-nuke_linux_amd64 \
    && chmod 755 /usr/local/bin/cloud-nuke

# Sentry CLI
RUN set -ex \
    && curl -fsSL https://sentry.io/get-cli/ | bash

# oh-my-zsh plugins
# 	zsh-autosuggestions - suggests commands as you type based on history and completions
#   zsh-syntax-highlighting - enables highlighting of commands as they are typed at a zsh prompt
ARG USERNAME=vscode
ARG PLUGIN_FOLDER="/home/$USERNAME/.oh-my-zsh/custom/plugins"
RUN git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUGIN_FOLDER"/zsh-syntax-highlighting
RUN git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_FOLDER"/zsh-autosuggestions
RUN git clone https://github.com/blimmer/zsh-aws-vault.git "$PLUGIN_FOLDER"/zsh-aws-vault
COPY dotfiles/.zshrc /home/$USERNAME/

# Copy shift-left files
COPY shift-left /workspaces/shift-left
COPY tests      /workspaces/tests
COPY automator  /workspaces/automator
COPY version.txt     /opt/version.txt
COPY signature.txt     /opt/signature.txt
COPY dotfiles/.czrc /home/$USERNAME/

RUN chown -R vscode:vscode /workspaces
RUN chmod 755 /workspaces

# Remove library scripts for final image
RUN set -ex \
    && apt-get --purge remove unzip -y \
    && apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/library-scripts \
    && rm -rf /tmp/packages-tmp
