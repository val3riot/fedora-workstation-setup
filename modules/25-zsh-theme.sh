#!/usr/bin/env bash
set -Eeuo pipefail
source "$ROOT_DIR/lib/common.sh"
load_config "$ROOT_DIR"

[[ "${CONFIG_ZSH_THEME:-false}" == true ]] || exit 0

sudo -v
install_available_packages zsh git

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  installer="$TOOLS_DIR/tmp/install-oh-my-zsh.sh"
  download "$OH_MY_ZSH_INSTALL_URL" "$installer"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$installer" --unattended
fi

config_dir="$HOME/.config/workstation-setup"
mkdir -p "$config_dir" "$HOME/.config"

if ! command_exists starship && [[ ! -x "$HOME/.local/bin/starship" ]]; then
  archive="$TOOLS_DIR/tmp/starship-x86_64-unknown-linux-gnu.tar.gz"
  extract_dir="$(mktemp -d)"
  download "$STARSHIP_ARCHIVE_URL" "$archive"
  tar -xzf "$archive" -C "$extract_dir" starship
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$extract_dir/starship" "$HOME/.local/bin/starship"
  rm -r -- "$extract_dir"
fi

omz_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
mkdir -p "$omz_custom"
if [[ ! -d "$omz_custom/zsh-syntax-highlighting" ]]; then
  git clone --depth 1 "$ZSH_SYNTAX_HIGHLIGHTING_REPO_URL" "$omz_custom/zsh-syntax-highlighting"
fi
if [[ ! -d "$omz_custom/zsh-autosuggestions" ]]; then
  git clone --depth 1 "$ZSH_AUTOSUGGESTIONS_REPO_URL" "$omz_custom/zsh-autosuggestions"
fi

install -m 0644 "$ROOT_DIR/templates/starship.toml" "$HOME/.config/starship.toml"
install -m 0644 "$ROOT_DIR/templates/zsh-theme.zsh" "$config_dir/zsh-theme.zsh"

zshrc="$HOME/.zshrc"
touch "$zshrc"
begin='# >>> workstation-setup zsh theme >>>'
end='# <<< workstation-setup zsh theme <<<'

# Conserva il primo originale prima di una modifica gestita significativa.
[[ -e "$zshrc.workstation-setup.bak" ]] || cp -p "$zshrc" "$zshrc.workstation-setup.bak"

begin_count="$(grep -Fc "$begin" "$zshrc" || true)"
end_count="$(grep -Fc "$end" "$zshrc" || true)"
[[ "$begin_count" == "$end_count" ]] ||
  die "Blocco tema incompleto in $zshrc: ripristinalo prima di continuare (backup: $zshrc.workstation-setup.bak)."

cleaned="$(mktemp)"
awk -v begin="$begin" -v end="$end" '
  $0 == begin { managed=1; next }
  $0 == end { managed=0; next }
  !managed { print }
' "$zshrc" > "$cleaned"
while [[ -s "$cleaned" && "$(tail -n 1 "$cleaned")" == "" ]]; do
  sed -i '$d' "$cleaned"
done
{
  cat "$cleaned"
  [[ ! -s "$cleaned" ]] || printf '\n'
  printf '%s\n' "$begin"
  printf '%s\n' '[[ -r "$HOME/.config/workstation-setup/zsh-theme.zsh" ]] && source "$HOME/.config/workstation-setup/zsh-theme.zsh"'
  printf '%s\n' "$end"
} > "$zshrc"
rm -f "$cleaned"

log "Tema Zsh/Starship configurato (backup: $zshrc.workstation-setup.bak)"
