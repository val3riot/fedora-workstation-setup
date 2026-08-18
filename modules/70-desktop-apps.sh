#!/usr/bin/env bash
set -Eeuo pipefail
source "$ROOT_DIR/lib/common.sh"
load_config "$ROOT_DIR"
[[ "${INCLUDE_DESKTOP_APPS:-false}" == true ]] || exit 0

SECTION="${1:-all}"
case "$SECTION" in
  all|flatpak|rpm|gnome|jetbrains) ;;
  *) die "Sezione non valida: $SECTION. Usa: all, flatpak, rpm, gnome oppure jetbrains" ;;
esac

install_rpm_url() {
  local package_name=$1 url=$2 output=$3
  rpm -q "$package_name" >/dev/null 2>&1 && return 0
  download "$url" "$output"
  sudo dnf install -y "$output"
}

install_flatpak_app() {
  local app_id=$1
  flatpak info --user "$app_id" >/dev/null 2>&1 && return 0
  flatpak install --user --noninteractive -y flathub "$app_id"
}

if [[ "$SECTION" == all || "$SECTION" == flatpak ]] &&
   [[ "$INSTALL_DISCORD" == true || "$INSTALL_OBSIDIAN" == true ]]; then
  install_available_packages flatpak
  command_exists flatpak || die "Flatpak non è disponibile: impossibile installare le app desktop."
  flatpak remote-add --user --if-not-exists flathub "$FLATHUB_REPO_URL"

  [[ "$INSTALL_DISCORD" == true ]] && install_flatpak_app com.discordapp.Discord
  [[ "$INSTALL_OBSIDIAN" == true ]] && install_flatpak_app md.obsidian.Obsidian
fi

if [[ "$SECTION" == all || "$SECTION" == rpm ]] && [[ "$INSTALL_DBEAVER" == true ]]; then
  install_rpm_url dbeaver-ce \
    "$DBEAVER_RPM_URL" \
    "$TOOLS_DIR/tmp/dbeaver-ce-latest.x86_64.rpm"
fi

if [[ "$SECTION" == all || "$SECTION" == rpm ]] &&
   [[ "$INSTALL_THUNDERBIRD" == true || "$INSTALL_LIBREOFFICE" == true ]]; then
  desktop_rpm_packages=()
  [[ "$INSTALL_THUNDERBIRD" == true ]] && desktop_rpm_packages+=(thunderbird)
  [[ "$INSTALL_LIBREOFFICE" == true ]] && desktop_rpm_packages+=(libreoffice)
  install_available_packages "${desktop_rpm_packages[@]}"
fi

if [[ "$SECTION" == all || "$SECTION" == gnome ]] &&
   [[ "$INSTALL_DASH_TO_DOCK" == true || "$ENABLE_WINDOW_BUTTONS" == true ]]; then
  if ! command_exists gnome-shell; then
    warn "GNOME Shell non rilevata: configurazione Dash to Dock e pulsanti finestra saltata."
  else
    if [[ "$INSTALL_DASH_TO_DOCK" == true ]]; then
      install_available_packages gnome-shell-extension-dash-to-dock
      if command_exists gnome-extensions; then
        if ! gnome-extensions enable dash-to-dock@micxgx.gmail.com; then
          warn "Dash to Dock installata ma non ancora caricata da GNOME: esegui logout/login e rilancia --desktop."
        fi
      else
        warn "gnome-extensions non disponibile: impossibile abilitare Dash to Dock."
      fi
    fi

    if [[ "$ENABLE_WINDOW_BUTTONS" == true ]]; then
      if command_exists gsettings; then
        gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
      else
        warn "gsettings non disponibile: impossibile abilitare i pulsanti minimizza e massimizza."
      fi
    fi
  fi
fi

if [[ "$SECTION" == all || "$SECTION" == rpm ]] &&
   [[ "$INSTALL_BRUNO" == true && ! -x /usr/bin/bruno ]]; then
  bruno_url="$(curl -fsSL "$BRUNO_RELEASES_API_URL" | jq -r '.assets[] | select(.name | test("x86_64.*\\.rpm$|x86_64\\.rpm$"; "i")) | .browser_download_url' | head -n1)"
  if [[ -n "$bruno_url" && "$bruno_url" != null ]]; then
    install_rpm_url bruno "$bruno_url" "$TOOLS_DIR/tmp/bruno-latest.x86_64.rpm"
  else
    warn "RPM Bruno non trovato nella release GitHub più recente."
  fi
fi

if [[ "$SECTION" == all || "$SECTION" == jetbrains ]] &&
   [[ "$INSTALL_JETBRAINS_TOOLBOX" == true ]]; then
  toolbox_base="$TOOLS_DIR/jetbrains-toolbox"
  mkdir -p "$toolbox_base"
  if ! find "$toolbox_base" -type f -name jetbrains-toolbox -perm -u+x | grep -q .; then
    api="$JETBRAINS_TOOLBOX_API_URL"
    toolbox_url="$(curl -fsSL "$api" | jq -r '.TBA[0].downloads.linux.link // empty')"
    if [[ -z "$toolbox_url" ]]; then
      warn "URL JetBrains Toolbox non trovato nell’API ufficiale."
    else
      archive="$TOOLS_DIR/tmp/jetbrains-toolbox.tar.gz"
      download "$toolbox_url" "$archive"
      tar -xzf "$archive" -C "$toolbox_base" --strip-components=1
    fi
  fi
  toolbox_bin="$(find "$toolbox_base" -type f -name jetbrains-toolbox -perm -u+x | head -n1 || true)"
  if [[ -n "$toolbox_bin" ]]; then
    ln -sfn "$toolbox_bin" "$HOME/.local/bin/jetbrains-toolbox"
  fi
fi
