#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Installer for wtp-flow. Run from a checkout:  ./install.sh [options]
set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)

usage() {
  cat <<'EOF'
usage: ./install.sh [options]

Installs wtp-flow, wtp-dir and the bash completion into your home directory (no root needed).

  --prefix DIR           install under DIR: DIR/bin and DIR/share/bash-completion/completions
                         (default: bin in ~/.local/bin, completion in $XDG_DATA_HOME/bash-completion/completions)
  --bin-dir DIR          where to put the wtp-flow script
  --completion-dir DIR   where to put the bash completion file
  --no-completion        skip the bash completion
  --skills DIR           also install the agent skills (wtp, wtp-flow) into DIR (required: no default)
  --link                 symlink to this checkout instead of copying (updates with git pull)
  --force                overwrite files that do not look like wtp-flow's
  --uninstall            remove what this script installs (same options select the locations)
  -h, --help             show this help
EOF
}

die()  { printf 'install.sh: %s\n' "$*" >&2; exit 1; }
info() { printf '%s\n' "$*"; }

bin_dir= comp_dir= skills_dir= prefix=
do_comp=1 do_skills=0 link=0 force=0 uninstall=0

while [ $# -gt 0 ]; do
  case $1 in
    --prefix)         prefix=${2:?--prefix needs a directory}; shift ;;
    --prefix=*)       prefix=${1#*=} ;;
    --bin-dir)        bin_dir=${2:?--bin-dir needs a directory}; shift ;;
    --bin-dir=*)      bin_dir=${1#*=} ;;
    --completion-dir) comp_dir=${2:?--completion-dir needs a directory}; shift ;;
    --completion-dir=*) comp_dir=${1#*=} ;;
    --no-completion)  do_comp=0 ;;
    --skills)         do_skills=1; if [ $# -ge 2 ]; then skills_dir=$2; shift; fi ;;
    --skills=*)       skills_dir=${1#*=}; do_skills=1 ;;
    --link)           link=1 ;;
    --force)          force=1 ;;
    --uninstall)      uninstall=1 ;;
    -h|--help)        usage; exit 0 ;;
    *) usage >&2; die "unknown option '$1'" ;;
  esac
  shift
done

expand() { case $1 in "~") printf %s "$HOME" ;; "~/"*) printf %s "$HOME/${1#"~/"}" ;; *) printf %s "$1" ;; esac; }

if [ -n "$prefix" ]; then
  prefix=$(expand "$prefix")
  : "${bin_dir:=$prefix/bin}" "${comp_dir:=$prefix/share/bash-completion/completions}"
fi
: "${bin_dir:=$HOME/.local/bin}"
: "${comp_dir:=${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions}"
[ $do_skills -eq 0 ] || { [ -n "$skills_dir" ] && [[ $skills_dir != -* ]] || die "--skills needs a directory (there is no default), e.g. --skills ~/.pi/agent/skills"; }
bin_dir=$(expand "$bin_dir") comp_dir=$(expand "$comp_dir") skills_dir=$(expand "$skills_dir")

SRC_BIN=$HERE/wtp-flow
SRC_DIR=$HERE/wtp-dir
SRC_COMP=$HERE/completions/wtp-flow.bash
SKILLS=(wtp wtp-flow)

[ -f "$SRC_BIN" ] || die "run this from a wtp-flow checkout (missing $SRC_BIN)"

# Refuse to clobber something that is not ours unless --force.
ours() { # file marker-regex
  [ ! -e "$1" ] && [ ! -L "$1" ] && return 0
  [ $force -eq 1 ] && return 0
  [ -L "$1" ] && case $(readlink "$1") in "$HERE"/*) return 0 ;; esac
  grep -qE "$2" "$1" 2>/dev/null
}

put() { # src dest mode marker
  local src=$1 dest=$2 mode=$3
  ours "$dest" "$4" || die "$dest exists and does not look like wtp-flow's (use --force to overwrite)"
  mkdir -p "$(dirname "$dest")"
  if [ $link -eq 1 ]; then ln -sfn "$src" "$dest"; else rm -f "$dest"; install -m "$mode" "$src" "$dest"; fi
  info "  $dest$([ $link -eq 1 ] && echo " -> $src")"
}

put_dir() { # srcdir destdir
  local src=$1 dest=$2
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    [ $force -eq 1 ] || [ -L "$dest" ] || grep -q "^name: $(basename "$src")$" "$dest/SKILL.md" 2>/dev/null \
      || die "$dest exists and is not this skill (use --force to overwrite)"
    rm -rf "$dest"
  fi
  mkdir -p "$(dirname "$dest")"
  if [ $link -eq 1 ]; then ln -sfn "$src" "$dest"; else cp -R "$src" "$dest"; fi
  info "  $dest$([ $link -eq 1 ] && echo " -> $src")"
}

remove() { # path marker-regex
  [ -e "$1" ] || [ -L "$1" ] || return 0
  ours "$1" "$2" || { info "  skipped $1 (does not look like wtp-flow's; use --force)"; return 0; }
  rm -f "$1"; info "  removed $1"
}

remove_skill() {
  local d=$1
  [ -e "$d" ] || [ -L "$d" ] || return 0
  if [ -L "$d" ] || [ $force -eq 1 ] || grep -q "^name: $(basename "$d")$" "$d/SKILL.md" 2>/dev/null; then
    rm -rf "$d"; info "  removed $d"
  else
    info "  skipped $d (not a wtp-flow skill; use --force)"
  fi
}

if [ $uninstall -eq 1 ]; then
  info "Uninstalling wtp-flow:"
  remove "$bin_dir/wtp-flow" 'wtp-flow'
  remove "$bin_dir/wtp-dir" 'wtp-dir'
  remove "$comp_dir/wtp-flow" 'wtp-flow'
  if [ $do_skills -eq 1 ]; then for s in "${SKILLS[@]}"; do remove_skill "$skills_dir/$s"; done; fi
  info "Done. Remove the 'wtp-flow shell-init' / completion lines from your shell rc yourself if you added them."
  exit 0
fi

command -v git >/dev/null || die "git is required"
[ -f "$SRC_COMP" ] || [ $do_comp -eq 0 ] || die "missing $SRC_COMP"
[ -f "$SRC_DIR" ] || die "missing $SRC_DIR"

info "Installing wtp-flow:"
put "$SRC_BIN" "$bin_dir/wtp-flow" 755 'wtp-flow'
put "$SRC_DIR" "$bin_dir/wtp-dir" 755 'wtp-dir'
[ $do_comp -eq 0 ] || put "$SRC_COMP" "$comp_dir/wtp-flow" 644 'wtp-flow'
if [ $do_skills -eq 1 ]; then
  for s in "${SKILLS[@]}"; do put_dir "$HERE/skills/$s" "$skills_dir/$s"; done
fi

echo
command -v wtp >/dev/null || info "WARNING: 'wtp' is not on PATH. wtp-flow needs it: https://github.com/satococoa/wtp"
case ":$PATH:" in
  *":$bin_dir:"*) ;;
  *) info "NOTE: $bin_dir is not on your PATH. Add this to your shell rc:"
     info "    export PATH=\"$bin_dir:\$PATH\"" ;;
esac
info "Optional, in your ~/.bashrc:"
info "    eval \"\$(wtp-flow shell-init)\"    # start/track/checkout cd you into the worktree"
info "    eval \"\$(wtp-dir shell-init)\"      # wtp-dir: fuzzy-pick a worktree and cd there (needs tv or fzf)"
if [ $do_comp -eq 1 ]; then
  info "    source \"$comp_dir/wtp-flow\"       # only if completion is not auto-loaded (needs the bash-completion package)"
fi
