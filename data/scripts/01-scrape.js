import fs from 'fs';
import * as cheerio from 'cheerio';
import { csvFormat } from 'd3-dsv';

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const fetchTable = async (series, page) => {
	const res = await fetch('https://centrodedescargas.cnig.es/CentroDescargas/archivosSerie', {
		method: 'POST',
		body: new URLSearchParams({
			codSerie: series,
			numPagina: page
		})
	});
	return await res.text();
};

const getId = ($) => {
	const id = $.find('td[data-th="Descargas"] div:nth-child(2) a[title="Descargar"]').attr('id');
	return id.split('_')[1];
};

const getAttribute = ($, attribute) => {
	return $.find(`td[data-th="${attribute}"] div:nth-child(2)`).text().trim();
};

const scrape = async (series) => {
	let page = 1;
	const maxRetries = 5;
	const delayMs = 1000;
	const results = [];

	while (true) {
		let retries = 0;
		let success = false;
		let html;

		while (retries < maxRetries && !success) {
			try {
				html = await fetchTable(series, page);
				success = true;
			} catch (error) {
				retries++;
				console.log(`Retry ${retries}/${maxRetries} after error: ${error.message}`);
				await delay(delayMs * Math.pow(2, retries));
			}
		}

		if (!success) {
			console.log(`Failed to fetch page ${page} after ${maxRetries} retries.`);
			break;
		}

		const $ = cheerio.load(html);
		const rows = $('table tbody tr');

		const lastPage = $('a[aria-label="Última"]').length === 0;
		const pages = lastPage ? page : $('a[aria-label="Última"]').attr('id').split('_')[1];
		console.log(`Scraping page ${page} of ${pages}… (${Math.floor((page / pages) * 100)}%)`);

		rows.each((index, row) => {
			const columns = $(row).find('td');
			const download_id = getId($(columns));
			const filename = getAttribute($(columns), 'Nombre');
			const format = getAttribute($(columns), 'Formato');
			const date = getAttribute($(columns), 'Fecha');
			const size = getAttribute($(columns), 'Tamaño (MB)');

			results.push({ download_id, filename, format, series, date, size });
		});

		if (lastPage) {
			break;
		}

		page++;
	}

	return results;
};

const main = async ({ filename, series }) => {
	console.log('Starting scrape:', filename, series);
	const data = await scrape(series);
	fs.writeFileSync(`./data/input-data/${filename}.csv`, csvFormat(data));
	console.log('Scrape complete:', filename, series);
};

try {
	// be patient, this takes a while
	await main({ filename: 'MDT02_COB2', series: 'MDT02' });
	await main({ filename: 'MDT05_COB1', series: 'MDT05' });
	await main({ filename: 'MDT25_COB1', series: '02107' });

	await main({ filename: 'MDT25_COB2', series: 'T25C2' });
	await main({ filename: 'MDT200_COB1', series: '02109' });
	await main({ filename: 'MDT200_COB2', series: 'T2002' });
} catch (error) {
	console.error(error);
}
