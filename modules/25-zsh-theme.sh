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
  printf '%s  %s\n' "$OH_MY_ZSH_INSTALL_SHA256" "$installer" | sha256sum --check --status ||
    die "Checksum dell'installer Oh My Zsh non valido."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$installer" --unattended
fi

config_dir="$HOME/.config/workstation-setup"
mkdir -p "$config_dir" "$HOME/.config"

starship_path="$(command -v starship 2>/dev/null || true)"
starship_state="$config_dir/starship-version"
if [[ -z "$starship_path" || "$starship_path" == "$HOME/.local/bin/starship" ]] &&
   { [[ ! -x "$HOME/.local/bin/starship" ]] || [[ "$(cat "$starship_state" 2>/dev/null)" != "$STARSHIP_VERSION $STARSHIP_ARCHIVE_SHA256" ]]; }; then
  archive="$TOOLS_DIR/tmp/starship-${STARSHIP_VERSION}-x86_64-unknown-linux-gnu.tar.gz"
  extract_dir="$(mktemp -d)"
  download "$STARSHIP_ARCHIVE_URL" "$archive"
  printf '%s  %s\n' "$STARSHIP_ARCHIVE_SHA256" "$archive" | sha256sum --check --status ||
    die "Checksum dell'archivio Starship non valido."
  tar -xzf "$archive" -C "$extract_dir" starship
  mkdir -p "$HOME/.local/bin"
  install -m 0755 "$extract_dir/starship" "$HOME/.local/bin/starship"
  printf '%s %s\n' "$STARSHIP_VERSION" "$STARSHIP_ARCHIVE_SHA256" > "$starship_state"
  rm -r -- "$extract_dir"
fi

install_pinned_plugin() {
  local name=$1 url=$2 commit=$3 target="$omz_custom/$1"
  if [[ ! -d "$target" ]]; then
    git clone --filter=blob:none "$url" "$target"
  fi
  [[ -d "$target/.git" ]] || die "$target esiste ma non è un repository Git."
  [[ "$(git -C "$target" remote get-url origin)" == "$url" ]] ||
    die "Remote inatteso per $name in $target."
  if ! git -C "$target" diff --quiet || ! git -C "$target" diff --cached --quiet; then
    die "$name contiene modifiche locali; non verrà sovrascritto."
  fi
  if ! git -C "$target" cat-file -e "${commit}^{commit}" 2>/dev/null; then
    git -C "$target" fetch --depth 1 origin "$commit"
  fi
  git -C "$target" checkout --quiet --detach "$commit"
  [[ "$(git -C "$target" rev-parse HEAD)" == "$commit" ]] || die "Revisione inattesa per $name."
}

omz_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"
mkdir -p "$omz_custom"
install_pinned_plugin zsh-syntax-highlighting "$ZSH_SYNTAX_HIGHLIGHTING_REPO_URL" "$ZSH_SYNTAX_HIGHLIGHTING_COMMIT"
install_pinned_plugin zsh-autosuggestions "$ZSH_AUTOSUGGESTIONS_REPO_URL" "$ZSH_AUTOSUGGESTIONS_COMMIT"

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
  # HOME deve essere espansa da Zsh, non dall'installer.
  # shellcheck disable=SC2016
  printf '%s\n' '[[ -r "$HOME/.config/workstation-setup/zsh-theme.zsh" ]] && source "$HOME/.config/workstation-setup/zsh-theme.zsh"'
  printf '%s\n' "$end"
} > "$zshrc"
rm -f "$cleaned"

log "Tema Zsh/Starship configurato (backup: $zshrc.workstation-setup.bak)"
