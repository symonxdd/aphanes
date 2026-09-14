# webOS Dev Mode Manager for desktop

The desktop counterpart of the mobile app at the repository root. Started
in September 2026; nothing is built beyond the scaffold yet.

Same purpose as mobile: manage a paired LG webOS TV in developer mode, or
with Homebrew Channel installed, without the UX problems of the existing
desktop tool. The mobile app's feature set is the target: pair a TV,
install and uninstall homebrew apps and IPKs, show device details and the
Developer Mode session's remaining time. An SFTP file browser and an SSH
terminal are not planned for desktop either; neither is ruled out.

Unaffiliated with LG Electronics Inc. or the webOS Open Source Edition
project.

## Layout

```
desktop/
  Cargo.toml                 Cargo workspace (both Rust crates, shared deps, release profile)
  package.json               npm scripts: dev, build, typecheck, tauri
  index.html, src/           React 19 + TypeScript (strict) frontend, built by Vite
  src-tauri/                 Tauri 2 shell: window config, capabilities, icons, thin commands
  crates/aphanes-protocol/   Pure Rust protocol layer on russh; no Tauri types in it
```

The protocol crate is the boundary that matters. Everything that talks to
a TV (pairing, SSH, luna calls, IPK install) lives there and knows nothing
about windows, events or the frontend. Tauri commands in `src-tauri` call
into it and return. The mobile app keeps its own Dart SSH layer; the two
share no code.

## Building

Needs Rust (stable), Node 22 and the platform prerequisites Tauri lists at
https://tauri.app/start/prerequisites/ (on Windows: the MSVC build tools
and WebView2). No NASM, CMake or Perl: russh is built on the `ring`
backend, which needs none of them.

```
npm install
npm run tauri dev      # run with hot reload
npm run tauri build    # produce installers under target/release/bundle
```

Four checks are expected to pass before every commit:
`npm run typecheck`, `npm run format:check` (Prettier, 120 columns),
`cargo clippy --workspace --all-targets -- -D warnings` and
`cargo fmt --all --check`.

## References

The webOS protocol details come from webosbrew's
[ares-cli-rs](https://github.com/webosbrew/ares-cli-rs) (Apache-2.0),
read as a reference and never linked, and from
[dev-manager-desktop](https://github.com/webosbrew/dev-manager-desktop)
(Apache-2.0) for the Developer Mode session check. Neither's UI is
carried over.
