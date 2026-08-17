import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/theme_mode_controller.dart';

/// Flips between light and dark, falling back to system brightness display
/// (via [MediaQuery]) until the user makes an explicit choice.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode? chosen = ref.watch(themeModeControllerProvider);
    final Brightness effective =
        chosen == ThemeMode.light
            ? Brightness.light
            : chosen == ThemeMode.dark
            ? Brightness.dark
            : MediaQuery.platformBrightnessOf(context);
    final bool isDark = effective == Brightness.dark;

    return IconButton(
      icon: Icon(
        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
      ),
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () {
        ref
            .read(themeModeControllerProvider.notifier)
            .select(isDark ? ThemeMode.light : ThemeMode.dark);
      },
    );
  }
}
