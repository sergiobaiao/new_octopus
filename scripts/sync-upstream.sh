#!/usr/bin/env bash
set -euo pipefail

# Syncs this fork with a formbricks/formbricks upstream release, without
# losing this fork's own changes (CI workflow, Dockerfiles, rebrand patch,
# docker/patches/). Usage:
#
#   scripts/sync-upstream.sh <tag-or-ref>   # e.g. scripts/sync-upstream.sh 5.2.2
#   scripts/sync-upstream.sh                # defaults to latest upstream release
#
# What it does:
#   1. Adds/updates the "upstream" remote (formbricks/formbricks).
#   2. Fetches upstream tags.
#   3. Merges the given ref into the current branch.
#   4. On conflicts: files this fork actually owns (tracked in
#      OWNED_PATHS below) are left for you to resolve by hand, since a
#      conflict there means upstream touched the same lines as a local
#      customization. Every other conflicted file is pure upstream-side
#      history divergence (e.g. a squashed/rebased release branch) with
#      no local customization at risk, so it's safe to auto-resolve by
#      taking upstream's side.
#   5. Re-applies docker/patches/*.patch (idempotent) so the rebrand
#      patch still matches the merged source tree.
#
# Refuses to run with a dirty working tree, and aborts the merge (leaving
# your tree exactly as it was) if an owned-path conflict shows up instead
# of guessing at a resolution.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Paths this fork customizes directly (not through docker/patches/). A
# merge conflict inside one of these means upstream changed something we
# also changed on purpose -- that needs a human, not an auto-resolve.
OWNED_PATHS=(
  ".github/workflows/build-multiarch.yml"
  "apps/web/Dockerfile"
  "apps/web/Dockerfile.optimized"
  "apps/web/images/formbricks-wordmark.svg"
  "apps/web/public/favicon.ico"
  "apps/web/public/logo-transparent.png"
  "docker/patches/"
)

if [ -n "$(git status --porcelain)" ]; then
  echo "ERROR: working tree is dirty. Commit or stash before syncing." >&2
  exit 1
fi

if git remote get-url upstream >/dev/null 2>&1; then
  git remote set-url upstream https://github.com/formbricks/formbricks.git
else
  git remote add upstream https://github.com/formbricks/formbricks.git
fi

echo "Fetching upstream tags..."
git fetch upstream --tags

REF="${1:-}"
if [ -z "$REF" ]; then
  REF="$(git ls-remote --tags --refs upstream \
    | awk -F/ '{print $NF}' \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V | tail -1)"
  echo "No ref given, defaulting to latest release tag: $REF"
fi

echo "Merging upstream/$REF into $(git branch --show-current)..."
if git merge "$REF" --no-edit; then
  echo "Clean merge, no conflicts."
else
  conflicts="$(git diff --name-only --diff-filter=U)"

  for owned in "${OWNED_PATHS[@]}"; do
    if grep -qF "$owned" <<<"$conflicts"; then
      echo "ERROR: conflict in owned path '$owned' -- resolve by hand:" >&2
      echo "$conflicts" | grep -F "$owned" >&2
      echo "Aborting merge (working tree left untouched)." >&2
      git merge --abort
      exit 1
    fi
  done

  echo "No conflicts in owned paths -- taking upstream's side for:"
  echo "$conflicts"
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    status="$(git status --porcelain -- "$f" | cut -c1-2)"
    if [ "$status" = "UD" ]; then
      git rm -- "$f"
    else
      git checkout --theirs -- "$f"
      git add -- "$f"
    fi
  done <<<"$conflicts"

  git commit --no-edit
fi

echo "Re-applying docker/patches/*.patch..."
bash docker/patches/apply-patches.sh

echo "Done. Review the result (git log, git diff HEAD~1), then push when ready."
