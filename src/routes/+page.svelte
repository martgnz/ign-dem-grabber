<script>
	import '../app.css';
	import Map from '$lib/Map.svelte';
	import { innerWidth } from 'svelte/reactivity/window';

	const options = [
		{
			text: '2 metros',
			value: 'MDT02',
			coverage: [{ text: '2ª cobertura (2015-2021)', value: 'COB2', tiles: 'MTN25' }]
		},
		{
			text: '5 metros',
			value: 'MDT05',
			coverage: [{ text: '1ª cobertura (2008-2015)', value: 'COB1', tiles: 'MTN50' }]
		},
		{
			text: '25 metros',
			value: 'MDT25',
			coverage: [
				{ text: '1ª cobertura (2008-2015)', value: 'COB1', tiles: 'MTN50' },
				{ text: '2ª cobertura (2015-2021)', value: 'COB2', tiles: 'MTN25' }
			]
		},
		{
			text: '200 metros',
			value: 'MDT200',
			coverage: [
				{ text: '1ª cobertura (2008-2016)', value: 'COB1', tiles: 'provinces' },
				{ text: '2ª cobertura (2015-2021)', value: 'COB2', tiles: 'MTN25' }
			]
		}
	];

	let coverage = $state({ MDT02: 'COB2', MDT05: 'COB1', MDT25: 'COB1', MDT200: 'COB1' });
	let dem = $state('MDT05');

	let selected = $derived({
		dem: dem,
		// -.-
		// find the full coverage object since we need the tile slug too
		coverage: options.find((d) => d.value === dem).coverage.find((d) => d.value === coverage[dem])
	});
</script>

<main>
	<header>
		<h1>Descarga modelos digitales <br /> de elevación del IGN</h1>
		<div class="highlight">
			Actualización 2024: descargas en formato GeoTIFF y resoluciones actualizadas con múltiples
			coberturas.
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
			<details open={innerWidth.current < 740 ? false : true}>
				<summary>Escoge la resolución</summary>
				{#each options as option, idx}
					<div class="radio">
						<input
							type="radio"
							name="dem"
							id={option.value}
							value={option.value}
							bind:group={dem}
						/>
						<label for={option.value}>
							{option.text}
							{#if option.note}<span class="note">({@html option.note})</span>{/if}
							{#if option.value === 'MDT200' && coverage[option.value] === 'COB1'}
								<span class="note">
									<form
										method="post"
										id="form"
										action="https://centrodedescargas.cnig.es/CentroDescargas/descargaDir"
									>
										<input type="hidden" name="secDescDirLA" value="11608426" />
										<input type="hidden" name="codSerie" value="02109" />
										<button type="submit">Hoja nacional</button>
									</form>
								</span>
							{/if}
						</label>

						<select bind:value={coverage[option.value]} disabled={option.coverage.length === 1}>
							{#each option.coverage as d}
								<option value={d.value}>{d.text}</option>
							{/each}
						</select>
					</div>
				{/each}
			</details>
		</div>

		<div class="info">
			<p>
				Datos en formato <a href="https://cogeo.org/">Cloud Optimized GeoTiff</a>.
			</p>
			<p>
				Licencia de uso
				<a href="https://www.ign.es/resources/licencia/Condiciones_licenciaUso_IGN.pdf"
					>CC-BY 4.0 scne.es</a
				>.
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
	@media (max-width: calc(740px - 1px)) {
		header {
			margin-left: auto;
			margin-right: auto;
			left: 0;
			right: 0;
		}
	}
	a {
		color: black;
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
	.desc {
		margin-bottom: 0;
	}
	details summary {
		cursor: pointer;
		font-size: 1rem;
		font-weight: 700;
		margin: 0;
		margin-bottom: 0.5rem;
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
	.radio input {
		top: 1px;
		position: relative;
	}
	label {
		padding-left: 2px;
		width: 100%;
	}
	.note {
		font-size: 12px;
		font-weight: 300;
		font-style: italic;
	}
	.note form button {
		font-weight: 300;
		font-style: italic;
		cursor: pointer;
		appearance: none;
		background: none;
		border: none;
		text-decoration: underline;
		margin: 0;
		padding: 0;
		padding-top: 2px;
	}
	.options {
		margin-top: 10px;
		margin-bottom: 10px;
	}
	.info p {
		font-weight: 300;
		font-size: 12px;
		margin-bottom: 2px;
	}
	.highlight {
		display: inline-block;
		font-size: 12px;
		font-weight: 400;
		background-color: #ffffba;
		border: 1px solid #eeeead;
		border-radius: 5px;
		padding: 6px;
		padding-top: 4px;
		padding-bottom: 4px;
		margin-bottom: 8px;
	}
</style>
