---
title: Architecture
description: Tech stack, folder structure, state management, theming, and the reasoning behind each decision in webOS Dev Mode Manager.
---

This page covers *decisions*: what was chosen and why. For explanations of the technologies themselves, see [concepts.md](concepts.md).

## Tech stack

- **Flutter**, Material 3, Android first. iOS is undecided; no platform-specific choice has been made that would foreclose it.
- **Riverpod** (`flutter_riverpod`) for state, chosen in the first milestone and used consistently since. Business logic lives in providers and services, not in widgets, so it can be tested without pumping a widget tree.
- **`dartssh2`** for SSH and SFTP. Pure Dart, so there is no native library to build per platform, and it covers both the command channel and file upload the app needs.
- **`flutter_secure_storage`** for anything credential-shaped, backed by the platform keystore.
- **`shared_preferences`** for ordinary settings that are not secrets.
- **`pointycastle`** and **`asn1lib`** for decrypting the TV's key during pairing, which needs OpenSSL's legacy `EVP_BytesToKey` derivation and AES-CBC against a PEM format no higher-level Dart package handles.
- **`http`** and **`crypto`** for the Homebrew catalog fetch and its integrity check.
- **`file_picker`** for choosing a local `.ipk`.
- **`url_launcher`** for handing links to the system browser.
- **`lucide_icons_flutter`** for the device detail page's field icons.
- **`flutter_colorpicker`** for the accent color setting.

Every third-party package was checked on pub.dev for maintenance recency, popularity and open issues before being added, with the reasoning recorded in the commit that introduced it.

## Folder structure

Feature-first, not layer-first. Everything belonging to one feature sits together, so a feature can be read or removed without hunting across the tree.

```
lib/
  core/                  shared across features, owns nothing product-specific
    persistence/         secure storage and prefs seams
    ssh/                 SSH connection, luna bus calls, legacy key support
    theme/               light, dark and OLED themes
    ui/                  widgets reused by more than one feature
    validation/          input validation shared by forms
  features/
    apps/                install, uninstall, Homebrew catalog
    devices/             pairing, device list, reachability, detail page
    files/               placeholder tab
    home/                the shell: app bar, tabs, page view
    onboarding/          first-run screens
    settings/            theme, accent color, tab visibility, about
    terminal/            placeholder tab
```

Each feature subdivides the same way:

| Folder | Holds |
|---|---|
| `models/` | Plain data classes, no Flutter imports |
| `services/` | Everything that talks to the outside world |
| `state/` | Riverpod providers and controllers |
| `ui/` | Screens, and a `widgets/` folder for their parts |

`core/` never imports from `features/`. Features may import from `core/`, and a feature may import another feature's providers where that dependency is real (the Apps tab genuinely depends on which device is active).

## Talking to a TV

Three layers, each with one job:

**`SshConnectionService`** opens an authenticated connection and nothing else. It also carries the fallback for older TVs whose SSH implementation predates modern signature algorithms and needs `ssh-rsa` explicitly offered.

**`LunaCommandService`** sends one luna message and parses one JSON reply, including the subscription case where a call reports progress across several messages. It lives in `core/ssh/` rather than under the apps feature, because devices need it too.

**Feature services** (`AppsService`, `DeviceDetailService`, `DevmodePairingService`) compose those two into real operations. They own the knowledge of which luna address does what, and translate failures into messages worth showing.

Every one of these opens a connection, does its work, and closes it. There is no long-lived shared connection. That matches how the app is actually used, in short bursts triggered by a tap, and it means no state to invalidate when a TV goes away mid-session.

### Failing fast

A full SSH connect and authenticate has a long timeout, appropriate for a deliberate action. Landing on a tab is not a deliberate action, and waiting out that timeout on a TV that is simply switched off is a poor experience.

So a **reachability probe** gates the slow paths: a raw TCP connect to the SSH port with a three second timeout, no handshake. `deviceReachabilityProvider` is an `autoDispose` family keyed by device id, deliberately not a background poller. Leaving and returning to a screen rechecks it, and so does a pull to refresh; nothing polls a TV nobody is looking at.

Because the Apps tab, the Devices tab and the device detail page all watch the same provider, invalidating the family in one place brings all of them back in line at once.

## Caching what does not change

Model, firmware, webOS release, SoC and OTA ID do not change without a firmware update. Re-fetching them on every visit to the device detail page and showing a spinner while it happens is work with no payoff.

`DeviceInfoCacheController` keeps them in memory, backed by secure storage, keyed by device id. Opening a TV's page shows the stored copy immediately while a fresh fetch runs behind it, and a successful fetch writes through. A fetch that returns exactly what is stored skips both the write and the rebuild.

The Developer Mode session is deliberately excluded. It is a countdown, so a stored "3 hours remaining" would be actively wrong the next day rather than merely stale, and it is a credential besides. It is re-read on every visit and says so while it does.

The cache lives in secure storage alongside the device records rather than in plain preferences. None of those fields is a secret on its own, but they are keyed by device id, and splitting one device's data across two stores by field is worse than keeping it together.

## Storing credentials

Device records, private keys included, are persisted entirely through the platform keystore via `DeviceStorageService`. Never plaintext preferences, never logged, never committed.

`SecureKeyValueStore` exists as a one-interface seam over `flutter_secure_storage` so services depending on it can be tested against an in-memory fake. The real implementation has no platform-channel handler under `flutter test` and hangs rather than failing, so without the seam those tests could not run at all.

## Theming

Three themes derived from one seed color: light, dark, and OLED.

Light and dark both define an explicit surface ladder rather than leaning on `ColorScheme.fromSeed`'s defaults. That is deliberate: mixing the two theming models meant switching between light and dark was not an interpolated color change but a flip between flat explicit colors on one side and Material 3's tonal-elevation tint on the other, which read as a glitch rather than a transition.

OLED is the dark palette with every surface forced to true black and `surfaceTint` zeroed. Zeroing that single value is what stops the accent wash on cards, sheets and dialogs, rather than patching each widget's theme individually. It is on by default, but it is only ever read once the resolved theme is already dark, so a phone in light mode is unaffected and never switched on its account.

The accent color is user-selectable and everything derives from it.

## The shell

`HomePage` owns an app bar, a `PageView` and a `NavigationBar`, with tabs kept alive so switching does not rebuild them. Files and Terminal are hidden by default and switchable on in settings; a tab disappearing while the user is on it falls back to Devices rather than leaving the selection pointing at nothing.

Both tap and swipe drive the same selection. A guard stops `onPageChanged` from rewriting the selected tab during a tap-driven animation, which would otherwise flicker the title and the nav highlight through every tab in between.

### System insets

Every screen respects the status bar, navigation bar and display cutouts. This is the highest UX bar the project holds itself to, because content drawing under system bars on a phone is one of the specific problems this rewrite exists to fix. The app runs edge to edge with the system bars styled to match the current surface.

## Every outbound request

Managing a TV happens directly between the app and the TV. The complete list of everything else the app contacts, each only when the screen or action needing it is used:

| Destination | For | Sends |
|---|---|---|
| The paired TV | Everything the app does to a TV. SSH on 9922, key server on 9991 during pairing | The user's own data, to their own device |
| `repo.webosbrew.org` | The Homebrew catalog listing and package icons | Nothing about the user |
| Whatever host a catalog entry names | That package's `.ipk` download | Nothing about the user |
| `developer.lge.com` | The Developer Mode remaining-time check | The session token read from the TV |

Only the LG session check sends any data, and what it sends is the session token read from the TV. It is there only because there is no local way to learn how long a session has left. Adding a destination beyond this list is a change to a project constraint, not an implementation detail.

There is no telemetry, no analytics, no crash reporting, and no auto-update mechanism that fetches and runs remote code.

## Testing

Tests cover the parts where being wrong is expensive and a widget tree is not needed: the pairing handshake and its PEM decryption, catalog parsing and integrity checking, luna reply parsing, the info cache and its write-through, and the legacy SSH identity.

Widget tests cover behavior that is easy to regress by accident rather than layout: that a previously opened TV shows its details with no spinner, that a first visit still shows one, that an unreachable TV with stored facts skips the notice, and that an info sheet with no expandable section disposes cleanly.

Nothing in the suite touches a real TV or the network.
