# webOS Dev Mode Manager docs site

This is a [Starlight](https://starlight.astro.build/) (Astro) site that turns the Markdown files in [/docs](../docs/) into a browsable documentation website, published at https://symonxdd.github.io/aphanes/.

## What are Astro and Starlight?

- **[Astro](https://astro.build/)** is a web framework for content-focused websites. It handles routing, the dev server, and building everything down to static HTML/CSS with minimal JS.
- **[Starlight](https://starlight.astro.build/)** is an official Astro integration: a docs site in a box. It is added as a dependency (`@astrojs/starlight`) and registered in [astro.config.mjs](astro.config.mjs)'s `integrations` array, and it supplies the whole docs UI for free (sidebar, search, theme toggle, previous/next links, table of contents), so all that is left is Markdown content and a sidebar config.

Astro is the general-purpose framework; Starlight is the docs layer on top of it.

## How it is wired up

There is no second copy of the docs. [src/content.config.ts](src/content.config.ts) points Starlight's content loader straight at `../docs`, so every `.md` file in the repo's `docs/` folder becomes a page:

| File in `/docs` | Page |
|---|---|
| `README.md` | `/` (home page) |
| `concepts.md` | `/concepts/` |
| `architecture.md` | `/architecture/` |
| `pairing.md` | `/pairing/` |

Adding a page means adding a Markdown file to `/docs` with `title` and `description` frontmatter, then adding an entry to the `sidebar` array in [astro.config.mjs](astro.config.mjs).

### Links that work in both places

Files in `/docs` link to each other with plain relative filenames (`architecture.md`), which is what GitHub needs to render a working link when browsing the repo. Those are not the site's URLs, so [src/remark-doc-links.mjs](src/remark-doc-links.mjs) rewrites them to the matching Starlight route at build time, carrying any `#fragment` across unchanged.

Write links the GitHub way and they work in both places.

### Screenshots

Images live in [/docs/screenshots](../docs/screenshots/) so the same files serve the root README and any docs page that wants them. Astro processes and optimises images referenced relatively from Markdown, which is what `sharp` is a dependency for.

## Running it locally

```
npm install
npm run dev
```

Then open the URL it prints. `npm run build` produces the static site in `dist/`, and `npm run preview` serves that build.

## Deployment

[.github/workflows/deploy-docs.yml](../.github/workflows/deploy-docs.yml) builds and publishes to GitHub Pages on every push to `main` that touches `docs/`, `docs-site/`, or the workflow itself. It can also be run manually from the Actions tab.

The repository needs **Settings, Pages, Source: GitHub Actions** enabled once before the first deploy will publish.
