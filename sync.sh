#!/usr/bin/env bash

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POWER_MAC_ROOT="$SCRIPT_DIR"
# shellcheck source=lib/core.sh
source "$SCRIPT_DIR/lib/core.sh"

show_help() {
  cat <<'EOF'
Usage:
  ./sync.sh
  ./sync.sh --all [--dry-run]
  ./sync.sh --components ID,ID,... [--dry-run]

Without selection flags, sync.sh reads the components recorded by install.sh.
If no state exists, it detects configs linked by older power_mac releases and
migrates them after a successful sync.

Options:
  --all                 Sync every selectable component configuration.
  --components LIST     Sync a comma-separated list of component IDs.
  --dry-run             Show config changes without writing them.
  --help                Show this help.
EOF
}

SELECTION_MODE="state"
COMPONENTS_ARGUMENT=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --all)
      [ "$SELECTION_MODE" = state ] || pm_die "--all conflicts with --components"
      SELECTION_MODE="all"
      ;;
    --components)
      [ "$#" -ge 2 ] || pm_die "--components requires a comma-separated value"
      [ "$SELECTION_MODE" = state ] || pm_die "--components conflicts with --all"
      SELECTION_MODE="components"
      COMPONENTS_ARGUMENT="$2"
      shift
      ;;
    --dry-run) POWER_MAC_DRY_RUN=true ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *) pm_die "Unknown argument '$1'. Run ./sync.sh --help." ;;
  esac
  shift
done

pm_load_components
SELECTED_COMPONENTS=()
STATE_LOADED=false
MIGRATE_STATE=false
if pm_load_state && [ "${#PM_STATE_COMPONENTS[@]}" -gt 0 ]; then
  STATE_LOADED=true
  POWER_MAC_TMUX_STYLE="$PM_STATE_TMUX_STYLE"
fi

case "$SELECTION_MODE" in
  all)
    while IFS= read -r id; do
      [ -n "$id" ] && SELECTED_COMPONENTS+=("$id")
    done < <(pm_selectable_component_ids)
    ;;
  components)
    pm_split_csv "$COMPONENTS_ARGUMENT" SELECTED_COMPONENTS
    ;;
  state)
    if [ "$STATE_LOADED" = true ]; then
      SELECTED_COMPONENTS=("${PM_STATE_COMPONENTS[@]}")
    else
      while IFS= read -r id; do
        [ -n "$id" ] && SELECTED_COMPONENTS+=("$id")
      done < <(pm_detect_legacy_components)

      if [ "${#SELECTED_COMPONENTS[@]}" -gt 0 ]; then
        pm_warn "No saved state found; detected legacy power_mac configs: $(pm_join_by , "${SELECTED_COMPONENTS[@]}")"
      else
        SELECTED_COMPONENTS=(shell wezterm neovim aerospace)
        pm_warn "No saved state or managed symlinks found; using the legacy sync configuration"
      fi
      MIGRATE_STATE=true
    fi
    ;;
esac

pm_validate_selected_ids "${SELECTED_COMPONENTS[@]}"
pm_resolve_components "${SELECTED_COMPONENTS[@]}" >/dev/null
RESOLVED_COMPONENTS=("${PM_RESOLVED_COMPONENTS[@]}")

FAILURES=()
for id in "${RESOLVED_COMPONENTS[@]}"; do
  configs="$(pm_component_field "$id" COMPONENT_CONFIGS)"
  sync_hook="$(pm_component_field "$id" COMPONENT_SYNC_HOOKS)"
  [ -n "$configs" ] || [ -n "$sync_hook" ] || continue
  pm_step "Syncing $(pm_component_field "$id" COMPONENT_LABELS)"
  if ! pm_sync_component "$id"; then
    FAILURES+=("$id")
  fi
done

if [ "${#FAILURES[@]}" -gt 0 ]; then
  pm_error "Sync failed for: $(pm_join_by , "${FAILURES[@]}")"
  exit 1
fi

if [ "$MIGRATE_STATE" = true ]; then
  if pm_save_state "$POWER_MAC_TMUX_STYLE" "${SELECTED_COMPONENTS[@]}"; then
    pm_ok "Saved detected components for future syncs"
  else
    pm_warn "Configs synced, but component state could not be saved"
  fi
fi

printf '\n%sSelected configurations are in sync.%s\n\n' "$PM_GREEN" "$PM_RESET"
