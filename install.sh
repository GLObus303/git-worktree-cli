#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "git-worktree-cli install"
echo

if ! command -v fzf >/dev/null 2>&1; then
  echo "Missing fzf (needed for arrow-key pick)."
  echo "  brew install fzf"
  echo
else
  echo "fzf: ok ($(command -v fzf))"
fi

echo "Add this line to ~/.zshrc:"
echo
echo "  source \"$ROOT/wt.zsh\""
echo
echo "Then open a new shell (or: source ~/.zshrc) and run: wt list"
