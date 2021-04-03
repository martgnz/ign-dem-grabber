#!/usr/bin/env bash

function fmt_brackets {
  local color=$1; shift

  [[ $* =~ ^(\[.*\])(.*) ]] \
    && >&2 printf "$color%b\033[0m%b" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" \
    || >&2 printf "%b" "$*"
}

function inf  { fmt_brackets "\033[1;34m" "$@" "\n"; }
function warn { fmt_brackets "\033[1;33m"  "$@" "\n"; }
function err  { fmt_brackets "\033[1;31m"  "$@" "\n" && exit 1; }

function backoff:reset { backoff_base=$1 backoff_retries=0 backoff_interval=$1 ; }
function backoff:wait { sleep $backoff_interval; }
function backoff:incr { ((backoff_retries+=1)) ; backoff_interval=$(( backoff_base * 2 ** (backoff_retries - 1) ));  }

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

  backoff:reset 3

  # only print csv header on page 1
  [[ $page -eq 1 ]] && echo "series,id,name,page"

  while true; do
    inf "[+] Extracting $series, page $page"
    { cnig-list $series $page | grep -E 'secGeo|nombreGeo' | python <(cat << EOF
import sys
import csv
import lxml.html

html = lxml.html.fromstring(sys.stdin.read())

writer = csv.writer(sys.stdout)

names = html.xpath('//input[contains(@id, "nombreGeo")]/@value')
ids = html.xpath('//input[contains(@id, "secGeo")]/@value')
assert(len(names) == len(ids))
for _id, name in zip(names, ids):
    split = _id.split('.')
    _id = split[0] + '.' + split[1].lower()

    writer.writerow(["$series", name, _id, "$page"])
EOF
    ) ; } 2> /dev/null ; pipe=("${PIPESTATUS[@]}")

    # HTTP > 200 -> ban
    if [[ ${pipe[0]} -gt 0 ]]; then
      backoff:incr
      warn "[!] curl failed, retrying in ${backoff_interval}s"
      backoff:wait
      continue
    fi

    # HTTP 200 -> grep failed = empty
    [[ ${pipe[1]} -gt 0 ]] && inf "\r\033[1A\033[40C (empty)" && break

    backoff:reset 3

    backoff:wait

    ((page+=1))

  done

  inf "[+] all done!"
}

hash python &> /dev/null || { hash python3 &> /dev/null && shopt -s expand_aliases && alias python=python3 ; } || err "[!] this script requires python 3"
python -c 'import lxml.html' &> /dev/null || err "[!] lxml not found (pip install lxml)"
hash curl &> /dev/null || err "[!] curl not found"

main "$@"
