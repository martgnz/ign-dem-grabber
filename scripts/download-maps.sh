#!/usr/bin/env bash

# don't redownload data
if [ ! -f maps/cuadriculas.zip ]; then
  wget -O maps/cuadriculas.zip --post-data 'secDescDirCata=9000003' https://centrodedescargas.cnig.es/CentroDescargas/descargaDir
  unzip -jod maps maps/cuadriculas.zip \
    MTN25_ETRS89_Peninsula_Baleares_Canarias.\* \
    MTN50_ETRS89_Peninsula_Baleares_Canarias.\*
fi

if [ ! -f maps-clean/provinces.json ]; then
  wget -O maps-clean/provinces.json https://unpkg.com/es-atlas@0.4.0/es/provinces.json
fi