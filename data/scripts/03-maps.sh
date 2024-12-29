#!/usr/bin/env bash

convert() {
  mapshaper data/input-data/cuadriculas/MTN$1_OFICIAL_ETRS89_Peninsula_Baleares_Canarias.shp \
    -rename-fields name=NOMBRE_$1,id=MTN$1_CLAS \
    -each 'id=id.replace("/", "-")' \
    -drop fields=CCFF$1 \
    -rename-layers dem \
    -proj wgs84 \
    -o data/output-data/MTN$1.json format=topojson
}

convert_provinces() {
  mapshaper data/input-data/provinces.json \
    -rename-layers dem=provinces \
    -drop target=autonomous_regions \
    -o data/output-data/provinces.json format=topojson
}

convert 25
convert 50

convert_provinces
