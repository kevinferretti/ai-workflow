export CODEX_HOME="${CODEX_HOME:-/home/codex/.codex}"
export PLATFORM_ROOT="${PLATFORM_ROOT:-/workspace/platform}"
export WORKSPACE_REPOS="${WORKSPACE_REPOS:-/workspace/repos}"
export HISTFILE=/commandhistory/.zsh_history
export HISTSIZE=50000
export SAVEHIST=50000
setopt append_history share_history hist_ignore_space

alias ll='ls -alF'
alias platform='cd "${PLATFORM_ROOT}"'
alias repos='cd "${WORKSPACE_REPOS}"'

if [ -d "${PLATFORM_ROOT}" ]; then
  cd "${PLATFORM_ROOT}"
fi
