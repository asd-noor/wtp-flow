# wtp-flow

git-flow, where `work` and `hotfix` branches live in their own git worktrees, managed by
[wtp](https://github.com/satococoa/wtp). Branching and merge behaviour follow `git flow` (AVH edition);
the difference is that you `cd` between worktrees instead of switching branches. `release` branches are the
exception: they only touch a changelog and a version, so they switch the main worktree, as in plain git-flow.

| wtp-flow | git-flow                      | branches from | merges into                         |
|----------|-------------------------------|---------------|-------------------------------------|
| master   | master                        | -             | -                                   |
| develop  | develop                       | -             | -                                   |
| work     | feature, bugfix, support (one type) | develop | develop                             |
| release  | release                       | develop       | master (tagged), tag back into develop |
| hotfix   | hotfix                        | master        | master (tagged), tag back into develop |

## Install

Requires `git`, [`wtp`](https://github.com/satococoa/wtp) and a GNU userland (`realpath -m`; on macOS
install coreutils).

```sh
git clone <this repo> && cd wtp-flow
./install.sh                 # script -> ~/.local/bin, completion -> ~/.local/share/bash-completion/completions
```

Options: `--prefix DIR` (installs `DIR/bin` and `DIR/share/bash-completion/completions`; use `--prefix /usr/local`
with sudo for a system-wide install), `--bin-dir`, `--completion-dir`, `--no-completion`, `--link` (symlink to the
checkout so `git pull` updates it), `--skills DIR` (also install the agent skills into DIR; there is no default, so it fails without one),
`--force`, and `--uninstall` (removes only what it installed; pass the same location options). It never overwrites
a file that doesn't look like wtp-flow's unless you pass `--force`. Not on `PATH`? It tells you what to add.

Then optionally add this to your shell rc so `start`/`track`/`checkout` cd you into the worktree, and `finish`
cd's you out of a removed one:

```sh
eval "$(wtp-flow shell-init)"
```

Or skip the installer: put the `wtp-flow` script anywhere on your `PATH`.

## Shell completion

Bash completion lives in `completions/wtp-flow.bash`. It completes subcommands, flags (per command and per
branch type), and real names from the repo: local `work`/`release`/`hotfix` branches using your configured
prefixes, remote-only ones for `track`, remotes for `pull`, directories for `-w`/`config basedir`, files for
`-f`. Load it from your shell rc:

```sh
source /path/to/wtp-flow/completions/wtp-flow.bash
```

or copy it to `~/.local/share/bash-completion/completions/wtp-flow` (loaded on demand when the
bash-completion package is installed). It does not depend on that package.

## Use it from an AI agent

`skill/wtp-flow/` is an [Agent Skill](https://agentskills.io) (`SKILL.md` plus `references/`). Copy or symlink the
`wtp-flow` directory into your agent's skills folder (`./install.sh --skills DIR`, e.g. `~/.pi/agent/skills`, or `~/.claude/skills` for Claude Code).
It teaches the agent the branch model, to work inside worktrees rather than switching branches, to stay
non-interactive, and to leave pushing to you.

## Quick start

```sh
wtp-flow init                      # master + develop, .wtp.yml; prompts like git flow init (-d for defaults)
wtp-flow work start login          # work/login off develop, in ../worktrees/work/login
# ...commit...
wtp-flow work finish               # merge into develop, remove worktree + branch (name inferred from cwd)

wtp-flow release start 1.2.0       # release/1.2.0 off develop; the main worktree switches to it
wtp-flow release finish -m "1.2.0" # merge to master, tag 1.2.0, merge the tag into develop, main back on develop

wtp-flow hotfix start 1.2.1        # hotfix/1.2.1 off master
wtp-flow hotfix finish -p          # same as release finish, then push develop, master and the tag
```

## Commands

```
wtp-flow init [-d] [-f] [-p <work>] [-r <release>] [-x <hotfix>] [-t <tag>] [-w <worktree-dir>]
wtp-flow config [basedir [<dir>]]
wtp-flow relocate [-n]
wtp-flow shell-init

wtp-flow work    list [-v]
wtp-flow work    start [-F] <name> [<base>]
wtp-flow work    finish [-F] [-r] [-p] [-k|--keeplocal|--keepremote] [-D] [-S] [--no-ff] [--push] [<name>]
wtp-flow work    publish | track <name> | checkout [<name>] | delete [-f] [-r] <name>
wtp-flow work    diff [<name>] | rebase [-i] [-p] [<name>] | pull <remote> [<name>]

wtp-flow release list [-v]
wtp-flow release start [-F] <version> [<base>]
wtp-flow release finish [-F] [-s] [-u <key>] [-m <msg> | -f <file>] [-p] [-k|--keeplocal|--keepremote]
                        [-D] [-n] [-b] [-S] [-T <tagname>] [--ff-master] [<version>]
wtp-flow release publish | track <name> | checkout [<name>] | delete [-f] [-r] <name>

wtp-flow hotfix  ...same as release, minus --ff-master; branches from master
```

Notes on flags (all as in git-flow):

- `finish` with no name uses the branch you are on. `work` names also accept a unique prefix.
- `work finish`: fast-forwards when it can; `--no-ff` always makes a merge commit; `-S` squashes;
  `-r` rebases onto develop first (`-p` keeps merges). Use `--push` to push develop afterwards
  (for `work finish`, `-p` means preserve-merges, as in git-flow).
- `release`/`hotfix finish`: merges `--no-ff` into master, creates an annotated tag (`-s`/`-u` sign it,
  `-m`/`-f` set the message, `-n` skips it, `-T` renames it), then merges the **tag** into develop
  (`-b` skips that). `-p` pushes develop, master and the tag.
- Finishing deletes the local branch, its worktree, and the `origin` branch if one exists. `-k` keeps the
  branches (the worktree is still removed; `checkout` recreates it). `-D` forces removal of a worktree that
  has untracked files.
- `start` refuses if a release or hotfix is already open, or if the tag already exists.
- `-F` fetches `origin` first. Finishing and starting refuse when master/develop have diverged from or are
  behind `origin`.
- `feature` is accepted as an alias of `work`.

## Configuration

Stored by `wtp-flow init` in the repo's git config (`wtpflow.*`): `branch.master`, `branch.develop`,
`prefix.work`, `prefix.release`, `prefix.hotfix`, `prefix.versiontag` (defaults: `master`, `develop`,
`work/`, `release/`, `hotfix/`, and no tag prefix). `wtp-flow config` shows them.

### Where worktrees live

The location is wtp's `defaults.base_dir` in `.wtp.yml`, the single source of truth (per-machine: worktree directory, setup hooks). It is not meant to be shared, so `wtp-flow init` adds it to `.git/info/exclude` (repo-local, shared by all worktrees, never dirties the tree, and `.gitignore` is untouched). It skips this if the file is already ignored; a `.wtp.yml` that is already tracked is left alone with a note.
Default `../worktrees`, so branch `work/login` lives in `../worktrees/work/login`.

- Set it with `wtp-flow init -w <dir>` (or answer the prompt), or later with `wtp-flow config basedir <dir>`.
  Editing `.wtp.yml` by hand works too. Relative paths resolve against the main worktree; absolute paths work. A leading `~` or `$HOME` is expanded to your home directory before it is written, because wtp itself would read it as relative to the repo root.
- Changing it does not move existing worktrees. `wtp-flow relocate` does (`-n` for a dry run). It skips
  locked worktrees, missing directories and occupied targets, and refuses if you are standing inside a
  worktree it would move.
- Old and new locations can coexist: wtp-flow always asks git where a worktree actually is.
- wtp hooks (`post_create`: copy `.env`, `npm install`, ...) in `.wtp.yml` run for every new worktree.

## Differences from git-flow, all due to worktrees

- `work` and `hotfix` `start`/`track`/`checkout` create a worktree instead of switching your checkout.
- `release start`/`track`/`checkout` switch the main worktree (which must have no uncommitted changes) onto the
  release branch, no worktree. `finish` moves it back to `develop`, so `develop` must not be checked out in
  another worktree at that point. While a release is open, `work finish` and `hotfix finish` still merge
  into `develop` through a throwaway worktree.
- `finish` never touches your current checkout. It merges in the worktree that already has the target
  branch checked out (which must have no uncommitted changes), or in a throwaway one.
- A conflicting merge is aborted and nothing changes, instead of being left half-done. Resolve it on the
  topic branch (`git merge develop`) and re-run `finish`.
- `bugfix` and `support` are folded into `work`, so support branches come off develop, not master.
- When a release is open, `hotfix finish` still back-merges into develop only (AVH behaviour).
- Config keys are `wtpflow.*`, not `gitflow.*`: a repo set up with real git-flow needs `wtp-flow init` once.

## Known limits

- Short flags cannot be combined (`-F -k`, not `-Fk`).
- If the back-merge into develop conflicts after master was merged and tagged, you are told to merge the
  tag by hand; re-running `finish` then fails on "tag already exists" (same as git-flow).
- Signed tags (`-s`, `-u`) are untested. The only remote supported is `origin`.

## License

GPL-3.0-or-later (GNU GPL version 3 or, at your option, any later version). See [LICENSE](LICENSE).
