<div align="center">

# ⚡ power_mac

**Bootstrap a new Mac from zero to fully productive in one command.**

*Dotfiles, apps, terminal setup, window management — all automated.*

![Version](https://img.shields.io/badge/version-1.4.1-blueviolet?style=flat-square)
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

The installer opens an interactive terminal menu. Use the arrow keys to move,
**Space** to select or deselect software, and **Enter** to continue. Recommended
apps are selected initially.

The interactive flow starts with a `power_mac` welcome screen and a compact
preparation log while it discovers modules, restores saved preferences, and
readies the terminal interface. It then transitions into a categorized app
table for selection.

> 💡 **Homebrew** and the Gum terminal interface are installed automatically
> when needed.

### Non-interactive usage

```bash
# Install all compatible components (recommended alternatives win)
./install.sh --all

# Install only selected component bundles
./install.sh --components shell,wezterm,neovim

# Preview without changing the machine
./install.sh --components tmux --tmux-style top --dry-run
```

Run `./install.sh --help` for the complete component list.

---

## 📦 What gets installed

### 🖥️ Terminal & Shell

| Tool | Description | Install |
| --- | --- | --- |
| 🖥️ **WezTerm** | GPU-accelerated terminal with Lua-based config | `brew install --cask wezterm` |
| 🐚 **Zsh + Oh My Zsh** | Shell framework with plugins and themes | installed by script |
| ⚡ **Powerlevel10k** | Fast, highly customizable Zsh prompt theme | cloned by script |
| 🪟 **Tmux** | Terminal multiplexer — sessions, splits, status bar | `brew install tmux` |

### 🪄 Window Management

| Tool | Description | Install |
| --- | --- | --- |
| 🌌 **AeroSpace** | i3-like tiling window manager for macOS | `brew install --cask nikitabobko/tap/aerospace` |
| ▭ **Rectangle** | Keyboard-driven window snapping | `brew install --cask rectangle` |
| 🔄 **AltTab** | Windows-style alt-tab app switcher | `brew install --cask alt-tab` |

> AeroSpace and Rectangle are alternatives. The installer prevents selecting
> both and keeps only the most recently selected one in its saved state. When
> switching, it reminds you to quit or disable the previous window manager.

### 🛠️ Productivity & Utilities

| Tool | Description | Install |
| --- | --- | --- |
| 📋 **Maccy** | Lightweight keyboard-driven clipboard manager | `brew install --cask maccy` |
| 🚀 **Raycast** | Launcher and productivity command palette | `brew install --cask raycast` |
| 📊 **Stats** | System monitor (CPU, RAM, temps) in the menu bar | `brew install --cask stats` |
| 🧊 **Thaw** | Menu bar manager — hide and organize menu bar icons | `brew install --cask thaw` |

### ✍️ Editor

| Tool | Description | Install |
| --- | --- | --- |
| 💚 **Neovim** | Hyperextensible Vim-based editor (LazyVim config included) | `brew install neovim` |
| 😺 **Lazygit** | Terminal UI for Git | `brew install lazygit` |

---

## 🗂️ Dotfiles & configs included

| File/Folder | Maps to | Description |
| --- | --- | --- |
| `📄 .zshrc` | `~/.zshrc` | Zsh config with Oh My Zsh, plugins, and PATH setup |
| `🎨 .p10k.zsh` | `~/.p10k.zsh` | Powerlevel10k prompt layout and segments |
| `📤 exports` | `~/.config/exports` | Environment variable exports |
| `⌨️ alias` | `~/.config/alias` | Common zsh aliases (git, docker, tmux, tools) |
| `🌌 .aerospace.toml` | `~/.aerospace.toml` | AeroSpace workspace and keybinding config |
| `🖥️ wezterm.lua` | `~/.config/wezterm/wezterm.lua` | WezTerm terminal font, theme, and UI settings |
| `💚 nvim/` | `~/.config/nvim/` | Full LazyVim-based Neovim configuration |
| `🪟 tmux-installer/` | — | Tmux installer script + Dracula-themed status bar configs |

---

## ⚙️ What the script does

1. 🍺 Bootstraps **Homebrew** and the Gum terminal UI when needed
2. ✅ Lets you select individual app/config bundles
3. 🧩 Resolves shared dependencies such as **MesloLGS NF**
4. 📦 Installs only the selected CLI tools and GUI apps
5. 🔗 Safely backs up and symlinks each selected component's configs
6. 💾 Records successful selections for future config syncs
7. 🪝 Installs this repository's conventional-commit Git hook

## 🔄 Sync selected configs

`install.sh` records successful selections in `~/.config/power_mac/state`.
Running `./sync.sh` updates only those components:

```bash
./sync.sh
./sync.sh --components shell,wezterm
./sync.sh --all --dry-run
```

Machines configured before v1.2 are migrated automatically. If no state file
exists, `sync.sh` first detects configs already linked to this repository. When
none can be detected, it preserves the original behavior by syncing the legacy
Shell, WezTerm, Neovim, and AeroSpace config set. Every successful sync also
reinstalls this repository's Git hooks before migrated component state is saved.

## 🧩 Adding software

Components are auto-discovered from `components/*.sh`. A normal Homebrew formula
or cask needs only one small module declaring its ID, label, package, and optional
config mappings. Shared discovery, menus, validation, dependency ordering,
installation, dry-runs, state, and syncing require no core-script changes.

---

## 📝 Notes

- After the install, run `exec zsh` or restart your terminal to apply all changes
- Work-specific aliases can go in `~/.config/goodrx_alias` (loaded before `~/.config/alias`)
- Contributing? See [CONTRIBUTOR.md](CONTRIBUTOR.md) for commit format, versioning, and PR workflow.

---

<div align="center">

Made with ❤️ for a productive Mac setup &nbsp;•&nbsp; **v1.4.1**

</div>
