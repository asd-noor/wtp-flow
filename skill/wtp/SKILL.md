---
name: wtp
description: Manage Git worktrees with the `wtp` CLI (Worktree Plus) - create, list, switch to, run commands in, and remove worktrees, plus configure .wtp.yml post-create hooks that copy .env files, symlink directories, or run setup commands. Use when the user wants parallel branches checked out side by side, an isolated checkout for a feature, hotfix, PR review or agent task, or mentions worktrees or wtp.
license: MIT
compatibility: Requires git and the wtp binary (github.com/satococoa/wtp) on PATH. Written against wtp 2.10.x.
metadata:
  upstream: https://github.com/satococoa/wtp
  version: "1.0"
---

# Git worktrees with wtp

`wtp` wraps `git worktree` with predictable paths, automatic remote-branch tracking, and setup hooks defined in `.wtp.yml`. Run it from inside the repository (any worktree of it).

## Quick reference

| Task | Command |
| - | - |
| Worktree for an existing local or remote branch | `wtp add feature/auth` |
| New branch + worktree (from HEAD) | `wtp add -b feature/new` |
| New branch from a commit/branch | `wtp add -b hotfix/urgent main` |
| Create and print only the path (scripting) | `wtp add -b feature/x --quiet` |
| Create, then run a command inside it | `wtp add -b feature/x --exec "npm test"` |
| List worktrees | `wtp list` (`-q` paths only, `-c` compact) |
| Print a worktree's absolute path | `wtp cd feature/auth` (no arg or `@` = main worktree) |
| Run a command in a worktree | `wtp exec feature/auth -- go test ./...` |
| Remove worktree | `wtp remove feature/auth` |
| Remove even if dirty | `wtp remove -f feature/auth` |
| Remove worktree and its branch (must be merged) | `wtp remove --with-branch feature/auth` |
| Also force-delete unmerged branch | `wtp remove --with-branch --force-branch feature/auth` |
| Create starter `.wtp.yml` | `wtp init` |

Worktree names are the branch names (slashes are nested directories), e.g. `feature/auth` lives at `<base_dir>/feature/auth`. The default `base_dir` is `../worktrees` relative to the repo root.

## Workflow

1. **Inspect first**: `wtp list` to see what exists and avoid path collisions.
2. **Create**: `wtp add -b <new-branch> [<start-point>]` for new work, `wtp add <branch>` for an existing branch. If the branch exists only on one remote it is tracked automatically.
3. **Capture the path** when you need to work inside it from an agent shell: `dir=$(wtp add -b feature/x --quiet)` or `dir=$(wtp cd feature/x)`, then use `git -C "$dir" ...`, `wtp exec`, or `cd "$dir"`. Post-create hooks (copy/symlink/command) have already run when `add` returns.
4. **Clean up** when done: `wtp remove <name>`; add `--with-branch` once the branch is merged. Check `git -C <path> status` before using `-f`, since forcing discards uncommitted work.

## Agent guidance

- `wtp cd` only prints a path. Use `cd "$(wtp cd <name>)"` or `wtp exec`. Each Bash tool call may start in a fresh cwd, so prefer absolute paths.
- Use `--quiet` whenever you parse output; `wtp list -q` gives one path per line.
- Never pass `-f`, `--force-branch`, or remove a worktree the user did not ask about without confirming; these delete uncommitted or unmerged work.
- Do not edit `.wtp.yml` hooks to run untrusted commands: `command` hooks execute on every `wtp add`.
- A branch can be checked out in only one worktree at a time (git rule). To work on the same branch elsewhere, create a new branch with `-b`.

## Configuration (.wtp.yml)

Lives at the repo root. Create with `wtp init`. Minimal useful example:

```yaml
version: "1.0"
defaults:
  base_dir: "../worktrees"
hooks:
  post_create:
    - type: copy        # includes gitignored files
      from: ".env"
    - type: symlink     # share big mutable dirs
      from: "node_modules"
    - type: command
      command: "npm ci"
```

Hooks run in order after creation. `from` always resolves in the main worktree and `to` in the new one (`to` defaults to `from`). Command hooks get `GIT_WTP_WORKTREE_PATH` and `GIT_WTP_REPO_ROOT`. Full schema and options: [references/CONFIG.md](references/CONFIG.md).

## Troubleshooting

| Error | Fix |
| - | - |
| branch not found | Not local and not on a remote. Use `wtp add -b <name>` to create it, or `git fetch` first. |
| exists in multiple remotes | Pick one: `git branch --track <b> origin/<b>`, then `wtp add <b>`. |
| worktree already exists | Path collision; run `wtp list`, reuse it with `wtp cd`, or choose another branch name. |
| uncommitted changes (on remove) | Commit/stash in that worktree, or `wtp remove -f` if the changes are disposable. |
| branch is checked out elsewhere | Git allows one worktree per branch; use `-b` for a new branch. |
