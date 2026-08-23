---
title: webOS Dev Mode Manager
description: Documentation for webOS Dev Mode Manager, a mobile-first Android app for managing LG webOS TVs in Developer Mode.
---

> Unaffiliated with LG Electronics Inc. or the webOS Open Source Edition
> project.

**webOS Dev Mode Manager** is a mobile-first Android app for managing an LG webOS TV that has Developer Mode enabled. It pairs with a TV over the local network, installs and uninstalls homebrew apps on it, and reports what hardware and firmware that TV is running.

The repository and the codebase use the codename **Aphanes**, from the Ancient Greek ἀφανής, meaning unseen or not manifest. The shipped app presents itself as webOS Dev Mode Manager everywhere a person looks.

## Why it exists

The community already has an excellent tool for this: [dev-manager-desktop](https://github.com/webosbrew/dev-manager-desktop). It is desktop-first, and it shows on a phone. Content draws underneath the system status and navigation bars, the bottom navigation is icon-only with no labels, and removing a paired device is hard to find.

This project is a rewrite that treats the phone as the primary target rather than an afterthought. Its protocol work is informed by reading dev-manager-desktop and [ares-cli-rs](https://github.com/webosbrew/ares-cli-rs), both Apache-2.0, but none of their UI or UX is carried over. That inadequate mobile experience is the entire reason this exists.

## What works today

- **Pairing.** Trade the six-character passphrase shown in the TV's own Developer Mode app for a permanent SSH key, then reconnect with that key from then on. See [pairing.md](pairing.md) for how that exchange actually works.
- **Several paired TVs.** Keep more than one, switch which is active, rename them, correct an address that changed, remove one.
- **Reachability.** A fast probe reports whether each TV is answering, rechecked by pulling to refresh, and shared across every screen that cares.
- **Apps.** List what is installed, uninstall with confirmation, and install either from the public Homebrew catalog or from an `.ipk` file already on the phone. Catalog downloads are checked against their published SHA-256 before anything is installed.
- **Device details.** Model, firmware, webOS release, SoC and OTA ID, plus the current Developer Mode session and a renew action for it. Every field has an explainer.

## What is not built

Browsing the TV's filesystem over SFTP, and an SSH terminal. Both were in the original scope and both were set aside in favour of the device detail page. Each keeps a tab reserved in the app, hidden by default and switchable on in settings, where it says as much. Neither is ruled out.

## Where to go next

- [concepts.md](concepts.md) explains every piece of technology involved, in plain language, with a glossary. Start here if terms like luna bus, IPK or Developer Mode session are unfamiliar.
- [architecture.md](architecture.md) covers the tech stack, folder structure, state management and the reasoning behind each decision.
- [pairing.md](pairing.md) walks through the Developer Mode key exchange in detail, including what is verified and what deliberately is not.

## Privacy

Managing a TV happens directly between the app and that TV on the local network, with no third party in that path. Device lists, files and credentials never leave the phone, and none of it is synced anywhere. There is no telemetry.

Three features do reach the internet, each only when opened or used: the Homebrew catalog listing, package downloads, and the Developer Mode remaining-time check. [architecture.md](architecture.md#every-outbound-request) lists all of them, including the one that transmits anything.
