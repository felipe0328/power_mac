#!/bin/bash

set -e

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

# ── 1. Homebrew ───────────────────────────────────────────────────────────────
step "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  warn "Homebrew not found — installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH immediately for Apple Silicon
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  ok "Homebrew installed"
else
  ok "Homebrew already installed"
fi

# ── 2. CLI tools ──────────────────────────────────────────────────────────────
step "Installing CLI tools..."
brew install tmux neovim lazygit direnv fzf
ok "CLI tools installed"

# ── 3. GUI apps ───────────────────────────────────────────────────────────────
step "Installing apps..."
brew install --cask ghostty aerospace alt-tab raycast maccy stats thaw font-meslo-lg-nerd-font
ok "Apps installed"

# ── 4. Oh My Zsh ─────────────────────────────────────────────────────────────
step "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  ok "Oh My Zsh installed"
else
  ok "Oh My Zsh already installed"
fi

# ── 5. Powerlevel10k theme ────────────────────────────────────────────────────
step "Installing Powerlevel10k..."
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  ok "Powerlevel10k installed"
else
  ok "Powerlevel10k already installed"
fi

# ── 6. zsh-autosuggestions plugin ─────────────────────────────────────────────
step "Installing zsh-autosuggestions..."
ZSH_AUTO_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
if [ ! -d "$ZSH_AUTO_DIR" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTO_DIR"
  ok "zsh-autosuggestions installed"
else
  ok "zsh-autosuggestions already installed"
fi

# ── 7. Dotfiles ───────────────────────────────────────────────────────────────
step "Linking dotfiles..."
mkdir -p "$HOME/.config"

ln -sf "$SCRIPT_DIR/.zshrc" "$HOME/.zshrc"
ln -sf "$SCRIPT_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
ln -sf "$SCRIPT_DIR/.aerospace.toml" "$HOME/.aerospace.toml"
ln -sf "$SCRIPT_DIR/exports" "$HOME/.config/exports"
mkdir -p "$HOME/.config/ghostty"
ln -sf "$SCRIPT_DIR/config.ghostty" "$HOME/.config/ghostty/config.ghostty"
# macOS also loads Application Support after XDG (and overrides it) — remove defaults there
rm -f "$HOME/Library/Application Support/com.mitchellh.ghostty/config" \
      "$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty" 2>/dev/null || true

# nvim — back up if a real directory already exists (not a symlink)
if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  warn "Existing nvim config found — backing up to ~/.config/nvim.bak"
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
fi
ln -sf "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"

# Create an empty alias stub so .zshrc doesn't error on first launch
touch "$HOME/.config/alias"

ok "Dotfiles linked"

# ── 8. App preferences ────────────────────────────────────────────────────────
step "Applying app preferences..."
# Kill apps first so they don't overwrite the imported prefs on quit
killall Stats 2>/dev/null || true
killall Thaw 2>/dev/null || true

defaults import eu.exelban.Stats "$SCRIPT_DIR/stats/eu.exelban.Stats.plist"
defaults import com.stonerl.Thaw "$SCRIPT_DIR/thaw/com.stonerl.Thaw.plist"
ok "App preferences applied"

# ── 9. Tmux ───────────────────────────────────────────────────────────────────
step "Setting up Tmux..."
bash "$SCRIPT_DIR/tmux-installer/tmux-installer.sh"

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}All done!${NC}"
echo -e "  Restart your terminal (or run ${BLUE}exec zsh${NC}) to apply all changes."
echo -e "  ${YELLOW}Note:${NC} Fill in ~/.config/alias and ~/.config/uber_db with your personal entries.\n"
