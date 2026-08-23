# webOS Dev Mode Manager

> Unaffiliated with LG Electronics Inc. or the webOS Open Source Edition
> project.

A mobile-first manager for LG webOS smart TVs in Developer Mode or with
Homebrew Channel installed. Pair a TV from a phone, install and uninstall
homebrew apps on it, and see what firmware, webOS release and Developer
Mode session it is running.

## Screenshots

| Devices | Devices, OLED | Device detail | Apps | Catalog |
|:--:|:--:|:--:|:--:|:--:|
| <img src="docs/screenshots/main-screen.jpg" width="160" alt="Devices tab listing a paired TV"> | <img src="docs/screenshots/main-screen-oled.jpg" width="160" alt="Devices tab in the OLED theme"> | <img src="docs/screenshots/device-detail-screen.jpg" width="160" alt="Device detail page"> | <img src="docs/screenshots/apps-screen.jpg" width="160" alt="Apps installed on the TV"> | <img src="docs/screenshots/homebrew-catalog-list.jpg" width="160" alt="Browsing the Homebrew catalog"> |

| Install an app | Pair a device | Field explainer | Title card |
|:--:|:--:|:--:|:--:|
| <img src="docs/screenshots/install-an-app-sheet.jpg" width="160" alt="Choosing an install source"> | <img src="docs/screenshots/pair-a-device-screen.jpg" width="160" alt="Pairing screen"> | <img src="docs/screenshots/ip-address-explainer-sheet.jpg" width="160" alt="Explainer sheet for the IP address field"> | <img src="docs/screenshots/cinematic-splashscreen.jpg" width="160" alt="Full screen app title card"> |

| First run | First run, OLED | Settings | About |
|:--:|:--:|:--:|:--:|
| <img src="docs/screenshots/onboarding.jpg" width="160" alt="First run screen"> | <img src="docs/screenshots/onboarding-dark-oled.jpg" width="160" alt="First run screen in the OLED theme"> | <img src="docs/screenshots/settings-screen.jpg" width="160" alt="Settings sheet"> | <img src="docs/screenshots/about-screen.jpg" width="160" alt="About sheet"> |

## Why it exists

This exists to fix the mobile experience of the community's
[dev-manager-desktop](https://github.com/webosbrew/dev-manager-desktop),
which is desktop-first: content draws under the system status and
navigation bars on a phone, the bottom navigation is icon-only with no
labels, and deleting a paired device is hard to find.

## Status

Early development. Mobile only (Android first) for now; a desktop
counterpart is planned for later and lives as an empty placeholder in
[/desktop](desktop).

Working today: pairing a TV from its Developer Mode passphrase, keeping
several paired TVs and switching between them, installing and
uninstalling apps from the public Homebrew catalog or from an .ipk file
on the phone, and a device detail page covering model, firmware, webOS
release, SoC, OTA ID and the Developer Mode session, including renewing
it.

Not built yet: browsing the TV's filesystem over SFTP, and an SSH
terminal. Each has a tab reserved in the app, hidden by default and
switchable on in settings, where it says as much. Neither is ruled out;
opening an issue is the way to ask for one.

## Documentation

The full docs site is at **[symonxdd.github.io/aphanes](https://symonxdd.github.io/aphanes/)**, or browse the same content directly in [docs/](docs/):

- [docs/README.md](docs/README.md): project overview and current status
- [docs/concepts.md](docs/concepts.md): plain-language explanations of every technology involved (Developer Mode, SSH, the luna bus, IPK packages, OTA IDs), plus a glossary
- [docs/architecture.md](docs/architecture.md): tech stack, folder structure, and the reasoning behind each decision
- [docs/pairing.md](docs/pairing.md): how the Developer Mode key exchange actually works, and what is deliberately not verified

## Getting started

This is a standard Flutter project.

```
flutter pub get
flutter run
```

## Privacy and safety

- Managing a TV happens directly between this app and that TV on the
  local network. No third-party server sits in that path, and device
  lists, files, and credentials never leave the phone. None of it is
  synced to a cloud anywhere.
- Device credentials are stored via secure platform storage, never in
  plaintext, never logged.
- No telemetry, analytics, or crash reporting without an explicit,
  separate opt-in.
- Every TV-modifying action (install, uninstall, file write/delete,
  terminal command) happens only when directly triggered.

Three things reach the internet, each only when opened or used:

- **Browsing the Homebrew app catalog** reads the public listing at
  repo.webosbrew.org, and loads package icons from there. Nothing about
  the phone or its paired TVs is sent.
- **Installing from that catalog** downloads the package from wherever
  the catalog points, which today is GitHub for nearly every entry. Each
  download is verified against the catalog's published SHA-256 and
  refused on a mismatch.
- **The Developer Mode remaining-time check**, on a device's detail page,
  asks developer.lge.com, sending the session token read from that TV.
  It is the only request that transmits anything, and there is no
  local-only way to obtain that number. Renewing a session does not use
  it: renewing only tells the TV to open its own Developer Mode app.

## Credits

The webOS devmode pairing protocol (the TV's key server and its key
exchange) is implemented from scratch here, informed by reading the
community's [dev-manager-desktop](https://github.com/webosbrew/dev-manager-desktop)
and [ares-cli-rs](https://github.com/webosbrew/ares-cli-rs) projects
(both Apache-2.0), not copied from their source.
