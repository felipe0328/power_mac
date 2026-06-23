#!/bin/bash
# Version: 1.0.1

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

install_cask() {
  local cask="$1"
  local name="${cask##*/}"  # strip tap prefix (e.g. nikitabobko/tap/aerospace → aerospace)
  if brew list --cask "$name" &>/dev/null; then
    ok "$name already installed"
  else
    if brew install --cask "$cask"; then
      ok "$name installed"
    else
      warn "$name installation failed — skipping"
    fi
  fi
}

# MesloLGS NF — required by wezterm.lua and .p10k.zsh (nerdfont-v3).
# Uses the Powerlevel10k-patched build so the family name matches configs exactly.
install_meslo_lgs_nf() {
  local variant="$1"
  local filename="MesloLGS NF ${variant}.ttf"
  local dest="$HOME/Library/Fonts/$filename"
  local url_variant="${variant// /%20}"

  if [ -f "$dest" ]; then
    ok "$filename already installed"
    return 0
  fi

  if curl -fsSL \
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${url_variant}.ttf" \
    -o "$dest"; then
    ok "$filename installed"
  else
    warn "Failed to install $filename"
  fi
}

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

# ── 3. Fonts ──────────────────────────────────────────────────────────────────
step "Installing fonts..."
mkdir -p "$HOME/Library/Fonts"
for variant in "Regular" "Bold" "Italic" "Bold Italic"; do
  install_meslo_lgs_nf "$variant"
done
ok "Fonts installed (MesloLGS NF — WezTerm + Powerlevel10k)"

# ── 4. GUI apps ───────────────────────────────────────────────────────────────
step "Installing apps..."
for cask in wezterm nikitabobko/tap/aerospace alt-tab raycast maccy stats thaw; do
  install_cask "$cask"
done

# ── 5. Oh My Zsh ─────────────────────────────────────────────────────────────
step "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  ok "Oh My Zsh installed"
else
  ok "Oh My Zsh already installed"
fi

# ── 6. Powerlevel10k theme ────────────────────────────────────────────────────
step "Installing Powerlevel10k..."
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  ok "Powerlevel10k installed"
else
  ok "Powerlevel10k already installed"
fi

# ── 7. zsh-autosuggestions plugin ─────────────────────────────────────────────
step "Installing zsh-autosuggestions..."
ZSH_AUTO_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
if [ ! -d "$ZSH_AUTO_DIR" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_AUTO_DIR"
  ok "zsh-autosuggestions installed"
else
  ok "zsh-autosuggestions already installed"
fi

# ── 8. Dotfiles ───────────────────────────────────────────────────────────────
step "Linking dotfiles..."
mkdir -p "$HOME/.config"

ln -sf "$SCRIPT_DIR/.zshrc"         "$HOME/.zshrc"
ln -sf "$SCRIPT_DIR/.p10k.zsh"      "$HOME/.p10k.zsh"
ln -sf "$SCRIPT_DIR/.aerospace.toml" "$HOME/.aerospace.toml"
ln -sf "$SCRIPT_DIR/exports"        "$HOME/.config/exports"

mkdir -p "$HOME/.config/wezterm"
ln -sf "$SCRIPT_DIR/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

# nvim — back up if a real directory already exists (not a symlink)
if [ -d "$HOME/.config/nvim" ] && [ ! -L "$HOME/.config/nvim" ]; then
  warn "Existing nvim config found — backing up to ~/.config/nvim.bak"
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak"
fi
ln -sf "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"

# Create an empty alias stub so .zshrc doesn't error on first launch
touch "$HOME/.config/alias"

ok "Dotfiles linked"

# ── 9. Tmux ──────────────────────────────────────────────────────────────────
step "Setting up Tmux..."
# Run from its own directory so relative `cp` paths inside the script resolve correctly
(cd "$SCRIPT_DIR/tmux-installer" && bash tmux-installer.sh)
ok "Tmux configured"

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}All done!${NC}"
echo -e "  Restart your terminal (or run ${BLUE}exec zsh${NC}) to apply all changes."
echo -e "  ${YELLOW}Note:${NC} Fill in ~/.config/alias with your personal entries.\n"
