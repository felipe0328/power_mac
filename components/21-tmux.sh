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
  local config_source="$POWER_MAC_ROOT/tmux-installer/tmux-${POWER_MAC_TMUX_STYLE}.conf"
  pm_link_config "$config_source" "$HOME/.tmux.conf"
}

power_mac_dry_run_tmux() {
  pm_ok "[dry-run] Would install tmux and TPM with the ${POWER_MAC_TMUX_STYLE} configuration"
}

component_define \
  "tmux" \
  "Tmux" \
  "Terminal multiplexer, TPM, and a selectable top or bottom status bar" \
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
  ""
