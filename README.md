# power_conf

A personal setup repo to bootstrap a new Mac with all the dev tools and dotfiles ready to go. Clone this repo and run the install script — it handles everything from Homebrew to terminal configs.

> The install script will automatically install **Homebrew** if it is not already present on the machine.

---

## What gets installed

### Terminal & Shell

| Tool | Description | Install |
|------|-------------|---------|
| **Ghostty** | GPU-accelerated terminal with native macOS UI | `brew install --cask ghostty` |
| **Zsh + Oh My Zsh** | Shell framework with plugins and themes | installed by script |
| **Powerlevel10k** | Fast, highly customizable Zsh prompt theme | `brew install powerlevel10k` |
| **Tmux** | Terminal multiplexer — sessions, splits, status bar | `brew install tmux` |

### Window Management

| Tool | Description | Install |
|------|-------------|---------|
| **AeroSpace** | i3-like tiling window manager for macOS | `brew install --cask aerospace` |
| **AltTab** | Windows-style alt-tab app switcher | `brew install --cask alt-tab` |

### Productivity & Utilities

| Tool | Description | Install |
|------|-------------|---------|
| **Raycast** | Spotlight replacement — launcher, clipboard, snippets | `brew install --cask raycast` |
| **Maccy** | Lightweight keyboard-driven clipboard manager | `brew install --cask maccy` |
| **Stats** | System monitor (CPU, RAM, temps) in the menu bar | `brew install --cask stats` |
| **Thaw** | Menu bar manager — hide and organize menu bar icons | `brew install --cask thaw` |

### Editor

| Tool | Description | Install |
|------|-------------|---------|
| **Neovim** | Hyperextensible Vim-based editor (LazyVim config included) | `brew install neovim` |
| **Lazygit** | Terminal UI for Git | `brew install lazygit` |

---

## Dotfiles & configs included

| File/Folder | Maps to | Description |
|---|---|---|
| `.zshrc` | `~/.zshrc` | Zsh config with Oh My Zsh, plugins, and PATH setup |
| `.p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k prompt layout and segments |
| `exports` | `~/.config/exports` | Environment variable exports |
| `.aerospace.toml` | `~/.aerospace.toml` | AeroSpace workspace and keybinding config |
| `nvim/` | `~/.config/nvim/` | Full LazyVim-based Neovim configuration |
| `tmux-installer/` | — | Tmux installer script + Dracula-themed status bar configs |
| `stats/` | `~/Library/Preferences/` | Stats menu bar layout and module preferences |
| `thaw/` | `~/Library/Preferences/` | Thaw menu bar icon configuration |

---

## Usage

```bash
git clone <this-repo> ~/power_conf
cd ~/power_conf
chmod +x install.sh
./install.sh
```
