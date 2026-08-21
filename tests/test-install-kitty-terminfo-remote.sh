#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
test_dir="$(mktemp -d)"
trap 'rm -rf -- "$test_dir"' EXIT

mkdir -p "$test_dir/bin" "$test_dir/remote-home"
install -m 0755 "$ROOT_DIR/tests/fixtures/ssh" "$test_dir/bin/ssh"

for _ in 1 2; do
  PATH="$test_dir/bin:$PATH" \
    TEST_REMOTE_HOME="$test_dir/remote-home" \
    "$ROOT_DIR/bin/install-kitty-terminfo-remote" test-host >/dev/null
done

TERMINFO="$test_dir/remote-home/.terminfo" infocmp -x xterm-kitty >/dev/null

mkdir -p "$test_dir/empty-path"
if PATH="$test_dir/bin:$PATH" \
  TEST_REMOTE_HOME="$test_dir/remote-home" \
  TEST_REMOTE_PATH="$test_dir/empty-path" \
  "$ROOT_DIR/bin/install-kitty-terminfo-remote" test-host \
    >"$test_dir/missing-tic.log" 2>&1; then
  printf '%s\n' 'FAIL helper riuscito senza tic remoto' >&2
  exit 1
fi
grep -Fq 'tic non è disponibile sul sistema remoto' "$test_dir/missing-tic.log"

printf '%s\n' 'OK   helper terminfo remoto idempotente'
