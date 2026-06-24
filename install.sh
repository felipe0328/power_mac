#!/usr/bin/env bash
# Version: 1.2.0

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POWER_MAC_ROOT="$SCRIPT_DIR"
# shellcheck source=lib/core.sh
source "$SCRIPT_DIR/lib/core.sh"
# shellcheck source=lib/ui.sh
source "$SCRIPT_DIR/lib/ui.sh"

show_help() {
  cat <<'EOF'
Usage:
  ./install.sh
  ./install.sh --all [--tmux-style top|bottom] [--dry-run]
  ./install.sh --components ID,ID,... [--tmux-style top|bottom] [--dry-run]

Options:
  --all                 Install every selectable component.
  --components LIST     Install a comma-separated list of component IDs.
  --tmux-style STYLE    Use the top or bottom Tmux status bar (default: bottom).
  --dry-run             Show the resolved work without changing the machine.
  --help                Show this help and the available component IDs.

With no selection flags, an interactive multi-select menu is shown. Use Space
to toggle components and Enter to continue.
EOF
  if [ "${#COMPONENT_IDS[@]}" -gt 0 ]; then
    printf '\nAvailable components:\n'
    local i
    for ((i = 0; i < ${#COMPONENT_IDS[@]}; i++)); do
      [ "${COMPONENT_HIDDEN[$i]}" = false ] || continue
      printf '  %-12s %s\n' "${COMPONENT_IDS[$i]}" "${COMPONENT_DESCRIPTIONS[$i]}"
    done
  fi
}

SELECTION_MODE="interactive"
COMPONENTS_ARGUMENT=""
TMUX_STYLE="bottom"
TMUX_STYLE_SET=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --all)
      [ "$SELECTION_MODE" = interactive ] || pm_die "--all conflicts with --components"
      SELECTION_MODE="all"
      ;;
    --components)
      [ "$#" -ge 2 ] || pm_die "--components requires a comma-separated value"
      [ "$SELECTION_MODE" = interactive ] || pm_die "--components conflicts with --all"
      SELECTION_MODE="components"
      COMPONENTS_ARGUMENT="$2"
      shift
      ;;
    --tmux-style)
      [ "$#" -ge 2 ] || pm_die "--tmux-style requires top or bottom"
      TMUX_STYLE="$2"
      TMUX_STYLE_SET=true
      shift
      ;;
    --dry-run)
      POWER_MAC_DRY_RUN=true
      ;;
    --help|-h)
      pm_load_components
      show_help
      exit 0
      ;;
    *)
      pm_die "Unknown argument '$1'. Run ./install.sh --help."
      ;;
  esac
  shift
done

case "$TMUX_STYLE" in top|bottom) ;; *) pm_die "Invalid Tmux style '$TMUX_STYLE'; expected top or bottom" ;; esac

if [ "$(uname -s)" != Darwin ] && [ "${POWER_MAC_ALLOW_NON_DARWIN:-false}" != true ]; then
  pm_die "power_mac supports macOS only"
fi

INTERACTIVE_UI=false
if [ "$SELECTION_MODE" = interactive ]; then
  INTERACTIVE_UI=true
  if [ "${POWER_MAC_ALLOW_NON_TTY_INTERACTIVE:-false}" != true ]; then
    [ -t 0 ] && [ -t 1 ] || pm_die "Interactive mode requires a terminal; use --all or --components"
  fi
  pm_ui_clear
  pm_ui_banner
  pm_ui_preparing_header
  pm_ui_loading "Loading the component catalog"
fi

pm_load_components
SELECTABLE_COUNT=0
for ((i = 0; i < ${#COMPONENT_IDS[@]}; i++)); do
  [ "${COMPONENT_HIDDEN[$i]}" = false ] && SELECTABLE_COUNT=$((SELECTABLE_COUNT + 1))
done

STATE_MESSAGE="Fresh setup detected"
if pm_load_state; then
  STATE_MESSAGE="Saved setup preferences restored"
  if [ "$TMUX_STYLE_SET" = false ]; then
    TMUX_STYLE="$PM_STATE_TMUX_STYLE"
  fi
fi

if [ "$INTERACTIVE_UI" = true ]; then
  pm_ui_ready "$SELECTABLE_COUNT apps and tools discovered"
  pm_ui_loading "Checking saved setup preferences"
  pm_ui_ready "$STATE_MESSAGE"
  pm_ui_loading "Preparing the terminal interface"
  pm_ensure_gum
  pm_ui_ready "Terminal interface ready"
  pm_ui_pause
  pm_ui_clear
  pm_ui_banner
  pm_ui_preparing_header
  pm_ui_ready "$SELECTABLE_COUNT apps and tools discovered"
  pm_ui_ready "$STATE_MESSAGE"
  pm_ui_ready "Terminal interface ready"
fi

SELECTED_COMPONENTS=()
if [ "$SELECTION_MODE" = all ]; then
  while IFS= read -r id; do
    [ -n "$id" ] && SELECTED_COMPONENTS+=("$id")
  done < <(pm_selectable_component_ids)
elif [ "$SELECTION_MODE" = components ]; then
  pm_split_csv "$COMPONENTS_ARGUMENT" SELECTED_COMPONENTS
else
  pm_ui_selection_header
  menu_options=()
  for ((i = 0; i < ${#COMPONENT_IDS[@]}; i++)); do
    [ "${COMPONENT_HIDDEN[$i]}" = false ] || continue
    printf -v menu_label "  %-19s %-18s %s:%s" \
      "${COMPONENT_CATEGORIES[$i]}" \
      "${COMPONENT_LABELS[$i]}" \
      "${COMPONENT_DESCRIPTIONS[$i]}" \
      "${COMPONENT_IDS[$i]}"
    menu_options+=("$menu_label")
  done
  selection_output="$(
    gum choose \
      --no-limit \
      --selected "*" \
      --height 14 \
      --label-delimiter ":" \
      "${menu_options[@]}"
  )" || {
    pm_warn "Installation cancelled"
    exit 0
  }
  while IFS= read -r id; do
    [ -n "$id" ] && SELECTED_COMPONENTS+=("$id")
  done <<< "$selection_output"
fi

pm_validate_selected_ids "${SELECTED_COMPONENTS[@]}"

if pm_array_contains "tmux" "${SELECTED_COMPONENTS[@]}" && [ "$SELECTION_MODE" = interactive ] && [ "$TMUX_STYLE_SET" = false ]; then
  TMUX_STYLE="$(gum choose --selected "$TMUX_STYLE" --header "Choose the Tmux status bar position" bottom top)" || {
    pm_warn "Installation cancelled"
    exit 0
  }
fi
POWER_MAC_TMUX_STYLE="$TMUX_STYLE"

pm_resolve_components "${SELECTED_COMPONENTS[@]}" >/dev/null
RESOLVED_COMPONENTS=("${PM_RESOLVED_COMPONENTS[@]}")

printf '\n%sSelected components%s\n' "$PM_BOLD" "$PM_RESET"
for id in "${SELECTED_COMPONENTS[@]}"; do
  printf '  • %s\n' "$(pm_component_field "$id" COMPONENT_LABELS)"
done
for id in "${RESOLVED_COMPONENTS[@]}"; do
  if ! pm_array_contains "$id" "${SELECTED_COMPONENTS[@]}"; then
    printf '  + %s (dependency)\n' "$(pm_component_field "$id" COMPONENT_LABELS)"
  fi
done
if pm_array_contains "tmux" "${SELECTED_COMPONENTS[@]}"; then
  printf '  • Tmux style: %s\n' "$TMUX_STYLE"
fi

if [ "$SELECTION_MODE" = interactive ]; then
  gum confirm "Install this selection?" || {
    pm_warn "Installation cancelled"
    exit 0
  }
fi

if pm_requires_homebrew "${RESOLVED_COMPONENTS[@]}"; then
  pm_step "Checking Homebrew..."
  pm_ensure_homebrew || pm_die "Homebrew is required but could not be installed"
fi

SUCCESSFUL_COMPONENTS=()
FAILED_COMPONENTS=()
for id in "${RESOLVED_COMPONENTS[@]}"; do
  dependencies=()
  pm_split_csv "$(pm_component_field "$id" COMPONENT_DEPENDENCIES)" dependencies
  dependency_failed=false
  for dependency in "${dependencies[@]}"; do
    if pm_array_contains "$dependency" "${FAILED_COMPONENTS[@]}"; then
      dependency_failed=true
      break
    fi
  done
  if [ "$dependency_failed" = true ]; then
    pm_error "Skipping $id because a dependency failed"
    FAILED_COMPONENTS+=("$id")
  elif pm_install_component "$id"; then
    SUCCESSFUL_COMPONENTS+=("$id")
  else
    pm_error "Component '$id' failed"
    FAILED_COMPONENTS+=("$id")
  fi
done

if [ "${POWER_MAC_SKIP_REPO_HOOKS:-false}" = true ]; then
  :
elif [ "$POWER_MAC_DRY_RUN" = true ]; then
  pm_step "Repository setup"
  pm_ok "[dry-run] Would install this repository's Git hooks"
else
  pm_step "Repository setup"
  if bash "$SCRIPT_DIR/scripts/install-hooks.sh"; then
    pm_ok "Git hooks installed"
  else
    pm_warn "Git hooks could not be installed"
  fi
fi

STATE_COMPONENTS=()
for id in "${SELECTED_COMPONENTS[@]}"; do
  if pm_array_contains "$id" "${SUCCESSFUL_COMPONENTS[@]}"; then
    STATE_COMPONENTS+=("$id")
  fi
done
[ "${#STATE_COMPONENTS[@]}" -eq 0 ] || pm_save_state "$TMUX_STYLE" "${STATE_COMPONENTS[@]}" ||
  pm_warn "Could not save installer state"

if [ "${#FAILED_COMPONENTS[@]}" -gt 0 ]; then
  printf '\n%sInstallation finished with failures:%s %s\n' \
    "$PM_RED" "$PM_RESET" "$(pm_join_by , "${FAILED_COMPONENTS[@]}")"
  exit 1
fi

printf '\n%sAll selected components are ready.%s\n' "$PM_GREEN" "$PM_RESET"
printf 'Restart affected apps or run %sexec zsh%s to reload the shell.\n\n' "$PM_BLUE" "$PM_RESET"
