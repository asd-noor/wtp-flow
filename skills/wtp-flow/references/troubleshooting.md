# wtp-flow troubleshooting

| Message | Meaning | Fix |
|---------|---------|-----|
| `Not a wtp-flow-enabled repo yet` | No `wtpflow.*` config, or `master`/`develop` missing. | `wtp-flow init -d` (a repo set up with real git-flow also needs this once; config keys differ). |
| `wtp not found` | The `wtp` binary is not on PATH. | Install https://github.com/satococoa/wtp. |
| `Could not merge 'X' into 'Y' (merge conflicts, or untracked files ...)` | The merge was aborted; nothing changed. Git's own message above says which. | Conflicts: in the topic worktree `git merge Y`, resolve, commit, re-run `finish`. "untracked working tree files would be overwritten": move or delete those files in Y's worktree, re-run. |
| `Finish was aborted due to conflicts during rebase` | `finish -r` stopped mid-rebase in the worktree. | Resolve in that worktree, `git rebase --continue`, re-run `finish`. |
| `Working tree '<path>' contains unstaged or uncommitted changes` | The topic worktree, or the worktree holding the target branch (`develop`/`master`, often the main checkout), has tracked changes. | Commit or stash there, re-run. Untracked files do not count. |
| `There is an existing release/hotfix branch 'X'. Finish that one first.` | Only one of each may be open. | Finish or `delete` the open one (ask the user which). |
| `Tag 'X' already exists. Pick another name.` | Version already tagged. | Choose another version, or `-T <name>` on finish. |
| `Branch 'X' is behind 'origin/X'` | A long-lived branch is behind the remote. | Update it first: `git -C <worktree-of-X> pull --ff-only` (or `git fetch origin X:X` if it is not checked out anywhere). |
| `Branches 'X' and 'origin/X' have diverged` | Local and remote history differ. | Stop and ask the user; do not force anything. |
| `Warning: could not remove worktree ... Branch kept` | The worktree has untracked/ignored files. | Inspect them; if disposable, re-run `finish -D`, or `git worktree remove --force <path>` then `git branch -D <branch>`. |
| `Warning: could not delete 'X' from origin` | Remote refused the delete (protected branch, no permission). | Informational; the local finish succeeded. |
| `You are inside the worktree of 'X'` (relocate) | cwd is in a worktree that would move. | Run from the main checkout. |
| `Branch 'X' has been not been merged into 'develop'` (delete) | Unmerged work. | Confirm with the user, then `delete -f`. |

## Partial finish

If `release finish` / `hotfix finish` reports a conflict while merging the **tag into develop**, `master` is
already merged and tagged. Do not re-run `finish` (it fails on "tag exists"). Merge the tag into `develop`
by hand in the worktree that has `develop` checked out, then remove the leftovers:
`git worktree remove <path>` and `git branch -D <branch>`.

## Checking state

```sh
wtp-flow config            # branches, prefixes, worktree dir
wtp-flow work list -v      # also: release list, hotfix list
git worktree list          # ground truth for where worktrees are
git branch --list 'work/*' 'release/*' 'hotfix/*'
```
wtp-flow always asks git where a worktree is, so worktrees outside the configured directory still work.
