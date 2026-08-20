import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Material 3 seed-color theming, shared between light and dark mode.
///
/// Deliberately lightweight: no custom [TextTheme] or widget themes beyond
/// what [ColorScheme.fromSeed] derives, so new screens can lean on
/// `Theme.of(context)` directly instead of a separate design-token layer.
abstract final class AppTheme {
  // The default accent color, and what "reset to default" in the accent
  // color picker (see accent_color_sheet.dart) falls back to.
  static const Color seed = Color(0xFF9333EA);

  static final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  );

  // M3's default AppBar tints and grows a shadow when content scrolls
  // under it. Disabled everywhere via the theme (rather than per-AppBar)
  // so every screen's app bar stays visually flat and consistent as more
  // get added.
  static const AppBarTheme _appBarTheme = AppBarTheme(
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
  );

  // Mirrors dark/oled's own explicit surface ladder, scaffoldBackgroundColor,
  // bottomSheetTheme, cardTheme, and surfaceTint override below - light was
  // previously left on ColorScheme.fromSeed's own defaults for all of that,
  // which meant switching between light and dark wasn't just an interpolated
  // color change: bottom sheets, cards, and the scrolled-under app bar tint
  // flipped between two entirely different theming models (flat, explicit
  // colors on one side; M3's default tonal-elevation tint on the other) on
  // the same switch, which is what read as a visible glitch rather than a
  // clean transition.
  static ThemeData light(Color seedColor) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
    ).copyWith(
      surface: const Color(0xFFFFFFFF),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF5F5F5),
      surfaceContainer: const Color(0xFFEFEFEF),
      surfaceContainerHigh: const Color(0xFFE8E8E8),
      surfaceContainerHighest: const Color(0xFFE0E0E0),
      surfaceTint: Colors.transparent,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFFFFFFF),
      inputDecorationTheme: _inputDecorationTheme,
      appBarTheme: _appBarTheme.copyWith(
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFFF5F5F5),
        modalBackgroundColor: Color(0xFFF5F5F5),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFFF5F5F5),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  // A plain, neutral dark grey ladder (Material's own canonical #121212
  // base), not the faint seed-tinted grey ColorScheme.fromSeed generates
  // by default. Only the surface family changes - primary/secondary/
  // tertiary/error (buttons, accents) stay exactly as the seed derives
  // them.
  static ThemeData dark(Color seedColor) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      // Material's own canonical #121212 base - the bottom sheet / card
      // tier below stays at #1A1A1A on purpose, so a screen's own
      // background still reads as a step below whatever's raised above it.
      surface: const Color(0xFF121212),
      surfaceContainerLowest: const Color(0xFF080808),
      surfaceContainerLow: const Color(0xFF1A1A1A),
      surfaceContainer: const Color(0xFF202020),
      surfaceContainerHigh: const Color(0xFF2A2A2A),
      surfaceContainerHighest: const Color(0xFF333333),
      surfaceTint: Colors.transparent,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF121212),
      inputDecorationTheme: _inputDecorationTheme,
      appBarTheme: _appBarTheme.copyWith(
        backgroundColor: const Color(0xFF121212),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1A1A1A),
        modalBackgroundColor: Color(0xFF1A1A1A),
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1A1A1A),
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  /// Same palette as [dark], but every surface - background, cards, sheets,
  /// dialogs, all of it - is forced to true black, with tonal elevation
  /// tinting turned off entirely. What actually saves power and looks
  /// clean on OLED panels, rather than dark mode's usual dark grey with a
  /// faint primary-colored wash on raised surfaces.
  static ThemeData oled(Color seedColor) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      surface: Colors.black,
      surfaceContainerLowest: Colors.black,
      surfaceContainerLow: Colors.black,
      surfaceContainer: Colors.black,
      surfaceContainerHigh: Colors.black,
      surfaceContainerHighest: Colors.black,
      // The single lever every M3 widget's default elevation-tint overlay
      // reads from - zeroing it here is what actually stops the "accent
      // wash" on bottom sheets, cards, dialogs, menus, etc., rather than
      // having to patch each widget's own theme individually.
      surfaceTint: Colors.transparent,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.black,
      inputDecorationTheme: _inputDecorationTheme,
      appBarTheme: _appBarTheme.copyWith(backgroundColor: Colors.black),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.black,
        modalBackgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: Colors.black,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

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
