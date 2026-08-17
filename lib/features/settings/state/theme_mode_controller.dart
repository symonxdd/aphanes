import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/shared_preferences_provider.dart';

const String _prefsKey = 'theme_mode';

/// Persisted theme choice. Null means "follow system brightness", which is
/// the default until the user picks light or dark explicitly, at which
/// point system-following is permanently disabled for this install.
class ThemeModeController extends Notifier<ThemeMode?> {
  @override
  ThemeMode? build() {
    final String? stored = ref
        .watch(sharedPreferencesProvider)
        .getString(_prefsKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => null,
    };
  }

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await ref.read(sharedPreferencesProvider).setString(_prefsKey, mode.name);
  }
}

final NotifierProvider<ThemeModeController, ThemeMode?>
themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode?>(ThemeModeController.new);
