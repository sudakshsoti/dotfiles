#!/bin/sh
# Zed create_worktree hook: turn a detached-HEAD worktree into a branch off origin/main.
# Invoked as: new-worktree-branch.sh "$ZED_WORKTREE_ROOT"
set -e

wt="$1"
if [ -z "$wt" ]; then
  echo "no worktree path passed (expected \$ZED_WORKTREE_ROOT as \$1)" >&2
  exit 1
fi

# $ZED_WORKTREE_ROOT looks like .../<worktree-name>/<repo-name>, so the
# leaf is the repo name (value-connect) and the parent is the unique
# worktree name (e.g. humble-geyser) — use that for the branch.
branch="$(basename "$(dirname "$wt")")"

git -C "$wt" fetch origin main --quiet
git -C "$wt" switch -c "$branch" origin/main

echo "created branch '$branch' off origin/main in $wt"
