#!/usr/bin/env bash
# Point this repo at .githooks/ (commit-msg validator).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.githooks"

chmod +x "$HOOKS_DIR/commit-msg"
git -C "$REPO_ROOT" config core.hooksPath .githooks

echo "Git hooks installed (core.hooksPath=.githooks)"
