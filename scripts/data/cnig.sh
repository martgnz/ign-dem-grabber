#!/usr/bin/env bash

# logging
COLORS=("\033[1;32m" "\033[1;34m" "\033[1;33m" "\033[1;31m")

function log:inf  { >&2 printf "%b" "\n\033[1A" "${COLORS[1]}" "[+] " "\033[0m" "$@" "\033[s" "\n"           ; }
function log:warn { >&2 printf "%b" "\n\033[1A" "${COLORS[2]}" "[!] " "\033[0m" "$@" "\033[s" "\n"           ; }
function log:err  { >&2 printf "%b" "\n\033[1A" "${COLORS[3]}" "[!] " "\033[0m" "$@" "\033[s" "\n" && exit 1 ; }
function log:upd  { >&2 printf "%b" "\033[u" "\033[0K" "$@" "\n" ; }
function log:rst  { >&2 printf "%b" "\033[u" "\033[0G" "\033[K"  ; }

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

function cnig-filename {
  { curl -i 'http://centrodedescargas.cnig.es/CentroDescargas/descargaDir' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:87.0) Gecko/20100101 Firefox/87.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' --compressed -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: http://centrodedescargas.cnig.es' -H 'Referer: http://centrodedescargas.cnig.es/CentroDescargas/buscadorCatalogo.do?codFamilia=LIDAR' --data-raw "secDescDirLA=$1" --fail | grep -oE 'filename=.*.asc' -m 1 | sed s/filename=// ; } 2> /dev/null
  return ${PIPESTATUS[1]}
}

# cnig-list MDT02 1
function cnig-list {
  local series=$1
  local page=${2:-1}
  # XXX this curl could suck less
  curl 'http://centrodedescargas.cnig.es/CentroDescargas/resultadosArchivos' --data-raw "geom=None&coords=%7B%22type%22+%3A+%22FeatureCollection%22%2C+%22features%22+%3A+%5B%7B%22type%22%3A%22Feature%22%2C%22geometry%22%3A%7B%22type%22%3A+%22Polygon%22%2C%22coordinates%22%3A+%5B%5B%5B-180%2C-90%5D%2C%5B-180%2C84.1640960027031%5D%2C%5B180.122131343973%2C84.1640960027031%5D%2C%5B180.122131343973%2C-90%5D%2C%5B-180%2C-90%5D%5D%5D%7D%7D%5D%7D&numPagina=$page&numTotalReg=2248&codSerie=$series&series=$series&codProvAv=&codIneAv=&codComAv=&numHojaAv=&todaEsp=&todoMundo=&tipoBusqueda=VI&tipoArchivo=&contiene=&subSerieExt=&codSubSerie=&idProcShape=" --fail 2> /dev/null
}

function with-retry {
  # XXX parse these as arguments
  local base_wait=2
  local backoff_base=5
  local max_wait=120
  local max_retry=10

  backoff:init $base_wait
  while true; do
    "$@" && break
    backoff:incr $backoff_base $max_wait $max_retry || log:err "$1 failed $backoff_retries time(s), bye"
    log:warn "$1 failed $backoff_retries time(s), retrying in:"
    backoff:wait log:upd "%ds"
  done
}

function bar {
  local val=$1
  local bas=$2
  local wid=$3
  local txt=$4

  [[ -z $wid ]] && [[ -n $txt ]] && wid=${#txt}

  local per=$(( (wid * val) / bas ))

  if [[ -n $txt ]]; then
    printf "\033[7m${txt:0:$per}\033[27m${txt:$per:$((wid-per))}"
  else
    printf "\033[7m%*s\033[27m%*s" $per '' $((wid-per)) ''
  fi
}

function main {
  local series=${1:-"MDT02"}
  local page=${2:-1}

  # only print csv header on page 1
  [[ $page -eq 1 ]] && echo "series,filename,id,date,size,page"

  local prompt="▏ cnig.es $series #%02d %02d|%02d ▕"

  while true; do
    # note that at this point parsing this using bash is more an exercise than
    # a good idea
    local list=$(with-retry cnig-list $series $page)
    local ids=($(echo "$list" | grep 'secGeo' | grep -oE 'value=.*\"' | sed s/value\=// | sed s/\"//g))
    local dates=($(echo "$list" | grep 'data-th="Fecha"' | perl -pe 's/.*\>\s*(.*?)\s*\<.*/"\1"/' | perl -pe 's/\s*,\s*/,/g'))
    local sizes=($(echo "$list" | grep 'data-th="Tamaño' | perl -pe 's/.*\>\s*(.*?)\s*\<.*/\1/'))
    local len=${#ids[@]}

    [[ $len -eq 0 ]] && break

    local i=1
    local filename

    log:inf "${COLORS[1]}$(printf "$prompt" $page 1 $len)\033[0m"

    for id in "${ids[@]}"; do
      filename=$(with-retry cnig-filename $id)
      echo $series,$filename,$id,${dates[$i-1]},${sizes[$i-1]},$page

      ((i+=1))

      log:rst

      log:inf "${COLORS[1]}$(bar $i $len '' "$(printf "$prompt" $page $i $len)")\033[0m $id -> $filename"
    done

    ((page+=1))

  done
}

main "$@"
