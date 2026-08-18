#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/common.sh"

WALLPAPER_DIR="$ROOT_DIR/wallpapers"

command_exists gsettings || die "gsettings non è disponibile: questa funzione richiede GNOME."
[[ -d "$WALLPAPER_DIR" ]] || die "Cartella dei wallpaper non trovata: $WALLPAPER_DIR"

mapfile -d '' wallpapers < <(
  find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
    -print0 | sort -z
)

((${#wallpapers[@]} > 0)) ||
  die "Nessuna immagine trovata in $WALLPAPER_DIR. Aggiungi un file JPG, PNG o WebP e riprova."

printf 'Scegli il wallpaper da applicare:\n'
for index in "${!wallpapers[@]}"; do
  printf '  %d) %s\n' "$((index + 1))" "$(basename "${wallpapers[$index]}")"
done

while true; do
  read -r -p "Numero [1-${#wallpapers[@]}]: " choice
  if [[ "$choice" =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#wallpapers[@]})); then
    break
  fi
  warn "Scelta non valida."
done

selected="${wallpapers[$((choice - 1))]}"
wallpaper_uri="file://$selected"
gsettings set org.gnome.desktop.background picture-uri "$wallpaper_uri"
gsettings set org.gnome.desktop.background picture-uri-dark "$wallpaper_uri"
gsettings set org.gnome.desktop.background picture-options 'zoom'

log "Wallpaper applicato: $(basename "$selected")"
