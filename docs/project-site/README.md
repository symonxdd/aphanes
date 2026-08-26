# webOS Dev Mode Manager project site

The marketing site for the app: what it does, why it exists, what it
looks like, and where to download it. Built with
[Next.js](https://nextjs.org/) and [Tailwind](https://tailwindcss.com/),
deployed on Vercel.

Not to be confused with [/docs-site](../../docs-site/), which is the
Starlight documentation site built from the Markdown in [/docs](../).
This one is the front page; that one is the manual.

## Running it locally

```
npm install
npm run dev
```

`npm run build` produces a production build, and `npm run start` serves
it.

## How it is put together

| Path | What it holds |
|---|---|
| `src/app/layout.js` | The shell, and the theme provider |
| `src/app/page.js` | The section order, and nothing else |
| `src/components/` | One file per section, plus the header and theme toggle |
| `src/hooks/useLatestRelease.js` | The GitHub release the download button points at |

### The theme

[next-themes](https://github.com/pacocoursey/next-themes) with
`attribute="class"`, so a `.dark` class on `<html>` is the only switch,
and every colour is a CSS variable defined twice in
[globals.css](src/app/globals.css).

`disableTransitionOnChange` is what makes the swap instant. Without it
every themed colour animates on its own schedule and the page appears to
melt between states rather than change. The provider also writes the
class in a blocking script before React hydrates, which is why there is
no flash of the wrong theme on load.

Components that read the resolved theme render a neutral placeholder
until they have mounted. The server cannot know what the browser will
resolve to, so anything else guarantees a hydration mismatch.

### The hero stays dark

The hero is `--void` in both themes, on purpose: the app's own title card
fades to black regardless of theme, and the site opens the same way. The
header notices when it is floating over that band and borrows light
colours until it clears it.

### Screenshots

The screenshots live in [/docs/screenshots](../screenshots/), the same
files the repository README shows.
[scripts/sync-screenshots.mjs](scripts/sync-screenshots.mjs) copies them
into `public/screens` before every dev run and build, because Next
refuses to import modules from outside its own project root. The copy is
gitignored, so there is one source of truth and nothing duplicated in
version control.

## Deployment

Vercel, from this subdirectory. In the project settings the **root
directory** must be `docs/project-site`; everything else is Next.js
defaults. Pushes to `main` deploy automatically.

GitHub Pages serves the documentation site instead, at
<https://symonxdd.github.io/aphanes/>.
