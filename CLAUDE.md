# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Mac bootstrap dotfiles repo (v1.2+). Running `./install.sh` opens an interactive component selector to provision a new Mac with CLI tools, GUI apps, fonts, shell config, and symlinked dotfiles. After the initial install, `./sync.sh` refreshes only the previously-selected components' configs.

## Key commands

```bash
# Interactive install (opens component selector)
./install.sh

# Install everything non-interactively
./install.sh --all

# Install specific components
./install.sh --components shell,wezterm,neovim

# Preview without changing the machine
./install.sh --all --dry-run

# Re-sync configs for previously installed components
./sync.sh

# Validate shell scripts before opening a PR
bash -n install.sh sync.sh lib/core.sh components/*.sh
shellcheck install.sh sync.sh lib/core.sh components/*.sh
./install.sh --all --dry-run

# Run tests
bash tests/installer_test.sh

# Enable the conventional commit hook (required before committing)
./scripts/install-hooks.sh

# Preview version bump
./scripts/bump-version.sh --dry-run
VERSION_BASE_REF=origin/main VERSION_HEAD_REF=HEAD ./scripts/bump-version.sh --report
```

## Architecture

### Component system

The installer auto-discovers modules from `components/*.sh` (sorted by filename prefix). Each module calls `component_define` with 14 positional arguments:

```
component_define id label description category default hidden dependencies \
                 kind package configs install_hook sync_hook dry_run_hook post_hook
```

- **kind**: `formula` (brew formula), `cask` (brew cask), `custom` (needs install hook), `virtual` (no package)
- **configs**: pipe-separated `source|destination` pairs relative to repo root and `$HOME`
- **dependencies**: comma-separated component IDs, resolved with topological sort (cycles are rejected)

The shared framework in `lib/core.sh` handles discovery, validation, dependency resolution, Homebrew installation, config symlinking with backup, dry-run support, and state persistence. `lib/ui.sh` provides the interactive terminal UI (uses `gum`).

Installer state is saved to `~/.config/power_mac/state` so `sync.sh` knows which components to refresh. Machines from before v1.2 are auto-migrated by detecting existing symlinks.

### Adding a new component

Create `components/NN-name.sh` with a single `component_define` call. For a standard Homebrew formula/cask, no hooks are needed. The numbering prefix controls load order. No changes to `install.sh`, `sync.sh`, or `lib/core.sh` are required.

## Commit conventions

Every commit **must** follow [Conventional Commits](https://www.conventionalcommits.org/). The `commit-msg` hook (`.githooks/commit-msg`) enforces this locally. Run `./scripts/install-hooks.sh` once after cloning.

Allowed prefixes: `feat`, `fix`, `breaking`, `chore`, `docs`, `refactor`, `perf`, `test`, `ci`, `build`, `revert`

Breaking changes: use `breaking:` or `feat!:` / `fix!:`

## Versioning

The canonical version lives in `VERSION`. `README.md` (badge + footer) and `install.sh` (header comment) are kept in sync automatically by `scripts/bump-version.sh`. **Do not edit version numbers manually in a PR.**

Semver mapping: `breaking:`/`feat!:`/`fix!:` = major, `feat:` = minor, everything else = patch.

Squash merges are disabled — the CI workflow needs individual conventional commits.

## Neovim config

`nvim/` is a LazyVim-based config. Plugins are declared under `nvim/lua/plugins/`, core options under `nvim/lua/config/`. The lockfile `nvim/lazy-lock.json` is not checked into the repo — Lazy.nvim regenerates it on first launch.

The neovim component depends on `ripgrep` and `fd`, which are auto-installed as dependencies.

## Dotfile symlink map

Config mappings are declared in each component's `component_define` call. Key mappings:

| Component | Repo file | Symlinked to |
|---|---|---|
| shell | `.zshrc` | `~/.zshrc` |
| shell | `.p10k.zsh` | `~/.p10k.zsh` |
| shell | `exports` | `~/.config/exports` |
| shell | `alias` | `~/.config/alias` |
| aerospace | `.aerospace.toml` | `~/.aerospace.toml` |
| wezterm | `wezterm.lua` | `~/.config/wezterm/wezterm.lua` |
| neovim | `nvim/` | `~/.config/nvim/` |
