#!/usr/bin/env bash

# Shared component registry and execution helpers for power_mac.
# Keep this file compatible with the Bash 3.2 shipped by macOS.

POWER_MAC_ROOT="${POWER_MAC_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
POWER_MAC_STATE_FILE="${POWER_MAC_STATE_FILE:-$HOME/.config/power_mac/state}"
POWER_MAC_DRY_RUN="${POWER_MAC_DRY_RUN:-false}"
POWER_MAC_TMUX_STYLE="${POWER_MAC_TMUX_STYLE:-bottom}"

PM_GREEN=$'\033[0;32m'
PM_BLUE=$'\033[0;34m'
PM_YELLOW=$'\033[1;33m'
PM_RED=$'\033[0;31m'
# Used by entrypoints after this shared library is sourced.
# shellcheck disable=SC2034
PM_BOLD=$'\033[1m'
PM_RESET=$'\033[0m'

pm_step() { printf '\n%s==>%s %s\n' "$PM_BLUE" "$PM_RESET" "$1"; }
pm_ok() { printf '  %s✓%s %s\n' "$PM_GREEN" "$PM_RESET" "$1"; }
pm_warn() { printf '  %s!%s %s\n' "$PM_YELLOW" "$PM_RESET" "$1"; }
pm_error() { printf '  %s✗%s %s\n' "$PM_RED" "$PM_RESET" "$1" >&2; }
pm_die() {
  pm_error "$1"
  exit 1
}

pm_array_contains() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    [ "$item" = "$needle" ] && return 0
  done
  return 1
}

pm_append_unique() {
  local array_name="$1"
  local value="$2"
  local current
  eval "current=(\"\${${array_name}[@]}\")"
  if ! pm_array_contains "$value" "${current[@]}"; then
    eval "${array_name}+=(\"\$value\")"
  fi
}

pm_join_by() {
  local delimiter="$1"
  shift
  local output=""
  local item
  for item in "$@"; do
    if [ -n "$output" ]; then
      output="${output}${delimiter}"
    fi
    output="${output}${item}"
  done
  printf '%s' "$output"
}

pm_split_csv() {
  local csv="$1"
  local output_name="$2"
  eval "${output_name}=()"
  [ -n "$csv" ] || return 0
  local old_ifs="$IFS"
  local values=()
  IFS=','
  read -r -a values <<< "$csv"
  IFS="$old_ifs"
  local value
  for value in "${values[@]}"; do
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    [ -n "$value" ] && eval "${output_name}+=(\"\$value\")"
  done
}

COMPONENT_IDS=()
COMPONENT_LABELS=()
COMPONENT_DESCRIPTIONS=()
COMPONENT_CATEGORIES=()
COMPONENT_DEFAULTS=()
COMPONENT_HIDDEN=()
COMPONENT_DEPENDENCIES=()
COMPONENT_KINDS=()
COMPONENT_PACKAGES=()
COMPONENT_CONFIGS=()
COMPONENT_INSTALL_HOOKS=()
COMPONENT_SYNC_HOOKS=()
COMPONENT_DRY_RUN_HOOKS=()
COMPONENT_POST_HOOKS=()

# component_define id label description category default hidden dependencies
#                  kind package configs install_hook sync_hook dry_run_hook post_hook
component_define() {
  [ "$#" -eq 14 ] || pm_die "component_define expected 14 arguments, received $#"
  COMPONENT_IDS+=("$1")
  COMPONENT_LABELS+=("$2")
  COMPONENT_DESCRIPTIONS+=("$3")
  COMPONENT_CATEGORIES+=("$4")
  COMPONENT_DEFAULTS+=("$5")
  COMPONENT_HIDDEN+=("$6")
  COMPONENT_DEPENDENCIES+=("$7")
  COMPONENT_KINDS+=("$8")
  COMPONENT_PACKAGES+=("$9")
  COMPONENT_CONFIGS+=("${10}")
  COMPONENT_INSTALL_HOOKS+=("${11}")
  COMPONENT_SYNC_HOOKS+=("${12}")
  COMPONENT_DRY_RUN_HOOKS+=("${13}")
  COMPONENT_POST_HOOKS+=("${14}")
}

pm_component_index() {
  local id="$1"
  local i
  for ((i = 0; i < ${#COMPONENT_IDS[@]}; i++)); do
    if [ "${COMPONENT_IDS[$i]}" = "$id" ]; then
      printf '%s' "$i"
      return 0
    fi
  done
  return 1
}

pm_component_field() {
  local id="$1"
  local field="$2"
  local index
  index="$(pm_component_index "$id")" || return 1
  eval "printf '%s' \"\${${field}[${index}]}\""
}

pm_load_components() {
  local module
  local found=false
  for module in "$POWER_MAC_ROOT"/components/*.sh; do
    [ -f "$module" ] || continue
    found=true
    # shellcheck source=/dev/null
    source "$module"
  done
  [ "$found" = true ] || pm_die "No component modules found in $POWER_MAC_ROOT/components"
  pm_validate_registry
}

pm_validate_hook() {
  local id="$1"
  local hook_name="$2"
  local hook_type="$3"
  [ -z "$hook_name" ] && return 0
  type "$hook_name" >/dev/null 2>&1 ||
    pm_die "Component '$id' references missing $hook_type hook '$hook_name'"
}

pm_validate_configs() {
  local id="$1"
  local configs="$2"
  [ -z "$configs" ] && return 0
  local line source_path destination extra
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    IFS='|' read -r source_path destination extra <<< "$line"
    if [ -z "$source_path" ] || [ -z "$destination" ] || [ -n "$extra" ]; then
      pm_die "Component '$id' has malformed config mapping '$line'"
    fi
    case "$destination" in
      /*|../*|*/../*) pm_die "Component '$id' config destination must be relative to HOME: '$destination'" ;;
    esac
  done <<< "$configs"
}

pm_validate_registry() {
  local i id other j dependencies dependency kind default_value hidden_value
  for ((i = 0; i < ${#COMPONENT_IDS[@]}; i++)); do
    id="${COMPONENT_IDS[$i]}"
    [[ "$id" =~ ^[a-z0-9][a-z0-9-]*$ ]] ||
      pm_die "Invalid component ID '$id'"
    [ -n "${COMPONENT_LABELS[$i]}" ] || pm_die "Component '$id' has no label"
    [ -n "${COMPONENT_CATEGORIES[$i]}" ] || pm_die "Component '$id' has no category"

    for ((j = i + 1; j < ${#COMPONENT_IDS[@]}; j++)); do
      other="${COMPONENT_IDS[$j]}"
      [ "$id" != "$other" ] || pm_die "Duplicate component ID '$id'"
    done

    default_value="${COMPONENT_DEFAULTS[$i]}"
    hidden_value="${COMPONENT_HIDDEN[$i]}"
    case "$default_value" in true|false) ;; *) pm_die "Component '$id' has invalid default '$default_value'" ;; esac
    case "$hidden_value" in true|false) ;; *) pm_die "Component '$id' has invalid hidden value '$hidden_value'" ;; esac

    kind="${COMPONENT_KINDS[$i]}"
    case "$kind" in
      formula|cask)
        [ -n "${COMPONENT_PACKAGES[$i]}" ] || pm_die "Component '$id' has no Homebrew package"
        ;;
      custom|virtual) ;;
      *) pm_die "Component '$id' has unsupported kind '$kind'" ;;
    esac
    if [ "$kind" = custom ] && [ -z "${COMPONENT_INSTALL_HOOKS[$i]}" ]; then
      pm_die "Custom component '$id' must provide an install hook"
    fi

    pm_validate_hook "$id" "${COMPONENT_INSTALL_HOOKS[$i]}" "install"
    pm_validate_hook "$id" "${COMPONENT_SYNC_HOOKS[$i]}" "sync"
    pm_validate_hook "$id" "${COMPONENT_DRY_RUN_HOOKS[$i]}" "dry-run"
    pm_validate_hook "$id" "${COMPONENT_POST_HOOKS[$i]}" "post-install"
    pm_validate_configs "$id" "${COMPONENT_CONFIGS[$i]}"

    pm_split_csv "${COMPONENT_DEPENDENCIES[$i]}" dependencies
    for dependency in "${dependencies[@]}"; do
      pm_component_index "$dependency" >/dev/null ||
        pm_die "Component '$id' depends on unknown component '$dependency'"
    done
  done

  local check_ids=()
  for id in "${COMPONENT_IDS[@]}"; do
    check_ids+=("$id")
  done
  pm_resolve_components "${check_ids[@]}" >/dev/null
}

PM_RESOLVED_COMPONENTS=()

pm_resolve_visit() {
  local id="$1"
  local path="$2"
  case ",$path," in
    *",$id,"*) pm_die "Component dependency cycle detected: ${path},${id}" ;;
  esac
  pm_array_contains "$id" "${PM_RESOLVED_COMPONENTS[@]}" && return 0

  local dependencies=()
  local dependency
  pm_split_csv "$(pm_component_field "$id" COMPONENT_DEPENDENCIES)" dependencies
  for dependency in "${dependencies[@]}"; do
    if [ -n "$path" ]; then
      pm_resolve_visit "$dependency" "${path},${id}"
    else
      pm_resolve_visit "$dependency" "$id"
    fi
  done
  PM_RESOLVED_COMPONENTS+=("$id")
}

pm_resolve_components() {
  PM_RESOLVED_COMPONENTS=()
  local id
  for id in "$@"; do
    pm_component_index "$id" >/dev/null || pm_die "Unknown component '$id'"
    pm_resolve_visit "$id" ""
  done
  printf '%s\n' "${PM_RESOLVED_COMPONENTS[@]}"
}

pm_selectable_component_ids() {
  local i
  for ((i = 0; i < ${#COMPONENT_IDS[@]}; i++)); do
    [ "${COMPONENT_HIDDEN[$i]}" = false ] && printf '%s\n' "${COMPONENT_IDS[$i]}"
  done
}

pm_default_component_ids() {
  local i
  for ((i = 0; i < ${#COMPONENT_IDS[@]}; i++)); do
    if [ "${COMPONENT_HIDDEN[$i]}" = false ] && [ "${COMPONENT_DEFAULTS[$i]}" = true ]; then
      printf '%s\n' "${COMPONENT_IDS[$i]}"
    fi
  done
}

pm_validate_selected_ids() {
  local id hidden
  [ "$#" -gt 0 ] || pm_die "No components selected"
  for id in "$@"; do
    pm_component_index "$id" >/dev/null || pm_die "Unknown component '$id'"
    hidden="$(pm_component_field "$id" COMPONENT_HIDDEN)"
    [ "$hidden" = false ] || pm_die "Component '$id' is internal and cannot be selected directly"
  done
}

pm_requires_homebrew() {
  local id kind package
  for id in "$@"; do
    kind="$(pm_component_field "$id" COMPONENT_KINDS)"
    package="$(pm_component_field "$id" COMPONENT_PACKAGES)"
    case "$kind" in
      formula|cask) return 0 ;;
      custom) [ -z "$package" ] || return 0 ;;
    esac
  done
  return 1
}

pm_ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    pm_ok "Homebrew already installed"
    return 0
  fi
  [ "$POWER_MAC_DRY_RUN" = false ] || {
    pm_warn "[dry-run] Homebrew would be installed"
    return 0
  }
  pm_warn "Homebrew not found — installing"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" ||
    return 1
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  command -v brew >/dev/null 2>&1
}

pm_ensure_gum() {
  command -v gum >/dev/null 2>&1 && return 0
  [ "$POWER_MAC_DRY_RUN" = false ] ||
    pm_die "Gum is required for interactive dry-runs. Install it with 'brew install gum' or use --all/--components."
  pm_step "Installing interactive interface..."
  pm_ensure_homebrew || pm_die "Could not install Homebrew"
  brew install gum || pm_die "Could not install Gum"
  pm_ok "Gum installed"
}

pm_backup_real_path() {
  local destination="$1"
  if [ -e "$destination" ] && [ ! -L "$destination" ]; then
    local backup
    backup="${destination}.bak.$(date +%Y%m%d%H%M%S)"
    if [ "$POWER_MAC_DRY_RUN" = true ]; then
      pm_warn "[dry-run] Would back up $destination to $backup"
    else
      mv "$destination" "$backup" || return 1
      pm_warn "Backed up existing $destination to $backup"
    fi
  fi
}

pm_link_config() {
  local source_path="$1"
  local destination="$2"
  if [ ! -e "$source_path" ]; then
    pm_error "Config source is missing: $source_path"
    return 1
  fi
  if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source_path" ]; then
    pm_ok "$(basename "$destination") already linked"
    return 0
  fi
  pm_backup_real_path "$destination" || return 1
  if [ "$POWER_MAC_DRY_RUN" = true ]; then
    pm_ok "[dry-run] Would link $destination -> $source_path"
    return 0
  fi
  mkdir -p "$(dirname "$destination")" || return 1
  if [ -L "$destination" ]; then
    rm "$destination" || return 1
  fi
  ln -s "$source_path" "$destination" || return 1
  pm_ok "Linked $destination"
}

pm_sync_declared_configs() {
  local id="$1"
  local configs line source_path destination
  configs="$(pm_component_field "$id" COMPONENT_CONFIGS)"
  [ -n "$configs" ] || return 0
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    IFS='|' read -r source_path destination <<< "$line"
    pm_link_config "$POWER_MAC_ROOT/$source_path" "$HOME/$destination" || return 1
  done <<< "$configs"
}

pm_paths_match() {
  local first="$1"
  local second="$2"
  local first_dir second_dir first_path second_path

  first_dir="$(cd "$(dirname "$first")" 2>/dev/null && pwd -P)" || return 1
  second_dir="$(cd "$(dirname "$second")" 2>/dev/null && pwd -P)" || return 1
  first_path="$first_dir/$(basename "$first")"
  second_path="$second_dir/$(basename "$second")"
  [ "$first_path" = "$second_path" ]
}

pm_symlink_points_to() {
  local destination="$1"
  local expected_source="$2"
  [ -L "$destination" ] || return 1

  local link_target
  link_target="$(readlink "$destination")" || return 1
  case "$link_target" in
    /*) ;;
    *) link_target="$(dirname "$destination")/$link_target" ;;
  esac
  pm_paths_match "$link_target" "$expected_source"
}

pm_component_has_managed_config() {
  local id="$1"
  local configs line source_path destination
  configs="$(pm_component_field "$id" COMPONENT_CONFIGS)"
  [ -n "$configs" ] || return 1

  while IFS= read -r line; do
    [ -z "$line" ] && continue
    IFS='|' read -r source_path destination <<< "$line"
    if pm_symlink_points_to "$HOME/$destination" "$POWER_MAC_ROOT/$source_path"; then
      return 0
    fi
  done <<< "$configs"
  return 1
}

pm_detect_legacy_components() {
  local id
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    if pm_component_has_managed_config "$id"; then
      printf '%s\n' "$id"
    fi
  done < <(pm_selectable_component_ids)
}

pm_install_brew_component() {
  local id="$1"
  local kind package installed_name
  kind="$(pm_component_field "$id" COMPONENT_KINDS)"
  package="$(pm_component_field "$id" COMPONENT_PACKAGES)"
  installed_name="${package##*/}"
  if [ "$kind" = formula ]; then
    if brew list --formula "$installed_name" >/dev/null 2>&1; then
      pm_ok "$installed_name already installed"
    elif brew install "$package"; then
      pm_ok "$installed_name installed"
    else
      return 1
    fi
  else
    if brew list --cask "$installed_name" >/dev/null 2>&1; then
      pm_ok "$installed_name already installed"
    elif brew install --cask "$package"; then
      pm_ok "$installed_name installed"
    else
      return 1
    fi
  fi
}

pm_dry_run_component() {
  local id="$1"
  local kind package hook
  kind="$(pm_component_field "$id" COMPONENT_KINDS)"
  package="$(pm_component_field "$id" COMPONENT_PACKAGES)"
  hook="$(pm_component_field "$id" COMPONENT_DRY_RUN_HOOKS)"
  if [ -n "$hook" ]; then
    "$hook" "$id" || return 1
  else
    case "$kind" in
      formula) pm_ok "[dry-run] Would install Homebrew formula $package" ;;
      cask) pm_ok "[dry-run] Would install Homebrew cask $package" ;;
      virtual) ;;
      custom) pm_ok "[dry-run] Would run custom installer for $id" ;;
    esac
  fi
  pm_sync_component "$id"
}

pm_sync_component() {
  local id="$1"
  local hook
  hook="$(pm_component_field "$id" COMPONENT_SYNC_HOOKS)"
  if [ -n "$hook" ]; then
    "$hook" "$id" || return 1
  else
    pm_sync_declared_configs "$id" || return 1
  fi
}

pm_install_component() {
  local id="$1"
  local label kind hook post_hook
  label="$(pm_component_field "$id" COMPONENT_LABELS)"
  kind="$(pm_component_field "$id" COMPONENT_KINDS)"
  hook="$(pm_component_field "$id" COMPONENT_INSTALL_HOOKS)"
  post_hook="$(pm_component_field "$id" COMPONENT_POST_HOOKS)"
  pm_step "$label"

  if [ "$POWER_MAC_DRY_RUN" = true ]; then
    pm_dry_run_component "$id"
    return $?
  fi

  case "$kind" in
    formula|cask) pm_install_brew_component "$id" || return 1 ;;
    custom) "$hook" "$id" || return 1 ;;
    virtual) [ -z "$hook" ] || "$hook" "$id" || return 1 ;;
  esac
  pm_sync_component "$id" || return 1
  [ -z "$post_hook" ] || "$post_hook" "$id" || return 1
  return 0
}

PM_STATE_COMPONENTS=()
PM_STATE_TMUX_STYLE="bottom"

pm_load_state() {
  PM_STATE_COMPONENTS=()
  PM_STATE_TMUX_STYLE="bottom"
  [ -f "$POWER_MAC_STATE_FILE" ] || return 1
  local key value
  while IFS='=' read -r key value; do
    case "$key" in
      components) pm_split_csv "$value" PM_STATE_COMPONENTS ;;
      tmux_style) PM_STATE_TMUX_STYLE="$value" ;;
    esac
  done < "$POWER_MAC_STATE_FILE"
  case "$PM_STATE_TMUX_STYLE" in top|bottom) ;; *) PM_STATE_TMUX_STYLE=bottom ;; esac
  return 0
}

pm_save_state() {
  local tmux_style="$1"
  shift
  local merged=()
  local id
  if pm_load_state; then
    for id in "${PM_STATE_COMPONENTS[@]}"; do
      pm_component_index "$id" >/dev/null 2>&1 && pm_append_unique merged "$id"
    done
  fi
  for id in "$@"; do
    pm_append_unique merged "$id"
  done
  if [ "$POWER_MAC_DRY_RUN" = true ]; then
    pm_ok "[dry-run] Would save state: $(pm_join_by , "${merged[@]}")"
    return 0
  fi
  local state_dir
  state_dir="$(dirname "$POWER_MAC_STATE_FILE")"
  mkdir -p "$state_dir" || return 1
  local temporary="${POWER_MAC_STATE_FILE}.tmp.$$"
  {
    printf 'components=%s\n' "$(pm_join_by , "${merged[@]}")"
    printf 'tmux_style=%s\n' "$tmux_style"
  } > "$temporary" || return 1
  mv "$temporary" "$POWER_MAC_STATE_FILE"
}
