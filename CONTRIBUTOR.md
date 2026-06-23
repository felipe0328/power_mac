# Contributing to power_mac

Thanks for helping improve this Mac bootstrap repo. This guide covers commit messages, versioning, git hooks, and pull requests.

## Getting started

1. Fork the repository and clone your fork.
2. Create a branch from `main`.
3. Run `./install.sh` (full setup) or `./scripts/install-hooks.sh` (hooks only).
4. Make changes and test locally (`./sync.sh` applies config symlinks without reinstalling apps).
5. Open a pull request targeting `main` on the upstream repo.

## Commit messages (required)

Every commit must follow [Conventional Commits](https://www.conventionalcommits.org/). A `commit-msg` git hook enforces this locally.

### Format

```
<type>[optional scope][optional !]: <description>
```

### Allowed types

| Prefix | When to use |
| --- | --- |
| `feat:` | New feature (new app, dotfile, workspace layout) |
| `fix:` | Bug fix |
| `breaking:` | Breaking change |
| `feat!:` / `fix!:` | Breaking change (alternative syntax) |
| `chore:` | Maintenance, tooling, version bumps |
| `docs:` | Documentation only |
| `refactor:` | Code change that is not a fix or feature |
| `perf:` | Performance improvement |
| `test:` | Tests |
| `ci:` | CI / GitHub Actions |
| `build:` | Build system |
| `revert:` | Revert a prior commit |

### Examples

```
feat: add alias file for git and docker
fix: move on-mode-changed above on-window-detected blocks
feat!: remove ghostty config in favor of wezterm
breaking: require macOS 14 or newer
chore: bump version to 1.1.0 [skip version]
```

### Invalid examples

```
Improving aerospace config          # missing type prefix
feat add aliases                    # missing colon
WIP                                 # not conventional
```

### Exceptions (hook allows without prefix)

- Merge commits (`Merge pull request #…`, `Merge branch …`)
- Automated version commits containing `[skip version]`

### Enable the hook

```bash
./scripts/install-hooks.sh
```

This sets `core.hooksPath` to `.githooks` for this repository only (not global git config).

## Versioning

The current version lives in [`VERSION`](VERSION). The README badge and `install.sh` header are synced from that file automatically.

### Semver mapping

| Change | Commit examples | Bump | Example |
| --- | --- | --- | --- |
| Breaking | `breaking:`, `feat!:`, `fix!:`, `BREAKING CHANGE` in body | **major** | `1.0.2` → `2.0.0` |
| New feature | `feat:` | **minor** | `1.0.2` → `1.1.0` |
| Fix / small change | `fix:`, `chore:`, `docs:`, `refactor:`, `perf:` | **patch** | `1.0.2` → `1.0.3` |

### Automation

On every push to `main`, the [version workflow](.github/workflows/version.yml):

1. Reads commits in the push (or since the last `VERSION` change).
2. Picks the highest applicable bump (breaking > feat > fix/chore/docs).
3. Updates `VERSION`, `README.md`, and `install.sh`.
4. Commits `chore: bump version to X.Y.Z [skip version]` back to `main`.

You do **not** need to edit `VERSION` manually in PRs.

### Preview a bump locally

```bash
./scripts/bump-version.sh --dry-run
```

## Opening a pull request

1. Target the `main` branch on the upstream repository.
2. Write a clear PR description of what changed and why.
3. Link issues when applicable: `Fixes #1` in the PR body closes the issue on merge.
4. Use conventional commit messages on every commit in the branch.

### Squash merges

If the maintainer squash-merges your PR, the **squash commit message** must follow conventional format — it is what drives the version bump on `main`.

## Questions

Open an issue or ask in your PR if anything is unclear.
