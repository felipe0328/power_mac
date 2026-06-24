#!/usr/bin/env bash

power_mac_install_meslo_fonts() {
  local variant filename destination url_variant
  mkdir -p "$HOME/Library/Fonts" || return 1
  for variant in "Regular" "Bold" "Italic" "Bold Italic"; do
    filename="MesloLGS NF ${variant}.ttf"
    destination="$HOME/Library/Fonts/$filename"
    url_variant="${variant// /%20}"
    if [ -f "$destination" ]; then
      pm_ok "$filename already installed"
    elif curl -fsSL \
      "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20${url_variant}.ttf" \
      -o "$destination"; then
      pm_ok "$filename installed"
    else
      return 1
    fi
  done
}

power_mac_dry_run_meslo_fonts() {
  pm_ok "[dry-run] Would install four MesloLGS NF font variants"
}

component_define \
  "meslo-fonts" \
  "MesloLGS NF" \
  "Nerd Font used by WezTerm and Powerlevel10k" \
  "Internal" \
  "false" \
  "true" \
  "" \
  "custom" \
  "" \
  "" \
  "power_mac_install_meslo_fonts" \
  "" \
  "power_mac_dry_run_meslo_fonts" \
  ""
