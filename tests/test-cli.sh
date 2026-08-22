#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

help_output="$("$ROOT_DIR/install.sh" --help)"
grep -Fq '  --all' <<<"$help_output"
grep -Fq -- '--config-zsh-theme' <<<"$help_output"
grep -Fq 'INSTALL_AGENTS=true in config/local.env' <<<"$help_output"
grep -Fq './bin/provenance-audit.sh' <<<"$help_output"
grep -Fq 'Versioni, fonti e checksum: config/sources.env' <<<"$help_output"
[[ "$("$ROOT_DIR/install.sh" --info)" == "$help_output" ]]

printf '%s\n' 'OK   CLI --help/--info'
