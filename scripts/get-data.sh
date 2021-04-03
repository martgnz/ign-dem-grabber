wget -O scripts/data/MDT02_recursos.zip https://centrodedescargas.cnig.es/CentroDescargas/documentos/MDT02_recursos.zip
unzip -jod scripts/data scripts/data/MDT02_recursos.zip MDT02_COB2_Fechas.\* 

wget -O scripts/data/MDT05_recursos.zip https://centrodedescargas.cnig.es/CentroDescargas/documentos/MDT05_recursos.zip
unzip -jod scripts/data scripts/data/MDT05_recursos.zip MDT05.\* 

convert() {
  mapshaper scripts/data/$1.shp -clean -rename-layers dem -proj wgs84 -o static/$2.json format=topojson

  # geo2topo -n dem=<( \
  #     shp2json --encoding utf8 -n scripts/data/${1}.shp \
  #       | geoproject -n -r d3=d3-composite-projections 'd3.geoConicConformalSpain()') \
  #   | toposimplify -f -p 0.25 \
  #   | topoquantize 1e3 \
  #   > static/$2.json
}

convert MDT02_COB2_Fechas MDT02
convert MDT05 MDT05