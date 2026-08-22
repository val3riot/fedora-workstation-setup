#!/usr/bin/env bash
set -Eeuo pipefail
source "$ROOT_DIR/lib/common.sh"
load_config "$ROOT_DIR"

[[ "$PROFILE" == "development" && "$INSTALL_AGENTS" == true ]] || exit 0

AGENTS_ROOT="$TOOLS_DIR/Agents"
CODEX_HOME="$HOME/.codex"
CLAUDE_CONFIG_DIR="$AGENTS_ROOT/claude"
COPILOT_HOME="$AGENTS_ROOT/copilot"
export AGENTS_ROOT CODEX_HOME CLAUDE_CONFIG_DIR COPILOT_HOME
mkdir -p "$AGENTS_ROOT" "$CODEX_HOME" "$CLAUDE_CONFIG_DIR" "$COPILOT_HOME" "$HOME/.local/bin"
chmod 700 "$AGENTS_ROOT" "$CODEX_HOME" "$CLAUDE_CONFIG_DIR" "$COPILOT_HOME"

# Mantiene il percorso organizzativo storico senza spostare ~/.codex mentre
# Codex può essere in esecuzione e senza separare autenticazione e configurazione.
codex_alias="$AGENTS_ROOT/codex"
if [[ ! -e "$codex_alias" && ! -L "$codex_alias" ]]; then
  ln -s "$CODEX_HOME" "$codex_alias"
elif [[ -L "$codex_alias" && "$(readlink -f "$codex_alias")" != "$(readlink -f "$CODEX_HOME")" ]]; then
  die "$codex_alias è un link verso una destinazione inattesa; non verrà sovrascritto."
elif [[ -d "$codex_alias" && ! -L "$codex_alias" && "$codex_alias" != "$CODEX_HOME" ]]; then
  warn "$codex_alias è una directory reale preesistente: conservata senza modifiche."
fi

remove_legacy_npm_agent() {
  local package=$1
  export NVM_DIR="$TOOLS_DIR/nvm"
  [[ -s "$NVM_DIR/nvm.sh" ]] || return 0
  # shellcheck disable=SC1090
  source "$NVM_DIR/nvm.sh"
  command_exists npm || return 0
  if npm list --global --depth=0 --json 2>/dev/null |
    jq -e --arg package "$package" '.dependencies[$package] != null' >/dev/null; then
    log "Rimozione precedente installazione npm: $package"
    npm uninstall --global "$package"
  fi
}

install_vendor_agent() {
  local label=$1 url=$2 installer=$3
  log "Installazione $label dalla fonte ufficiale"
  download "$url" "$installer"
  bash "$installer"
}

# Le configurazioni, le sessioni e l'autenticazione non vengono rimosse.
remove_legacy_npm_agent '@openai/codex'
remove_legacy_npm_agent '@anthropic-ai/claude-code'
remove_legacy_npm_agent '@github/copilot'

install_vendor_agent \
  'OpenAI Codex (standalone)' \
  "$CODEX_INSTALL_URL" \
  "$TOOLS_DIR/tmp/install-codex.sh"

install_vendor_agent \
  'Anthropic Claude Code (native)' \
  "$CLAUDE_INSTALL_URL" \
  "$TOOLS_DIR/tmp/install-claude-code.sh"

log 'Installazione GitHub Copilot CLI dallo script ufficiale'
copilot_installer="$TOOLS_DIR/tmp/install-copilot-cli.sh"
download "$COPILOT_INSTALL_URL" "$copilot_installer"
PREFIX="$HOME/.local" bash "$copilot_installer"

for executable in codex claude copilot; do
  [[ -x "$HOME/.local/bin/$executable" ]] ||
    die "$executable non è disponibile nel path atteso: $HOME/.local/bin/$executable"
done

printf '%s\n' \
  "AGENTS_ROOT=$AGENTS_ROOT" \
  "CODEX_HOME=$CODEX_HOME" \
  "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR" \
  "COPILOT_HOME=$COPILOT_HOME"
