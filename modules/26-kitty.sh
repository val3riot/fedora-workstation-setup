#!/usr/bin/env bash
set -Eeuo pipefail
source "$ROOT_DIR/lib/common.sh"
load_config "$ROOT_DIR"

[[ "$PROFILE" == development ]] || exit 0

sudo -v
install_available_packages kitty

target="$HOME/.config/kitty/kitty.conf"
install_managed_config "$ROOT_DIR/templates/kitty.conf" "$target" '# workstation-setup: managed kitty config'
log "Kitty configurato in $target"
