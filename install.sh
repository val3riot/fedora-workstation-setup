#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/common.sh"

show_info() {
  cat <<'INFO'
Fedora Workstation Setup

USO
  ./install.sh [PROFILO] [OPZIONI]

PROFILI
  --base          Sistema essenziale, shell, rete e strumenti di base.
  --development   Ambiente di sviluppo completo; profilo predefinito.
  --desktop       Applicazioni desktop e configurazione GNOME.
  --all           Ambiente di sviluppo e applicazioni desktop.

OPZIONI
  --config-zsh-theme  Installa e configura Starship e i plugin Zsh.
  --set-wallpaper     Sceglie uno sfondo dalla cartella wallpapers/.
  --help, --info, -h  Mostra questa guida.

COMPONENTI PRINCIPALI
  Development   Kitty, tmux, SDKMAN, Node/NVM, Miniconda, TeX Live,
                Docker rootless/Desktop, VS Code, KVM/libvirt e Vagrant.
  Desktop       DBeaver, Bruno, JetBrains Toolbox, Thunderbird,
                LibreOffice, Discord, Obsidian e Dash to Dock.
  Agenti AI     Codex, Claude Code e Copilot CLI; opt-in con
                INSTALL_AGENTS=true in config/local.env.

CONFIGURAZIONE
  cp config/local.env.example config/local.env
  Versioni, fonti e checksum: config/sources.env

VERIFICA
  ./bin/test.sh                 Suite completa del repository.
  ./bin/doctor.sh               Stato della workstation.
  ./bin/provenance-audit.sh     Provenienza del software installato.
  ./bin/audit-urls.sh --online  Fonti e raggiungibilità degli endpoint.

UTILITÀ
  ./bin/add-git-identity.sh
  docker-runtime status|rootless|desktop
  laptop-power-mode status|dev|quiet|normal|full|default
  install-kitty-terminfo-remote user@host
INFO
}

if [[ "${1:-}" == --info || "${1:-}" == --help || "${1:-}" == -h ]]; then
  (( $# == 1 )) || die "--help/--info non accettano altri argomenti."
  show_info
  exit 0
fi

[[ ${EUID:-$(id -u)} -ne 0 ]] ||
  die "Esegui install.sh come utente normale; lo script richiederà sudo quando necessario."

require_fedora_44
command_exists sudo || die "sudo non è installato."
load_config "$ROOT_DIR"
validate_config

MODE=--development
PROFILE=development
INCLUDE_DESKTOP_APPS=false
CONFIG_ZSH_THEME=false
profile_selected=false

while (($#)); do
  case "$1" in
    base|--base)
      [[ "$profile_selected" == false ]] || die "Specifica un solo profilo."
      MODE=--base; PROFILE=base; INCLUDE_DESKTOP_APPS=false; profile_selected=true
      ;;
    development|--develop|--development)
      [[ "$profile_selected" == false ]] || die "Specifica un solo profilo."
      MODE=--development; PROFILE=development; INCLUDE_DESKTOP_APPS=false; profile_selected=true
      ;;
    --desktop)
      [[ "$profile_selected" == false ]] || die "Specifica un solo profilo."
      MODE=--desktop; PROFILE=development; INCLUDE_DESKTOP_APPS=true; profile_selected=true
      ;;
    --all)
      [[ "$profile_selected" == false ]] || die "Specifica un solo profilo."
      MODE=--all; PROFILE=development; INCLUDE_DESKTOP_APPS=true; profile_selected=true
      ;;
    --config-zsh-theme) CONFIG_ZSH_THEME=true ;;
    --set-wallpaper)
      (( $# == 1 )) || die "--set-wallpaper non accetta altri argomenti."
      exec "$ROOT_DIR/bin/set-wallpaper.sh"
      ;;
    *) die "Opzione non valida: $1. Usa --help per l'elenco dei comandi." ;;
  esac
  shift
done

export ROOT_DIR PROFILE INCLUDE_DESKTOP_APPS CONFIG_ZSH_THEME

log "Controllo sintassi degli script"
while IFS= read -r -d '' script; do
  bash -n "$script" || die "Errore di sintassi in: ${script#"$ROOT_DIR"/}"
done < <(find "$ROOT_DIR" -type f -name '*.sh' -print0)
bash -n "$ROOT_DIR/bin/laptop-power-mode"
bash -n "$ROOT_DIR/bin/docker-runtime"

for module in "$ROOT_DIR"/modules/*.sh; do
  module_name="$(basename "$module")"
  if [[ "$MODE" == --desktop && "$module_name" != 70-desktop-apps.sh &&
        ! ( "$CONFIG_ZSH_THEME" == true && "$module_name" == 25-zsh-theme.sh ) ]]; then
    continue
  fi
  log "Modulo: $module_name"
  if ! bash "$module"; then
    die "Modulo fallito: $module_name"
  fi
done

if [[ "$MODE" == --desktop ]]; then
  log "Sezione desktop completata"
  printf '%s\n' \
    "Le applicazioni desktop abilitate sono installate." \
    "Verifica con: $ROOT_DIR/bin/doctor.sh"
  if rpm -q gnome-shell-extension-dash-to-dock >/dev/null 2>&1 &&
     ! gnome-extensions list --enabled 2>/dev/null | grep -Fqx dash-to-dock@micxgx.gmail.com; then
    printf '%s\n' "Esegui logout/login per caricare Dash to Dock, quindi rilancia: $0 --desktop"
  else
    printf '%s\n' "Non è necessario riavviare la sessione."
  fi
else
  log "Setup completato"
  printf '%s\n' \
    "Riavvia la sessione per rendere Zsh la shell predefinita." \
    "Poi esegui: $ROOT_DIR/bin/doctor.sh" \
    "Per aggiungere account Git: $ROOT_DIR/bin/add-git-identity.sh"
fi
