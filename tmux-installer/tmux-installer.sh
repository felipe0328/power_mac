#!/usr/bin/env bash

# Backward-compatible entrypoint. Tmux is now managed by the shared component
# system so it receives the same backup, state, dry-run, and validation behavior.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STYLE="${1:-bottom}"

case "$STYLE" in
  top|bottom) ;;
  *)
    printf 'Usage: %s [top|bottom]\n' "$0" >&2
    exit 1
    ;;
esac

exec "$SCRIPT_DIR/../install.sh" --components tmux --tmux-style "$STYLE"
