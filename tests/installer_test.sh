#!/usr/bin/env bash

set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_TMP="$(mktemp -d)"
PASS_COUNT=0
FAIL_COUNT=0

cleanup() {
  rm -rf "$TEST_TMP"
}
trap cleanup EXIT

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf 'ok %d - %s\n' "$PASS_COUNT" "$1"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf 'not ok - %s\n' "$1" >&2
}

assert_contains() {
  local text="$1"
  local expected="$2"
  case "$text" in
    *"$expected"*) return 0 ;;
    *) printf 'Expected output to contain: %s\n' "$expected" >&2; return 1 ;;
  esac
}

assert_file_contains() {
  local file="$1"
  local expected="$2"
  [ -f "$file" ] && assert_contains "$(cat "$file")" "$expected"
}

make_fake_bin() {
  local directory="$1"
  mkdir -p "$directory"

  cat > "$directory/brew" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${POWER_MAC_TEST_LOG:?}"
if [ "$1" = list ]; then
  exit 1
fi
package="${@: -1}"
if [ -n "${POWER_MAC_FAIL_PACKAGE:-}" ] && [ "$package" = "$POWER_MAC_FAIL_PACKAGE" ]; then
  exit 1
fi
exit 0
EOF

  cat > "$directory/git" <<'EOF'
#!/usr/bin/env bash
printf 'git %s\n' "$*" >> "${POWER_MAC_TEST_LOG:?}"
if [ "${POWER_MAC_FAIL_HOOKS:-false}" = true ] &&
  [ "$1" = -C ] &&
  [ "$3" = config ] &&
  [ "$4" = core.hooksPath ]; then
  exit 1
fi
if [ "$1" = clone ]; then
  destination="${@: -1}"
  mkdir -p "$destination/.git"
fi
exit 0
EOF

  cat > "$directory/curl" <<'EOF'
#!/usr/bin/env bash
output=""
while [ "$#" -gt 0 ]; do
  if [ "$1" = -o ]; then
    output="$2"
    shift
  fi
  shift
done
if [ -n "$output" ]; then
  mkdir -p "$(dirname "$output")"
  : > "$output"
else
  printf '#!/usr/bin/env sh\nexit 0\n'
fi
EOF

  cat > "$directory/gum" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = confirm ]; then
  [ "${POWER_MAC_GUM_CONFIRM:-yes}" = yes ]
  exit
fi
if [ "$1" = choose ]; then
  if [ "${POWER_MAC_GUM_CANCEL:-false}" = true ]; then
    exit 1
  fi
  case "$*" in
    *"Tmux status bar"*) printf '%s\n' "${POWER_MAC_GUM_TMUX_STYLE:-bottom}" ;;
    *"Choose one window manager"*) printf '%s\n' "${POWER_MAC_GUM_WINDOW_MANAGER:-aerospace}" ;;
    *) printf '%s\n' "${POWER_MAC_GUM_SELECTION:-neovim}" ;;
  esac
fi
EOF
  chmod +x "$directory"/*
}

run_install() {
  local home="$1"
  shift
  HOME="$home" \
    PATH="$TEST_TMP/fake-bin:$PATH" \
    POWER_MAC_ALLOW_NON_DARWIN=true \
    POWER_MAC_SKIP_REPO_HOOKS=true \
    POWER_MAC_UI_DELAY=0 \
    POWER_MAC_TEST_LOG="$TEST_TMP/commands.log" \
    "$ROOT/install.sh" "$@"
}

run_sync() {
  local home="$1"
  shift
  HOME="$home" \
    PATH="$TEST_TMP/fake-bin:$PATH" \
    POWER_MAC_TEST_LOG="$TEST_TMP/commands.log" \
    POWER_MAC_FAIL_HOOKS="${POWER_MAC_FAIL_HOOKS:-false}" \
    "$ROOT/sync.sh" "$@"
}

make_fake_bin "$TEST_TMP/fake-bin"
: > "$TEST_TMP/commands.log"

output="$("$ROOT/install.sh" --help)"
if assert_contains "$output" "raycast" && assert_contains "$output" "tmux"; then
  pass "help lists auto-discovered components"
else
  fail "help lists auto-discovered components"
fi

if run_install "$TEST_TMP/home-invalid" --components unknown --dry-run >/dev/null 2>&1; then
  fail "unknown component is rejected"
else
  pass "unknown component is rejected"
fi

home="$TEST_TMP/home-dry"
mkdir -p "$home"
output="$(run_install "$home" --components shell,wezterm --dry-run)"
if assert_contains "$output" "MesloLGS NF (dependency)" && [ ! -e "$home/.zshrc" ] && [ ! -e "$home/.config/power_mac/state" ]; then
  pass "dry-run resolves dependencies without writing"
else
  fail "dry-run resolves dependencies without writing"
fi

home="$TEST_TMP/home-install"
mkdir -p "$home"
if run_install "$home" --components neovim,aerospace >/dev/null &&
  [ -L "$home/.config/nvim" ] &&
  [ -L "$home/.aerospace.toml" ] &&
  assert_file_contains "$home/.config/power_mac/state" "components=neovim,aerospace"; then
  pass "selected formula and cask install with configs and state"
else
  fail "selected formula and cask install with configs and state"
fi

if run_install "$home" --components lazygit >/dev/null &&
  assert_file_contains "$home/.config/power_mac/state" "neovim" &&
  assert_file_contains "$home/.config/power_mac/state" "aerospace" &&
  assert_file_contains "$home/.config/power_mac/state" "lazygit"; then
  pass "subsequent installs merge saved state"
else
  fail "subsequent installs merge saved state"
fi

home="$TEST_TMP/home-window-manager-conflict"
mkdir -p "$home"
output="$(run_install "$home" --components rectangle --dry-run)"
if assert_contains "$output" "Homebrew cask rectangle"; then
  pass "Rectangle is available as a Homebrew cask"
else
  fail "Rectangle is available as a Homebrew cask"
fi

if run_install "$home" --components aerospace,rectangle --dry-run >/dev/null 2>&1; then
  fail "conflicting window managers are rejected"
else
  pass "conflicting window managers are rejected"
fi

output="$(run_install "$home" --all --dry-run)"
if assert_contains "$output" "AeroSpace" &&
  ! assert_contains "$output" "Homebrew cask rectangle" >/dev/null 2>&1; then
  pass "all mode prefers the recommended window manager"
else
  fail "all mode prefers the recommended window manager"
fi

home="$TEST_TMP/home-window-manager-switch"
mkdir -p "$home"
if run_install "$home" --components aerospace >/dev/null &&
  output="$(run_install "$home" --components rectangle)" &&
  assert_contains "$output" "Quit or disable AeroSpace" &&
  assert_file_contains "$home/.config/power_mac/state" "components=rectangle" &&
  ! assert_file_contains "$home/.config/power_mac/state" "aerospace" >/dev/null 2>&1; then
  pass "selecting Rectangle replaces AeroSpace in saved state"
else
  fail "selecting Rectangle replaces AeroSpace in saved state"
fi

state_home="$TEST_TMP/home-state-sync"
mkdir -p "$state_home/.config/power_mac"
printf 'components=wezterm\ntmux_style=bottom\n' > "$state_home/.config/power_mac/state"
if run_sync "$state_home" >/dev/null &&
  [ -L "$state_home/.config/wezterm/wezterm.lua" ] &&
  [ ! -e "$state_home/.config/nvim" ] &&
  [ ! -e "$state_home/.aerospace.toml" ]; then
  pass "saved-state sync touches only recorded component configs"
else
  fail "saved-state sync touches only recorded component configs"
fi

legacy_home="$TEST_TMP/home-legacy-detected"
mkdir -p "$legacy_home/.config/wezterm" "$legacy_home/.config"
ln -s "$ROOT/wezterm.lua" "$legacy_home/.config/wezterm/wezterm.lua"
ln -s "$ROOT/nvim" "$legacy_home/.config/nvim"
: > "$TEST_TMP/commands.log"
output="$(run_sync "$legacy_home")"
if assert_contains "$output" "detected legacy power_mac configs: wezterm,neovim" &&
  assert_file_contains "$legacy_home/.config/power_mac/state" "components=wezterm,neovim" &&
  assert_file_contains "$TEST_TMP/commands.log" "config core.hooksPath .githooks" &&
  [ ! -e "$legacy_home/.zshrc" ] &&
  [ ! -e "$legacy_home/.aerospace.toml" ]; then
  pass "legacy migration reinstalls hooks before saving state"
else
  fail "legacy migration reinstalls hooks before saving state"
fi

empty_home="$TEST_TMP/home-no-state"
mkdir -p "$empty_home"
output="$(run_sync "$empty_home")"
if assert_contains "$output" "using the legacy sync configuration" &&
  [ -L "$empty_home/.zshrc" ] &&
  [ -L "$empty_home/.config/wezterm/wezterm.lua" ] &&
  [ -L "$empty_home/.config/nvim" ] &&
  [ -L "$empty_home/.aerospace.toml" ] &&
  [ ! -e "$empty_home/.tmux.conf" ] &&
  assert_file_contains "$empty_home/.config/power_mac/state" "components=shell,wezterm,neovim,aerospace"; then
  pass "sync without state falls back to the legacy config set"
else
  fail "sync without state falls back to the legacy config set"
fi

dry_migration_home="$TEST_TMP/home-legacy-dry"
mkdir -p "$dry_migration_home/.config/wezterm"
ln -s "$ROOT/wezterm.lua" "$dry_migration_home/.config/wezterm/wezterm.lua"
: > "$TEST_TMP/commands.log"
output="$(run_sync "$dry_migration_home" --dry-run)"
if assert_contains "$output" "Would install this repository's Git hooks" &&
  [ ! -e "$dry_migration_home/.config/power_mac/state" ] &&
  [ ! -s "$TEST_TMP/commands.log" ]; then
  pass "legacy migration dry-run reports hooks without side effects"
else
  fail "legacy migration dry-run reports hooks without side effects"
fi

failed_hooks_home="$TEST_TMP/home-legacy-hook-failure"
mkdir -p "$failed_hooks_home/.config/wezterm"
ln -s "$ROOT/wezterm.lua" "$failed_hooks_home/.config/wezterm/wezterm.lua"
if POWER_MAC_FAIL_HOOKS=true run_sync "$failed_hooks_home" >/dev/null 2>&1; then
  fail "hook failure makes legacy migration fail"
elif [ ! -e "$failed_hooks_home/.config/power_mac/state" ]; then
  pass "hook failure prevents migrated state persistence"
else
  fail "hook failure prevents migrated state persistence"
fi

home="$TEST_TMP/home-backup"
mkdir -p "$home/.config/nvim"
printf 'personal\n' > "$home/.config/nvim/init.lua"
if run_sync "$home" --components neovim >/dev/null &&
  [ -L "$home/.config/nvim" ] &&
  find "$home/.config" -maxdepth 1 -name 'nvim.bak.*' -type d | grep . >/dev/null; then
  pass "config sync backs up real directories"
else
  fail "config sync backs up real directories"
fi

home="$TEST_TMP/home-tmux"
mkdir -p "$home"
printf 'personal tmux\n' > "$home/.tmux.conf"
if run_install "$home" --components tmux --tmux-style top >/dev/null &&
  [ -L "$home/.tmux.conf" ] &&
  [ "$(readlink "$home/.tmux.conf")" = "$ROOT/tmux-installer/tmux-top.conf" ] &&
  find "$home" -maxdepth 1 -name '.tmux.conf.bak.*' -type f | grep . >/dev/null &&
  [ -d "$home/.tmux/plugins/tpm/.git" ]; then
  pass "Tmux preserves config and installs TPM safely"
else
  fail "Tmux preserves config and installs TPM safely"
fi

if run_install "$home" --components lazygit >/dev/null &&
  assert_file_contains "$home/.config/power_mac/state" "tmux_style=top"; then
  pass "later installs preserve the saved Tmux style"
else
  fail "later installs preserve the saved Tmux style"
fi

home="$TEST_TMP/home-partial"
mkdir -p "$home"
if POWER_MAC_FAIL_PACKAGE=lazygit run_install "$home" --components neovim,lazygit >/dev/null 2>&1; then
  fail "partial package failure returns non-zero"
elif assert_file_contains "$home/.config/power_mac/state" "components=neovim" &&
  ! assert_file_contains "$home/.config/power_mac/state" "lazygit" >/dev/null 2>&1; then
  pass "partial failure saves only successful selections"
else
  fail "partial failure saves only successful selections"
fi

home="$TEST_TMP/home-interactive"
mkdir -p "$home"
interactive_output="$(HOME="$home" \
  PATH="$TEST_TMP/fake-bin:$PATH" \
  POWER_MAC_ALLOW_NON_DARWIN=true \
  POWER_MAC_ALLOW_NON_TTY_INTERACTIVE=true \
  POWER_MAC_SKIP_REPO_HOOKS=true \
  POWER_MAC_UI_DELAY=0 \
  POWER_MAC_TEST_LOG="$TEST_TMP/commands.log" \
  POWER_MAC_GUM_SELECTION=neovim \
  "$ROOT/install.sh")"
if assert_contains "$interactive_output" "power_mac" &&
  assert_contains "$interactive_output" "Preparing your installer" &&
  assert_contains "$interactive_output" "apps and tools discovered" &&
  assert_contains "$interactive_output" "Choose your setup" &&
  assert_file_contains "$home/.config/power_mac/state" "components=neovim"; then
  pass "interactive welcome UI leads into chosen component"
else
  fail "interactive welcome UI leads into chosen component"
fi

home="$TEST_TMP/home-interactive-conflict"
mkdir -p "$home"
interactive_output="$(HOME="$home" \
  PATH="$TEST_TMP/fake-bin:$PATH" \
  POWER_MAC_ALLOW_NON_DARWIN=true \
  POWER_MAC_ALLOW_NON_TTY_INTERACTIVE=true \
  POWER_MAC_SKIP_REPO_HOOKS=true \
  POWER_MAC_UI_DELAY=0 \
  POWER_MAC_TEST_LOG="$TEST_TMP/commands.log" \
  POWER_MAC_GUM_SELECTION=$'aerospace\nrectangle' \
  POWER_MAC_GUM_WINDOW_MANAGER=rectangle \
  "$ROOT/install.sh")"
if assert_contains "$interactive_output" "should not run together" &&
  assert_contains "$interactive_output" "Keeping Rectangle" &&
  assert_file_contains "$home/.config/power_mac/state" "components=rectangle" &&
  ! assert_file_contains "$home/.config/power_mac/state" "aerospace" >/dev/null 2>&1; then
  pass "interactive conflicts warn and ask which component to keep"
else
  fail "interactive conflicts warn and ask which component to keep"
fi

home="$TEST_TMP/home-cancel"
mkdir -p "$home"
if HOME="$home" \
  PATH="$TEST_TMP/fake-bin:$PATH" \
  POWER_MAC_ALLOW_NON_DARWIN=true \
  POWER_MAC_ALLOW_NON_TTY_INTERACTIVE=true \
  POWER_MAC_SKIP_REPO_HOOKS=true \
  POWER_MAC_UI_DELAY=0 \
  POWER_MAC_TEST_LOG="$TEST_TMP/commands.log" \
  POWER_MAC_GUM_CANCEL=true \
  "$ROOT/install.sh" >/dev/null &&
  [ ! -e "$home/.config/power_mac/state" ]; then
  pass "interactive cancellation exits without state changes"
else
  fail "interactive cancellation exits without state changes"
fi

home="$TEST_TMP/home-rejected"
mkdir -p "$home"
if HOME="$home" \
  PATH="$TEST_TMP/fake-bin:$PATH" \
  POWER_MAC_ALLOW_NON_DARWIN=true \
  POWER_MAC_ALLOW_NON_TTY_INTERACTIVE=true \
  POWER_MAC_SKIP_REPO_HOOKS=true \
  POWER_MAC_UI_DELAY=0 \
  POWER_MAC_TEST_LOG="$TEST_TMP/commands.log" \
  POWER_MAC_GUM_SELECTION=neovim \
  POWER_MAC_GUM_CONFIRM=no \
  "$ROOT/install.sh" >/dev/null &&
  [ ! -e "$home/.config/power_mac/state" ] &&
  [ ! -e "$home/.config/nvim" ]; then
  pass "rejected confirmation exits without installation"
else
  fail "rejected confirmation exits without installation"
fi

fixture_root="$TEST_TMP/fixture-root"
mkdir -p "$fixture_root/components"
cat > "$fixture_root/components/fixture.sh" <<'EOF'
component_define "fixture" "Fixture" "Auto-discovered test component" "Tests" "true" "false" "" "formula" "fixture" "" "" "" "" ""
EOF
output="$(
  POWER_MAC_ROOT="$fixture_root" HOME="$TEST_TMP/fixture-home" bash -c \
    'source "$1/lib/core.sh"; pm_load_components; pm_selectable_component_ids' _ "$ROOT"
)"
if [ "$output" = fixture ]; then
  pass "new module is discovered without core edits"
else
  fail "new module is discovered without core edits"
fi

invalid_root="$TEST_TMP/invalid-root"
mkdir -p "$invalid_root/components"
cat > "$invalid_root/components/a.sh" <<'EOF'
component_define "a" "A" "A" "Tests" "true" "false" "missing" "virtual" "" "" "" "" "" ""
EOF
if POWER_MAC_ROOT="$invalid_root" HOME="$TEST_TMP/invalid-home" bash -c \
  'source "$1/lib/core.sh"; pm_load_components' _ "$ROOT" >/dev/null 2>&1; then
  fail "invalid dependency is rejected"
else
  pass "invalid dependency is rejected"
fi

duplicate_root="$TEST_TMP/duplicate-root"
mkdir -p "$duplicate_root/components"
cat > "$duplicate_root/components/a.sh" <<'EOF'
component_define "same" "A" "A" "Tests" "true" "false" "" "virtual" "" "" "" "" "" ""
EOF
cat > "$duplicate_root/components/b.sh" <<'EOF'
component_define "same" "B" "B" "Tests" "true" "false" "" "virtual" "" "" "" "" "" ""
EOF
if POWER_MAC_ROOT="$duplicate_root" HOME="$TEST_TMP/duplicate-home" bash -c \
  'source "$1/lib/core.sh"; pm_load_components' _ "$ROOT" >/dev/null 2>&1; then
  fail "duplicate component IDs are rejected"
else
  pass "duplicate component IDs are rejected"
fi

cycle_root="$TEST_TMP/cycle-root"
mkdir -p "$cycle_root/components"
cat > "$cycle_root/components/a.sh" <<'EOF'
component_define "a" "A" "A" "Tests" "true" "false" "b" "virtual" "" "" "" "" "" ""
EOF
cat > "$cycle_root/components/b.sh" <<'EOF'
component_define "b" "B" "B" "Tests" "true" "false" "a" "virtual" "" "" "" "" "" ""
EOF
if POWER_MAC_ROOT="$cycle_root" HOME="$TEST_TMP/cycle-home" bash -c \
  'source "$1/lib/core.sh"; pm_load_components' _ "$ROOT" >/dev/null 2>&1; then
  fail "dependency cycles are rejected"
else
  pass "dependency cycles are rejected"
fi

mapping_root="$TEST_TMP/mapping-root"
mkdir -p "$mapping_root/components"
cat > "$mapping_root/components/a.sh" <<'EOF'
component_define "a" "A" "A" "Tests" "true" "false" "" "virtual" "" "missing-delimiter" "" "" "" ""
EOF
if POWER_MAC_ROOT="$mapping_root" HOME="$TEST_TMP/mapping-home" bash -c \
  'source "$1/lib/core.sh"; pm_load_components' _ "$ROOT" >/dev/null 2>&1; then
  fail "malformed config mappings are rejected"
else
  pass "malformed config mappings are rejected"
fi

printf '1..%d\n' "$((PASS_COUNT + FAIL_COUNT))"
if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
