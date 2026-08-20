import 'package:flutter/material.dart';

/// Resolves a persisted theme choice (null meaning "follow system") down
/// to an actual [Brightness].
Brightness resolveEffectiveBrightness(BuildContext context, ThemeMode? chosen) {
  return switch (chosen) {
    ThemeMode.light => Brightness.light,
    ThemeMode.dark => Brightness.dark,
    ThemeMode.system || null => MediaQuery.platformBrightnessOf(context),
  };
}
