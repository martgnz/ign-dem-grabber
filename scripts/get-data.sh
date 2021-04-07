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

# FIXME: do many-to-many merges
convert_mdt0205() {
  mapshaper scripts/data/$1.shp \
    -clean \
    -rename-layers dem \
    -proj wgs84 \
    -rename-fields filename=$3,date=$4 \
    -join scripts/cnig-cleaned-ids/$2.csv keys=filename,filename string-fields=id   \
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
  mapshaper scripts/data/provinces.json \
    -rename-layers dem=provinces \
    -drop target=autonomous_regions \
    -proj wgs84 \
    -drop fields=id \
    -join scripts/cnig-cleaned-ids/MDT200.csv keys=name,name \
    -o static/$1.json format=topojson
}

convert_mdt0205 MDT02_COB2_Fechas MDT02 Fichero Fecha
convert_mdt0205 MDT05 MDT05 FICHERO FECHA
convert_mdt25 MDT25
convert_mdt200 MDT200