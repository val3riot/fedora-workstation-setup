#!/usr/bin/env bash
set -Eeuo pipefail
source "$ROOT_DIR/lib/common.sh"
load_config "$ROOT_DIR"

mkdir -p \
  "$TOOLS_DIR" \
  "$TOOLS_DIR/tmp" \
  "$PROJECTS_DIR/personali" \
  "$PROJECTS_DIR/lavoro" \
  "$PROJECTS_DIR/universita" \
  "$PROJECTS_DIR/homelab" \
  "$HOME/.local/bin" \
  "$HOME/.config/git/identities" \
  "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
