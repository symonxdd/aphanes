---
title: How it works
description: A plain-language walkthrough of every technology and term behind webOS Dev Mode Manager, from Developer Mode and the luna bus to IPK packages and OTA IDs.
---

This page explains every piece of technology the app touches, in plain language, including why things are named what they are when that is not obvious. [architecture.md](architecture.md) documents *decisions* (which package was chosen and why); this page documents *concepts* (what a luna bus even is). Skip to the [glossary](#glossary) for quick lookups, or read top to bottom.

## The big picture

An LG TV runs an operating system called webOS. Normally it will only run apps that came from LG's own store. Turning on **Developer Mode** relaxes that, and in doing so opens a small door on the TV: an SSH server.

From there, everything this app does is one of two things:

1. **Running a command on the TV.** Installing an app, uninstalling one, reading the firmware version. These are ordinary commands, sent over SSH, the same way a developer would type them into a terminal.
2. **Sending a file to the TV.** Installing an app means uploading an `.ipk` package and then telling the TV to install it.

There is no cloud service in the middle. The phone talks to the TV directly, at an address on the home network.

## Developer Mode

Developer Mode is LG's own switch for letting a TV run software that did not come from the LG Content Store. It is enabled from an app on the TV itself, using a free LG developer account.

Two things about it matter constantly:

**It expires.** Sessions are deliberately temporary, and the webOS Homebrew project documents an overall limit of 1000 hours, with the timer resettable from the Developer Mode app on the TV. When a session lapses, the TV stops accepting developer connections, and apps installed through Developer Mode are removed with it.

**Its remaining time cannot be worked out locally.** Nothing on the TV reports a countdown. The only way to learn how long is left is to ask LG's own session endpoint, sending the session token that was read from the TV. That is the one request this app makes that transmits anything, and it exists only because there is no local alternative.

Renewing is different, and needs no such call. It asks the TV to open its own Developer Mode app with an extend flag, which is exactly the same as walking over and reopening that app by hand. Expect it to appear on the TV screen when the button is used.

### The Homebrew Channel

Separately from LG's Developer Mode, the community maintains the [Homebrew Channel](https://github.com/webosbrew/webos-homebrew-channel), installed on a rooted TV. A TV with it installed can also be managed by this app. It is not required, and this app does not root anything.

## SSH

**SSH** (Secure Shell) is an encrypted way to control another machine's command line. It is not a way to fetch data like a web request is; it is a login. That distinction matters, because a login always has to say *which account* it is logging into, and that account decides what is allowed afterward.

On a webOS TV in Developer Mode, that account is always **`prisoner`**. It is not created during pairing and it is not chosen. It is a fixed, sandboxed account built into every webOS TV's Developer Mode, with only the access Developer Mode is meant to have rather than full control of the TV.

The TV listens for SSH on **port 9922**, not the usual 22.

### Keys instead of passwords

SSH can authenticate with a password, but it is far more common to use a **key pair**: two matching files, one private and one public. The TV holds the public half; whoever holds the private half can log in.

Pairing is the process of obtaining that private key once. Afterward the key is all that is needed, and the TV's Developer Mode app does not have to be reopened for the app to connect. [pairing.md](pairing.md) covers exactly how that key is obtained.

## The luna bus

webOS is built around a message bus called **luna** (sometimes written as ls2, for LunaService 2). Rather than every part of the system calling every other part directly, services register a name on the bus and receive JSON messages at addresses that look like URLs:

```
luna://com.webos.applicationManager/launch
luna://com.webos.service.tv.systemproperty/getSystemInfo
```

A message carries a JSON payload and gets a JSON reply. Nearly everything interesting about a webOS TV is reachable this way: installing apps, listing them, reading system properties, launching something on screen.

From an SSH session, messages are sent with a command-line tool called `luna-send`. So a single "install this app" action becomes: open an SSH connection, run a `luna-send` command with the right address and payload, read the JSON that comes back. That is what this app is doing under the hood for almost every TV operation.

### Why replies arrive in pieces

Some luna calls answer once and finish. Others **subscribe**, meaning the TV keeps sending updates on the same connection as work progresses. Installing an app is one of those: the TV reports its progress in a series of JSON messages rather than going quiet and then saying "done". That is why an install can show a real progress state rather than an indeterminate spinner.

## IPK packages

An **IPK** is the package format webOS uses for apps, the same format used by OpenWRT and other embedded Linux systems. It is a single file containing the app's code, its icons, and a small manifest describing it.

Installing one from this app means uploading the file to a temporary location on the TV over SFTP (a file-transfer mode that rides on the same SSH connection), then sending a luna message telling the TV's app installer to install from that path.

Two sources are supported:

- **The Homebrew catalog.** A public listing of community apps, published at `repo.webosbrew.org`. Each entry names a download URL and a SHA-256 checksum.
- **A local file.** Any `.ipk` already on the phone, picked through the system file picker.

### Why the checksum matters

The catalog does not host most packages itself; entries point at wherever the developer publishes them, usually GitHub release assets. That means the bytes come from a third party. Every catalog download is hashed and compared against the checksum the catalog published, and refused on a mismatch, so a compromised download host cannot quietly swap a package for something else. A catalog entry that publishes no checksum cannot be installed from here at all.

## What the TV reports about itself

The device detail page reads a handful of values off the TV. Several have names that explain nothing on their own:

**Firmware** is the version of the TV's own system software. LG numbers these per model, so two TVs on the same webOS release can show different firmware versions.

**webOS version** is the release of the webOS platform that firmware is built on. This is the number that decides what a TV can actually run, since homebrew apps are often written against a minimum release.

**SoC** stands for *system on a chip*: one piece of silicon carrying the processor, graphics, memory controller, video decoders and I/O that would otherwise be spread across several chips. It is the main thing deciding how quickly a TV's interface runs, and it is why an older TV can feel slow while still receiving firmware updates. The software moves on; the chip does not. The value shown is the TV's own internal platform name rather than a marketing one, which is why it reads as a short code.

**OTA ID** stands for *over the air*, meaning firmware delivered over the internet rather than from a USB stick. The ID appears to be how LG tells one firmware target from another, though LG does not document what it is used for. It is more specific than a model name, and TVs sold in different regions can carry different ones, which makes it a useful string to search for when looking up firmware.

## Finding the TV on the network

Every device on a home network has an **IP address**. Most home routers hand these out automatically using **DHCP**, on a lease that renews from time to time, and a device can come back on a different address than before. That is the single most common reason a TV that worked yesterday stops answering today.

The saved pairing key does not depend on the address at all, so correcting the address is enough to recover; there is no need to pair again.

Before doing anything slow, the app runs a **reachability probe**: a raw TCP connection to the TV's SSH port with a short timeout. It does not log in, it just checks whether anything answers. That is enough to tell "the TV is off or on another network" apart from "the TV is there but something else went wrong", without waiting out the much longer timeout a real login attempt would need.

## Glossary

| Term | Meaning |
|---|---|
| **Aphanes** | The project's codename, from Ancient Greek ἀφανής, unseen or not manifest. The shipped app is called webOS Dev Mode Manager. |
| **DHCP** | The protocol a router uses to hand out IP addresses automatically, on a renewing lease. |
| **Developer Mode** | LG's switch allowing a TV to run software that did not come from its store. Expires and must be renewed. |
| **Homebrew Channel** | A community app store for rooted webOS TVs, separate from LG's Developer Mode. |
| **IPK** | The package file format webOS uses for apps. |
| **luna / ls2** | webOS's internal message bus. Services are addressed with `luna://` URLs and exchange JSON. |
| **luna-send** | The command-line tool for sending a message on the luna bus. |
| **NDUID** | A webOS device's unique identifier. Its first six characters are the Developer Mode passphrase. |
| **OTA ID** | An identifier distinguishing one firmware target from another, more specific than a model name. |
| **prisoner** | The fixed, sandboxed account name every webOS TV's Developer Mode uses for SSH. |
| **SFTP** | File transfer carried over an SSH connection. |
| **SoC** | System on a chip. The single chip a TV is built around. |
| **SSH** | An encrypted remote login to another machine's command line. Port 9922 on a webOS TV. |
| **webOS** | The operating system LG smart TVs run. |
| **webOS OSE** | webOS Open Source Edition, LG's open-source webOS for other hardware. Related to, but not the same as, TV firmware. |
