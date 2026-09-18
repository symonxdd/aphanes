import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
                  // Centred on the height above the button block rather
                  // than the whole screen, which reads as sitting a little
                  // high: the eye expects the pitch above the middle and
                  // the action below it.
                  Positioned.fill(
                    bottom: 56,
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
                          const SizedBox(height: 18),
                          // Three rows instead of one sentence: scanned
                          // rather than parsed, and the YouTube line gets
                          // to be its own item. Left-aligned inside a
                          // narrow centred column, since a list wants a
                          // left edge and the tagline above has none. The
                          // icons are the ones those screens already use.
                          // Left padding only, which shifts the centred
                          // block right by half of it: an optical
                          // correction for the ragged right edge of the
                          // wrapped lines, which otherwise leaves the icons
                          // looking closer to the phone's edge than the
                          // text is.
                          Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Material glyphs sit inside more padding
                                  // than Lucide's, so the two Material icons
                                  // get two extra points to read the same
                                  // size as the TV between them.
                                  _FeatureRow(
                                    icon: Icons.apps_outlined,
                                    size: 20,
                                    // This glyph sits high in its box.
                                    nudge: 1,
                                    text:
                                        'Install apps, including the one that '
                                        'makes YouTube ad free',
                                  ),
                                  SizedBox(height: 10),
                                  _FeatureRow(
                                    icon: LucideIcons.tv,
                                    text: "Check the TV's details",
                                  ),
                                  SizedBox(height: 10),
                                  _FeatureRow(
                                    icon: Icons.refresh,
                                    size: 22,
                                    text: 'Renew the Developer Mode session',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // The price line is a public commitment the README
                          // and project site also make, and this is the one
                          // place every user reads it. It closes the pitch,
                          // so it sits with the pitch rather than with the
                          // button.
                          Text(
                            'No ads, no tracking, free forever.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // The disclaimer is legal text and goes where legal
                        // text goes: under the button, as the quietest
                        // thing on the screen.
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => isReplay
                                ? Navigator.of(context).pop()
                                : ref
                                      .read(
                                        onboardingControllerProvider.notifier,
                                      )
                                      .complete(),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              textStyle: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Got it, boss'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Unaffiliated with LG Electronics Inc. or the '
                          'webOS Open Source Edition project.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
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

/// One line of the intro's feature list: a small icon and a short phrase,
/// both in the muted color so the tagline above keeps the emphasis.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.text,
    this.size = 18,
    this.nudge = 0,
  });

  final IconData icon;
  final String text;
  final double size;

  /// Extra downward offset for a glyph drawn high in its box.
  final double nudge;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The icon slot is a fixed width so the text column keeps one
        // left edge whatever size each icon is.
        SizedBox(
          width: 22,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              // Centred on the first line of bodyMedium (a 20px line box),
              // plus the usual optical pixel.
              padding: EdgeInsets.only(top: (20 - size) / 2 + 1 + nudge),
              child: Icon(icon, size: size, color: color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
