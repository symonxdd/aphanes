# Changelog

The desktop app's own releases, tagged `desktop-v*`. The Android app's
are in [the changelog at the repository root](../CHANGELOG.md); the two
are versioned independently.

## v1.0.0

Initial release 👏

### ✨ New

- **Pair an LG TV in Developer Mode from a Windows PC.** Six characters
  shown on the TV buys a permanent key, kept in Windows Credential
  Manager, and the TV answers from then on with nothing to reopen.
- Browse and search the public Homebrew catalog, read a package's full
  description, and install it straight to the TV. Every download is
  checked against the catalog's published SHA-256 and refused on a
  mismatch; the rare package that publishes no hash asks first, naming
  the host it comes from.
- Install an .ipk from the PC through the file picker.
- See what is installed on a TV and what is running, open any of it on
  the TV, and remove any of it after a confirmation.
- Watch the Developer Mode session's remaining time on the device
  details, and renew it from the desk.
- Keep several TVs in a sidebar, each with a dot that says whether it is
  reachable right now. Rename them, correct an address that changed,
  and remove one after a confirmation in plain sight.
- The app updates itself: Check for updates, in Settings, looks for a
  newer release, and downloads and installs one only on a click each.
  Nothing is checked in the background.
- Light, dark and true-black OLED themes, and an accent color picker.
