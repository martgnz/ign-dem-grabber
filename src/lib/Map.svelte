<style>
#map {
	position: absolute;
	top: 0;
	bottom: 0;
	width: 100%;
}
:global(.mapboxgl-popup) {
	width: 230px;
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
import { json } from 'd3-fetch';
import { feature } from 'topojson-client';
import { Map, AttributionControl, Popup, LngLatBounds, LngLat } from 'maplibre-gl';
import { browser } from '$app/env';
import { tile } from '../stores';

export let dem;

let container;
let map;
let popup;

// fetch topojson
const fetchData = () => json(`${dem}.json`);

onMount(async () => {
	// use retina tiles if dpi > 1
	const retina = window.devicePixelRatio > 1 ? '@2' : '';

	const bounds = [
		[-21, 25],
		[10, 45]
	];

	// start map
	map = new Map({
		container: 'map',
		center: [-6, 40],
		zoom: 5.75,
		maxZoom: 10,
		minZoom: 5.75,
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

	map.dragRotate.disable();
	map.addControl(
		new AttributionControl({
			customAttribution:
				'© <a href="https://centrodedescargas.cnig.es/CentroDescargas/index.jsp#">IGN</a> © <a href="https://www.openstreetmap.org/copyright">OpenStreetMap contributors</a> © <a href="https://carto.com/attribution/#basemaps">CARTO</a>'
		})
	);

	// add our tiles
	map.on('load', () => {
		fetchData().then((data) => {
			const grid = feature(data, data.objects.dem);

			map.addSource('dem', {
				type: 'geojson',
				data: grid
			});

			map.addLayer({
				id: 'dem',
				type: 'fill',
				source: 'dem',
				layout: {},
				paint: {
					'fill-color': 'rgba(0,0,0,.05)',
					'fill-outline-color': 'rgba(0,0,0,.15)'
				}
			});

			map.addLayer({
				id: 'dem-clicked',
				type: 'fill',
				source: 'dem',
				layout: {},
				paint: {
					'fill-color': 'rgba(244, 244, 150, 0.5)',
					'fill-outline-color': 'rgba(0,0,0,.5)'
				},
				filter: ['==', 'id', '']
			});

			map.addLayer({
				id: 'dem-hover',
				type: 'line',
				source: 'dem',
				layout: {},
				paint: {
					'line-color': '#555',
					'line-width': 2.5
				},
				filter: ['==', 'id', '']
			});
		});
	});

	// create a popup, but don't add it to the map yet.
	popup = new Popup({
		closeButton: false,
		closeOnClick: false,
		offset: 15
	});

	// hover
	map.on('click', 'dem', clicked);
	map.on('mousemove', 'dem', mousemoved);
	map.on('mouseleave', 'dem', mouseleft);
});

const clicked = (e) => {
	const { id, name, datum, utm_zone, date } = e.features[0].properties;

	// some tiles don't have imagery
	if (name === 'null') return;

	map.setFilter('dem-clicked', ['==', 'id', id]);
	popup
		.setLngLat(e.lngLat)
		.setHTML(
			`<div class="tip-container">
				<div class="tip-title">${dem === 'MDT200' ? name : `Hoja ${name}`}</div>
				${tooltipRow({ name: 'Fecha', data: date })}
				${tooltipRow({ name: 'Datum', data: datum })}
				${tooltipRow({ name: 'Zona UTM', data: utm_zone })}
				<form
					method="post"
					id="form"
					action="https://centrodedescargas.cnig.es/CentroDescargas/descargaDir">
					<input type="hidden" name="secuencialDescDir" value="${id}" />
					<button class="tip-download" type="submit">Descargar</button>
				</form>
		</div>`
		)
		.addTo(map);
};

const tooltipRow = ({ name, data }) => {
	if (!data) return '';

	return `<div class="tip-row">
		<div class="tip-name">${name}</div>
		<div class="tip-value">${data}</div>
		</div>`;
};

const mousemoved = (e) => {
	const id = e.features[0].properties.id;
	map.setFilter('dem-hover', ['==', 'id', id]);
};

const mouseleft = (e) => {
	map.setFilter('dem-hover', ['==', 'id', '']);
};

// update the grid
// FIXME: this is not great
$: if (browser && map && map.getSource('dem') && dem) {
	fetchData().then((data) => {
		const grid = feature(data, data.objects.dem);

		popup.remove();
		map.getSource('dem').setData(grid);
	});
}
</script>

<div id="map" bind:this={container} />
