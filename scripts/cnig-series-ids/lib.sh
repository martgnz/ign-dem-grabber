#!/usr/bin/env bash

# logging
_LOG_STATUS=("\033[1;32m" "\033[1;34m" "\033[1;33m" "\033[1;31m")
function log:fmt {
  [[ ${*:2:$#} =~ ^(\[.*\])(.*) ]] \
    && printf "$1%b\033[0m%b" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" \
    || printf "%b" "${*:2:$#}"
}
function log:inf  { >&2 log:fmt "${_LOG_STATUS[1]}" "$@" "\033[s" "\n"           ; }
function log:warn { >&2 log:fmt "${_LOG_STATUS[2]}" "$@" "\033[s" "\n"           ; }
function log:err  { >&2 log:fmt "${_LOG_STATUS[3]}" "$@" "\033[s" "\n" && exit 1 ; }
function log:upd  { >&2 printf "%b"  "\033[u" "\033[0K" "$@"    "\n"  ; }
function log:rst  { >&2 printf "%b"  "\033[u" "\033[0G" "\033[K"      ; }
function log:status:upd { log:upd $(log:fmt "\033[u\033[0G${_LOG_STATUS[$1]}" "$2") ; }
# disable fancy logging if stdout is a term
if [ -t 1 ]; then
function log:upd  { : ; }
function log:rst  { : ; }
function log:status:upd { : ; }
fi

# exponential backoff
function backoff:init { backoff_retries=0 ; backoff_interval=${1:-0}; }
function backoff:wait {
  while [[ $backoff_interval -gt 0 ]]; do
    [[ $# -gt 0 ]] && "$1" "$(printf "$2" "$backoff_interval")"
    sleep 1
    ((backoff_interval-=1))
  done
}
function backoff:incr {
  ((backoff_retries+=1))
  backoff_interval=$(( $1 * 2 ** (backoff_retries - 1) ))

  # max retries
  [[ -n $3 ]] && [[ $backoff_retries -gt $3 ]] && return 1
  # clamp backoff to $2 if set
  [[ -n $2 ]] && [[ $backoff_interval -gt $2 ]] && backoff_interval=$2

  return 0
}
