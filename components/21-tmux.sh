#!/usr/bin/env bash

power_mac_install_tmux() {
  if brew list --formula tmux >/dev/null 2>&1; then
    pm_ok "tmux already installed"
  else
    brew install tmux || return 1
    pm_ok "tmux installed"
  fi

  local tpm_dir="$HOME/.tmux/plugins/tpm"
  if [ -d "$tpm_dir/.git" ]; then
    pm_ok "Tmux Plugin Manager already installed"
  elif [ -e "$tpm_dir" ]; then
    pm_warn "$tpm_dir exists and is not a TPM checkout; leaving it untouched"
    return 1
  else
    mkdir -p "$(dirname "$tpm_dir")" || return 1
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir" || return 1
    pm_ok "Tmux Plugin Manager installed"
  fi
}

power_mac_sync_tmux() {
  local style_source="$POWER_MAC_ROOT/tmux-installer/tmux-${POWER_MAC_TMUX_STYLE}.conf"
  pm_link_config "$POWER_MAC_ROOT/tmux-installer/tmux.conf" "$HOME/.tmux.conf" || return 1
  pm_link_config "$style_source" "$HOME/.config/tmux/style.conf"
}

power_mac_post_tmux() {
  local plugin_installer="$HOME/.tmux/plugins/tpm/bin/install_plugins"
  local running_server=false
  if [ ! -x "$plugin_installer" ]; then
    pm_error "TPM plugin installer is missing or not executable: $plugin_installer"
    return 1
  fi

  # TPM reads its install path from the server environment. Load the new config
  # first when a server already exists, including when this shell is detached.
  if tmux list-sessions >/dev/null 2>&1; then
    running_server=true
    if ! tmux source-file "$HOME/.tmux.conf"; then
      pm_warn "The running Tmux server could not load the new config before plugin installation"
    fi
  fi

  "$plugin_installer" || return 1
  pm_ok "Tmux plugins installed"

  if [ "$running_server" = true ]; then
    if tmux source-file "$HOME/.tmux.conf"; then
      pm_ok "Running Tmux session reloaded"
    else
      pm_warn "Tmux is installed, but the running session could not be reloaded"
    fi
  fi
}

power_mac_dry_run_tmux() {
  pm_ok "[dry-run] Would install tmux, TPM, and plugins with the ${POWER_MAC_TMUX_STYLE} style"
}

component_define \
  "tmux" \
  "Tmux" \
  "Terminal multiplexer, plugins, and a selectable top or bottom style" \
  "Terminal & Shell" \
  "true" \
  "false" \
  "" \
  "custom" \
  "tmux" \
  "" \
  "power_mac_install_tmux" \
  "power_mac_sync_tmux" \
  "power_mac_dry_run_tmux" \
  "power_mac_post_tmux"
