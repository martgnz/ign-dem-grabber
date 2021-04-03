<style>
main {
	display: grid;
	grid-template-columns: 40% 1fr;
	grid-column-gap: 1rem;
	margin-bottom: 2rem;
}
header {
	max-width: 500px;
}
h1 {
	color: #111;
	font-size: 1.5rem;
	margin-bottom: 0.5rem;
}
h2 {
	font-size: 1rem;
	margin: 0;
	margin-bottom: 0.5rem;
}
.radio:not(:last-child) {
	margin-bottom: 1rem;
}
.options {
	margin-top: 1.5rem;
}
footer {
	font-size: 0.85rem;
	padding-top: 0.5rem;
	border-top: 1px solid #dfdfdf;
}
</style>

<script>
import Map from '$lib/Map.svelte';
import { tile } from '../stores.js';

let dem = 'MDT05';

const options = [
	{
		value: 'MDT02',
		text: '2m - la más detallada, no cubre todo el territorio'
	},
	{
		value: 'MDT05',
		text: '5m - detalle alto, para ciudades medias'
	},
	{
		value: 'MDT25',
		text: '25m - detalle medio, para grandes ciudades'
	},
	{
		value: 'MDT200',
		text: '200m - detalle bajo, para regiones'
	}
];
</script>

<main>
	<header>
		<h1>Modelos digitales de elevación</h1>
		<p>
			Descarga los modelos digitales de elevación (DEM) del <a
				href="http://centrodedescargas.cnig.es/CentroDescargas/index.jsp#"
				>Centro Nacional de Información Geográfica</a> de manera sencilla en diferentes resoluciones.
		</p>

		<p>
			Los archivos están en formato <code>asc</code>, para convertirlos a TIF con GDAL puedes hacer:
		</p>
		<p><code><span class="no-select">$ </span>gdalwarp output.tif input.asc</code></p>

		<p>
			En <a href="https://github.com/dwtkns/gdal-cheat-sheet#raster-operations">esta guía</a> hay más
			comandos útiles.
		</p>

		<div class="options">
			<h2>Resoluciones</h2>

			{#each options as option}
				<div class="radio">
					<input type="radio" name="dem" id={option.value} value={option.value} bind:group={dem} />
					<label for={option.value}>{option.text}</label>
				</div>
			{/each}
		</div>

		{#if $tile}
			<form
				method="post"
				id="form"
				action="https://centrodedescargas.cnig.es/CentroDescargas/descargaDir">
				<input type="hidden" name="secuencialDescDir" bind:value={$tile} />
				<input type="hidden" name="aceptCodsLicsDD_0" value="15" />
				<button type="submit">Descarga</button>
			</form>
		{/if}
	</header>

	<div class="content">
		<Map {dem} />
	</div>
</main>
<footer>
	Fuente: <a href="http://centrodedescargas.cnig.es/CentroDescargas/index.jsp#"
		>Centro Nacional de Información Geográfica.
	</a>
</footer>
