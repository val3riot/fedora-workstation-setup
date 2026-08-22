#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$ROOT_DIR/lib/common.sh"

show_info() {
  cat <<'INFO'
Fedora Workstation Setup - comandi rapidi

INSTALLAZIONE E VERIFICA
  ./install.sh --base          Installa l'ambiente essenziale.
  ./install.sh --development   Installa l'ambiente di sviluppo (predefinito).
  ./install.sh --desktop       Installa soltanto le applicazioni desktop.
  ./install.sh --all           Installa sviluppo e applicazioni desktop.
  ./install.sh --config-zsh-theme
                               Aggiunge il tema Zsh/Starship opzionale.
  ./install.sh --set-wallpaper Sceglie e applica uno sfondo dalla cartella wallpapers/.
  ./bin/check-setup.sh          Controlla la sintassi senza installare nulla.
  ./bin/doctor.sh               Verifica lo stato della workstation.

UTILITÀ E COMANDI DOPO IL SETUP
  ./bin/add-git-identity.sh     Crea un'identità Git e il relativo alias SSH.
  docker-runtime status        Mostra runtime e context Docker correnti.
  docker-runtime rootless      Passa a Docker Engine rootless.
  docker-runtime desktop       Passa a Docker Desktop.
  laptop-power-mode status     Mostra profilo energetico e limiti CPU.
  laptop-power-mode dev [20-100]
                               Profilo bilanciato con limite CPU configurabile.
  laptop-power-mode quiet [20-100]
                               Profilo a basso consumo con limite CPU configurabile.
  laptop-power-mode normal     Ripristina profilo bilanciato e CPU al 100%.
  laptop-power-mode full       Abilita il profilo per le massime prestazioni.
  laptop-power-mode default    Riapplica il profilo configurato.
  install-kitty-terminfo-remote user@host
                               Installa xterm-kitty per l'utente remoto via OpenSSH.

ALIAS SHELL CREATI
  ll       -> ls -alF
  gst      -> git status
  ..       -> cd ..
  update-a -> sudo dnf upgrade --refresh -y && flatpak update -y

ALTRI ALIAS
  nvm alias default -> versione indicata da NVM_NODE_VERSION (Node LTS di default)

Gli eseguibili installati sono disponibili dopo aver riaperto la shell.
I nomi degli alias SSH dipendono dai valori inseriti in add-git-identity.sh.
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
