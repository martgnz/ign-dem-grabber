#!/usr/bin/env bash

convert() {
  mapshaper scripts/maps-clean/$1.shp \
    -clean \
    -simplify 2% \
    -rename-layers dem \
    -proj wgs84 \
    -o static/$1.json format=topojson
}

convert_mdt200() {
  mapshaper scripts/maps-clean/provinces.json \
    -rename-layers dem=provinces \
    -drop target=autonomous_regions \
    -proj wgs84 \
    -drop fields=id \
    -o static/MDT200.json format=topojson
}

convert MDT02
convert MDT05
convert MDT25
convert_mdt200