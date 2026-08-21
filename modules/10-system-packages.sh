#!/usr/bin/env bash
set -Eeuo pipefail
source "$ROOT_DIR/lib/common.sh"
load_config "$ROOT_DIR"

sudo -v
if [[ "$RUN_SYSTEM_UPGRADE" == true ]]; then
  sudo dnf upgrade --refresh -y
fi

base_packages=(
  git gitk git-lfs openssh-clients curl wget rsync
  unzip zip tar gzip bzip2 xz jq tree
  zsh bash-completion xdg-user-dirs
  gedit
  cifs-utils
)

install_available_packages "${base_packages[@]}"

[[ "$PROFILE" == "base" ]] && exit 0

dev_packages=(
  ripgrep fd-find fzf bat btop htop tmux ShellCheck
  gcc gcc-c++ make cmake ninja-build pkgconf-pkg-config
  openssl-devel libffi-devel zlib-ng-compat-devel
  gdb strace lsof
  pciutils usbutils iproute bind-utils traceroute nmap-ncat
)

install_available_packages "${dev_packages[@]}"

if [[ "$INSTALL_VPN_SUPPORT" == true ]]; then
  vpn_packages=(
    openvpn openconnect
    NetworkManager-openvpn NetworkManager-openvpn-gnome
    NetworkManager-openconnect NetworkManager-openconnect-gnome
  )
  install_available_packages "${vpn_packages[@]}"
fi

if [[ "$INSTALL_PODMAN" == true ]]; then
  install_available_packages podman podman-compose
fi
