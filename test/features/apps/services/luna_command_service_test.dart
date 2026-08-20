import 'package:aphanes/features/apps/services/luna_command_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wraps a plain string in single quotes', () {
    expect(
      LunaCommandService.shellEscape('com.webos.appInstallService'),
      "'com.webos.appInstallService'",
    );
  });

  test('wraps a luna URI in single quotes', () {
    expect(
      LunaCommandService.shellEscape(
        'luna://com.webos.applicationManager/dev/listApps',
      ),
      "'luna://com.webos.applicationManager/dev/listApps'",
    );
  });

  test('wraps a JSON payload in single quotes untouched', () {
    expect(
      LunaCommandService.shellEscape('{"id":"com.ares.defaultName"}'),
      '\'{"id":"com.ares.defaultName"}\'',
    );
  });

  test('escapes an embedded single quote', () {
    expect(
      LunaCommandService.shellEscape("it's here"),
      r"""'it'\''s here'""",
    );
  });
}
