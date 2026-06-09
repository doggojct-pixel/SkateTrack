#!/bin/zsh
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: ./scripts/set_github_remote.sh git@github.com:YOUR_ACCOUNT/SkateTrack.git"
  exit 1
fi

REMOTE_URL="$1"

git checkout main >/dev/null 2>&1 || true
if git remote get-url origin >/dev/null 2>&1; then
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

if ! git show-ref --verify --quiet refs/heads/develop; then
  git branch develop
fi

echo "origin is now set to: $(git remote get-url origin)"
echo "Branches:"
git branch --list
