# git-worktree-cli (`wt`)

Personal CLI for Momence feature [git worktrees](https://git-scm.com/docs/git-worktree).

I use this on the Momence monorepo. Paths for env copy and yarn (`backend/`, `frontend/`, `eslint-plugin/`, and a fixed list of `.env*` files) are hardcoded for that layout. If you are not working in that repo, this tool is the wrong fit unless you fork and change those paths.

It only manages checkouts under `<repo>/.worktrees/`. It ignores Cursor agent worktrees under `~/.cursor/worktrees/`.

## Setup

```bash
git clone https://github.com/GLObus303/git-worktree-cli.git ~/Documents/Projects/git-worktree-cli
cd ~/Documents/Projects/git-worktree-cli
./install.sh
brew install fzf   # if you do not have it yet
```

Add to `~/.zshrc`:

```zsh
source "$HOME/Documents/Projects/git-worktree-cli/wt.zsh"
```

Reload the shell. There is no PATH install: the zsh function calls `bin/wt` by absolute path so `wt go` can `cd`.

## Commands

```text
wt                 same as wt go — fzf pick, then cd
wt new <branch>    create under .worktrees/<branch-with-slashes-as-dashes>
                   copies Momence env files; runs yarn (skip with --no-install)
                   optional: [path] [--from <ref>]
wt list            bordered table: branch, path, dirty, commit subject ≤100
wt go [query]      fzf pick (arrows), then cd — includes main + .worktrees/*
wt rm [query]      remove worktree only (branch stays); --force if dirty
wt open [query]    open in Cursor (or VS Code)
wt claim <branch>  checkout branch here (detach the worktree that held it)
wt prune           git worktree prune
```

`wt new` refuses if the repo does not look like Momence (`backend/`, `frontend/`, `eslint-plugin/`). Other commands warn and continue.

## Notes

- Docker/DB for Momence stay shared with the main checkout. You do not need `task init` per worktree.
- Copied `.env*` files keep the same ports. Two checkouts serving at once will collide.
- The Momence monorepo may still have a Cursor `/create-worktree` helper. That is separate from `wt`.

`list` / `go` show a bordered table (branch, relative path, dirty `*`, last commit subject ≤100 chars). No GitHub/PR calls.

Git only allows one worktree per branch. To work on a branch that already has a worktree, use `wt go` (cd there) or `wt claim <branch>` (steal the checkout into your current tree; the other worktree goes detached).
