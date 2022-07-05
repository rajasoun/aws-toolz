# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.231.6/containers/python-3/.devcontainer/base.Dockerfile

# [Choice] Python version (use -bullseye variants on local arm64/Apple Silicon): 3, 3.10, 3.9, 3.8, 3.7, 3.6, 3-bullseye, 3.10-bullseye, 3.9-bullseye, 3.8-bullseye, 3.7-bullseye, 3.6-bullseye, 3-buster, 3.10-buster, 3.9-buster, 3.8-buster, 3.7-buster, 3.6-buster
ARG VARIANT="3.10-bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/python:0-${VARIANT} as base

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
       pass gnupg2 httpie netcat \
    && apt-get autoremove -y  \
    && apt-get clean -y \
    && rm -r /var/cache/* /var/lib/apt/lists/*

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1

# toolz-base image
FROM debian:bullseye-slim as toolz-base
RUN set -x \
    && apt-get update \
    && apt-get upgrade -y \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
       curl wget ca-certificates \
    && apt-get autoremove -y  \
    && apt-get clean -y \
    && rm -r /var/cache/* /var/lib/apt/lists/*

# aws-vault CLI
FROM toolz-base as aws-vault
ENV AWS_VAULT_URL=github.com/99designs/aws-vault/releases/download
ENV AWS_VAULT_VERSION=v6.6.0
RUN set -ex \
    && curl -L -o /usr/local/bin/aws-vault \
        https://${AWS_VAULT_URL}/${AWS_VAULT_VERSION}/aws-vault-linux-amd64 \
    && chmod 755 /usr/local/bin/aws-vault

# cloud-nuke CLI
FROM toolz-base as cloud-nuke
ENV CLOUD_NUKE_URL=github.com/gruntwork-io/cloud-nuke/releases/download
ENV CLOUD_NUKE_VERSION=v0.11.6
RUN set -ex \
    && curl -L -o /usr/local/bin/cloud-nuke \
        https://${CLOUD_NUKE_URL}/${CLOUD_NUKE_VERSION}/cloud-nuke_linux_amd64 \
    && chmod 755 /usr/local/bin/cloud-nuke

# aws-nuke CLI
FROM toolz-base as aws-nuke
ENV AWS_NUKE_URL=github.com/rebuy-de/aws-nuke/releases/download
ENV AWS_NUKE_VERSION=v2.19.0
ENV AWS_NUKE_EXEC=aws-nuke-${AWS_NUKE_VERSION}-linux-amd64

RUN set -ex \
    && wget -c https://${AWS_NUKE_URL}/$AWS_NUKE_VERSION/${AWS_NUKE_EXEC}.tar.gz -O - | \
       tar -xz -C /tmp
RUN set -ex \
    && mv /tmp/${AWS_NUKE_EXEC} /usr/local/bin/aws-nuke

# awless CLI
FROM toolz-base as awless
ENV AWS_LESS_URL=github.com/wallix/awless/releases/download
ENV AWS_LESS_VERSION=v0.1.11
ENV AWS_LESS_EXEC=awless

RUN set -ex \
    && wget -c https://${AWS_LESS_URL}/$AWS_LESS_VERSION/${AWS_LESS_EXEC}-linux-amd64.tar.gz -O - | \
       tar -xz -C /tmp
RUN set -ex \
    && mv /tmp/${AWS_LESS_EXEC} /usr/local/bin/awless

# Fetch CLI
FROM toolz-base as fetch
ENV FETCH_URL=github.com/gruntwork-io/fetch/releases/download
ENV FETCH_VERSION=v0.4.4
RUN set -ex \
    && curl -L -o /usr/local/bin/fetch \
        https://${FETCH_URL}/${FETCH_VERSION}/fetch_linux_amd64 \
    && chmod 755 /usr/local/bin/fetch

# syft & grype support
FROM toolz-base as syft-grype
ENV SYFT_INSTALL_SCRIPT="https://raw.githubusercontent.com/anchore/syft/main/install.sh"
ENV GRYPE_INSTALL_SCRIPT="https://raw.githubusercontent.com/anchore/grype/main/install.sh"
RUN set -ex \
    && curl -sSfL "$SYFT_INSTALL_SCRIPT" | sh -s -- -b /usr/local/bin \
    && curl -sSfL "$GRYPE_INSTALL_SCRIPT" | sh -s -- -b /usr/local/bin

# kubectl
FROM toolz-base as kubectl
RUN set -ex \
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256" \
    && echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    && kubectl version --client

# Pulumi
FROM toolz-base as pulumi
RUN set -ex \
    && curl -fsSL https://get.pulumi.com | bash -s -- --version $PULUMI_VERSION \
    && mv ~/.pulumi/bin/* /usr/local/bin

FROM base
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
COPY shift-left     /workspaces/shift-left
COPY tests          /workspaces/tests
COPY automator      /workspaces/automator
COPY version.txt    /opt/version.txt
COPY signature.txt  /opt/signature.txt
COPY dotfiles/.czrc /home/$USERNAME/

#COPY tools
COPY --from=aws-vault       /usr/local/bin/aws-vault    /usr/local/bin/aws-vault
COPY --from=cloud-nuke      /usr/local/bin/cloud-nuke   /usr/local/bin/cloud-nuke
COPY --from=aws-nuke        /usr/local/bin/aws-nuke     /usr/local/bin/aws-nuke
COPY --from=awless          /usr/local/bin/awless       /usr/local/bin/awless
COPY --from=fetch           /usr/local/bin/fetch        /usr/local/bin/fetch
COPY --from=syft-grype      /usr/local/bin/syft         /usr/local/bin/syft
COPY --from=syft-grype      /usr/local/bin/grype        /usr/local/bin/grype
COPY --from=kubectl         /usr/local/bin/kubectl      /usr/local/bin/kubectl
COPY --from=pulumi          /usr/local/bin/pulumi       /usr/local/bin/pulumi

COPY --from=rajasoun/aws-sso:1.0.1  /usr/local/bin/aws-sso  /usr/local/bin/aws-sso

RUN fetch --repo="https://github.com/rajasoun/aws-toolz" \
    --tag="1.0.1" \
    --source-path="/aws-cost-hub/aws-cli" \
    /workspaces/tools/
RUN fetch --repo="https://github.com/rajasoun/aws-toolz" \
    --tag="1.0.1" \
    --source-path="/.devcontainer/.aws/aws_vault_env.sh" \
    /workspaces/tools/aws_vault_env.sh
RUN fetch --repo="https://github.com/rajasoun/aws-toolz" \
    --tag="1.0.1" \
    --source-path="/aws-cost-hub/cost-explorer/libs/identity.py" \
    /workspaces/tools/identity.py

RUN chown -R vscode:vscode /workspaces
RUN chmod 755 /workspaces
RUN chmod a+x  /workspaces/tools/*.sh
RUN chmod a+x  /workspaces/tools/*.py

# Remove library scripts for final image
RUN set -ex \
    && apt-get --purge remove unzip -y \
    && apt-get autoremove --assume-yes \
    && apt-get clean --assume-yes \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/library-scripts \
    && rm -rf /tmp/packages-tmp \
    && rm -rf /tmp/*
