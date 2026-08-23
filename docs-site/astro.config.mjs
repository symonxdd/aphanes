// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { remarkDocLinks } from './src/remark-doc-links.mjs';

// https://astro.build/config
export default defineConfig({
	// GitHub Pages serves project sites from https://<user>.github.io/<repo>/
	site: 'https://symonxdd.github.io',
	base: '/aphanes',
	markdown: {
		remarkPlugins: [remarkDocLinks],
	},
	integrations: [
		starlight({
			// The shipped name, not the Aphanes codename: this site is a
			// user-facing surface.
			title: 'webOS Dev Mode Manager',
			social: [
				{ icon: 'github', label: 'GitHub', href: 'https://github.com/symonxdd/aphanes' },
			],
			sidebar: [
				{ label: 'Overview', link: '/' },
				{ label: 'How It Works', link: '/concepts/' },
				{ label: 'Architecture', link: '/architecture/' },
				{ label: 'Pairing', link: '/pairing/' },
			],
		}),
	],
});
