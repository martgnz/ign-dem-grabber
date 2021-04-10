#!/usr/bin/env bash

convert_mdt0205() {
  mapshaper scripts/maps-clean/$1.shp \
    -clean \
    -rename-layers dem \
    -proj wgs84 \
    -o static/$1.json format=topojson
}

convert_mdt25() {
  mapshaper -i scripts/maps-clean/MDT25.shp encoding=1252 \
    -clean \
    -rename-layers dem \
    -proj wgs84 \
    -o static/MDT25.json format=topojson
}

convert_mdt200() {
  mapshaper scripts/maps-clean/provinces.json \
    -rename-layers dem=provinces \
    -drop target=autonomous_regions \
    -proj wgs84 \
    -drop fields=id \
    -o static/MDT200.json format=topojson
}

convert_mdt0205 MDT02
convert_mdt0205 MDT05
convert_mdt25
convert_mdt200