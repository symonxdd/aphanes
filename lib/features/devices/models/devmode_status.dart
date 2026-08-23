/// Whether this TV currently has a live webOS Developer Mode session, and
/// how long is left on it. webOS's own Developer Mode sessions expire
/// periodically by design; this is what "Renew" on the device detail page
/// acts on.
class DevModeStatus {
  const DevModeStatus({this.token, this.remaining});

  final String? token;

  /// Exactly what LG's session endpoint returned, unparsed.
  final String? remaining;

  bool get hasToken => token != null;

  /// [remaining] read as a real duration, or null when it is not in a
  /// shape this recognises.
  ///
  /// LG does not document the format, and dev-manager-desktop passes the
  /// string straight through without parsing it either. A real TV was
  /// observed returning "999:52:55", so hours run well past 24 and are
  /// not zero-padded to a fixed width; that shape is handled first
  /// below. The written-out forms after it are defensive, for firmware
  /// that words it differently.
  ///
  /// Anything unrecognised gives up cleanly and callers fall back to
  /// showing [remaining] verbatim, so a format this does not know costs
  /// nothing beyond not counting down.
  Duration? get remainingDuration {
    final String? raw = remaining?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    // "999:59:59", where hours are free to exceed 24.
    final RegExp clock = RegExp(r'^(\d+):([0-5]?\d):([0-5]?\d)$');
    final RegExpMatch? asClock = clock.firstMatch(raw);
    if (asClock != null) {
      return Duration(
        hours: int.parse(asClock.group(1)!),
        minutes: int.parse(asClock.group(2)!),
        seconds: int.parse(asClock.group(3)!),
      );
    }

    // "3 days 4 hours", "45 minutes", "12h 30m", and similar. Summed
    // rather than matched as a whole, so the order and the separators
    // between the parts do not matter.
    final RegExp parts = RegExp(
      r'(\d+)\s*(days?|d|hours?|hrs?|h|minutes?|mins?|m|seconds?|secs?|s)\b',
      caseSensitive: false,
    );
    Duration total = Duration.zero;
    bool matched = false;
    for (final RegExpMatch part in parts.allMatches(raw)) {
      final int value = int.parse(part.group(1)!);
      final String unit = part.group(2)!.toLowerCase();
      matched = true;
      if (unit.startsWith('d')) {
        total += Duration(days: value);
      } else if (unit.startsWith('h')) {
        total += Duration(hours: value);
      } else if (unit.startsWith('m')) {
        total += Duration(minutes: value);
      } else {
        total += Duration(seconds: value);
      }
    }
    return matched && total > Duration.zero ? total : null;
  }
}
