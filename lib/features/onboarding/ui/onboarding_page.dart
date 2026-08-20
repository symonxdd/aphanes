import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ambient_backdrop.dart';
import '../../../core/ui/aphanes_title.dart';
import '../../../core/ui/app_icon_glyph.dart';
import '../state/onboarding_controller.dart';

/// A single, one-time screen explaining what the app does, shown before
/// `HomePage` until dismissed - and where the LG-unaffiliated disclaimer
/// lives, satisfying "visible on first-run" literally rather than as a
/// permanent banner. `AphanesApp` wraps the Onboarding/Home swap in an
/// `AnimatedSwitcher`, so completing onboarding is enough on its own to
/// cross-fade into `HomePage`.
///
/// Also reachable a second way: pushed as an ordinary route from
/// SettingsSheet's "Show intro again" row, with [isReplay] set. That case
/// doesn't touch [onboardingControllerProvider] at all - it's purely a
/// "look at this again" view, so its own button just pops back to Settings
/// instead.
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({this.isReplay = false, super.key});

  final bool isReplay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const AmbientBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              // A Stack, not a Column with an Expanded/Center around the
              // tagline: a Column's Expanded only centers within whatever
              // space is left over after its siblings, and the icon/title
              // block above is much taller than the button block below, so
              // that leftover space's own midpoint sits well below the
              // screen's true center. Positioned.fill + Center here instead
              // centers on the full available height.
              child: Stack(
                children: [
                  Positioned(
                    top: 64,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        const AppIconGlyph(size: 96),
                        const SizedBox(height: 20),
                        DefaultTextStyle(
                          style: theme.textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          child: const AphanesTitle(),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Manage your webOS TV's Developer Mode.",
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Install apps, browse files, open a terminal, '
                            'and track the Developer Mode session time.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 32,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Deliberately small and muted: a factual footnote,
                        // not a second pitch competing with the tagline
                        // above.
                        Text(
                          'Unaffiliated with LG Electronics Inc. or the '
                          'webOS Open Source Edition project.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => isReplay
                                ? Navigator.of(context).pop()
                                : ref
                                      .read(onboardingControllerProvider.notifier)
                                      .complete(),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                              ),
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Got it, boss'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
