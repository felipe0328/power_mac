<div align="center">

# 🤝 Contributing to power_mac

**Help shape the Mac bootstrap setup — dotfiles, configs, and install automation.**

*Commit format · versioning · git hooks · pull requests*

![Conventional Commits](https://img.shields.io/badge/commits-conventional-ff69b4?style=flat-square)
![Semver](https://img.shields.io/badge/versioning-semver-blueviolet?style=flat-square)
![Hooks](https://img.shields.io/badge/git-hooks-enabled-informational?style=flat-square)

[← Back to README](README.md)

</div>

---

## 🚀 Getting started

```bash
# 1. Fork & clone your fork
git clone git@github.com:YOUR_USERNAME/power_mac.git ~/power_conf
cd ~/power_conf

# 2. Create a branch
git checkout -b my-feature

# 3. Enable hooks (required for commits)
./scripts/install-hooks.sh

# 4. Optional: full local setup
./install.sh

# 5. After editing configs — apply without reinstalling
./sync.sh
```

> 💡 **Fork workflow:** push to your fork, then open a PR targeting `main` on the upstream repo (`felipe0328/power_mac`).

### Workflow at a glance

| Step | Action |
| --- | --- |
| 1️⃣ | Fork the repo and clone locally |
| 2️⃣ | Branch from `main` |
| 3️⃣ | Run `./scripts/install-hooks.sh` |
| 4️⃣ | Make changes — test with `./sync.sh` |
| 5️⃣ | Commit with conventional messages (`feat:`, `fix:`, …) |
| 6️⃣ | Open a PR → `main` on upstream |

---

## ✍️ Commit messages

Every commit **must** follow [Conventional Commits](https://www.conventionalcommits.org/). A `commit-msg` hook enforces this locally.

### Format

```text
<type>[optional scope][optional !]: <description>
```

### Allowed types

| Prefix | When to use |
| --- | --- |
| `feat:` | New feature — app, dotfile, workspace layout |
| `fix:` | Bug fix |
| `breaking:` | Breaking change |
| `feat!:` / `fix!:` | Breaking change (alternative syntax) |
| `chore:` | Maintenance, tooling, version bumps |
| `docs:` | Documentation only |
| `refactor:` | Refactor — not a fix or feature |
| `perf:` | Performance improvement |
| `test:` | Tests |
| `ci:` | CI / GitHub Actions |
| `build:` | Build system |
| `revert:` | Revert a prior commit |

### ✅ Good examples

```bash
feat: add alias file for git and docker
fix: move on-mode-changed above on-window-detected blocks
feat!: remove ghostty config in favor of wezterm
breaking: require macOS 14 or newer
chore: bump version to 1.1.0 [skip version]
```

### ❌ Bad examples

```bash
Improving aerospace config    # missing type prefix
feat add aliases              # missing colon
WIP                           # not conventional
```

### Exceptions (hook skips validation)

- Merge commits — `Merge pull request #…`, `Merge branch …`
- Automated bumps — messages containing `[skip version]`

### Enable the hook

```bash
./scripts/install-hooks.sh
```

Sets `core.hooksPath` to `.githooks` for **this repo only** (not global git config). Also runs automatically via `./install.sh`.

---

## 🏷️ Versioning

The canonical version lives in [`VERSION`](VERSION). The README badge and `install.sh` header stay in sync automatically.

### Semver mapping

| Change | Commit examples | Bump | Example |
| --- | --- | --- | --- |
| 💥 Breaking | `breaking:`, `feat!:`, `fix!:`, `BREAKING CHANGE` | **major** | `1.0.2` → `2.0.0` |
| ✨ New feature | `feat:` | **minor** | `1.0.2` → `1.1.0` |
| 🔧 Fix / tweak | `fix:`, `chore:`, `docs:`, `refactor:`, `perf:` | **patch** | `1.0.2` → `1.0.3` |

> 📌 **Multiple commits in one PR?** The automation picks the **highest** bump (breaking > feat > fix). Order does not matter.

### How automation works

On every push to `main`, the [version workflow](.github/workflows/version.yml):

1. 📖 Reads all commits in the push
2. 🧮 Picks the highest bump level (breaking → feat → patch)
3. 📝 Updates `VERSION`, `README.md`, and `install.sh`
4. 🤖 Commits `chore: bump version to X.Y.Z [skip version]` back to `main`

You do **not** need to edit `VERSION` manually in PRs.

### Preview locally

```bash
./scripts/bump-version.sh --dry-run
```

### GitHub setup (maintainers)

| Setting | Value |
| --- | --- |
| **Actions** | Enabled |
| **Workflow permissions** | Read and write |
| **Branch protection** | Allow `github-actions[bot]` to push to `main` (if protected) |
| **Secrets** | None required — uses `GITHUB_TOKEN` |

---

## 🔀 Opening a pull request

1. 🎯 Target `main` on the **upstream** repository
2. 📝 Describe what changed and why
3. 🔗 Link issues when applicable — `Fixes #1` closes the issue on merge
4. ✍️ Use conventional commits on every commit in the branch

### Squash merges

If the PR is **squash-merged**, only the **squash commit message** is analyzed. Write it to match the biggest change in the PR:

```bash
feat: add automated versioning and contributor guide   # → minor bump
fix: correct aerospace TOML parse error                 # → patch bump
```

---

## ❓ Questions

Open an issue or ask in your PR — happy to help.

---

<div align="center">

Made with ❤️ for contributors &nbsp;•&nbsp; [README](README.md) &nbsp;•&nbsp; **power_mac**

</div>
