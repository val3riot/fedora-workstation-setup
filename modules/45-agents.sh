#!/usr/bin/env bash
set -Eeuo pipefail
source "$ROOT_DIR/lib/common.sh"
load_config "$ROOT_DIR"

[[ "$PROFILE" == "development" && "$INSTALL_AGENTS" == true ]] || exit 0

export NVM_DIR="$TOOLS_DIR/nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] || die "NVM non disponibile: abilita INSTALL_NVM e rilancia il profilo development."
# shellcheck disable=SC1090
source "$NVM_DIR/nvm.sh"
command_exists npm || die "npm non disponibile dopo il caricamento di NVM."

AGENTS_ROOT="$TOOLS_DIR/Agents"
CODEX_HOME="$AGENTS_ROOT/codex"
CLAUDE_CONFIG_DIR="$AGENTS_ROOT/claude"
COPILOT_HOME="$AGENTS_ROOT/copilot"
export AGENTS_ROOT CODEX_HOME CLAUDE_CONFIG_DIR COPILOT_HOME
mkdir -p "$CODEX_HOME" "$CLAUDE_CONFIG_DIR" "$COPILOT_HOME"
chmod 700 "$AGENTS_ROOT" "$CODEX_HOME" "$CLAUDE_CONFIG_DIR" "$COPILOT_HOME"

install_agent() {
  local package=$1 executable=$2
  if command_exists "$executable"; then
    printf '  già installato: %s (%s)\n' "$package" "$(command -v "$executable")"
  else
    npm install --global "$package"
  fi
}

install_agent '@openai/codex' codex
install_agent '@anthropic-ai/claude-code' claude
install_agent '@github/copilot' copilot

printf '%s\n' \
  "AGENTS_ROOT=$AGENTS_ROOT" \
  "CODEX_HOME=$CODEX_HOME" \
  "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR" \
  "COPILOT_HOME=$COPILOT_HOME"
