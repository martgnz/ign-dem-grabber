<style>
#map {
	position: absolute;
	top: 0;
	bottom: 0;
	width: 100%;
}
.tooltip {
	padding: 8px;
	background: white;
	font-size: 14px;
	border: 1px solid #000000;
	position: absolute;
	/* pointer-events: none; */
}
button {
	cursor: pointer;
	padding: 5px;
	background: #fff;
	font-size: 14px;
	border: 1px solid #222;
	border-radius: 4px;
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
let pointer;

// fetch topojson
const fetchData = () => json(`${dem}.json`);

onMount(async () => {
	// use retina tiles if dpi > 1
	const retina = window.devicePixelRatio > 1 ? '@2' : '';

	// start map
	map = new Map({
		container: 'map',
		center: [-6, 40],
		zoom: 5.75,
		maxZoom: 10,
		// bounds
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
				'© <a href="https://centrodedescargas.cnig.es/CentroDescargas/index.jsp#">CNIG</a> © <a href="https://www.openstreetmap.org/copyright">OpenStreetMap contributors</a> © <a href="https://carto.com/attribution/#basemaps">CARTO</a>'
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
					'fill-outline-color': 'rgba(0,0,0,.1)'
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
	const { id, file, date } = e.features[0].properties;

	console.log(e.features[0].properties);

	map.setFilter('dem-clicked', ['==', 'id', id]);
	popup
		.setLngLat(e.lngLat)
		.setHTML(
			`<div class="tip-container">
			<div>${file}</div>
			<div>${date}</div>
			<div>${id}</div>
		</div>`
		)
		.addTo(map);
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
