<style>
.container {
	position: relative;
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
import { onMount } from 'svelte';
import { json } from 'd3-fetch';
import { feature } from 'topojson-client';
import { geoConicConformalSpain } from 'd3-composite-projections';
import { browser } from '$app/env';
import { tile } from '../stores';

export let dem;

let container;
let geoPath;
let projection;
let es;
let path;
let hover;
let click;
let mx;
let my;
let pointer;

// fetch topojson
const fetchData = () => json(`${dem}.json`).then((data) => (es = feature(data, data.objects.dem)));

onMount(async () => {
	// https://kit.svelte.dev/docs#configuration-ssr
	const d3Geo = await import('d3-geo');
	geoPath = d3Geo.geoPath;

	const d3Selection = await import('d3-selection');
	pointer = d3Selection.pointer;

	fetchData();
});

const margin = { top: 20, right: 10, bottom: 10, left: 10 };

$: width = container ? container.getBoundingClientRect().width - margin.left - margin.right : 300;
$: height = 650 - margin.top - margin.bottom;

$: if (browser && dem) {
	fetchData();
	hover = null;
	tile.set(null);
}

$: if (browser && geoPath) {
	projection = geoConicConformalSpain().fitSize([width, height], es);
	path = geoPath().projection(projection);
}

const mousemoved = (e, d) => {
	hover = d;
};

const clicked = (e, d) => {
	tile.set({ path: d, id: d.properties.id, file: d.properties.file, date: d.properties.date });
	mx = pointer(e)[0];
	my = pointer(e)[1];
};
</script>

<div class="container" bind:this={container}>
	<svg width={width + margin.right + margin.left} height={height + margin.top + margin.bottom}>
		<g transform="translate({margin.left},{margin.top})">
			{#if es}
				{#each es.features as feature}
					<path
						on:mousemove={(e) => mousemoved(e, feature)}
						on:click={(e) => clicked(e, feature)}
						fill="#d3d3d3"
						stroke="black"
						stroke-width={0.25}
						d={path(feature)} />
				{/each}
				<path fill="none" stroke="black" d={projection.getCompositionBorders()} />
				{#if $tile}
					<path
						d={path($tile.path)}
						stroke-width={2}
						stroke="black"
						fill={'red'}
						pointer-events="none" />
				{/if}
				<path
					d={path(hover)}
					stroke-width={2}
					stroke="black"
					fill={'yellow'}
					pointer-events="none" />
			{/if}
		</g>
	</svg>

	{#if $tile}
		<div class="tooltip" style="left:{mx - 50}px;top:{my - 80}px">
			<div>{$tile.file}</div>
			<div>{$tile.date}</div>
		</div>
	{/if}
</div>
