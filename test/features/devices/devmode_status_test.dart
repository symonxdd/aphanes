import 'package:aphanes/features/devices/models/devmode_status.dart';
import 'package:flutter_test/flutter_test.dart';

Duration? parse(String? raw) => DevModeStatus(remaining: raw).remainingDuration;

void main() {
  group('remainingDuration', () {
    test('reads a clock, with hours allowed past 24', () {
      // Observed on a real TV, which is what pinned the format down.
      expect(parse('999:52:55'), const Duration(hours: 999, minutes: 52, seconds: 55));
      expect(parse('999:59:59'), const Duration(hours: 999, minutes: 59, seconds: 59));
      expect(parse('4:05:09'), const Duration(hours: 4, minutes: 5, seconds: 9));
      expect(parse(' 12:00:00 '), const Duration(hours: 12));
    });

    test('reads written-out units, in any order or separator', () {
      expect(parse('45 minutes'), const Duration(minutes: 45));
      expect(parse('3 days 4 hours'), const Duration(days: 3, hours: 4));
      expect(parse('12h 30m'), const Duration(hours: 12, minutes: 30));
      expect(parse('1 hour, 2 minutes, 3 seconds'),
          const Duration(hours: 1, minutes: 2, seconds: 3));
    });

    test('gives up on anything it does not recognise', () {
      // The caller falls back to showing LG's string verbatim, so
      // returning null here is the safe outcome, not a failure.
      expect(parse(null), isNull);
      expect(parse(''), isNull);
      expect(parse('   '), isNull);
      expect(parse('unlimited'), isNull);
      expect(parse('session active'), isNull);
      expect(parse('2026-08-25T12:00:00Z'), isNull);
    });

    test('treats a zero duration as unrecognised', () {
      // "0 hours" would otherwise start a countdown already at zero and
      // immediately claim the session had expired.
      expect(parse('0 hours'), isNull);
      expect(parse('0:00:00'), const Duration());
    });

    test('is null when there is no session at all', () {
      expect(const DevModeStatus().remainingDuration, isNull);
      expect(const DevModeStatus(token: 'abc').remainingDuration, isNull);
    });
  });
}
