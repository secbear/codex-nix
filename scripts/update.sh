#!/usr/bin/env bash
#
# Update codex to a new version.
#
# Usage:
#   ./scripts/update.sh              # update to latest
#   ./scripts/update.sh --check      # check for new version, don't update
#   ./scripts/update.sh 0.105.0      # update to specific version

set -euo pipefail

REPO="openai/codex"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PACKAGE_NIX="${SCRIPT_DIR}/../package.nix"

PLATFORMS=(
  "aarch64-apple-darwin"
  "x86_64-apple-darwin"
  "x86_64-unknown-linux-musl"
  "aarch64-unknown-linux-musl"
)

# A release ships the CLI and its code-mode host as separate assets, and
# package.nix keeps one hash set per asset. "<asset name>:<attribute set>".
ASSETS=(
  "codex:hashes"
  "codex-code-mode-host:codeModeHostHashes"
)

current_version() {
  grep 'version = "' "$PACKAGE_NIX" | head -1 | sed 's/.*"\(.*\)".*/\1/'
}

latest_version() {
  if command -v gh >/dev/null 2>&1; then
    gh release view --repo "$REPO" --json tagName -q '.tagName' | sed 's/^rust-v//'
  else
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
      | grep '"tag_name"' \
      | sed 's/.*"rust-v\(.*\)".*/\1/'
  fi
}

# --- main ---

CURRENT=$(current_version)
echo "Current version: ${CURRENT}"

if [[ "${1:-}" == "--check" ]] || [[ $# -eq 0 ]]; then
  LATEST=$(latest_version)
  echo "Latest version:  ${LATEST}"
  if [[ "$CURRENT" == "$LATEST" ]]; then
    echo "Already up to date."
    exit 0
  fi
  echo ""
  echo "Update available! Run:"
  echo "  ./scripts/update.sh ${LATEST}"
  [[ "${1:-}" == "--check" ]] && exit 0
  # If called with no args, fall through to update
  NEW_VERSION="$LATEST"
else
  NEW_VERSION="$1"
fi

echo "Updating to:     ${NEW_VERSION}"
echo ""

echo "Fetching SHA256 hashes..."
for asset_spec in "${ASSETS[@]}"; do
  asset="${asset_spec%%:*}"
  block="${asset_spec##*:}"

  for platform in "${PLATFORMS[@]}"; do
    url="https://github.com/${REPO}/releases/download/rust-v${NEW_VERSION}/${asset}-${platform}.tar.gz"

    # nix-prefetch-url writes progress to stderr and the hash to stdout; keep
    # stderr so a renamed or missing upstream target says why it failed.
    if ! hash=$(nix-prefetch-url "$url" | tail -1) || [[ -z "$hash" ]]; then
      echo "error: could not fetch hash for ${asset} ${platform}" >&2
      echo "       ${url}" >&2
      exit 1
    fi

    echo "  ${asset} ${platform}: ${hash}"

    tmp=$(mktemp)
    awk -v block="$block" -v platform="$platform" -v hash="$hash" '
      $0 ~ "^  " block " = \\{" { in_block=1 }
      in_block && $0 ~ "\"" platform "\"" {
        sub(/= "[^"]*"/, "= \"" hash "\"")
      }
      in_block && /\};/ { in_block=0 }
      { print }
    ' "$PACKAGE_NIX" > "$tmp"
    mv "$tmp" "$PACKAGE_NIX"
  done
done

tmp=$(mktemp)
sed "s/version = \"${CURRENT}\"/version = \"${NEW_VERSION}\"/" "$PACKAGE_NIX" > "$tmp"
mv "$tmp" "$PACKAGE_NIX"

echo ""
echo "Updated package.nix to v${NEW_VERSION}"
echo ""
echo "Next steps:"
echo "  1. nix build              # verify it builds"
echo "  2. ./result/bin/codex --version"
echo "  3. git add package.nix && git commit -m \"update codex to ${NEW_VERSION}\""
