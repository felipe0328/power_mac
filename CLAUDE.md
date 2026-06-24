# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Mac bootstrap dotfiles repo. Running `./install.sh` provisions a new Mac from scratch (Homebrew, CLI tools, GUI apps, fonts, Oh My Zsh + Powerlevel10k, symlinked dotfiles, git hooks, tmux). After the initial install, `./sync.sh` refreshes symlinks without reinstalling anything.

## Key commands

```bash
# Full install on a new Mac
./install.sh

# Re-apply symlinks after editing a config file (no reinstall)
./sync.sh

# Enable the conventional commit hook (required before committing)
./scripts/install-hooks.sh

# Preview what version bump the current branch would produce
./scripts/bump-version.sh --dry-run
VERSION_BASE_REF=origin/main VERSION_HEAD_REF=HEAD ./scripts/bump-version.sh --report
```

## Commit conventions

Every commit **must** follow [Conventional Commits](https://www.conventionalcommits.org/). The `commit-msg` hook (`.githooks/commit-msg`) enforces this locally. Run `./scripts/install-hooks.sh` once after cloning to activate it.

Allowed prefixes: `feat`, `fix`, `breaking`, `chore`, `docs`, `refactor`, `perf`, `test`, `ci`, `build`, `revert`

Breaking changes: use `breaking:` or `feat!:` / `fix!:`

Automated bump commits include `[skip version]` — the hook and CI skip those.

## Versioning

The canonical version lives in `VERSION`. `README.md` (badge + footer) and `install.sh` (header comment) are kept in sync automatically by `scripts/bump-version.sh`. **Do not edit version numbers manually in a PR** — the GitHub Actions workflow posts a preview comment on every PR and bumps after merge.

Semver mapping:
- `breaking:` / `feat!:` / `fix!:` → major
- `feat:` → minor
- everything else → patch

## Dotfile symlink map

`install.sh` and `sync.sh` both create these symlinks:

| Repo file | Symlinked to |
|---|---|
| `.zshrc` | `~/.zshrc` |
| `.p10k.zsh` | `~/.p10k.zsh` |
| `.aerospace.toml` | `~/.aerospace.toml` |
| `exports` | `~/.config/exports` |
| `alias` | `~/.config/alias` |
| `wezterm.lua` | `~/.config/wezterm/wezterm.lua` |
| `nvim/` | `~/.config/nvim/` |

Work-specific aliases go in `~/.config/goodrx_alias` — it is loaded before `~/.config/alias` by `.zshrc`.

## Neovim config

`nvim/` is a LazyVim-based config. Plugins are declared under `nvim/lua/plugins/`, core options under `nvim/lua/config/`. The lockfile `nvim/lazy-lock.json` is not checked into the repo — Lazy.nvim regenerates it on first launch.

Required CLI tools (installed by `install.sh`): `ripgrep`, `fd` — used by Snacks.picker for grep and file finding. Treesitter parsers are downloaded as pre-built binaries by nvim-treesitter.

## CI / GitHub Actions

`.github/workflows/version.yml` runs on PRs (`pull_request_target`) and pushes to `main`:

- **PR**: reads commit subjects via the GitHub API (never checks out PR code), posts a version preview comment, updates it on every push.
- **Merge to main**: bumps `VERSION`, `README.md`, `install.sh` and commits `chore: bump version to X.Y.Z [skip version]` using a deploy key stored as `VERSION_BUMP_SSH_KEY`.

Squash merges are disabled — the workflow needs individual conventional commits to determine the bump level.
