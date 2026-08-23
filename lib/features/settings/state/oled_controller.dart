import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/shared_preferences_provider.dart';

const String _oledPrefsKey = 'oled_enabled';

/// Whether dark mode should use true-black ([AppTheme.oled]) surfaces
/// instead of the usual dark grey.
///
/// On by default, which costs nothing to anyone who does not want dark
/// mode: this is read only once the resolved theme is already dark, so a
/// phone in light mode is unaffected by it and never switched on its
/// account. What it changes is that a phone that is already in dark mode
/// gets the true-black treatment without having to go and find this
/// setting first.
class OledController extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(_oledPrefsKey) ?? true;
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref.read(sharedPreferencesProvider).setBool(_oledPrefsKey, enabled);
  }
}

final NotifierProvider<OledController, bool> oledControllerProvider =
    NotifierProvider<OledController, bool>(OledController.new);
