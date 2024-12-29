#!/usr/bin/env bash

# fetch tile metadata from CNIG endpoint
csv () {
  echo "downloading $1…"
  curl -X POST https://centrodedescargas.cnig.es/CentroDescargas/informeResultados \
    -d "tipoReport=csv&codAgr=MOMDT&codSerie=$2" > ./data/input-data/$1.csv
}

# geo file with coverage
tile () {
  curl -X POST https://centrodedescargas.cnig.es/CentroDescargas/descargaDir -d 'secDescDirCata=9000003' > ./data/input-data/cuadriculas.zip

  unzip -jod data/input-data/cuadriculas data/input-data/cuadriculas.zip \
    MTN25_OFICIAL_ETRS89_Peninsula_Baleares_Canarias.\* \
    MTN50_OFICIAL_ETRS89_Peninsula_Baleares_Canarias.\*
}

# provinces, used for coverage too
provinces () {
  curl https://unpkg.com/es-atlas@0.6.0/es/provinces.json > data/input-data/provinces.json
}

csv MDT02_COB2 MDT02
csv MDT05_COB1 MDT05
csv MDT25_COB1 02107
csv MDT25_COB2 T25C2
csv MDT200_COB1 02109
csv MDT200_COB2 T2002

tile
provinces
