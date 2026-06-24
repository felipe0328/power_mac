#!/usr/bin/env bash

# Lightweight terminal presentation helpers. These deliberately do not depend
# on Gum so the welcome screen also works while Gum is being bootstrapped.

POWER_MAC_UI_DELAY="${POWER_MAC_UI_DELAY:-0.12}"

pm_ui_is_terminal() {
  [ -t 1 ] || [ "${POWER_MAC_ALLOW_NON_TTY_INTERACTIVE:-false}" = true ]
}

pm_ui_clear() {
  pm_ui_is_terminal || return 0
  case "${TERM:-}" in
    dumb|"") ;;
    *) printf '\033[2J\033[H' ;;
  esac
}

pm_ui_banner() {
  printf '%s' "$PM_BLUE"
  printf '╭──────────────────────────────────────────────────────────╮\n'
  printf '│                                                          │\n'
  printf '│   ⚡  %spower_mac%s%s                                      │\n' "$PM_BOLD" "$PM_RESET" "$PM_BLUE"
  printf '│       Your Mac setup, shaped by you.                     │\n'
  printf '│                                                          │\n'
  printf '╰──────────────────────────────────────────────────────────╯%s\n' "$PM_RESET"
}

pm_ui_pause() {
  [ "$POWER_MAC_UI_DELAY" = 0 ] && return 0
  sleep "$POWER_MAC_UI_DELAY"
}

pm_ui_loading() {
  printf '  %s◌%s %s...\n' "$PM_BLUE" "$PM_RESET" "$1"
  pm_ui_pause
}

pm_ui_ready() {
  printf '  %s✓%s %s\n' "$PM_GREEN" "$PM_RESET" "$1"
  pm_ui_pause
}

pm_ui_note() {
  printf '  %s•%s %s\n' "$PM_YELLOW" "$PM_RESET" "$1"
}

pm_ui_preparing_header() {
  printf '\n%sPreparing your installer%s\n\n' "$PM_BOLD" "$PM_RESET"
}

pm_ui_selection_header() {
  printf '\n%sChoose your setup%s\n' "$PM_BOLD" "$PM_RESET"
  printf 'Space toggles  •  Enter continues  •  Everything starts selected\n\n'
  printf '  %-19s %-18s %s\n' "CATEGORY" "APP" "DESCRIPTION"
  printf '  %-19s %-18s %s\n' "───────────────────" "──────────────────" "────────────────────────────"
}
