#!/usr/bin/env bash
set +u
[[ -f "$HOME/.config/workstation-setup/env.zsh" ]] && source "$HOME/.config/workstation-setup/env.zsh"

check() {
  local label=$1 command_name=$2
  if command -v "$command_name" >/dev/null 2>&1; then
    printf 'OK   %-20s %s\n' "$label" "$(command -v "$command_name")"
  else
    printf 'MISS %-20s\n' "$label"
  fi
}

check Git git
check Gitk gitk
check SSH ssh
check Zsh zsh
check Java java
check Maven mvn
check Gradle gradle
check Node node
check NVM nvm
check Conda conda
check VSCode code
check Docker docker
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  printf 'OK   %-20s %s\n' 'Docker Compose' "$(docker compose version --short 2>/dev/null || docker compose version 2>/dev/null)"
else
  printf 'MISS %-20s\n' 'Docker Compose'
fi
if rpm -q docker-desktop >/dev/null 2>&1; then
  printf 'OK   %-20s %s\n' 'Docker Desktop' '/opt/docker-desktop'
else
  printf 'MISS %-20s\n' 'Docker Desktop'
fi
if command -v podman >/dev/null 2>&1; then
  printf 'OPT  %-20s %s\n' 'Podman' "$(command -v podman)"
fi
check DBeaver dbeaver
check Bruno bruno
check Thunderbird thunderbird
check LibreOffice libreoffice
if command -v gnome-shell >/dev/null 2>&1; then
  if command -v gnome-extensions >/dev/null 2>&1 &&
     gnome-extensions list --enabled 2>/dev/null | grep -Fqx dash-to-dock@micxgx.gmail.com; then
    printf 'OK   %-20s %s\n' 'Dash to Dock' 'abilitata'
  elif rpm -q gnome-shell-extension-dash-to-dock >/dev/null 2>&1; then
    printf 'WARN %-20s %s\n' 'Dash to Dock' 'installata ma non abilitata'
  else
    printf 'MISS %-20s\n' 'Dash to Dock'
  fi
  if command -v gsettings >/dev/null 2>&1; then
    window_buttons="$(gsettings get org.gnome.desktop.wm.preferences button-layout 2>/dev/null)"
    if [[ "$window_buttons" == *minimize* && "$window_buttons" == *maximize* ]]; then
      printf 'OK   %-20s %s\n' 'Window buttons' "$window_buttons"
    else
      printf 'WARN %-20s %s\n' 'Window buttons' "$window_buttons"
    fi
  fi
fi
if command -v flatpak >/dev/null 2>&1 && flatpak info --user com.discordapp.Discord >/dev/null 2>&1; then
  printf 'OK   %-20s %s\n' 'Discord' 'com.discordapp.Discord (Flatpak)'
else
  printf 'MISS %-20s\n' 'Discord'
fi
if command -v flatpak >/dev/null 2>&1 && flatpak info --user md.obsidian.Obsidian >/dev/null 2>&1; then
  printf 'OK   %-20s %s\n' 'Obsidian' 'md.obsidian.Obsidian (Flatpak)'
else
  printf 'MISS %-20s\n' 'Obsidian'
fi
check OpenVPN openvpn
check OpenConnect openconnect
check 'SMB/CIFS' mount.cifs
check TuneD tuned-adm
check 'Power mode' laptop-power-mode
check 'Virt Manager' virt-manager
check 'Virsh' virsh
check 'Virt Install' virt-install
check 'Vagrant' vagrant

zsh_theme="$HOME/.config/workstation-setup/zsh-theme.zsh"
if [[ -f "$zsh_theme" ]] || grep -Fq '# >>> workstation-setup zsh theme >>>' "$HOME/.zshrc" 2>/dev/null; then
  printf '\nTema Zsh opzionale:\n'
  check Zsh zsh
  check Starship starship
  [[ -r "$HOME/.config/starship.toml" ]] &&
    printf 'OK   %-20s %s\n' 'Starship config' "$HOME/.config/starship.toml" ||
    printf 'MISS %-20s\n' 'Starship config'
  grep -Fq 'starship init zsh' "$zsh_theme" 2>/dev/null &&
    printf 'OK   %-20s\n' 'Starship init' || printf 'MISS %-20s\n' 'Starship init'
  if grep -Fq 'zsh-syntax-highlighting.zsh' "$zsh_theme" 2>/dev/null &&
     { rpm -q zsh-syntax-highlighting >/dev/null 2>&1 ||
       [[ -r "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] ||
       [[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] ||
       [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; }; then
    printf 'OK   %-20s\n' 'Syntax highlighting'
  else
    printf 'MISS %-20s\n' 'Syntax highlighting'
  fi
  if grep -Fq 'zsh-autosuggestions.zsh' "$zsh_theme" 2>/dev/null &&
     { rpm -q zsh-autosuggestions >/dev/null 2>&1 ||
       [[ -r "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] ||
       [[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] ||
       [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; }; then
    printf 'OK   %-20s\n' 'Autosuggestions'
  else
    printf 'MISS %-20s\n' 'Autosuggestions'
  fi
  block_count="$(grep -Fc '# >>> workstation-setup zsh theme >>>' "$HOME/.zshrc" 2>/dev/null || true)"
  [[ "$block_count" == 1 ]] && printf 'OK   %-20s\n' 'Blocco .zshrc' ||
    printf 'WARN %-20s %s\n' 'Blocco .zshrc' "occorrenze: $block_count"
  if grep -Eq "^[[:space:]]*alias[[:space:]]+gs=['\"]git status['\"]" "$HOME/.zshrc" "$zsh_theme" 2>/dev/null; then
    printf 'WARN %-20s %s\n' 'Alias gs' "rilevato gs='git status'"
  else
    printf 'OK   %-20s %s\n' 'Alias gs' 'non definito dal setup'
  fi
fi

kitty_config="$HOME/.config/kitty/kitty.conf"
if grep -Fq '# workstation-setup: managed kitty config' "$kitty_config" 2>/dev/null; then
  printf '\nKitty opzionale:\n'
  check Kitty kitty
  [[ -r "$kitty_config" ]] && printf 'OK   %-20s %s\n' 'Kitty config' "$kitty_config" ||
    printf 'MISS %-20s\n' 'Kitty config'
  for setting in 'shell zsh' 'scrollback_lines 20000' 'detect_urls yes'; do
    grep -Eq "^[[:space:]]*${setting}[[:space:]]*$" "$kitty_config" &&
      printf 'OK   %-20s %s\n' 'Kitty setting' "$setting" ||
      printf 'MISS %-20s %s\n' 'Kitty setting' "$setting"
  done
  duplicate_count="$(grep -Fc '# workstation-setup: managed kitty config' "$kitty_config" || true)"
  [[ "$duplicate_count" == 1 ]] && printf 'OK   %-20s\n' 'Kitty managed file' ||
    printf 'WARN %-20s %s\n' 'Kitty managed file' "marker: $duplicate_count"
  if command -v kitty >/dev/null 2>&1; then
    kitty --version 2>/dev/null | sed 's/^/OK   Kitty version        /'
  fi
fi

tmux_config="$HOME/.tmux.conf"
if grep -Fq '# workstation-setup: managed tmux config' "$tmux_config" 2>/dev/null; then
  printf '\ntmux opzionale:\n'
  check tmux tmux
  [[ -r "$tmux_config" ]] && printf 'OK   %-20s %s\n' 'tmux config' "$tmux_config" ||
    printf 'MISS %-20s\n' 'tmux config'
  if command -v tmux >/dev/null 2>&1; then
    tmux -V | sed 's/^/OK   tmux version         /'
    doctor_socket="workstation-setup-doctor-$$"
    if tmux -L "$doctor_socket" -f "$tmux_config" new-session -d -s workstation-setup-doctor 2>/dev/null; then
      printf 'OK   %-20s\n' 'tmux parsing'
      for query in 'mouse:on' 'default-terminal:tmux-256color' 'base-index:1' 'history-limit:100000'; do
        option="${query%%:*}" expected="${query#*:}"
        actual="$(tmux -L "$doctor_socket" show-options -gv "$option" 2>/dev/null || true)"
        [[ "$actual" == "$expected" ]] && printf 'OK   %-20s %s=%s\n' 'tmux option' "$option" "$actual" ||
          printf 'WARN %-20s %s=%s\n' 'tmux option' "$option" "${actual:-missing}"
      done
      pane_index="$(tmux -L "$doctor_socket" show-window-options -gv pane-base-index 2>/dev/null || true)"
      renumber="$(tmux -L "$doctor_socket" show-options -gv renumber-windows 2>/dev/null || true)"
      features="$(tmux -L "$doctor_socket" show-options -gv terminal-features 2>/dev/null || true)"
      [[ "$pane_index" == 1 ]] && printf 'OK   %-20s %s\n' 'tmux option' 'pane-base-index=1' ||
        printf 'WARN %-20s %s\n' 'tmux option' "pane-base-index=${pane_index:-missing}"
      [[ "$renumber" == on ]] && printf 'OK   %-20s %s\n' 'tmux option' 'renumber-windows=on' ||
        printf 'WARN %-20s %s\n' 'tmux option' "renumber-windows=${renumber:-missing}"
      [[ "$features" == *'xterm-kitty:RGB:clipboard'* ]] &&
        printf 'OK   %-20s %s\n' 'tmux true color' 'xterm-kitty:RGB:clipboard' ||
        printf 'WARN %-20s\n' 'tmux true color'
      tmux -L "$doctor_socket" kill-server 2>/dev/null || true
    else
      printf 'FAIL %-20s %s\n' 'tmux parsing' "$tmux_config"
    fi
  fi
  duplicate_count="$(grep -Fc '# workstation-setup: managed tmux config' "$tmux_config" || true)"
  [[ "$duplicate_count" == 1 ]] && printf 'OK   %-20s\n' 'tmux managed file' ||
    printf 'WARN %-20s %s\n' 'tmux managed file' "marker: $duplicate_count"
fi

printf '\nGit include condizionali:\n'
git config --global --get-regexp '^includeif\.' 2>/dev/null || echo 'Nessun profilo Git aggiunto.'

printf '\nCartelle XDG:\n'
for type in DESKTOP DOWNLOAD DOCUMENTS MUSIC PICTURES VIDEOS TEMPLATES PUBLICSHARE; do
  if command -v xdg-user-dir >/dev/null 2>&1; then
    printf '  %-12s %s\n' "$type" "$(xdg-user-dir "$type" 2>/dev/null)"
  fi
done

if command -v laptop-power-mode >/dev/null 2>&1; then
  printf '\nConfigurazione energetica:\n'
  laptop-power-mode status
  printf '\nServizio di avvio:\n'
  systemctl is-enabled laptop-power-mode.service 2>/dev/null || true
  systemctl is-active laptop-power-mode.service 2>/dev/null || true
fi

if command -v docker >/dev/null 2>&1; then
  printf '
Docker runtime:
'
  docker context ls 2>/dev/null || true
  if docker info >/dev/null 2>&1; then
    echo 'Docker daemon: raggiungibile senza sudo.'
    if docker info --format '{{json .SecurityOptions}}' 2>/dev/null | grep -q rootless; then
      echo 'Docker security: ROOTLESS attivo.'
    else
      echo 'Docker security: ATTENZIONE, daemon corrente non risulta rootless.'
    fi
  else
    echo 'Docker daemon: non raggiungibile; controlla systemctl --user status docker.'
  fi
fi

if command -v virsh >/dev/null 2>&1; then
  printf '
Virtualizzazione:
'
  [[ -e /dev/kvm ]] && echo 'KVM: disponibile (/dev/kvm).' || echo 'KVM: non disponibile.'
  virsh -c qemu:///system list --all >/dev/null 2>&1 &&     echo 'libvirt: qemu:///system raggiungibile.' ||     echo 'libvirt: qemu:///system non raggiungibile nella sessione corrente.'
fi
