import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/shared_preferences_provider.dart';
import '../../../core/theme/app_theme.dart';

const String _seedColorPrefsKey = 'seed_color_argb';

/// The Material seed color the whole app's palette is generated from -
/// see [AppTheme]. Defaults to [AppTheme.seed] (the brand red) until the
/// user picks something else in the accent color sheet.
class SeedColorController extends Notifier<Color> {
  @override
  Color build() {
    final int? argb = ref.watch(sharedPreferencesProvider).getInt(
      _seedColorPrefsKey,
    );
    return argb == null ? AppTheme.seed : Color(argb);
  }

  Future<void> set(Color color) async {
    state = color;
    await ref
        .read(sharedPreferencesProvider)
        .setInt(_seedColorPrefsKey, color.toARGB32());
  }

  Future<void> resetToDefault() => set(AppTheme.seed);
}

final NotifierProvider<SeedColorController, Color> seedColorProvider =
    NotifierProvider<SeedColorController, Color>(SeedColorController.new);
