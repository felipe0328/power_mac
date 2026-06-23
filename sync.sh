#!/bin/bash
#
# sync.sh — push config changes from this repo onto your machine.
#
# Use this after you edit a config in this folder (e.g. config.ghostty) and
# want the change applied to your computer. It does NOT install anything; it
# only refreshes the symlinks/preferences that install.sh originally set up.
#
# It keeps going if a single item fails and prints a summary at the end.

# Note: intentionally NOT using `set -e` so one failing step doesn't abort the
# whole sync. We track failures manually and exit non-zero if any occurred.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Colors ────────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

step() { echo -e "\n${BLUE}==>${NC} $1"; }
ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }
err()  { echo -e "  ${RED}✗${NC} $1"; }

FAILURES=0
fail() { err "$1"; FAILURES=$((FAILURES + 1)); }

# Back up a path if it exists and is a real file/dir (not the symlink we manage).
backup_if_real() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    local bak
    bak="${target}.bak.$(date +%Y%m%d%H%M%S)"
    if mv "$target" "$bak"; then
      warn "Existing $(basename "$target") was a real file — backed up to $bak"
    else
      fail "Could not back up $target"
      return 1
    fi
  fi
}

# link_config <source-in-repo> <destination-on-machine>
# Points the destination at the repo file so future edits stay in sync.
link_config() {
  local src="$1" dest="$2"

  if [ ! -e "$src" ]; then
    fail "Source missing, skipped: $src"
    return 1
  fi

  if ! mkdir -p "$(dirname "$dest")"; then
    fail "Could not create directory for $dest"
    return 1
  fi

  # If the destination is already a symlink to the right place, nothing to do.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    ok "$(basename "$dest") already up to date"
    return 0
  fi

  backup_if_real "$dest" || return 1

  if ln -sf "$src" "$dest"; then
    ok "Synced $(basename "$dest")"
  else
    fail "Could not link $dest -> $src"
    return 1
  fi
}

# import_prefs <domain> <plist-path> [app-name-to-quit]
import_prefs() {
  local domain="$1" plist="$2" app="${3:-}"

  if [ ! -f "$plist" ]; then
    fail "Plist missing, skipped: $plist"
    return 1
  fi

  # Quit the app first so it doesn't overwrite the imported prefs on exit.
  if [ -n "$app" ]; then
    killall "$app" 2>/dev/null || true
  fi

  if defaults import "$domain" "$plist"; then
    ok "Imported preferences for $domain"
  else
    fail "Could not import preferences for $domain"
    return 1
  fi
}

# ── 1. Dotfiles ───────────────────────────────────────────────────────────────
step "Syncing dotfiles..."
mkdir -p "$HOME/.config" || fail "Could not create ~/.config"

link_config "$SCRIPT_DIR/.zshrc"          "$HOME/.zshrc"
link_config "$SCRIPT_DIR/.p10k.zsh"       "$HOME/.p10k.zsh"
link_config "$SCRIPT_DIR/.aerospace.toml" "$HOME/.aerospace.toml"
link_config "$SCRIPT_DIR/exports"         "$HOME/.config/exports"
link_config "$SCRIPT_DIR/nvim"            "$HOME/.config/nvim"

# ── 2. Ghostty ────────────────────────────────────────────────────────────────
step "Syncing Ghostty config..."
link_config "$SCRIPT_DIR/config.ghostty" "$HOME/.config/ghostty/config"
# macOS also loads Application Support after XDG (and overrides it) — remove any
# stray defaults there so our config is the one that takes effect.
rm -f "$HOME/Library/Application Support/com.mitchellh.ghostty/config" \
      "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" 2>/dev/null || true
ok "Cleared Ghostty overrides in Application Support"

# ── 3. App preferences ────────────────────────────────────────────────────────
step "Syncing app preferences..."
import_prefs "eu.exelban.Stats" "$SCRIPT_DIR/stats/eu.exelban.Stats.plist" "Stats"
import_prefs "com.stonerl.Thaw" "$SCRIPT_DIR/thaw/com.stonerl.Thaw.plist"  "Thaw"

# ── Summary ───────────────────────────────────────────────────────────────────
if [ "$FAILURES" -eq 0 ]; then
  echo -e "\n${GREEN}Configs synced successfully.${NC}"
  echo -e "  Restart affected apps (or run ${BLUE}exec zsh${NC}) to pick up changes.\n"
  exit 0
else
  echo -e "\n${RED}Sync finished with $FAILURES issue(s).${NC} See the ${RED}✗${NC} lines above.\n"
  exit 1
fi
