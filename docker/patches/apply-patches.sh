#!/usr/bin/env bash
set -euo pipefail

# Applies every *.patch file in this directory against the repo root, in
# sorted order. Safe to re-run: a patch already applied is detected via a
# reverse dry-run and skipped instead of erroring out.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$REPO_ROOT"

shopt -s nullglob
patches=("$SCRIPT_DIR"/*.patch)

if [ ${#patches[@]} -eq 0 ]; then
  echo "No patches found in $SCRIPT_DIR"
  exit 0
fi

for patch_file in "${patches[@]}"; do
  name="$(basename "$patch_file")"

  if patch -p1 --dry-run --forward <"$patch_file" >/dev/null 2>&1; then
    echo "Applying $name"
    patch -p1 <"$patch_file"
  elif patch -p1 --dry-run --reverse <"$patch_file" >/dev/null 2>&1; then
    echo "Skipping $name (already applied)"
  else
    echo "ERROR: $name does not apply cleanly (forward or reverse)" >&2
    exit 1
  fi
done
