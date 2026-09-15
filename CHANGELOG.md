# Changelog

## v1.0.2

### ⚡ Improved

- **The first-run screen now says what the app does, one thing per
  line.** Three short rows replaced the paragraph that used to run under
  the title, and the first of them names the app that makes YouTube ad
  free, since that is what many people come looking for.
- The same screen promises, in writing, that the app is free forever
  with no ads and no tracking. The About sheet says it at greater
  length, and names GitHub as the only place official releases come
  from, so a paid copy found elsewhere can be recognized for what it is.
- The first-run screen no longer promises a file browser and a terminal.
  Neither is built, and both tabs already said so.
- The "Before pairing" checklist is clearer about what expiring costs:
  when a Developer Mode session runs out, after about 1000 hours, only
  turning Developer Mode back on is needed. The account, the app on the
  TV and the pairing all survive.
- The Developer Mode explainer now says why sessions expire at all, and
  what an expired one takes with it.
- The version line in the About sheet explains the real version and
  build number rather than the example it used to quote.

## v1.0.1

### ✨ New

- **The About sheet now links to the privacy policy.** It opens the
  policy on the project site, so what the app does with a TV's details,
  and the three requests that ever leave the phone, can be read without
  going looking for them.

### ⚡ Improved

- **App data no longer travels in Android's automatic backup.** Paired
  devices, their addresses and their pairing keys were eligible for
  Google Drive backup and for phone-to-phone transfer. They now stay on
  the phone they were created on.

## v1.0.0

Initial release 👏

### ✨ New

- **Pair an LG TV in Developer Mode from the phone.** Six characters
  shown on the TV buys a permanent key, and the TV answers from then on
  with nothing to reopen.
- Browse and search the public Homebrew catalog, and install a package
  straight to the TV. Every download is checked against the catalog's
  published SHA-256 and refused on a mismatch.
- Install an .ipk already on the phone.
- See what is installed on a TV, and remove any of it.
- Watch the Developer Mode session's remaining time on the device detail
  page, and renew it in one tap from the couch.
- Keep several TVs, switch between them, rename them, and correct an
  address that changed. Removing one asks first, in plain sight.
- A fast reachability check, so a sleeping TV says so in seconds rather
  than hanging on a long timeout.
- Every field on the device detail page explains itself in a sheet:
  model, SoC, OTA ID, firmware and the rest.
- Light, dark and true-black OLED themes.
- Every screen respects the status bar, the navigation bar and display
  cutouts, which is the reason this app exists.
