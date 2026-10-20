# wt — zsh wrapper so `wt` / `wt go` can change directory.
#
# Add to ~/.zshrc:
#   source "$HOME/Documents/Projects/git-worktree-cli/wt.zsh"

WT_ROOT="${WT_ROOT:-$HOME/Documents/Projects/git-worktree-cli}"
WT_BIN="${WT_BIN:-$WT_ROOT/bin/wt}"

wt() {
  local cmd="${1:-}"
  case "$cmd" in
    ""|go|cd)
      [[ -n "$cmd" ]] && shift
      local dest
      dest="$("$WT_BIN" go "$@")" || return $?
      if [[ -z "$dest" ]]; then
        return 1
      fi
      builtin cd "$dest"
      ;;
    *)
      "$WT_BIN" "$@"
      ;;
  esac
}
