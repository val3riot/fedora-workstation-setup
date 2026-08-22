#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

# Gli agenti devono usare esclusivamente gli installer nativi ufficiali.
grep -Fq 'https://chatgpt.com/codex/install.sh' "$ROOT_DIR/config/sources.env"
grep -Fq 'https://claude.ai/install.sh' "$ROOT_DIR/config/sources.env"
grep -Fq 'https://gh.io/copilot-install' "$ROOT_DIR/config/sources.env"
if grep -Eq 'npm (install|i).*(-g|--global).*(codex|claude|copilot)' "$ROOT_DIR/modules/45-agents.sh"; then
  printf '%s\n' 'FAIL installazione npm agente rilevata' >&2
  exit 1
fi

# I plugin Zsh disponibili in Fedora non devono essere clonati manualmente.
grep -Fq 'zsh-syntax-highlighting zsh-autosuggestions' "$ROOT_DIR/modules/25-zsh-theme.sh"
if grep -Eq 'git clone.*(zsh-syntax-highlighting|zsh-autosuggestions)' "$ROOT_DIR/modules/25-zsh-theme.sh"; then
  printf '%s\n' 'FAIL clone manuale plugin Zsh rilevato' >&2
  exit 1
fi

# Ogni download eseguibile/archivio statico deve avere un digest configurato.
for variable in OH_MY_ZSH_INSTALL_SHA256 STARSHIP_ARCHIVE_SHA256 NVM_INSTALL_SHA256 \
  MINICONDA_INSTALLER_SHA256 DOCKER_DESKTOP_RPM_SHA256; do
  grep -Eq "^${variable}=\"?[0-9a-f]{64}\"?$" "$ROOT_DIR/config/sources.env"
done

printf '%s\n' 'OK   policy provenienza repository'
