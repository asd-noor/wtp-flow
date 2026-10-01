# wtp-flow command reference

`<type>` is `work`, `release` or `hotfix` (`feature` is an alias of `work`). `<name>` is the branch name
without its prefix; for `release`/`hotfix` it is the version. With no name, `finish`, `publish`, `diff`,
`rebase` and `checkout` use the branch of the current directory. `work` names also accept a unique prefix.

## Setup

| Command | Effect |
|---------|--------|
| `init [-d] [-f] [-p <work>] [-r <release>] [-x <hotfix>] [-t <tagprefix>] [-w <dir>]` | Create `master` and `develop`, store `wtpflow.*` git config, write `.wtp.yml`. `-d` = no prompts (use this). `-f` = reinitialise. `-w` = worktree directory. Without `-w`, the directory defaults to `$WTP_FLOW_PARENT/<repo dir name>` if that env var is set, else `../worktrees`; an existing `base_dir` is never overridden. |
| `config` | Show branch names, prefixes, tag prefix, worktree directory. |
| `config basedir [<dir>]` | Show or set `defaults.base_dir` in `.wtp.yml`. Does not move existing worktrees. |
| `switch [query]` (alias `checkout [query]`) | Go to where a branch lives and print that directory. Rows: `@` (main checkout), `work/*`/`hotfix/*` worktrees (created if missing), and `master`/`develop`/`release/*` (moves the main checkout onto it; it must be clean). A query matching exactly one row (exact, substring, then fuzzy) is used immediately; otherwise an interactive tv/fzf picker opens, which fails without a terminal. |
| `relocate [-n]` | Move topic worktrees to `<base_dir>/<branch>`. `-n` = dry run. Skips locked/missing/occupied; refuses if cwd is inside one that would move. |
| `shell-init` | Prints a shell function that follows worktrees with `cd`. For humans; not useful to agents. |

## Common to all types

| Command | Effect |
|---------|--------|
| `<type> list [-v]` | List branches of this type; `-v` adds state (no commits yet / based on latest / may be rebased / merged). |
| `<type> start [-F] <name> [<base>]` | New branch + worktree (`release`: new branch, main worktree switched onto it; it must be clean). Base defaults to `develop` (`work`, `release`) or `master` (`hotfix`). `-F` fetches first. |
| `<type> checkout [<name>]` | Print the worktree path, creating the worktree if the branch has none. For `release`: switch the main worktree onto the branch and print its path. |
| `<type> publish [<name>]` | Push the branch to `origin` and set upstream. |
| `<type> track <name>` | Create a worktree for a branch that exists on `origin` (for `release`: switch the main worktree onto it). |
| `<type> delete [-f] [-r] <name>` | Remove worktree and local branch (`release`: main worktree goes back to `develop`). Refuses if unmerged unless `-f`. `-r` also deletes the remote branch. |

## work

| Command | Effect |
|---------|--------|
| `work finish [-F] [-r] [-p] [-k] [--keeplocal] [--keepremote] [-D] [-S] [--no-ff] [--push] [<name>]` | Merge into `develop`, then clean up. |
| `work diff [<name>]` | Changes on the branch since it left `develop`. |
| `work rebase [-i] [-p] [<name>]` | Rebase onto `develop` inside the worktree. |
| `work pull <remote> [<name>]` | Fast-forward pull of the branch from `<remote>`. |

Flags: `-F` fetch first; `-r` rebase onto develop before merging; `-p` preserve merges while rebasing;
`-k` keep branch (worktree is still removed); `--keeplocal`/`--keepremote` keep only that copy; `-D` force
worktree removal even with untracked files; `-S` squash; `--no-ff` always create a merge commit;
`--push` push `develop` afterwards. Default merge is fast-forward when possible.

## release / hotfix

`release finish|hotfix finish [-F] [-s] [-u <key>] [-m <msg> | -f <file>] [-p] [-k] [--keeplocal] [--keepremote] [-D] [-n] [-b] [-S] [-T <tagname>] [--ff-master] [<version>]`

- `-m`/`-f` tag message (pass one); `-s`/`-u` sign the tag; `-n` no tag; `-T` custom tag name.
- `-b` skip the back-merge into `develop`; `-S` squash into master; `--ff-master` (release only) fast-forward master.
- `-p` pushes `develop`, `master` and the tag to `origin`.
- Order: merge into `master` (`--no-ff`) → tag → merge the tag into `develop` → remove worktree/branch.
- `release start`/`hotfix start` fail if another branch of that type is open or the tag already exists.

## Config keys (git config, set by `init`)

`wtpflow.branch.master`, `wtpflow.branch.develop`, `wtpflow.prefix.work`, `wtpflow.prefix.release`,
`wtpflow.prefix.hotfix`, `wtpflow.prefix.versiontag` (defaults `master`, `develop`, `work/`, `release/`,
`hotfix/`, empty). Short flags cannot be combined (`-F -k`, not `-Fk`).
