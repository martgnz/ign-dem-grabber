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

# cnig-list MDT02 1
function cnig-list {
  local series=$1
  local page=${2:-1}
  # XXX this curl could suck less
  curl 'http://centrodedescargas.cnig.es/CentroDescargas/resultadosArchivos' --data-raw 'geom=None&coords=%7B%22type%22+%3A+%22FeatureCollection%22%2C+%22features%22+%3A+%5B%7B%22type%22%3A%22Feature%22%2C%22geometry%22%3A%7B%22type%22%3A+%22Polygon%22%2C%22coordinates%22%3A+%5B%5B%5B-180%2C-90%5D%2C%5B-180%2C84.1640960027031%5D%2C%5B180.122131343973%2C84.1640960027031%5D%2C%5B180.122131343973%2C-90%5D%2C%5B-180%2C-90%5D%5D%5D%7D%7D%5D%7D&numPagina='$page'&numTotalReg=2248&codSerie='$series'&series='$series'&codProvAv=&codIneAv=&codComAv=&numHojaAv=&todaEsp=&todoMundo=&tipoBusqueda=VI&tipoArchivo=&contiene=&subSerieExt=&codSubSerie=&idProcShape=' --fail
}


function main {
  local series=${1:-"MDT02"}
  local page=${2:-1}

  # XXX parse these as arguments
  local base_wait=2
  local backoff_base=5
  local max_wait=120
  local max_retry=10

  backoff:init

  # only print csv header on page 1
  [[ $page -eq 1 ]] && echo "series,id,name,page"

  while true; do
    log:inf "[-] extracting $series, page $page"

    { cnig-list $series $page | grep -E 'secGeo|nombreGeo' | python3 <(cat << EOF
import csv
import sys
import lxml.html

import collections
import itertools as it
import functools as fun

def rtl_compose(fns):
    return fun.reduce(lambda f, g: lambda x: g(f(x)), fns, lambda x: x)

def map_compose(fns, data, rtl=True):
    return map(rtl_compose(fns if rtl else reversed(fns)), data)

def extract(data):
    html = lxml.html.fromstring(data)
    uids = html.xpath('//input[contains(@id, "secGeo")]/@value')
    names = html.xpath('//input[contains(@id, "nombreGeo")]/@value')

    names = map_compose((
      lambda name: name.partition('.'),
      # assumedly tuple unpacking is evil, thanks python
      lambda c: (c[0], c[1], c[2].lower()),
      lambda c: ''.join(c),
    ), names)

    return zip(it.repeat("$series"), names, uids, it.repeat("$page"))

if __name__ == "__main__":
    writer = csv.writer(sys.stdout)
    rows = extract(sys.stdin.read())
    collections.deque(map(writer.writerow, rows), maxlen=0)

EOF
    ) ; } 2> /dev/null ; pipe=("${PIPESTATUS[@]}")

    # HTTP > 200 -> ban
    if [[ ${pipe[0]} -gt 0 ]]; then
      log:rst

      backoff:incr $backoff_base $max_wait $max_retry || log:err "[!] curl failed $backoff_retries time(s), bye"

      log:warn "[!] curl failed $backoff_retries time(s), retrying in:"
      backoff:wait log:upd '%ds'
      log:rst
      continue
    fi

    log:status:upd 0 "[+]"

    # HTTP 200 -> grep failed -> empty -> end
    if [[ ${pipe[1]} -gt 0 ]]; then
      log:upd "(empty)"
      break
    fi

    backoff:init $base_wait
    log:warn '[-] wait'
    backoff:wait log:upd '%ds'

    log:rst

    ((page+=1))
  done

  log:inf "[+] all done!"
}

hash python3 &> /dev/null || log:err "[!] this script requires python3"
python3 -c 'import lxml.html' &> /dev/null || log:err "[!] lxml not found (pip install lxml)"
hash curl &> /dev/null || log:err "[!] curl not found"

main "$@"
