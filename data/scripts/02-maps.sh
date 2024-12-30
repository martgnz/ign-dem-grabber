#!/usr/bin/env bash

# geo file with coverage
download_tiles () {
  curl -X POST https://centrodedescargas.cnig.es/CentroDescargas/descargaDir -d 'secDescDirCata=9000003' > ./data/input-data/cuadriculas.zip

  unzip -jod data/input-data/cuadriculas data/input-data/cuadriculas.zip \
    MTN25_OFICIAL_ETRS89_Peninsula_Baleares_Canarias.\* \
    MTN50_OFICIAL_ETRS89_Peninsula_Baleares_Canarias.\*
}

# provinces, used for coverage too
download_provinces () {
  curl https://unpkg.com/es-atlas@0.6.0/es/provinces.json > data/input-data/provinces.json
}

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
    -rename-fields target=dem id=name \
    -each 'name=id' \
    -o data/output-data/provinces.json format=topojson
}

download_tiles
download_provinces

convert 25
convert 50
convert_provinces
