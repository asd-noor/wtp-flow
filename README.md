# wtp-flow

git-flow (AVH semantics), where every topic branch lives in its own git worktree
managed by [wtp](https://github.com/satococoa/wtp).

| wtp-flow  | git-flow  |
|-----------|-----------|
| master    | master    |
| develop   | develop   |
| work      | feature, bugfix, support (merged into one: all branch from and merge back to develop) |
| release   | release   |
| hotfix    | hotfix    |

Requires `git` and `wtp` on `PATH`. Put `wtp-flow` anywhere on `PATH`, then
optionally `eval "$(wtp-flow shell-init)"` so `start`/`track`/`checkout` cd you
into the worktree (and `finish` cd's you out of a removed one).

```
wtp-flow init [-d] [-f] [-w <worktree-dir>]
wtp-flow config [basedir [<dir>]]
wtp-flow relocate [-n]
wtp-flow work    {list [-v] | start [-F] <name> [<base>] | finish [-F -r -p -k -D -S --no-ff] [<name>]
                  | publish | track <name> | checkout | delete [-f -r] | diff | rebase [-i -p] | pull}
wtp-flow release {list | start [-F] <version> [<base>] | finish [-F -s -u -m -f -p -k -n -b -S -T --ff-master] [<version>]
                  | publish | track | checkout | delete}
wtp-flow hotfix  {list | start [-F] <version> [<base>] | finish [same as release] | publish | track | checkout | delete}
```

Behaviour is the same as `git flow`: `work finish` fast-forwards when it can;
`release`/`hotfix finish` merge `--no-ff` into master, tag (no prefix by default),
and back-merge the **tag** into develop; only one release/hotfix at a time;
config lives in `wtpflow.*` (branch.master, branch.develop, prefix.*, prefix.versiontag).

## Differences, all due to worktrees

- `start`/`track`/`checkout` create a worktree (`<base_dir>/<branch>`, default `../worktrees/<branch>`) instead of switching your checkout.
- `finish` never touches your current checkout. It merges in the worktree that already has the target
  branch, or a throwaway one, then removes the topic worktree and branch.
- A conflicting merge is aborted rather than left half-done; resolve on the topic branch and re-run `finish`.
- `-k` keeps the branch but still removes its worktree (`checkout` recreates it).
- git-flow's `feature`, `bugfix` and `support` are one `work` type here. `feature` is still accepted as an alias of `work`.

## Where worktrees live

The location is wtp's `defaults.base_dir` in `.wtp.yml`, which is the single source of truth (commit it to
share it). Set it with `wtp-flow init -w <dir>` (or answer the prompt), and show or change it later with
`wtp-flow config basedir [<dir>]`. Relative paths resolve against the main worktree; absolute paths work too.
Changing it does not move existing worktrees; `wtp-flow relocate` does (`-n` for a dry run). It skips locked
worktrees and occupied targets, and refuses if you are standing inside a worktree it would move.
