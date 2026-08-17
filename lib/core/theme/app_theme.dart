import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Material 3 seed-color theming, shared between light and dark mode.
///
/// Deliberately lightweight: no custom [TextTheme] or widget themes beyond
/// what [ColorScheme.fromSeed] derives, so new screens can lean on
/// `Theme.of(context)` directly instead of a separate design-token layer.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF0F8A7C);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
  );

  /// Edge-to-edge system bar styling: transparent status bar, nav bar tinted
  /// to match the current surface color so it visually blends with the app.
  static SystemUiOverlayStyle systemOverlayStyle(ThemeData theme) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Brightness iconBrightness = isDark
        ? Brightness.light
        : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: iconBrightness,
      statusBarBrightness: theme.brightness,
      systemNavigationBarColor: theme.colorScheme.surface,
      systemNavigationBarDividerColor: theme.colorScheme.surface,
      systemNavigationBarIconBrightness: iconBrightness,
      // Without this, Android draws its own translucent scrim behind the
      // nav bar glyphs (back/home/recents) on top of the color above,
      // which is what was making the bar read as a separate opaque strip
      // instead of blending with the app.
      systemNavigationBarContrastEnforced: false,
    );
  }
}
