<script>
	import '../app.css';
	import Map from '$lib/Map.svelte';

	const options = [
		{
			value: 'MDT02',
			text: '2 metros',
			note: 'Incompleto',
			coverage: [{ text: '2ª cobertura (2015-2021)', value: 'COB2' }]
		},
		{
			value: 'MDT05',
			text: '5 metros',
			coverage: [{ text: '1ª cobertura (2008-2015)', value: 'COB1' }]
		},
		{
			value: 'MDT25',
			text: '25 metros',
			coverage: [
				{ text: '1ª cobertura (2008-2015)', value: 'COB1' },
				{ text: '2ª cobertura (2015-2021)', value: 'COB2' }
			]
		},
		{
			value: 'MDT200',
			text: '200 metros',
			coverage: [
				{ text: '1ª cobertura (2008-2016)', value: 'COB1' },
				{ text: '2ª cobertura (2015-2021)', value: 'COB2' }
			]
		}
	];

	let coverage = $state({ MDT02: 'COB2', MDT05: 'COB1', MDT25: 'COB2', MDT200: 'COB2' });
	let dem = $state('MDT05');

	let selected = $derived({
		dem: dem,
		coverage: coverage[dem]
	});
</script>

<main>
	<header>
		<h1>Descarga modelos digitales <br /> de elevación del IGN</h1>
		<div class="highlight">
			Actualización 2024: descarga en formato GeoTIFF, soporte de coberturas y nuevas hojas 2m.
		</div>
		<p class="desc">
			Con este mapa puedes descargar fácilmente los modelos digitales de elevación (DEM) realizados
			por el
			<a
				href="https://centrodedescargas.cnig.es/CentroDescargas/modelos-digitales-elevaciones#MDTER"
				>Instituto Geográfico Nacional</a
			> a partir de datos LIDAR.
		</p>

		<div class="options">
			<h2>Escoge la resolución</h2>

			{#each options as option, idx}
				<div class="radio">
					<input type="radio" name="dem" id={option.value} value={option.value} bind:group={dem} />
					<label for={option.value}>
						{option.text}
						{#if option.note}<span class="note">({option.note})</span>{/if}
					</label>

					<select bind:value={coverage[option.value]} disabled={option.coverage.length === 1}>
						{#each option.coverage as d}
							<option value={d.value}>{d.text}</option>
						{/each}
					</select>
				</div>
			{/each}
		</div>

		<div class="info">
			<p>
				Datos en formato <a href="https://cogeo.org/">Cloud Optimized GeoTiff</a>. Licencia
				<a href="https://www.ign.es/resources/licencia/Condiciones_licenciaUso_IGN.pdf">CC-BY</a>.
			</p>
			<p>
				<a
					href="https://centrodedescargas.cnig.es/CentroDescargas/documentos/{selected.dem}_recursos.zip"
				>
					Descarga la referencia técnica
				</a>.
			</p>
			<p>
				Código fuente disponible en <a href="https://github.com/martgnz/ign-dem-grabber">GitHub</a>.
			</p>
		</div>
	</header>

	<div class="content">
		<Map {selected} />
	</div>
</main>

<style>
	header {
		top: 2rem;
		left: 2rem;
		padding: 1rem;
		position: absolute;
		background: rgba(255, 255, 255, 0.9);
		border-radius: 4px;
		max-width: 310px;
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
		margin-bottom: 0.25rem;
		padding-bottom: 0.25rem;
		border-bottom: 1px solid #dfdfdf;
	}
	@media (min-width: 600px) {
		.radio:not(:last-child) {
			margin-bottom: 0.5rem;
			padding-bottom: 0.5rem;
		}
	}
	label {
		width: 100%;
	}
	.note {
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
	.desc {
		display: none;
	}
	@media (min-width: 600px) {
		.desc {
			display: block;
		}
	}
	.highlight {
		display: inline-block;
		font-size: 12px;
		font-weight: 300;
		background-color: #ffffba;
		border-radius: 5px;
		padding: 6px;
		padding-bottom: 4px;
		margin-bottom: 5px;
	}
</style>
