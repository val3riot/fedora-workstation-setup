#!/usr/bin/env bash
set -Eeuo pipefail
source "$ROOT_DIR/lib/common.sh"
load_config "$ROOT_DIR"

[[ "$PROFILE" == development ]] || exit 0

sudo -v
install_available_packages kitty kitty-terminfo ncurses
command_exists infocmp || die "infocmp non disponibile dopo l'installazione di ncurses."
infocmp -x xterm-kitty >/dev/null 2>&1 ||
  die "Il terminfo locale xterm-kitty non è disponibile."

target="$HOME/.config/kitty/kitty.conf"
install_managed_config "$ROOT_DIR/templates/kitty.conf" "$target" '# workstation-setup: managed kitty config'
log "Kitty configurato in $target"

install -m 0755 \
  "$ROOT_DIR/bin/install-kitty-terminfo-remote" \
  "$HOME/.local/bin/install-kitty-terminfo-remote"
log "Helper terminfo remoto installato in $HOME/.local/bin/install-kitty-terminfo-remote"

if [[ "$SET_KITTY_AS_DEFAULT_TERMINAL" == true ]]; then
  install_available_packages xdg-terminal-exec
  terminal_list="${XDG_CONFIG_HOME:-$HOME/.config}/xdg-terminals.list"
  install_managed_config \
    "$ROOT_DIR/templates/xdg-terminals.list" \
    "$terminal_list" \
    '# workstation-setup: managed default terminal'
  desktop_name="${XDG_CURRENT_DESKTOP%%:*}"
  if [[ -n "$desktop_name" ]]; then
    desktop_name="${desktop_name,,}"
    desktop_terminal_list="${XDG_CONFIG_HOME:-$HOME/.config}/${desktop_name}-xdg-terminals.list"
    install_managed_config \
      "$ROOT_DIR/templates/xdg-terminals.list" \
      "$desktop_terminal_list" \
      '# workstation-setup: managed default terminal'
  fi
  # La cache può mantenere il terminale selezionato prima di questa modifica.
  rm -f -- "${XDG_CACHE_HOME:-$HOME/.cache}/xdg-terminal-exec"
  log "Kitty impostato come terminale predefinito in $terminal_list"
fi
