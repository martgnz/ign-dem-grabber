<style>
header {
	top: 2rem;
	left: 2rem;
	padding: 1rem;
	position: absolute;
	background: rgba(255, 255, 255, 0.9);
	border-radius: 4px;
	max-width: 285px;
	z-index: 1;
	box-shadow: 0 0 6px rgba(0, 0, 0, 0.25);
}
h1 {
	color: #111;
	font-size: 1.25rem;
	line-height: 1.2;
	margin-top: 0;
	margin-bottom: 0.5rem;
	padding-bottom: 0.5rem;
	border-bottom: 1px solid #dfdfdf;
}
h2 {
	font-size: 1rem;
	margin: 0;
	margin-bottom: 0.5rem;
}
a {
	color: black;
	/* text-decoration: none; */
	/* border-bottom: 2px solid black; */
}
.radio {
	display: flex;
	align-items: baseline;
	position: relative;
}
.radio:not(:last-child) {
	margin-bottom: 0.5rem;
	padding-bottom: 0.5rem;
	border-bottom: 1px solid #dfdfdf;
}
label {
	width: 100%;
}
.note {
	pointer-events: none;
	position: absolute;
	right: 0;
	top: 0;
	font-size: 12px;
	font-weight: 300;
	font-style: italic;
}
.options {
	margin-top: 1rem;
	margin-bottom: 1rem;
}
.info p {
	font-weight: 300;
	font-size: 12px;
	margin-bottom: 2px;
}
</style>

<script>
import Map from '$lib/Map.svelte';
import { tile } from '../stores.js';

let dem = 'MDT05';

const options = [
	{
		value: 'MDT02',
		text: '2 metros',
		note: 'Cobertura incompleta'
	},
	{
		value: 'MDT05',
		text: '5 metros'
	},
	{
		value: 'MDT25',
		text: '25 metros'
	},
	{
		value: 'MDT200',
		text: '200 metros'
	}
];
</script>

<main>
	<header>
		<h1>Descarga modelos digitales <br /> de elevación</h1>
		<p>
			Con este mapa puedes descargar fácilmente los modelos digitales de elevación (DEM) realizados
			por el <a href="https://centrodedescargas.cnig.es/CentroDescargas/index.jsp#"
				>Centro Nacional de Información Geográfica</a> a partir de datos LIDAR.
		</p>

		<div class="options">
			<h2>Escoge la resolución</h2>

			{#each options as option}
				<div class="radio">
					<input type="radio" name="dem" id={option.value} value={option.value} bind:group={dem} />
					<label for={option.value}>{option.text}</label>
					{#if option.note}
						<div class="note">{option.note}</div>
					{/if}
				</div>
			{/each}
		</div>

		{#if $tile}
			<form
				method="post"
				id="form"
				action="https://centrodedescargas.cnig.es/CentroDescargas/descargaDir">
				<input type="hidden" name="secuencialDescDir" bind:value={$tile.id} />
				<input type="hidden" name="aceptCodsLicsDD_0" value="15" />
				<button type="submit">Descarga</button>
			</form>
		{/if}

		<div class="info">
			<p>
				Datos en <a href="https://gdal.org/drivers/raster/aaigrid.html#raster-aaigrid"
					>formato ASCII Grid</a>
				con
				<a href="https://www.ign.es/resources/licencia/Condiciones_licenciaUso_IGN.pdf"
					>licencia CC-BY</a
				>.
			</p>
			<p>
				<a href="https://centrodedescargas.cnig.es/CentroDescargas/documentos/{dem}_recursos.zip"
					>Descarga la referencia técnica</a
				>.
			</p>
			<p>
				Código fuente disponible en <a href="https://github.com/martgnz/cnig-dem-grabber">GitHub</a
				>.
			</p>
		</div>
	</header>

	<div class="content">
		<Map {dem} />
	</div>
</main>
