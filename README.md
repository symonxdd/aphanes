# webOS Dev Mode Manager

> Unaffiliated with LG Electronics Inc. or the webOS Open Source Edition
> project.

A mobile-first Android app for LG webOS TVs in Developer Mode. Pair a TV
from a phone, install homebrew apps on it, and keep track of how long the
Developer Mode session has left.

- **Website**: [aphanes-app.vercel.app](https://aphanes-app.vercel.app)
- **Download**: [the latest APK](https://github.com/symonxdd/aphanes/releases/latest)
- **Technical documentation**: [symonxdd.github.io/aphanes](https://symonxdd.github.io/aphanes/)

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

The Android app is feature complete for what it set out to do. Working
today:

- Pair a TV, keep several, and switch between them
- Install apps from the Homebrew catalog or from a local .ipk
- See a TV's hardware and firmware, and how long its Developer Mode
  session has left
- Renew that session without leaving the couch

Not built: an SFTP file browser and an SSH terminal. Both have a tab
reserved, hidden by default, and neither is ruled out.

A desktop counterpart is planned and lives as an empty placeholder in
[/desktop](desktop).

## Technical documentation

How the app is built and how the webOS side of it works.

The full site is at **[symonxdd.github.io/aphanes](https://symonxdd.github.io/aphanes/)**, or browse the same content directly in [docs/](docs/):

- [docs/README.md](docs/README.md): project overview and current status
- [docs/concepts.md](docs/concepts.md): plain-language explanations of every technology involved (Developer Mode, SSH, the luna bus, IPK packages, OTA IDs), plus a glossary
- [docs/architecture.md](docs/architecture.md): tech stack, folder structure, and the reasoning behind each decision
- [docs/pairing.md](docs/pairing.md): how the Developer Mode key exchange actually works, and the security choices behind it

## Getting started

This is a standard Flutter project.

```
flutter pub get
flutter run
```

## Releasing

A release takes two steps: the changelog entry, then the release itself.

### 1. The changelog entry

[CHANGELOG.md](CHANGELOG.md) holds one section per version, newest
first. The version being released needs its section written before it is
tagged. Only changes to the app belong there; documentation and website
work does not.

### 2. Publishing the release

```
dart run tool/release.dart
```

It refuses to run on a dirty working tree, or when CHANGELOG.md has no
section for the version being released, then:

1. Asks whether this is a patch, minor or major release, and shows the
   exact version it would move to
2. Bumps `version:` in [pubspec.yaml](pubspec.yaml), including the build
   number after the `+`, which Android requires to increase every time
3. Commits that one line as `chore(release): bump version to x.y.z`
4. Tags it `vx.y.z` and pushes the commit and the tag

Pushing the tag is what starts
[release.yml](.github/workflows/release.yml), which:

- Runs `flutter analyze` and `flutter test`, and stops if either fails
- Builds an arm64 release APK and signs it with the release key, which is
  kept in this repository's own Actions secrets and described under
  [Signing](#signing) below
- Publishes a GitHub release titled `Aphanes vx.y.z`, with
  `aphanes-vx.y.z.apk` attached and notes taken from that version's
  section of [CHANGELOG.md](CHANGELOG.md)

Progress shows under the repository's Actions tab.

### Signing

Release builds are signed from `android/key.properties` locally, or from
`ANDROID_KEYSTORE_*` repository secrets in CI. Neither is in the
repository. Without either, a release build falls back to the debug key
so it still compiles for anyone without the keystore; the workflow
checks the keystore arrived before it builds, so a release can never be
published that way.

## Privacy

- 📺 Talks straight to the TV, over the local network
- 🔐 Pairing keys stay in the phone's keystore, via
  [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- ☁️ No account, no sync, no telemetry
- 🌐 Three things reach the internet: the Homebrew catalog, app
  downloads, and the Developer Mode time check

The [project site](https://aphanes-app.vercel.app/#privacy) covers those
three in detail.

## Credits

The webOS devmode pairing protocol (the TV's key server and its key
exchange) is implemented here, informed by reading the
community's [dev-manager-desktop](https://github.com/webosbrew/dev-manager-desktop)
and [ares-cli-rs](https://github.com/webosbrew/ares-cli-rs) projects
(both Apache-2.0).
