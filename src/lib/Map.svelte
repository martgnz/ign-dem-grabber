<script>
	import 'maplibre-gl/dist/maplibre-gl.css';

	import { browser } from '$app/environment';
	import { onMount } from 'svelte';
	import { csv, json } from 'd3-fetch';
	import { selectAll } from 'd3-selection';
	import { feature } from 'topojson-client';
	import maplibregl from 'maplibre-gl';

	let { selected } = $props();

	let mounted = $state(false);
	let width = $state(0);
	let isMobile = $derived(width < 600);

	let container = $state(null);
	let map = $state(null);
	let popup = $state(null);

	let es = $state(null);
	let data = $state(null);

	let downloaded = $state({
		MDT02: [],
		MDT05: [],
		MDT25: [],
		MDT200: []
	});

	const roundMb = (size) => {
		if (size < 1) return size;
		return Math.floor(size);
	};

	const fetchData = async () =>
		await Promise.all([
			json(`${selected.coverage.tiles}.json`),
			csv(`${selected.dem}_${selected.coverage.value}.csv`)
		]);

	$effect(async () => {
		if (mounted && selected && map?.getSource('dem')) {
			[es, data] = await fetchData();
			const dataIds = new Set(data.map((d) => d.id));

			popup.remove();
			map.getSource('dem').setData({
				type: 'FeatureCollection',
				features: feature(es, es.objects.dem).features.filter((d) => {
					return dataIds.has(d.properties.id);
				})
			});
			map.setFilter('dem-downloaded', ['in', 'id', ...downloaded[selected.dem]]);
		}
	});

	onMount(async () => {
		// use retina tiles if dpi > 1
		const retina = window.devicePixelRatio > 1 ? '@2' : '';

		// start map
		map = new maplibregl.Map({
			container: 'map',
			center: isMobile ? [-4, 40] : [-6, 40],
			zoom: isMobile ? 5 : 5.5,
			minZoom: isMobile ? 5 : 5.5,
			maxZoom: 10,
			// maxBounds: bounds,
			attributionControl: false,
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
			new maplibregl.AttributionControl({
				customAttribution:
					'© <a href="https://centrodedescargas.cnig.es/CentroDescargas/index.jsp#">CC-BY 4.0 scne.es 2015-2021</a> © <a href="https://www.openstreetmap.org/copyright">OpenStreetMap contributors</a> © <a href="https://carto.com/attribution/#basemaps">CARTO</a>'
			})
		);

		// once tiles are loaded, add grid
		map.on('load', async () => {
			[es, data] = await fetchData();
			const dataIds = new Set(data.map((d) => d.id));

			map.addSource('dem', {
				type: 'geojson',
				data: {
					type: 'FeatureCollection',
					features: feature(es, es.objects.dem).features.filter((d) => {
						return dataIds.has(d.properties.id);
					})
				}
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
				id: 'dem-downloaded',
				type: 'fill',
				source: 'dem',
				layout: {},
				paint: {
					'fill-color': 'rgba(67, 135, 0, .4)',
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

		// hover
		map.on('click', 'dem', clicked);
		map.on('mousemove', 'dem', mousemoved);
		map.on('mouseleave', 'dem', mouseleft);

		// create a popup, but don't add it to the map yet.
		popup = new maplibregl.Popup({
			closeButton: true,
			closeOnClick: false,
			offset: 15
		});

		mounted = true;
	});

	const clicked = (e) => {
		const { id, name } = e.features[0].properties;
		const tile = data.filter((d) => d.id === id);

		if (!tile || !tile[0]) return;

		// we get the first match for the hover
		const { date, size, datum } = tile[0];

		map.setFilter('dem-clicked', ['==', 'id', id]);
		popup
			.setLngLat(e.lngLat)
			.setHTML(
				`<div class="tip-container">
				<div class="tip-title">${name}</div>
				${tooltipRow({ name: 'Fecha', data: date })}
				${tooltipRow({ name: 'Tamaño', data: `${roundMb(+size)}MB` })}

				${tile
					.map(
						(d) => `
					<form
						method="post"
						id="form"
						action="https://centrodedescargas.cnig.es/CentroDescargas/descargaDir">
						<input type="hidden" name="secDescDirLA" value="${d.download_id}" />
						<input type="hidden" name="codSerie" value="${d.series}" />
						<button class="tip-download" type="submit">Descargar ${d.datum}${d.utm_zone !== 'NA' ? ` (UTM ${d.utm_zone})` : ''}</button>
					</form>
				`
					)
					.join('')}
			
		</div>`
			)
			.addTo(map);

		// remove highlight when tooltip is closed manually
		// FIXME: is there a way to remove the listener once we click away?
		const closeButton = document.querySelector('.maplibregl-popup-close-button');
		closeButton.addEventListener('click', () => {
			map.setFilter('dem-clicked', ['==', 'id', '']);
		});

		// colour clicked tiles
		selectAll('.tip-download').on('click', () => {
			map.setFilter('dem-clicked', ['==', 'id', '']);

			downloaded[selected.dem].push(id);
			map.setFilter('dem-downloaded', ['in', 'id', ...downloaded[selected.dem]]);
		});
	};

	const tooltipRow = ({ name, data }) => {
		if (!data) return '';

		return `<div class="tip-row">
		<div class="tip-name">${name}</div>
		<div class="tip-value">${data}</div>
		</div>`;
	};

	const mousemoved = (e) => {
		const { id } = e.features[0].properties;
		const f = data.find((d) => d.id === id);
		if (!f) return;
		map.setFilter('dem-hover', ['==', 'id', f.id]);
	};

	const mouseleft = (e) => {
		map.setFilter('dem-hover', ['==', 'id', '']);
	};
</script>

<svelte:window bind:innerWidth={width} />

<div id="map" bind:this={container}></div>

<style>
	#map {
		position: absolute;
		top: 0;
		bottom: 0;
		width: 100%;
	}
	#map :global(.maplibregl-popup) {
		z-index: 1;
		width: 240px;
	}
	#map :global(.maplibregl-popup-content) {
		padding-top: 7px;
	}
	@media (min-width: 600px) {
		#map :global(.maplibregl-popup) {
			z-index: 0;
		}
	}
	#map :global(.tip-title) {
		font-weight: 700;
		font-size: 14px;
		margin-bottom: 0.25rem;
	}
	#map :global(.tip-row) {
		font-size: 14px;
		display: flex;
		justify-content: space-between;
	}
	#map :global(.tip-row:not(:last-of-type)) {
		border-bottom: 1px solid #dfdfdf;
		margin-bottom: 0.25rem;
		padding-bottom: 0.25rem;
	}
	#map :global(.tip-name) {
		color: #7d7d7d;
	}
	#map :global(#map form) {
		text-align: center;
		margin-top: 0.75rem;
	}
	#map :global(.tip-download) {
		margin-top: 10px;
		cursor: pointer;
		width: 100%;
		border: 1px solid #54851f;
		border-radius: 4px;
		background: #54851f;
		font-weight: 700;
		font-size: 14px;
		color: #fff;
		padding: 8px;
		text-align: center;
	}
	#map :global(.tip-download:hover) {
		background: #4e6e2c;
	}
</style>
