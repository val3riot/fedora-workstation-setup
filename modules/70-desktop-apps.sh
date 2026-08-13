#!/usr/bin/env bash
set -Eeuo pipefail
source "$ROOT_DIR/lib/common.sh"
load_config "$ROOT_DIR"
[[ "$PROFILE" == "development" ]] || exit 0

install_rpm_url() {
  local package_name=$1 url=$2 output=$3
  rpm -q "$package_name" >/dev/null 2>&1 && return 0
  download "$url" "$output"
  sudo dnf install -y "$output"
}

if [[ "$INSTALL_DBEAVER" == true ]]; then
  install_rpm_url dbeaver-ce \
    "$DBEAVER_RPM_URL" \
    "$TOOLS_DIR/tmp/dbeaver-ce-latest.x86_64.rpm"
fi

if [[ "$INSTALL_BRUNO" == true && ! -x /usr/bin/bruno ]]; then
  bruno_url="$(curl -fsSL "$BRUNO_RELEASES_API_URL" | jq -r '.assets[] | select(.name | test("x86_64.*\\.rpm$|x86_64\\.rpm$"; "i")) | .browser_download_url' | head -n1)"
  if [[ -n "$bruno_url" && "$bruno_url" != null ]]; then
    install_rpm_url bruno "$bruno_url" "$TOOLS_DIR/tmp/bruno-latest.x86_64.rpm"
  else
    warn "RPM Bruno non trovato nella release GitHub più recente."
  fi
fi

if [[ "$INSTALL_JETBRAINS_TOOLBOX" == true ]]; then
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
