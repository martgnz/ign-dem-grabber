# ign-dem-grabber

Download DEMs from the [Spanish National Geographic Institute](https://centrodedescargas.cnig.es/CentroDescargas/modelos-digitales-elevaciones#MDTER) easily.

[See the live app here](https://martingonzalez.net/ign-dem-grabber/).

## Getting started

This project uses [SvelteKit](https://svelte.dev/docs/kit/introduction). To start developing do `npm install` and `npm run dev`.

## Data

The instructions and scripts for obtaining and cleaning the data needed to run the app are on the `data` folder.

## Data licence

IGN makes the rasters available under a [CC-BY compatible licence](https://www.ign.es/resources/licencia/Condiciones_licenciaUso_IGN.pdf).

## Usage

These are common GDAL commands you can use to work with this imagery. You can find more in [this cheatsheet](https://github.com/dwtkns/gdal-cheat-sheet).

**Merge rasters**

```bash
gdal_merge.py -o merged.tif input1.tif input2.tif
```
