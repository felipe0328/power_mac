#!/usr/bin/env bash
# Bump VERSION, README badge/footer, and install.sh header from conventional commits.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

VERSION_FILE="$REPO_ROOT/VERSION"
README="$REPO_ROOT/README.md"
INSTALL_SH="$REPO_ROOT/install.sh"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "error: VERSION file not found" >&2
  exit 1
fi

current="$(tr -d '[:space:]' < "$VERSION_FILE")"
IFS=. read -r major minor patch <<< "$current"

sed_inplace() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# Skip re-entry when the latest commit is the automated version bump.
head_msg="$(git log -1 --format=%s 2>/dev/null || true)"
if [[ "$head_msg" == *"[skip version]"* ]]; then
  echo "No bump: latest commit is an automated version bump"
  exit 0
fi

# Commits to analyze: push range in CI, else since last VERSION change.
commit_range=""
if [[ -n "${GITHUB_EVENT_BEFORE:-}" && "${GITHUB_EVENT_BEFORE}" != "0000000000000000000000000000000000000000" ]]; then
  commit_range="${GITHUB_EVENT_BEFORE}..${GITHUB_SHA:-HEAD}"
else
  last_version_commit="$(git log -1 --format=%H -- VERSION 2>/dev/null || true)"
  if [[ -n "$last_version_commit" ]]; then
    commit_range="${last_version_commit}..HEAD"
  fi
fi

if [[ -z "$commit_range" ]]; then
  log_cmd=(git log --format=%s -20)
elif ! git rev-parse "${commit_range%%..*}" &>/dev/null 2>&1; then
  log_cmd=(git log --format=%s -20)
else
  log_cmd=(git log --format=%s "$commit_range")
fi

messages=()
while IFS= read -r line; do
  [[ -n "$line" ]] && messages+=("$line")
done < <("${log_cmd[@]}" 2>/dev/null || true)

if [[ ${#messages[@]} -eq 0 ]]; then
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
  echo "No bump: no conventional commits found in range"
  exit 0
fi

case $bump_level in
  3) major=$((major + 1)); minor=0; patch=0 ;;
  2) minor=$((minor + 1)); patch=0 ;;
  1) patch=$((patch + 1)) ;;
esac

new_version="${major}.${minor}.${patch}"

if [[ "$new_version" == "$current" ]]; then
  echo "No bump: already at ${current}"
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
