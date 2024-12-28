# scripts

These scripts scrape, download and clean the data necessary to obtain elevation imagery in various resolutions from the [CNIG website](https://centrodedescargas.cnig.es/CentroDescargas/index.jsp#). The output is a set of CSV and TopoJSON files that live on the `/static` folder.

## Requirements

You need to have `R` installed and in your path.

## Getting started

1. First, open a terminal and install the dependencies:

```bash
$ npm install
```

2. Navigate to this folder and run the scraper to get metadata for each tile on every resolution:

```bash
$ npm run 01-scrape-data
```

3. Run this script to download the tiles:

```bash
$ npm run 02-download-maps
```

4. Process the scraped data and generate clean CSVs and shapefiles:

```bash
$ npm run 03-clean-data
```

5. Convert the files to TopoJSON

```bash
$ npm run 04-convert-maps
```
