# ign-dem-grabber

## GDAL cheat sheet

**Merge rasters**

```bash
gdal_merge.py -o merged.tif input.asc
```

**Add geographic information**

For some reason QGIS doesn't recognise the coordinate system of these files straight away. To fix this we can look at the UTM zone of our map, see to what EPSG code [from this list](http://www.juntadeandalucia.es/medioambiente/site/rediam/menuitem.04dc44281e5d53cf8ca78ca731525ea0/?vgnextoid=2a412abcb86a2210VgnVCM1000001325e50aRCRD&lr=lang_es) corresponds (remember these files are usually ETRS89) and use gdalwarp.

This is how we add geographic metadata to a UTM30 tile:

```bash
gdalwarp -s_srs "EPSG:25830" -t_srs "EPSG:25830" -r bilinear merged.tif reprojected.tif
```
