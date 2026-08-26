// Copies /docs/screenshots into public/screens before dev and build.
//
// Next refuses to import modules from outside its own project root, so
// the site cannot reach up into /docs/screenshots directly. Copying at
// build time keeps one source of truth: the same files the README shows,
// with nothing duplicated in git (public/screens is ignored).
import { cp, mkdir, readdir, access } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const source = join(here, '..', '..', 'screenshots');
const target = join(here, '..', 'public', 'screens');

try {
  await access(source);
} catch {
  // On Vercel this means the deployment only checked out the root
  // directory. Said plainly, because the alternative is a stack trace
  // about a path nobody recognises.
  console.error(`sync-screenshots: cannot find ${source}`);
  console.error(
    'If this is a Vercel build, turn on "Include source files outside of ' +
      'the Root Directory in the Build Step" under Settings, Build and ' +
      'Deployment, Root Directory.',
  );
  process.exit(1);
}

await mkdir(target, { recursive: true });
await cp(source, target, { recursive: true });

const copied = await readdir(target);
console.log(`sync-screenshots: ${copied.length} files into public/screens`);
