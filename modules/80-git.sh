#!/usr/bin/env bash
set -Eeuo pipefail
source "$ROOT_DIR/lib/common.sh"
load_config "$ROOT_DIR"

git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global fetch.prune true
git config --global core.autocrlf input
git config --global core.editor 'code --wait'
git config --global user.useConfigOnly true

# Include tutti i profili creati dal comando add-git-identity.sh.
# Le includeIf specifiche vengono aggiunte automaticamente al file globale.
mkdir -p "$HOME/.config/git/identities"
touch "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"
