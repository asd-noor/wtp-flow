# wtp configuration reference

Source: https://github.com/satococoa/wtp (README and docs/architecture.md).

## Schema

```yaml
version: "1.0"
defaults:
  base_dir: "../worktrees"   # relative to the repo root; default shown
hooks:
  post_create:               # run sequentially after `wtp add`, output streamed
    - type: copy | symlink | command
```

## Hook types

### copy
Copies a file or directory, including gitignored ones (`.env`, `.claude`, `.cursor/`).

```yaml
- type: copy
  from: ".env"   # relative to the MAIN worktree
  to: ".env"     # relative to the NEW worktree; optional, defaults to `from`
```

### symlink
Links a path in the new worktree to the main worktree's copy. Suited to large, mutable directories (`node_modules`, `.cache`, `.bin`) that should be shared rather than duplicated.

```yaml
- type: symlink
  from: ".bin"
  to: ".bin"
```

### command
Runs a shell command in the new worktree.

```yaml
- type: command
  command: "npm install"
  env:                 # optional
    NODE_ENV: "development"
  work_dir: "."        # optional; defaults to the worktree root
```

Environment provided to command hooks: `GIT_WTP_WORKTREE_PATH` (new worktree), `GIT_WTP_REPO_ROOT` (main repo).

## Constraints

- Relative paths in hooks cannot escape the repository (`from`) or the new worktree (`to`).
- A failing hook surfaces as an error from `wtp add`; check `wtp list` to see whether the worktree itself was still created.

## Layout

With `base_dir: "../worktrees"`, branch `feature/auth` becomes `../worktrees/feature/auth`. Slashes in branch names create nested directories.

## Branch resolution on `wtp add <branch>`

1. Local branch, if it exists.
2. A matching remote branch (a tracking branch is created automatically).
3. Error if more than one remote matches; create the tracking branch manually first.
