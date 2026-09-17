# Tmux configuration

Start with the friendly **[Tmux cheatsheet](CHEATSHEET.md)** for prefixes,
sessions, panes, copying, recovery, status information, and plugin shortcuts.

Tmux is managed by the main power_mac component system:

```bash
./install.sh --components tmux --tmux-style bottom
./install.sh --components tmux --tmux-style top
```

The compatibility wrapper in this directory accepts the style as its argument:

```bash
./tmux-installer/tmux-installer.sh top
```

## Configuration layout

| Repository file | Installed location | Purpose |
| --- | --- | --- |
| `tmux.conf` | `~/.tmux.conf` | Behavior and plugin configuration shared by both styles |
| `tmux-bottom.conf` | `~/.config/tmux/style.conf` | `Ctrl-a`, purple palette, bottom status bar |
| `tmux-top.conf` | `~/.config/tmux/style.conf` | `Ctrl-b`, green palette, top status bar |

The installer preserves existing real files at both destinations as timestamped
backups and never deletes an existing TPM checkout. It installs missing plugins
automatically after the links are ready. Re-running the installer switches only
the selected style overlay and leaves already-installed plugins untouched.
