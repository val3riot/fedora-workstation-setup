#!/usr/bin/env bash
set -Eeuo pipefail
source "$ROOT_DIR/lib/common.sh"
load_config "$ROOT_DIR"

if [[ "$INSTALL_OH_MY_ZSH" == true && ! -d "$HOME/.oh-my-zsh" ]]; then
  installer="$TOOLS_DIR/tmp/install-oh-my-zsh.sh"
  download "$OH_MY_ZSH_INSTALL_URL" "$installer"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$installer" --unattended
fi

if [[ ! -f "$HOME/.zshrc" ]]; then
  cp "$ROOT_DIR/templates/zshrc" "$HOME/.zshrc"
else
  append_line_once '# workstation-setup: personal development environment' "$HOME/.zshrc"
  append_line_once '[[ -f "$HOME/.config/workstation-setup/env.zsh" ]] && source "$HOME/.config/workstation-setup/env.zsh"' "$HOME/.zshrc"
fi

mkdir -p "$HOME/.config/workstation-setup"
cat > "$HOME/.config/workstation-setup/env.zsh" <<ENV
export TOOLS_DIR="$TOOLS_DIR"
export PROJECTS_DIR="$PROJECTS_DIR"
export NVM_DIR="$TOOLS_DIR/nvm"
export SDKMAN_DIR="$TOOLS_DIR/sdkman"
export VAGRANT_HOME="$TOOLS_DIR/vagrant"
export VAGRANT_DEFAULT_PROVIDER="$VAGRANT_DEFAULT_PROVIDER"
export PATH="\$HOME/.local/bin:\$PATH"

alias ll='ls -alF'
alias gs='git status'
alias ..='cd ..'
alias update-a='sudo dnf upgrade --refresh -y && flatpak update -y'

[[ -s "\$NVM_DIR/nvm.sh" ]] && source "\$NVM_DIR/nvm.sh"
[[ -s "\$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "\$SDKMAN_DIR/bin/sdkman-init.sh"
[[ -f "$TOOLS_DIR/miniconda3/etc/profile.d/conda.sh" ]] && source "$TOOLS_DIR/miniconda3/etc/profile.d/conda.sh"
ENV

current_shell="$(getent passwd "$USER" | cut -d: -f7)"
zsh_path="$(command -v zsh || true)"
if [[ -n "$zsh_path" && "$current_shell" != "$zsh_path" ]]; then
  chsh -s "$zsh_path" || warn "Cambio shell non riuscito; esegui manualmente: chsh -s $zsh_path"
fi
