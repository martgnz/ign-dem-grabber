# don't redownload data
if [ ! -f scripts/data/MDT02_recursos.zip ]; then
  wget -O scripts/data/MDT02_recursos.zip https://centrodedescargas.cnig.es/CentroDescargas/documentos/MDT02_recursos.zip
  unzip -jod scripts/data scripts/data/MDT02_recursos.zip MDT02_COB2_Fechas.\* 
fi

if [ ! -f scripts/data/MDT05_recursos.zip ]; then
  wget -O scripts/data/MDT05_recursos.zip https://centrodedescargas.cnig.es/CentroDescargas/documentos/MDT05_recursos.zip
  unzip -jod scripts/data scripts/data/MDT05_recursos.zip MDT05.\* 
fi

if [ ! -f scripts/data/cuadriculas.zip ]; then
  wget -O scripts/data/cuadriculas.zip --post-data 'secDescDirCata=9000003' https://centrodedescargas.cnig.es/CentroDescargas/descargaDir
  unzip -jod scripts/data scripts/data/cuadriculas.zip MTN50_ETRS89_Peninsula_Baleares_Canarias.\*
fi

if [ ! -f scripts/data/provinces.json ]; then
  wget -O scripts/data/provinces.json https://unpkg.com/es-atlas@0.4.0/es/provinces.json
fi

convert() {
  mapshaper scripts/data/$1.shp \
    -clean \
    -rename-layers dem \
    -proj wgs84 \
    -rename-fields file=$3,date=$4 \
    -each "$5" \
    -join scripts/cnig-series-ids/$2.csv keys=file,name string-fields=id fields=id   \
    -o static/$2.json format=topojson
}

convert_mdt25() {
  mapshaper -i scripts/data/MTN50_ETRS89_Peninsula_Baleares_Canarias.shp encoding=1252 \
    -clean \
    -rename-layers dem \
    -proj wgs84 \
    -drop fields=NOMBRE_50,CCFF50 \
    -rename-fields name=MTN50_CLAS \
    -each 'name=name.replace(/\//g, "-")' \
    -join scripts/cnig-cleaned-ids/MDT25.csv keys=name,name string-fields=name   \
    -o static/$1.json format=topojson
}

convert_mdt200() {
  # FIXME: i know the replace is horrible but
  mapshaper scripts/data/provinces.json \
    -rename-layers dem=provinces \
    -drop target=autonomous_regions \
    -proj wgs84 \
    -drop fields=id \
    -join scripts/cnig-cleaned-ids/MDT200.csv keys=name,name \
    -o static/$1.json format=topojson
}

# convert MDT02_COB2_Fechas MDT02 Fichero Fecha ""
# convert MDT05 MDT05 FICHERO FECHA 'file=file.replace(/_/g, "-")'
convert_mdt25 MDT25
# convert_mdt200 MDT200