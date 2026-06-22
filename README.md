<div align="center">

# ⚡ power_mac

**Bootstrap a new Mac from zero to fully productive in one command.**

*Dotfiles, apps, terminal setup, window management — all automated.*

![Version](https://img.shields.io/badge/version-1.0.0-blueviolet?style=flat-square)
![macOS](https://img.shields.io/badge/macOS-14%2B-black?style=flat-square&logo=apple)
![Shell](https://img.shields.io/badge/shell-zsh-informational?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

</div>

---

## 🚀 Quick Start

```bash
git clone https://github.com/felipe0328/power_mac.git ~/power_conf
cd ~/power_conf
./install.sh
```

> 💡 **Homebrew** will be installed automatically if not present on the machine.

---

## 📦 What gets installed

### 🖥️ Terminal & Shell

| Tool | Description | Install |
|------|-------------|---------|
| 🦁 **Ghostty** | GPU-accelerated terminal with native macOS UI | `brew install --cask ghostty` |
| 🐚 **Zsh + Oh My Zsh** | Shell framework with plugins and themes | installed by script |
| ⚡ **Powerlevel10k** | Fast, highly customizable Zsh prompt theme | cloned by script |
| 🪟 **Tmux** | Terminal multiplexer — sessions, splits, status bar | `brew install tmux` |

### 🪄 Window Management

| Tool | Description | Install |
|------|-------------|---------|
| 🌌 **AeroSpace** | i3-like tiling window manager for macOS | `brew install --cask aerospace` |
| 🔄 **AltTab** | Windows-style alt-tab app switcher | `brew install --cask alt-tab` |

### 🛠️ Productivity & Utilities

| Tool | Description | Install |
|------|-------------|---------|
| 🚀 **Raycast** | Spotlight replacement — launcher, clipboard, snippets | `brew install --cask raycast` |
| 📋 **Maccy** | Lightweight keyboard-driven clipboard manager | `brew install --cask maccy` |
| 📊 **Stats** | System monitor (CPU, RAM, temps) in the menu bar | `brew install --cask stats` |
| 🧊 **Thaw** | Menu bar manager — hide and organize menu bar icons | `brew install --cask thaw` |

### ✍️ Editor

| Tool | Description | Install |
|------|-------------|---------|
| 💚 **Neovim** | Hyperextensible Vim-based editor (LazyVim config included) | `brew install neovim` |
| 😺 **Lazygit** | Terminal UI for Git | `brew install lazygit` |

---

## 🗂️ Dotfiles & configs included

| File/Folder | Maps to | Description |
|---|---|---|
| `📄 .zshrc` | `~/.zshrc` | Zsh config with Oh My Zsh, plugins, and PATH setup |
| `🎨 .p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k prompt layout and segments |
| `📤 exports` | `~/.config/exports` | Environment variable exports |
| `🌌 .aerospace.toml` | `~/.aerospace.toml` | AeroSpace workspace and keybinding config |
| `🦁 config.ghostty` | `~/.config/ghostty/config.ghostty` | Ghostty terminal font, theme, and UI settings |
| `💚 nvim/` | `~/.config/nvim/` | Full LazyVim-based Neovim configuration |
| `🪟 tmux-installer/` | — | Tmux installer script + Dracula-themed status bar configs |
| `📊 stats/` | `~/Library/Preferences/` | Stats menu bar layout and module preferences |
| `🧊 thaw/` | `~/Library/Preferences/` | Thaw menu bar icon configuration |

---

## ⚙️ What the script does

1. 🍺 Installs **Homebrew** if not present
2. 📦 Installs all **CLI tools** — tmux, neovim, lazygit, direnv, fzf
3. 🖥️ Installs all **GUI apps** via Homebrew Cask
4. 🐚 Installs **Oh My Zsh** and the **Powerlevel10k** theme
5. 🔌 Installs **zsh-autosuggestions** plugin
6. 🔗 **Symlinks** all dotfiles to their correct locations
7. 🎛️ Applies **app preferences** for Stats and Thaw
8. 🪟 Runs the interactive **Tmux installer**

---

## 📝 Notes

- After the install, run `exec zsh` or restart your terminal to apply all changes
- `~/.config/alias` is created as an empty stub — fill it in with your personal aliases
- App preferences (Stats, Thaw) are applied before the apps launch to avoid them being overwritten

---

<div align="center">

Made with ❤️ for a productive Mac setup &nbsp;•&nbsp; **v1.0.0**

</div>
