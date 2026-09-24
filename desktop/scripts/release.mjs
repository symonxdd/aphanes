// Makes a desktop release: bump the version, commit it, tag it, push.
//
// Run with `npm run release` from desktop/. Pushing the desktop-vx.y.z tag
// is what starts .github/workflows/release-desktop.yml, which builds the
// signed Windows installer and creates the GitHub release; nothing is
// built locally.
//
// The desktop app is versioned apart from the Android app, which has its
// own release command (tool/release.dart at the repository root), its own
// changelog and plain vx.y.z tags.
import { execFileSync } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import prompts from "prompts";

const CHANGELOG = "CHANGELOG.md";

/**
 * Every place the version lives. They must always agree: tauri.conf.json
 * is the one the installer and the updater read, and the rest are what
 * npm and Cargo read. Each pattern captures the text before the version
 * and the text after it, and is expected to match an exact number of
 * times, so a file whose layout changed stops the release instead of
 * being half updated.
 */
const SITES = [
  { path: "package.json", pattern: /^( {2}"version": ")([^"]+)(")/m, count: 1 },
  { path: "package-lock.json", pattern: /^( {2}"version": ")([^"]+)(")/m, count: 1 },
  { path: "package-lock.json", pattern: /("": \{\s*"name": "aphanes-desktop",\s*"version": ")([^"]+)(")/, count: 1 },
  { path: "src-tauri/tauri.conf.json", pattern: /^( {2}"version": ")([^"]+)(")/m, count: 1 },
  { path: "Cargo.toml", pattern: /^(version = ")([^"]+)(")/m, count: 1 },
  { path: "Cargo.lock", pattern: /(name = "aphanes-(?:desktop|protocol)"\r?\nversion = ")([^"]+)(")/g, count: 2 },
];

function fail(message) {
  console.error(message);
  process.exit(1);
}

function git(...args) {
  console.log(`$ git ${args.join(" ")}`);
  execFileSync("git", args, { stdio: "inherit" });
}

function bump(version, kind) {
  const [major, minor, patch] = version.split(".").map(Number);
  if (kind === "major") return `${major + 1}.0.0`;
  if (kind === "minor") return `${major}.${minor + 1}.0`;
  return `${major}.${minor}.${patch + 1}`;
}

/** Checks every site first, then writes, so a mismatch changes nothing. */
function writeVersion(current, next) {
  const files = new Map();
  for (const { path } of SITES) files.set(path, files.get(path) ?? readFileSync(path, "utf8"));

  for (const { path, pattern, count } of SITES) {
    const global = new RegExp(pattern.source, pattern.flags.includes("g") ? pattern.flags : pattern.flags + "g");
    const found = [...files.get(path).matchAll(global)].map((m) => m[2]);
    if (found.length !== count || found.some((v) => v !== current)) {
      fail(
        `${path}: expected ${count} version entries at ${current}, found ${found.join(", ") || "none"}. Nothing was changed.`,
      );
    }
    files.set(
      path,
      files.get(path).replace(global, (_, before, __, after) => `${before}${next}${after}`),
    );
  }

  for (const [path, text] of files) {
    writeFileSync(path, text);
    console.log(`Updated ${path}`);
  }
  return [...files.keys()];
}

if (!existsSync("src-tauri/tauri.conf.json")) fail("Run this from desktop/, with `npm run release`.");

// A dirty tree would get swept into the version commit, which is meant
// to contain only the version bump.
const dirty = execFileSync("git", ["status", "--porcelain"], { encoding: "utf8" }).trim();
if (dirty) fail(`Working tree is not clean:\n${dirty}\n\nCommit or stash first, then release.`);

const current = JSON.parse(readFileSync("package.json", "utf8")).version;
console.log(`Current desktop version: ${current}\n`);

// The same arrow-key menu as DS4 Dashboard's release script. Escape or
// Ctrl+C leaves it with nothing chosen, which cancels.
const { kind } = await prompts({
  type: "select",
  name: "kind",
  message: "What type of release is this?",
  choices: [
    { title: "Patch", description: `${current} -> ${bump(current, "patch")}, a fix`, value: "patch" },
    { title: "Minor", description: `${current} -> ${bump(current, "minor")}, a new feature`, value: "minor" },
    { title: "Major", description: `${current} -> ${bump(current, "major")}, a breaking change`, value: "major" },
  ],
});
if (!kind) fail("Release cancelled. Nothing was changed.");
const next = bump(current, kind);
const tag = `desktop-v${next}`;

// The release notes are this version's own section of the changelog, so
// without one the workflow would publish a release saying nothing. It
// checks this too, but stopping here costs a moment instead of a build.
const heading = `## v${next}`;
if (
  !readFileSync(CHANGELOG, "utf8")
    .split(/\r?\n/)
    .some((line) => line.trimEnd() === heading)
) {
  fail(`${CHANGELOG} has no "${heading}" section.\nWrite this version's entry before releasing it.`);
}

const changed = writeVersion(current, next);
git("add", ...changed);
git("commit", "-m", `chore(release): bump desktop to ${next}`);
git("tag", tag);
git("push");
git("push", "origin", tag);

console.log(`\nReleased ${tag}.`);
console.log("The build runs at https://github.com/symonxdd/aphanes/actions");
