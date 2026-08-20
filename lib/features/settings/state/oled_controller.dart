import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/shared_preferences_provider.dart';

const String _oledPrefsKey = 'oled_enabled';

/// Whether dark mode should use true-black ([AppTheme.oled]) surfaces
/// instead of the usual dark grey. Has no visible effect while the
/// resolved theme is light.
class OledController extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(_oledPrefsKey) ??
        false;
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_oledPrefsKey, enabled);
  }
}

final NotifierProvider<OledController, bool> oledControllerProvider =
    NotifierProvider<OledController, bool>(OledController.new);
