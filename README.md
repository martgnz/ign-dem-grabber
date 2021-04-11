# ign-dem-grabber

Download DEMs from the [Spanish National Geographic Institute](https://centrodedescargas.cnig.es/CentroDescargas/index.jsp) easily. [See the live app here](https://martingonzalez.net/ign-dem-grabber/).

## Getting started

This project uses [svelte-kit](https://github.com/sveltejs/kit). To start developing do `npm install` and `npm run dev`.

## Data

The scripts for obtaining and cleaning the data are on the `scripts` folder. For using the imagery you have to accept the terms of the [CC-BY licence](https://www.ign.es/resources/licencia/Condiciones_licenciaUso_IGN.pdf).

## Usage

These are common GDAL commands you can use to work with this imagery. You can find more in [this cheatsheet](https://github.com/dwtkns/gdal-cheat-sheet).

**Merge rasters**

```bash
gdal_merge.py -o merged.tif input1.asc input2.asc
```

**Add geographic information**

For some reason QGIS doesn't recognise the coordinate system of these files straight away. To fix this we can look at the UTM zone of our map, see to what EPSG code [from this list](http://www.juntadeandalucia.es/medioambiente/site/rediam/menuitem.04dc44281e5d53cf8ca78ca731525ea0/?vgnextoid=2a412abcb86a2210VgnVCM1000001325e50aRCRD&lr=lang_es) corresponds (remember these files are usually ETRS89) and use gdalwarp.

This is how we add geographic metadata to a UTM30 tile:

```bash
gdalwarp -s_srs "EPSG:25830" -t_srs "EPSG:25830" -r bilinear merged.tif reprojected.tif
```
