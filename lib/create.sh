#!/usr/bin/env bash
# Create a Momence feature worktree: git worktree add, copy local env files, yarn.
# Defines create_worktree <repo-root> <branch> [dest] [--no-install] [--from <ref>]

set -euo pipefail

_create_copy_if_exists() {
  local root="$1" dest="$2" rel="$3"
  local src="$root/$rel"
  local dst="$dest/$rel"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp -R "$src" "$dst"
    echo "copied $rel" >&2
  fi
}

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

  _create_copy_if_exists "$ROOT" "$DEST" .cursor
  _create_copy_if_exists "$ROOT" "$DEST" backend/.env
  _create_copy_if_exists "$ROOT" "$DEST" backend/.env.local
  _create_copy_if_exists "$ROOT" "$DEST" backend/.env.remote.local
  _create_copy_if_exists "$ROOT" "$DEST" backend/.env.test
  _create_copy_if_exists "$ROOT" "$DEST" frontend/.env
  _create_copy_if_exists "$ROOT" "$DEST" frontend/.env.local
  _create_copy_if_exists "$ROOT" "$DEST" frontend/.env.development.local
  _create_copy_if_exists "$ROOT" "$DEST" static-server/.env
  _create_copy_if_exists "$ROOT" "$DEST" e2e/.env
  _create_copy_if_exists "$ROOT" "$DEST" dbhub.toml
  _create_copy_if_exists "$ROOT" "$DEST" mprocs.yaml

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
  printf '%s\n' "$DEST"
}
