FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG NODE_MAJOR=22
ARG CODEX_NPM_VERSION=0.132.0
ARG USER_UID=1000
ARG USER_GID=1000
ARG TZ=UTC

ENV TZ="${TZ}" \
    CODEX_HOME=/home/codex/.codex \
    PLATFORM_ROOT=/workspace/platform \
    WORKSPACE_REPOS=/workspace/repos \
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
      bash-completion \
      bubblewrap \
      build-essential \
      ca-certificates \
      curl \
      dnsutils \
      fd-find \
      fzf \
      gh \
      git \
      git-lfs \
      gnupg \
      gosu \
      iproute2 \
      jq \
      less \
      locales \
      lsb-release \
      man-db \
      nano \
      openssh-client \
      pkg-config \
      python3 \
      python3-pip \
      python3-venv \
      ripgrep \
      rsync \
      sudo \
      unzip \
      vim \
      zsh \
    && locale-gen en_US.UTF-8 \
    && ln -sf /usr/bin/fdfind /usr/local/bin/fd \
    && git lfs install --system \
    && chmod u+s /usr/bin/bwrap \
    && install -d -m 0755 /etc/apt/keyrings \
    && curl -fsSL "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key" \
      | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
      > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "@openai/codex@${CODEX_NPM_VERSION}" \
    && npm cache clean --force \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN existing_group="$(getent group "${USER_GID}" | cut -d: -f1 || true)" \
    && if [ -z "${existing_group}" ]; then \
      groupadd --gid "${USER_GID}" codex; \
    elif [ "${existing_group}" != "codex" ]; then \
      groupmod --new-name codex "${existing_group}"; \
    fi \
    && existing_user="$(getent passwd "${USER_UID}" | cut -d: -f1 || true)" \
    && if [ -z "${existing_user}" ]; then \
      useradd --uid "${USER_UID}" --gid "${USER_GID}" --create-home --shell /usr/bin/zsh codex; \
    elif [ "${existing_user}" != "codex" ]; then \
      usermod --login codex --gid "${USER_GID}" --home /home/codex --move-home --shell /usr/bin/zsh "${existing_user}"; \
    fi \
    && echo "codex ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/codex \
    && chmod 0440 /etc/sudoers.d/codex \
    && install -d -m 0755 -o codex -g codex /home/codex \
    && install -d -m 0775 -o codex -g codex /workspace /workspace/repos /commandhistory \
    && install -d -m 0700 -o codex -g codex /home/codex/.codex /home/codex/.config/gh /home/codex/.ssh \
    && touch /commandhistory/.bash_history /commandhistory/.zsh_history \
    && chown codex:codex /commandhistory/.bash_history /commandhistory/.zsh_history

COPY infra/workspace/config/codex.config.toml /etc/codex/config.toml
COPY infra/workspace/home/.zshrc /home/codex/.zshrc
COPY infra/workspace/bin/install-platform-skills /usr/local/bin/install-platform-skills
COPY infra/workspace/bin/workspace-entrypoint /usr/local/bin/workspace-entrypoint

RUN chmod 0644 /etc/codex/config.toml \
    && chmod 0644 /home/codex/.zshrc \
    && chmod 0755 /usr/local/bin/install-platform-skills /usr/local/bin/workspace-entrypoint \
    && chown codex:codex /home/codex/.zshrc

WORKDIR /workspace/platform
ENTRYPOINT ["/usr/local/bin/workspace-entrypoint"]
CMD ["sleep", "infinity"]
