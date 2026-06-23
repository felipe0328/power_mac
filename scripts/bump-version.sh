#!/usr/bin/env bash
# Bump VERSION, README badge/footer, and install.sh header from conventional commits.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DRY_RUN=false
REPORT=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --report) REPORT=true ;;
    *)
      echo "error: unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

VERSION_FILE="$REPO_ROOT/VERSION"
README="$REPO_ROOT/README.md"
INSTALL_SH="$REPO_ROOT/install.sh"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "error: VERSION file not found" >&2
  exit 1
fi

emit_report() {
  local changed="$1"
  local version="$2"
  local bump_type="$3"
  local reason="$4"

  printf 'changed=%s\n' "$changed"
  printf 'current=%s\n' "$current"
  printf 'version=%s\n' "$version"
  printf 'bump_type=%s\n' "$bump_type"
  printf 'reason=%s\n' "$reason"
}

current="$(tr -d '[:space:]' < "$VERSION_FILE")"
# Preview mode reads the version from the trusted base ref, not from a fork's tree.
if [[ -n "${VERSION_BASE_REF:-}" ]]; then
  current="$(git show "${VERSION_BASE_REF}:VERSION" 2>/dev/null | tr -d '[:space:]')"
  if [[ -z "$current" ]]; then
    echo "error: could not read VERSION from ${VERSION_BASE_REF}" >&2
    exit 1
  fi
fi
IFS=. read -r major minor patch <<< "$current"

if [[ -z "${major:-}" || -z "${minor:-}" || -z "${patch:-}" ]]; then
  echo "error: invalid VERSION value: ${current}" >&2
  exit 1
fi

sed_inplace() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Skip re-entry when the latest commit is the automated version bump.
head_ref="${VERSION_HEAD_REF:-${GITHUB_SHA:-HEAD}}"
head_msg="$(git log -1 --format=%s "$head_ref" 2>/dev/null || true)"
if [[ "$REPORT" != true && "$head_msg" == *"[skip version]"* ]]; then
  echo "No bump: latest commit is an automated version bump"
  exit 0
fi

# Prefer the exact pushed range in CI. PR previews provide base/head refs, while
# local runs fall back to commits made since VERSION last changed.
commit_range=""
if [[ -n "${GITHUB_EVENT_BEFORE:-}" && "${GITHUB_EVENT_BEFORE}" != "0000000000000000000000000000000000000000" ]]; then
  commit_range="${GITHUB_EVENT_BEFORE}..${head_ref}"
elif [[ -n "${VERSION_BASE_REF:-}" ]]; then
  commit_range="${VERSION_BASE_REF}..${head_ref}"
else
  last_version_commit="$(git log -1 --format=%H -- VERSION 2>/dev/null || true)"
  if [[ -n "$last_version_commit" ]]; then
    commit_range="${last_version_commit}..${head_ref}"
  fi
fi

if [[ -z "$commit_range" ]]; then
  log_cmd=(git log --format=%s -20 "$head_ref")
elif ! git rev-parse "${commit_range%%..*}" &>/dev/null 2>&1; then
  log_cmd=(git log --format=%s -20 "$head_ref")
else
  log_cmd=(git log --format=%s "$commit_range")
fi

messages=()
while IFS= read -r line; do
  [[ -n "$line" ]] && messages+=("$line")
done < <("${log_cmd[@]}" 2>/dev/null || true)

if [[ ${#messages[@]} -eq 0 ]]; then
  if [[ "$REPORT" == true ]]; then
    emit_report "false" "$current" "none" "no commits to analyze"
    exit 0
  fi
  echo "No bump: no commits to analyze"
  exit 0
fi

# 0 = none, 1 = patch, 2 = minor, 3 = major
bump_level=0

for msg in "${messages[@]}"; do
  [[ -z "$msg" ]] && continue
  if [[ "$msg" =~ ^Merge ]]; then
    continue
  fi
  if [[ "$msg" == *"[skip version]"* ]]; then
    continue
  fi
  # Keep this precedence aligned with the Semver table in CONTRIBUTOR.md.
  if [[ "$msg" =~ ^breaking: ]] || [[ "$msg" =~ ^feat(\(.+\))?!: ]] || [[ "$msg" =~ ^fix(\(.+\))?!: ]] || [[ "$msg" == *"BREAKING CHANGE"* ]]; then
    bump_level=3
    continue
  fi
  if [[ "$msg" =~ ^feat(\(.+\))?: ]]; then
    (( bump_level < 3 )) && bump_level=2
    continue
  fi
  if [[ "$msg" =~ ^(fix|chore|docs|refactor|perf|test|ci|build|revert)(\(.+\))?: ]]; then
    (( bump_level < 2 )) && bump_level=1
  fi
done

if [[ $bump_level -eq 0 ]]; then
  if [[ "$REPORT" == true ]]; then
    emit_report "false" "$current" "none" "no conventional commits found in range"
    exit 0
  fi
  echo "No bump: no conventional commits found in range"
  exit 0
fi

case $bump_level in
  3) major=$((major + 1)); minor=0; patch=0; bump_type="major" ;;
  2) minor=$((minor + 1)); patch=0; bump_type="minor" ;;
  1) patch=$((patch + 1)); bump_type="patch" ;;
esac

new_version="${major}.${minor}.${patch}"

if [[ "$new_version" == "$current" ]]; then
  if [[ "$REPORT" == true ]]; then
    emit_report "false" "$current" "none" "already at ${current}"
    exit 0
  fi
  echo "No bump: already at ${current}"
  exit 0
fi

if [[ "$REPORT" == true ]]; then
  emit_report "true" "$new_version" "$bump_type" "conventional commits require ${bump_type} bump"
  exit 0
fi

echo "Bumping ${current} → ${new_version}"

apply_version() {
  printf '%s\n' "$new_version" > "$VERSION_FILE"
  sed_inplace "s|version-[0-9.]*-blueviolet|version-${new_version}-blueviolet|" "$README"
  sed_inplace "s|\*\*v[0-9.]*\*\*|**v${new_version}**|" "$README"
  sed_inplace "s|^# Version: .*|# Version: ${new_version}|" "$INSTALL_SH"
}

if [[ "$DRY_RUN" == true ]]; then
  echo "[dry-run] Would update VERSION, README.md, install.sh"
  exit 0
fi

apply_version
echo "Updated to ${new_version}"
