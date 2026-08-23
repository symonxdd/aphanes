---
title: Pairing
description: How the webOS Developer Mode key exchange actually works, what the passphrase really is, and which parts are deliberately not verified.
---

Pairing is the one part of this app that implements a protocol rather than calling an API. This page documents what actually happens, and just as importantly, what deliberately does not.

## The short version

1. The TV runs a small HTTP server on **port 9991**, its *key server*, enabled from the Developer Mode app.
2. A plain `GET /webos_rsa` returns an **encrypted** RSA private key, in a PEM format.
3. The passphrase shown on the TV screen decrypts it, **on the phone**. It is never sent to the TV.
4. The decrypted key is stored in the platform keystore and used for SSH from then on.

The key travels *from* the TV *to* the phone. The phone never generates one.

## The key server

It is plain HTTP, not HTTPS. The TV does not offer TLS here, so there is nothing to negotiate.

The request is deliberately a bare `GET /webos_rsa HTTP/1.0`, not an HTTP/1.1 request through a full client. The server is minimal and its responses are parsed directly rather than through a client library that would expect more of it than it provides.

The endpoint is **unauthenticated**. Anyone on the same network who can reach port 9991 while the key server is on can download the encrypted blob. That is not a flaw in this app; it is how the mechanism works. The passphrase is what makes the blob useful, and it never crosses the network at all.

## What the passphrase actually is

It is not a fresh one-time code, and it does not rotate.

Per LG's own webOS Open Source Edition source for the Developer Mode service, the passphrase is derived from the device's **NDUID**, its unique device identifier:

```js
passphrase: response.payload.nduid.slice(0, 6).toUpperCase()
```

The first six characters, uppercased. It is therefore **fixed for a given TV** and will read the same every time that TV's Developer Mode app is opened.

Two consequences worth understanding:

- Re-pairing the same TV later uses the same passphrase. Nothing needs resetting.
- The full NDUID is sensitive in a way that is easy to miss. Its first six characters *are* the passphrase, so displaying a complete NDUID anywhere is equivalent to displaying that TV's Developer Mode passphrase. The app does not show it.

## Decrypting the key

The blob is the "traditional" OpenSSL encrypted PEM format, which predates PKCS8 and PBES2 entirely. It looks like this:

```
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,65E41A35845545F9F6EEA0F87730BEA5
...
```

Decryption follows OpenSSL's classic scheme rather than anything modern:

- The key is derived from the passphrase with **`EVP_BytesToKey`**, which is iterated **MD5**, not PBKDF2. There is no separate salt field and no iteration count; the salt is the first eight bytes of the IV given on the `DEK-Info` line.
- The cipher is whatever `DEK-Info` names. AES-128, AES-192, AES-256 and 3DES in CBC mode are supported.

Neither ares-cli-rs nor dev-manager-desktop implement this themselves. Both hand the raw response to libssh, which reads the legacy format natively. There was therefore no reference implementation to port, and this is written directly against OpenSSL's documented algorithm using Dart's ASN.1 and crypto primitives.

Because the derivation is CPU-bound, it runs off the UI thread. That also makes it cheap to validate a passphrase as it is typed, against a blob fetched once, with no network round trip per keystroke and no partial-attempt state on the TV.

## Connecting afterwards

| Setting | Value |
|---|---|
| Port | 9922 |
| Username | `prisoner` |
| Auth | The decrypted private key |

`prisoner` is not chosen and not created during pairing. It is a fixed, sandboxed account present in every webOS TV's Developer Mode, with only the access Developer Mode is meant to have.

Once paired, the Developer Mode app does not need reopening and the key server does not need to stay on. The saved key is sufficient.

The key also does not depend on the TV's address, so a TV that moves to a new IP is recovered by correcting the address, not by pairing again.

## What is deliberately not verified

Two things a security-minded reader will notice are missing. Both are intentional, and both match the reference implementations.

**No TLS.** The key server does not offer it. There is nothing to verify.

**No SSH host-key pinning.** Normally an SSH client remembers a server's host key and refuses to connect if it changes, which is what protects against impersonation. webOS devices do not keep a stable host key across resets, so pinning would produce constant false alarms on ordinary user actions rather than meaningful protection.

The practical security boundary is therefore the local network plus physical access to read the passphrase off the TV screen. That is the same boundary the official tooling operates within, and it is worth being explicit about rather than implying more.

## Older TVs

Some TVs run an SSH implementation predating modern signature algorithms, and will not accept a key offered with the newer `rsa-sha2-*` signatures that current clients prefer. Those connections fail in a way that looks like a rejected key rather than an unsupported algorithm.

The connection layer keeps an explicit `ssh-rsa` fallback for exactly that case, so an older TV pairs and connects with the same flow as a current one.
