import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/effective_brightness.dart';
import '../state/theme_mode_controller.dart';

/// Flips between light and dark, falling back to system brightness display
/// (via [MediaQuery]) until the user makes an explicit choice.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeMode? chosen = ref.watch(themeModeControllerProvider);
    final Brightness effective = resolveEffectiveBrightness(context, chosen);
    final bool isDark = effective == Brightness.dark;

    // A bare InkWell+Icon, not IconButton: IconButton doesn't reliably
    // shrink to a tight custom size even with constraints overridden and
    // padding zeroed, which throws off the symmetric spacing this header
    // relies on to keep the title centered.
    return Tooltip(
      message: isDark ? 'Switch to light mode' : 'Switch to dark mode',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          ref
              .read(themeModeControllerProvider.notifier)
              .select(isDark ? ThemeMode.light : ThemeMode.dark);
        },
        child: Padding(
          // Asymmetric top/bottom, not a Transform: a real layout nudge
          // rather than a paint-only offset keeps the tap target exactly
          // where it visually sits.
          padding: const EdgeInsets.fromLTRB(4, 5, 4, 3),
          child: Icon(
            isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            size: 24,
          ),
        ),
      ),
    );
  }
}
