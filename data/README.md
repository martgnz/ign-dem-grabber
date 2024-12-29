# scripts

These scripts scrape, download and clean the data necessary to obtain elevation imagery in various resolutions from the [CNIG website](https://centrodedescargas.cnig.es/CentroDescargas/index.jsp#). The output is a set of CSV and TopoJSON files that live on the `/output-data` folder.

## Requirements

You need to have `curl` and `R` installed and in your path.

For the `R` script you need to install `tidyverse`.

## Getting started

1. First, on the root of the project, run this script to get metadata for each tile:

```bash
$ npm run 01-download
```

2. Run this to clean the data:

```bash
$ npm run 02-clean
```

3. And last, convert the maps to TopoJSON:

```bash
$ npm run 03-maps
```

Once that is done, copy the files to the `static` folder to upload them to the website.
