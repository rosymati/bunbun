#!/usr/bin/env bash
set -o errexit

NEW_VERSION=$(curl --silent https://api.github.com/repos/oven-sh/bun/releases/latest \
  | jq '.tag_name | ltrimstr("bun-v")' --raw-output)
CURRENT=$(grep -m1 'version = ' bun.nix | grep -oP '"\K[^"]+')

if [[ "$CURRENT" == "$NEW_VERSION" ]]; then
  echo "Already at $CURRENT, nothing to do"
  exit 0
fi

echo "$CURRENT -> $NEW_VERSION"

HASH_X64=$(nix store prefetch-file --hash-type sha256 --json \
  "https://github.com/oven-sh/bun/releases/download/bun-v${NEW_VERSION}/bun-linux-x64.zip" \
  | jq -r '.hash')
HASH_AARCH64=$(nix store prefetch-file --hash-type sha256 --json \
  "https://github.com/oven-sh/bun/releases/download/bun-v${NEW_VERSION}/bun-linux-aarch64.zip" \
  | jq -r '.hash')

sed -i "s/version = \"[0-9.]*\"/version = \"$NEW_VERSION\"/" bun.nix
sed -i "/bun-linux-x64.zip/{n; s|hash = \"[^\"]*\"|hash = \"$HASH_X64\"|}" bun.nix
sed -i "/bun-linux-aarch64.zip/{n; s|hash = \"[^\"]*\"|hash = \"$HASH_AARCH64\"|}" bun.nix
