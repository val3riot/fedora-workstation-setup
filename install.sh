#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/common.sh"

[[ ${EUID:-$(id -u)} -ne 0 ]] ||
  die "Esegui install.sh come utente normale; lo script richiederà sudo quando necessario."

require_fedora_44
command_exists sudo || die "sudo non è installato."
load_config "$ROOT_DIR"
validate_config

PROFILE="${1:-development}"
case "$PROFILE" in
  base|development) ;;
  *) die "Profilo non valido: $PROFILE. Usa: base oppure development" ;;
esac

export ROOT_DIR PROFILE

log "Controllo sintassi degli script"
while IFS= read -r -d '' script; do
  bash -n "$script" || die "Errore di sintassi in: ${script#$ROOT_DIR/}"
done < <(find "$ROOT_DIR" -type f -name '*.sh' -print0)
bash -n "$ROOT_DIR/bin/laptop-power-mode"
bash -n "$ROOT_DIR/bin/docker-runtime"

for module in "$ROOT_DIR"/modules/*.sh; do
  module_name="$(basename "$module")"
  log "Modulo: $module_name"
  if ! bash "$module"; then
    die "Modulo fallito: $module_name"
  fi
done

log "Setup completato"
printf '%s\n' \
  "Riavvia la sessione per rendere Zsh la shell predefinita." \
  "Poi esegui: $ROOT_DIR/bin/doctor.sh" \
  "Per aggiungere account Git: $ROOT_DIR/bin/add-git-identity.sh"
