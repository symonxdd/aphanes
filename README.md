# webOS Dev Mode Manager

> Unaffiliated with LG Electronics Inc. or the webOS Open Source Edition
> project.

A mobile-first manager for LG webOS smart TVs in Developer Mode or with
Homebrew Channel installed. Install and uninstall homebrew apps and IPKs,
browse the TV's filesystem over SFTP, and run a terminal session over SSH,
all from a phone.

This exists to fix the mobile experience of the community's
[dev-manager-desktop](https://github.com/webosbrew/dev-manager-desktop),
which is desktop-first: content draws under the system status and
navigation bars on a phone, the bottom navigation is icon-only with no
labels, and deleting a paired device is hard to find.

## Status

Early development. Mobile only (Android first) for now; a desktop
counterpart is planned for later and lives as an empty placeholder in
[/desktop](desktop).

## Getting started

This is a standard Flutter project.

```
flutter pub get
flutter run
```

## Privacy and safety

- Talks directly to paired TV(s) on the local network only. No
  third-party server in the data path, no cloud sync of device lists,
  files, or credentials.
- Device credentials are stored via secure platform storage, never in
  plaintext, never logged.
- No telemetry, analytics, or crash reporting without an explicit,
  separate opt-in.
- Every TV-modifying action (install, uninstall, file write/delete,
  terminal command) happens only when directly triggered.

## Credits

The webOS devmode pairing protocol (the TV's key server and its key
exchange) is implemented from scratch here, informed by reading the
community's [dev-manager-desktop](https://github.com/webosbrew/dev-manager-desktop)
and [ares-cli-rs](https://github.com/webosbrew/ares-cli-rs) projects
(both Apache-2.0), not copied from their source.
