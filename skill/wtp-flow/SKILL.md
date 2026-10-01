---
name: wtp-flow
description: Drives the wtp-flow CLI, a git-flow variant where every topic branch (work/*, release/*, hotfix/*) gets its own git worktree. Use when a repo uses wtp-flow (config keys `wtpflow.*`, a `.wtp.yml`), or when asked to start, finish, publish or clean up feature/bugfix/release/hotfix work with git-flow semantics in isolated worktrees, tag a release, ship a hotfix, or move worktrees to another directory.
license: MIT
compatibility: Requires bash, git, wtp (github.com/satococoa/wtp) and the wtp-flow script on PATH; GNU realpath for `relocate`. Needs a shell that can run commands.
metadata:
  version: "0.2"
---

# wtp-flow

git-flow where each topic branch lives in its own worktree. Branch model:

| Type | Branch | Starts from | Finishes into |
|------|--------|-------------|---------------|
| `work` (feature/bugfix/support) | `work/<name>` | `develop` | `develop` |
| `release` | `release/<version>` | `develop` | `master` + tag, tag merged into `develop` |
| `hotfix` | `hotfix/<version>` | `master` | `master` + tag, tag merged into `develop` |

## Rules for agents

1. **Never switch branches in the main checkout** (`git checkout`/`switch` to a topic branch). Start topic
   work with `wtp-flow <type> start`, which creates a worktree, and do the work there.
2. **Your shell does not keep a `cd`** between tool calls and `shell-init` is not loaded. Get the worktree
   path from output and use absolute paths or `git -C <path>` / `cd <path> && ...` in each command:
   ```sh
   dir=$(wtp-flow work checkout login)   # prints only the path (creates the worktree if missing)
   git -C "$dir" status
   ```
3. **Stay non-interactive.** Use `wtp-flow init -d`. Always pass `-m "<message>"` to `release finish` and
   `hotfix finish` (otherwise git may open an editor for the tag message).
4. **Do not push** (`-p`, `--push`, `publish`) or delete remote branches unless the user asked. `finish`
   deletes the `origin` copy of the topic branch if one exists; use `--keepremote` when that is not wanted.
5. **Finish with `wtp-flow`, not by hand.** Do not `git merge`/`git branch -d`/`git worktree remove` a topic
   branch yourself; `finish` merges, tags, back-merges and cleans up in the right order.
6. Commit your work in the topic worktree before `finish`: it refuses if tracked files are modified.

## Workflow

Check the repo is set up: `wtp-flow config` (fails with "Not a wtp-flow-enabled repo" if not; then run
`wtp-flow init -d`, which creates `master`/`develop` and `.wtp.yml`, after confirming with the user if the
repo already has branches).

**Work item**
```sh
wtp-flow work start <name>        # prints "A worktree for it was created at '<path>'"
# edit + commit inside <path>
wtp-flow work finish <name>       # run from anywhere; fast-forwards into develop when possible
```
Options: `--no-ff` (always a merge commit), `-S` (squash), `-r` (rebase onto develop first), `-k` (keep branch).

**Release**
```sh
wtp-flow release start 1.4.0      # only one release may be open
# stabilise in the worktree: version bump, changelog, fixes
wtp-flow release finish -m "Release 1.4.0" 1.4.0
```
**Hotfix**
```sh
wtp-flow hotfix start 1.4.1
# fix + commit in the worktree
wtp-flow hotfix finish -m "Hotfix 1.4.1" 1.4.1
```
`finish` merges into `master` with `--no-ff`, creates an annotated tag (name = version, plus the configured
tag prefix), merges the tag into `develop`, then removes the worktree and branch.

**Inspect**: `wtp-flow work list -v` (also `release`, `hotfix`), `wtp-flow work diff <name>`, `wtp list`.

## Output and errors

Success output ends with a "Summary of actions" block. Errors start with `Fatal:` or `Warning:` on stderr and
use a non-zero exit code. Read the message; common ones are in [troubleshooting](references/troubleshooting.md).
Key one: a **merge conflict** aborts the merge and changes nothing. Go to the topic worktree, run
`git merge develop` (or `master` for hotfixes), resolve, commit, then re-run `finish`.

## Relation to plain wtp

wtp-flow sits on top of `wtp`. For worktree hooks (`post_create` copy/symlink/command in `.wtp.yml`), `wtp
list`, `wtp exec` and other raw wtp usage, use the separate wtp skill (`skill/wtp`). But inside a wtp-flow
repo, do **not** create or remove `work/`, `release/` or `hotfix/` branches with `wtp add -b` or `wtp
remove`: that skips the flow's base branch, open-release checks, tagging and merge steps, and `wtp remove`
only finds worktrees under the current `base_dir`. Use `wtp-flow <type> start|finish|delete` for those.

## More

- Every command and flag: [references/commands.md](references/commands.md)
- Failure modes and recovery: [references/troubleshooting.md](references/troubleshooting.md)
- Worktree location is `defaults.base_dir` in `.wtp.yml` (default `../worktrees`): show or change with
  `wtp-flow config basedir [<dir>]`, then `wtp-flow relocate [-n]` to move existing worktrees.
