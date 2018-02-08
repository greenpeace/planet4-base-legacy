#!/usr/bin/env bash
set -ea

# ----------------------------------------------------------------------------
# Pretty printing

TERM="${TERM:-'dumb'}"

if test -t 1
then
    # Check that it supports colours
    ncolors=$(tput colors)

    if test -n "$ncolors" && test $ncolors -ge 8
    then
        bold="$(tput bold)"
        # underline="$(tput smul)"
        # standout="$(tput smso)"
        normal="$(tput sgr0)"
        # black="$(tput setaf 0)"
        red="$(tput setaf 1)"
        green="$(tput setaf 2)"
        # yellow="$(tput setaf 3)"
        # blue="$(tput setaf 4)"
        # magenta="$(tput setaf 5)"
        cyan="$(tput setaf 6)"
        white="$(tput setaf 7)"
    fi
fi

function _fatal() {
 _out "${bold:-}${red:-} [ERROR]${normal:-}" "$1" >&2
 exit 1
}

function _out() {
  local type
  local text
  type=$1

  shift
  text=$*

  printf "%s %s\n" "$type" "$text"
}

function _notice {
  _out "${white:-}[NOTICE]${white:-}" "$@"
}

function _skip() {
  _out "${cyan:-}  [SKIP]${normal:-}" "$@"
}

function _build() {
  _out "${green:-} [BUILD]${normal:-}" "$@"
}

function _pull() {
  _out "${green:-}  [PULL]${normal:-}" "$@"
}

function _verbose() {
  if [[ $verbosity != 'verbose' ]]
  then
    return
  fi
  _out "${green:-}  [PULL]${normal:-}" "$@"
}
