# SPDX-License-Identifier: GPL-3.0-or-later
# bash completion for wtp-flow. No dependency on the bash-completion package.
#
#   source /path/to/completions/wtp-flow.bash
# or install it as bash-completion's lazily loaded file for the command:
#   cp completions/wtp-flow.bash ~/.local/share/bash-completion/completions/wtp-flow

_wtp_flow_cfg() { git config --get "wtpflow.$1" 2>/dev/null || printf '%s' "$2"; }

_wtp_flow_prefix() {
  case $1 in
    work)    _wtp_flow_cfg prefix.work work/ ;;
    release) _wtp_flow_cfg prefix.release release/ ;;
    hotfix)  _wtp_flow_cfg prefix.hotfix hotfix/ ;;
  esac
}

# Set COMPREPLY from a space-separated word list.
_wtp_flow_words() { COMPREPLY=($(compgen -W "$1" -- "$cur")); }

# Names (branch minus prefix) of a kind: local branches, or remote-only ones for `track`.
_wtp_flow_names() { # kind local|remote
  local kind=$1 where=$2 prefix ref name out=
  prefix=$(_wtp_flow_prefix "$kind")
  if [ "$where" = remote ]; then
    while IFS= read -r ref; do
      ref=${ref#origin/}
      git show-ref --verify --quiet "refs/heads/$ref" 2>/dev/null && continue
      out+="${ref#"$prefix"} "
    done < <(git for-each-ref --format='%(refname:short)' "refs/remotes/origin/$prefix*" 2>/dev/null)
  else
    while IFS= read -r ref; do out+="${ref#"$prefix"} "; done \
      < <(git for-each-ref --format='%(refname:short)' "refs/heads/$prefix*" 2>/dev/null)
  fi
  _wtp_flow_words "$out"
}

_wtp_flow_branches() {
  _wtp_flow_words "$(git for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null | tr '\n' ' ')"
}

_wtp_flow_dirs()  { compopt -o filenames 2>/dev/null; COMPREPLY=($(compgen -d -- "$cur")); }
_wtp_flow_files() { compopt -o filenames 2>/dev/null; COMPREPLY=($(compgen -f -- "$cur")); }

_wtp_flow_topic() {
  local kind=$1 sub=${COMP_WORDS[2]:-} subs="list start finish publish track delete checkout"
  [ "$kind" != work ] || subs+=" diff rebase pull"

  if [ "$COMP_CWORD" -eq 2 ]; then
    case $cur in
      -*) _wtp_flow_words "-v --verbose -h --help" ;;
      *)  _wtp_flow_words "$subs help" ;;
    esac
    return
  fi

  # Value-taking flags: complete the value, or nothing.
  case $prev in
    -f|--messagefile)
      if [ "$sub" = finish ]; then _wtp_flow_files; return; fi ;;
    -m|--message|-u|--signingkey|-T|--tagname) COMPREPLY=(); return ;;
  esac

  # Count positional arguments already given after the subcommand.
  local i w npos=0
  for ((i = 3; i < COMP_CWORD; i++)); do
    w=${COMP_WORDS[i]}
    case $w in
      -m|--message|-u|--signingkey|-T|--tagname|--messagefile) ((i++)) ;;
      -f) [ "$sub" != finish ] || ((i++)) ;;
      -*) ;;
      *) ((npos++)) ;;
    esac
  done

  if [[ $cur == -* ]]; then
    case $sub in
      list)   _wtp_flow_words "-v --verbose" ;;
      start)  _wtp_flow_words "-F --fetch" ;;
      delete) _wtp_flow_words "-f --force -r --remote" ;;
      rebase) _wtp_flow_words "-i --interactive -p --preserve-merges" ;;
      finish)
        if [ "$kind" = work ]; then
          _wtp_flow_words "-F --fetch -r --rebase -p --preserve-merges -k --keep --keeplocal --keepremote -D --force_delete -S --squash --no-ff --push"
        else
          local f="-F --fetch -s --sign -u --signingkey -m --message -f --messagefile -p --push -k --keep --keeplocal --keepremote -D --force_delete -n --notag -b --nobackmerge -S --squash -T --tagname"
          [ "$kind" != release ] || f+=" --ff-master"
          _wtp_flow_words "$f"
        fi ;;
      *) COMPREPLY=() ;;
    esac
    return
  fi

  case $sub in
    finish|publish|delete|checkout) [ "$npos" -eq 0 ] && _wtp_flow_names "$kind" local ;;
    diff|rebase) [ "$kind" = work ] && [ "$npos" -eq 0 ] && _wtp_flow_names "$kind" local ;;
    track) [ "$npos" -eq 0 ] && _wtp_flow_names "$kind" remote ;;
    start) [ "$npos" -eq 1 ] && _wtp_flow_branches ;;   # <base>
    pull)
      if   [ "$npos" -eq 0 ]; then _wtp_flow_words "$(git remote 2>/dev/null | tr '\n' ' ')"
      elif [ "$npos" -eq 1 ]; then _wtp_flow_names "$kind" local; fi ;;
  esac
}

_wtp_flow() {
  local cur prev
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  COMPREPLY=()

  if [ "$COMP_CWORD" -eq 1 ]; then
    _wtp_flow_words "init work feature release hotfix switch checkout config relocate shell-init help version"
    return
  fi

  case ${COMP_WORDS[1]} in
    init)
      case $prev in
        -w|--worktrees) _wtp_flow_dirs; return ;;
        -p|--feature|--work|-r|--release|-x|--hotfix|-t|--tag) return ;;
      esac
      _wtp_flow_words "-d --defaults -f --force -p --work -r --release -x --hotfix -t --tag -w --worktrees --showcommands -h --help" ;;
    config)
      if   [ "$COMP_CWORD" -eq 2 ]; then _wtp_flow_words "basedir list"
      elif [ "$COMP_CWORD" -eq 3 ] && [ "$prev" = basedir ]; then _wtp_flow_dirs; fi ;;
    relocate) _wtp_flow_words "-n --dry-run -h --help" ;;
    switch|checkout)   # row keys: @, worktree branches, and branches the main checkout may be moved onto
      if [[ $cur == -* ]]; then _wtp_flow_words "-h --help"
      else _wtp_flow_words "$(wtp-flow _switch-rows 2>/dev/null | awk '{ print $1 }' | tr '\n' ' ')"; fi ;;
    work|feature) _wtp_flow_topic work ;;
    release)      _wtp_flow_topic release ;;
    hotfix)       _wtp_flow_topic hotfix ;;
  esac
}

complete -F _wtp_flow wtp-flow
