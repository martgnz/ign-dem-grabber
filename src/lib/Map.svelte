<style>
#map {
	position: absolute;
	top: 0;
	bottom: 0;
	width: 100%;
}
:global(.mapboxgl-popup) {
	z-index: 1;
	width: 230px;
}
@media (min-width: 600px) {
	:global(.mapboxgl-popup) {
		z-index: 0;
	}
}
:global(.tip-title) {
	font-weight: 700;
	font-size: 14px;
	margin-bottom: 0.25rem;
}
:global(.tip-row) {
	font-size: 14px;
	display: flex;
	justify-content: space-between;
}
:global(.tip-row:not(:last-of-type)) {
	border-bottom: 1px solid #dfdfdf;
	margin-bottom: 0.25rem;
	padding-bottom: 0.25rem;
}
:global(.tip-name) {
	color: #7d7d7d;
}
:global(#map form) {
	text-align: center;
	margin-top: 0.75rem;
}
:global(.tip-download) {
	cursor: pointer;
	width: 80%;
	border: 1px solid #54851f;
	border-radius: 4px;
	background: #54851f;
	font-weight: 700;
	font-size: 14px;
	color: #fff;
	padding: 8px;
	text-align: center;
}
:global(.tip-download:hover) {
	background: #4e6e2c;
}
</style>

<script>
import 'maplibre-gl/dist/maplibre-gl.css';

import { onMount } from 'svelte';
import { csv, json } from 'd3-fetch';
import { feature } from 'topojson-client';
import { Map, AttributionControl, Popup } from 'maplibre-gl';
import { browser } from '$app/env';

export let dem;

let width;
let container;
let geoMap;
let data;
let popup;
let selectAll;
let downloaded = {
	MDT02: [],
	MDT05: [],
	MDT25: [],
	MDT200: []
};

$: isMobile = width < 600;

// fetch topojson
const fetchData = () => Promise.all([json(`${dem}.json`), csv(`${dem}.csv`)]);

const getCleanGrid = (es, csv) => ({
	type: 'FeatureCollection',
	features: es.features.filter((d) => csv.map((k) => k.name).includes(d.properties.name))
});

onMount(async () => {
	// https://kit.svelte.dev/docs#troubleshooting-server-side-rendering
	const module = await import('d3-selection');
	selectAll = module.selectAll;

	// use retina tiles if dpi > 1
	const retina = window.devicePixelRatio > 1 ? '@2' : '';

	// const bounds = [
	// 	[-21, 25],
	// 	[10, 45]
	// ];

	// start map
	geoMap = new Map({
		container: 'map',
		center: isMobile ? [-4, 40] : [-6, 40],
		zoom: isMobile ? 5 : 5.5,
		minZoom: isMobile ? 5 : 5.5,
		maxZoom: 10,
		// maxBounds: bounds,
		style: {
			version: 8,
			sources: {
				tiles: {
					type: 'raster',
					tiles: [
						`https://a.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}${retina}.png`,
						`https://b.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}${retina}.png`
					],
					tileSize: 256
				}
			},
			layers: [
				{
					id: 'tiles',
					type: 'raster',
					source: 'tiles'
				}
			]
		}
	});

	geoMap.dragRotate.disable();
	geoMap.addControl(
		new AttributionControl({
			customAttribution:
				'© <a href="https://centrodedescargas.cnig.es/CentroDescargas/index.jsp#">IGN</a> © <a href="https://www.openstreetmap.org/copyright">OpenStreetMap contributors</a> © <a href="https://carto.com/attribution/#basemaps">CARTO</a>'
		})
	);

	// add our tiles
	geoMap.on('load', () => {
		fetchData().then(([es, csv]) => {
			const grid = getCleanGrid(feature(es, es.objects.dem), csv);
			data = csv;

			geoMap.addSource('dem', {
				type: 'geojson',
				data: grid
			});

			geoMap.addLayer({
				id: 'dem',
				type: 'fill',
				source: 'dem',
				layout: {},
				paint: {
					'fill-color': 'rgba(0,0,0,.05)',
					'fill-outline-color': 'rgba(0,0,0,.15)'
				}
			});

			geoMap.addLayer({
				id: 'dem-clicked',
				type: 'fill',
				source: 'dem',
				layout: {},
				paint: {
					'fill-color': 'rgba(244, 244, 150, 0.5)',
					'fill-outline-color': 'rgba(0,0,0,.5)'
				},
				filter: ['==', 'name', '']
			});

			geoMap.addLayer({
				id: 'dem-downloaded',
				type: 'fill',
				source: 'dem',
				layout: {},
				paint: {
					'fill-color': 'rgba(67, 135, 0, .4)',
					'fill-outline-color': 'rgba(0,0,0,.5)'
				},
				filter: ['==', 'name', '']
			});

			geoMap.addLayer({
				id: 'dem-hover',
				type: 'line',
				source: 'dem',
				layout: {},
				paint: {
					'line-color': '#555',
					'line-width': 2.5
				},
				filter: ['==', 'name', '']
			});
		});
	});

	// create a popup, but don't add it to the map yet.
	popup = new Popup({
		closeButton: true,
		closeOnClick: false,
		offset: 15
	});

	// hover
	geoMap.on('click', 'dem', clicked);
	geoMap.on('mousemove', 'dem', mousemoved);
	geoMap.on('mouseleave', 'dem', mouseleft);
});

const mousemoved = (e) => {
	const { name } = e.features[0].properties;

	const datum = data.find((d) => d.name === name);
	if (!datum) return;

	const id = datum.name;
	geoMap.setFilter('dem-hover', ['==', 'name', id]);
};

const mouseleft = (e) => {
	geoMap.setFilter('dem-hover', ['==', 'name', '']);
};

const clicked = (e) => {
	const { name: featureName } = e.features[0].properties;
	const tile = data.filter((d) => d.name === featureName);

	if (!tile) return;

	// we get the first match for the hover
	const { name, date, size, datum } = tile[0];
	const isMultiple = tile.length > 1;

	geoMap.setFilter('dem-clicked', ['==', 'name', name]);
	popup
		.setLngLat(e.lngLat)
		.setHTML(
			`<div class="tip-container">
				<div class="tip-title">${dem === 'MDT200' ? name : `Hoja ${name}`}</div>
				${tooltipRow({ name: 'Fecha', data: date })}
				${tooltipRow({ name: 'Datum', data: datum })}
				${tooltipRow({
					name: `Zona${isMultiple ? 's' : ''} UTM`,
					data: tile.map((d) => d.utm_zone).join(', ')
				})}
				${tooltipRow({ name: 'Tamaño', data: `${Math.floor(+size)}MB` })}

				${tile
					.map(
						(d) => `
					<form
						method="post"
						id="form"
						action="https://centrodedescargas.cnig.es/CentroDescargas/descargaDir">
						<input type="hidden" name="secuencialDescDir" value="${d.id}" />
						<button class="tip-download" type="submit">Descargar ${
							isMultiple ? `UTM ${d.utm_zone}` : 'hoja'
						}</button>
					</form>
				`
					)
					.join('')}
			
		</div>`
		)
		.addTo(geoMap);

	// colour clicked tiles
	selectAll('.tip-download').on('click', () => {
		geoMap.setFilter('dem-clicked', ['==', 'name', '']);

		downloaded[dem].push(id);
		geoMap.setFilter('dem-downloaded', ['in', 'name', ...downloaded[dem]]);
	});
};

const tooltipRow = ({ name, data }) => {
	if (!data) return '';

	return `<div class="tip-row">
		<div class="tip-name">${name}</div>
		<div class="tip-value">${data}</div>
		</div>`;
};

// update the grid
// FIXME: this is not great
$: if (browser && geoMap && geoMap.getSource('dem') && dem) {
	fetchData().then(([es, csv]) => {
		const grid = getCleanGrid(feature(es, es.objects.dem), csv);
		data = csv;

		popup.remove();
		geoMap.getSource('dem').setData(grid);
		geoMap.setFilter('dem-downloaded', ['in', 'name', ...downloaded[dem]]);
	});
}
</script>

<svelte:window bind:innerWidth={width} />

<div id="map" bind:this={container} />
