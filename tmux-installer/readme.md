# Tmux configuration

Tmux is managed by the main power_mac component system:

```bash
./install.sh --components tmux --tmux-style bottom
./install.sh --components tmux --tmux-style top
```

The compatibility wrapper in this directory accepts the style as its argument:

```bash
./tmux-installer/tmux-installer.sh top
```

The installer preserves existing real `~/.tmux.conf` files as timestamped
backups and never deletes an existing TPM checkout.
