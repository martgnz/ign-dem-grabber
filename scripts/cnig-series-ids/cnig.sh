#!/usr/bin/env bash

# cnig-list MDT02 1
function cnig-list {
  local series=$1
  local page=${2:-1}
  inf "[+] Extracting $series, page $page"
  # XXX this curl could suck less
  curl 'http://centrodedescargas.cnig.es/CentroDescargas/resultadosArchivos' --data-raw 'geom=None&coords=%7B%22type%22+%3A+%22FeatureCollection%22%2C+%22features%22+%3A+%5B%7B%22type%22%3A%22Feature%22%2C%22geometry%22%3A%7B%22type%22%3A+%22Polygon%22%2C%22coordinates%22%3A+%5B%5B%5B-180%2C-90%5D%2C%5B-180%2C84.1640960027031%5D%2C%5B180.122131343973%2C84.1640960027031%5D%2C%5B180.122131343973%2C-90%5D%2C%5B-180%2C-90%5D%5D%5D%7D%7D%5D%7D&numPagina='$page'&numTotalReg=2248&codSerie='$series'&series='$series'&codProvAv=&codIneAv=&codComAv=&numHojaAv=&todaEsp=&todoMundo=&tipoBusqueda=VI&tipoArchivo=&contiene=&subSerieExt=&codSubSerie=&idProcShape=' 2> /dev/null
}

function main {
  local series=${1:-"MDT02"}
  local page=${2:-1}

  echo "series,id,name,page"
  while true; do
    { cnig-list $series $page | grep -E 'secGeo|nombreGeo' | python -c "$(cat << EOF
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
    )" ; } || break
    ((page+=1))
    sleep 3
  done
}

function err {
  [[ $* =~ ^(\[.*\])(.*) ]] \
    && >&2 echo -e "\033[1;31m${BASH_REMATCH[1]}\033[1;0m${BASH_REMATCH[2]}" \
    || >&2 echo -e "$*"
  exit 1
}

function inf {
  [[ $* =~ ^(\[.*\])(.*) ]] \
    && >&2 echo -e "\033[1;34m${BASH_REMATCH[1]}\033[1;0m${BASH_REMATCH[2]}" \
    || >&2 echo -e "$*"
}

python -c 'import lxml.html' &> /dev/null || err "[!] lxml not found (pip install lxml)"

main "$@"
