export PATH="$HOME/.local/bin:$PATH"

if [[ -n "${__KITTY_WINDOW_ID__:-}" ]] && command -v kitten >/dev/null 2>&1; then
  __SSH__() {
    command kitten __SSH__ "$@"
  }
fi
