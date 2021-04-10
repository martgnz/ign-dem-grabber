#!/usr/bin/env bash

# don't redownload data
if [ ! -f scripts/maps/MDT02_recursos.zip ]; then
  wget -O scripts/maps/MDT02_recursos.zip https://centrodedescargas.cnig.es/CentroDescargas/documentos/MDT02_recursos.zip
  unzip -jod maps scripts/maps/MDT02_recursos.zip MDT02_COB2_Fechas.\* 
fi

if [ ! -f scripts/maps/MDT05_recursos.zip ]; then
  wget -O scripts/maps/MDT05_recursos.zip https://centrodedescargas.cnig.es/CentroDescargas/documentos/MDT05_recursos.zip
  unzip -jod maps scripts/maps/MDT05_recursos.zip MDT05.\* 
fi

if [ ! -f scripts/maps/cuadriculas.zip ]; then
  wget -O scripts/maps/cuadriculas.zip --post-data 'secDescDirCata=9000003' https://centrodedescargas.cnig.es/CentroDescargas/descargaDir
  unzip -jod maps scripts/maps/cuadriculas.zip MTN50_ETRS89_Peninsula_Baleares_Canarias.\*
fi

if [ ! -f scripts/maps-clean/provinces.json ]; then
  wget -O scripts/maps-clean/provinces.json https://unpkg.com/es-atlas@0.4.0/es/provinces.json
fi