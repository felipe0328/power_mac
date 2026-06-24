#!/usr/bin/env bash

power_mac_install_shell() {
  local zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended ||
      return 1
    pm_ok "Oh My Zsh installed"
  else
    pm_ok "Oh My Zsh already installed"
  fi

  if [ ! -d "$zsh_custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$zsh_custom/themes/powerlevel10k" || return 1
    pm_ok "Powerlevel10k installed"
  else
    pm_ok "Powerlevel10k already installed"
  fi

  if [ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$zsh_custom/plugins/zsh-autosuggestions" || return 1
    pm_ok "zsh-autosuggestions installed"
  else
    pm_ok "zsh-autosuggestions already installed"
  fi
}

power_mac_dry_run_shell() {
  pm_ok "[dry-run] Would install Oh My Zsh, Powerlevel10k, and zsh-autosuggestions"
}

component_define \
  "shell" \
  "Shell environment" \
  "Zsh, Oh My Zsh, Powerlevel10k, plugins, aliases, and exports" \
  "Terminal & Shell" \
  "true" \
  "false" \
  "meslo-fonts" \
  "custom" \
  "" \
  $'.zshrc|.zshrc\n.p10k.zsh|.p10k.zsh\nalias|.config/alias\nexports|.config/exports' \
  "power_mac_install_shell" \
  "" \
  "power_mac_dry_run_shell" \
  ""
