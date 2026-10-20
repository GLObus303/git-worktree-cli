#!/usr/bin/env bash
# Create a Momence feature worktree: git worktree add, copy local env files, yarn.
# Sourced or called with: create_worktree <repo-root> <branch> [dest] [--no-install] [--from <ref>]
# Prints the destination path on the last success line to stdout via WT_CREATED_PATH.

set -euo pipefail

create_worktree() {
  local ROOT="$1"
  shift

  local BRANCH=""
  local DEST=""
  local DO_INSTALL=1
  local FROM_REF="HEAD"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --no-install)
        DO_INSTALL=0
        shift
        ;;
      --from)
        FROM_REF="${2:?--from requires a ref}"
        shift 2
        ;;
      -*)
        echo "Unknown option: $1" >&2
        return 1
        ;;
      *)
        if [[ -z "$BRANCH" ]]; then
          BRANCH="$1"
        elif [[ -z "$DEST" ]]; then
          DEST="$1"
        else
          echo "Unexpected argument: $1" >&2
          return 1
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$BRANCH" ]]; then
    echo "Usage: wt new <branch> [path] [--no-install] [--from <ref>]" >&2
    return 1
  fi

  local SAFE_NAME="${BRANCH//\//-}"
  DEST="${DEST:-$ROOT/.worktrees/$SAFE_NAME}"

  if [[ "$DEST" != /* ]]; then
    DEST="$ROOT/$DEST"
  fi

  mkdir -p "$(dirname "$DEST")"

  if [[ -e "$DEST" ]]; then
    echo "Destination already exists: $DEST" >&2
    return 1
  fi

  if git -C "$ROOT" show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "Checking out existing branch '$BRANCH' into $DEST" >&2
    git -C "$ROOT" worktree add "$DEST" "$BRANCH"
  elif git -C "$ROOT" show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
    echo "Creating local branch '$BRANCH' from origin/$BRANCH into $DEST" >&2
    git -C "$ROOT" worktree add -b "$BRANCH" "$DEST" "origin/$BRANCH"
  else
    echo "Creating new branch '$BRANCH' from $FROM_REF into $DEST" >&2
    git -C "$ROOT" worktree add -b "$BRANCH" "$DEST" "$FROM_REF"
  fi

  copy_if_exists() {
    local rel="$1"
    local src="$ROOT/$rel"
    local dst="$DEST/$rel"
    if [[ -e "$src" ]]; then
      mkdir -p "$(dirname "$dst")"
      cp -R "$src" "$dst"
      echo "copied $rel" >&2
    fi
  }

  copy_if_exists backend/.env
  copy_if_exists backend/.env.local
  copy_if_exists backend/.env.remote.local
  copy_if_exists backend/.env.test
  copy_if_exists frontend/.env
  copy_if_exists frontend/.env.local
  copy_if_exists frontend/.env.development.local
  copy_if_exists static-server/.env
  copy_if_exists e2e/.env
  copy_if_exists dbhub.toml
  copy_if_exists mprocs.yaml

  if [[ "$DO_INSTALL" -eq 1 ]]; then
    export YARN_ENABLE_GLOBAL_CACHE=true
    echo "Installing dependencies (shared yarn cache)..." >&2
    if [[ -d "$DEST/eslint-plugin" ]]; then
      (cd "$DEST/eslint-plugin" && yarn)
    fi
    if [[ -d "$DEST/backend" ]]; then
      (cd "$DEST/backend" && yarn)
    fi
    if [[ -d "$DEST/frontend" ]]; then
      (cd "$DEST/frontend" && yarn)
    fi
  fi

  echo >&2
  echo "Worktree ready: $DEST" >&2
  # Path for callers that want to capture it
  printf '%s\n' "$DEST"
}
