import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/ui/ambient_backdrop.dart';
import '../../../core/ui/aphanes_title.dart';
import '../../../core/ui/app_icon_glyph.dart';
import '../../../core/ui/info_sheet.dart';
import '../../onboarding/ui/onboarding_page.dart';
import '../state/effective_brightness.dart';
import '../state/oled_controller.dart';
import '../state/package_info_provider.dart';
import '../state/seed_color_controller.dart';
import '../state/tab_visibility_controller.dart';
import '../state/theme_mode_controller.dart';
import 'about_sheet.dart';
import 'accent_color_sheet.dart';
import 'theme_selector.dart';

class SettingsSheet extends ConsumerWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext _) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<String> version = ref.watch(
      packageInfoProvider.select(
        (AsyncValue<PackageInfo> info) =>
            info.whenData((PackageInfo p) => p.version),
      ),
    );
    final ThemeMode? chosenMode = ref.watch(themeModeControllerProvider);
    final bool isDark =
        resolveEffectiveBrightness(context, chosenMode) == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Two equal, empty Expanded slots either side of the title,
              // rather than centering the row as a whole, so "Aphanes"
              // stays exactly centered regardless of the toggle's own
              // width, with the toggle vertically centered on just this
              // single-line row (the subtitle below sits outside it, so it
              // can't pull the toggle's alignment off the title).
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIconGlyph(size: 22),
                      const SizedBox(width: 8),
                      DefaultTextStyle(
                        style: theme.textTheme.headlineSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        child: const AphanesTitle(),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Transform.translate(
                        offset: const Offset(-6, 0),
                        child: const ThemeToggleButton(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Center(
                child: _AnimatedGradientText('A Symon Software Experience'),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('Appearance'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.palette_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Accent color'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: ref.watch(seedColorProvider),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => AccentColorSheet.show(context),
              ),
              // AnimatedSize alone, not AnimatedSwitcher+SizeTransition: the
              // two competing size animations AnimatedSwitcher runs during
              // its crossfade (one shrinking out, one growing in) is a
              // known jank source. Its child is pinned to full width via
              // the outer SizedBox below - without that, AnimatedSize
              // interpolates width too (from SizedBox.shrink's zero width
              // up to the tile's full width), which is what read as the
              // row sliding in sideways instead of just unfolding
              // downward. The inner AnimatedOpacity, on an easeIn curve,
              // is the actual fade-in.
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeIn,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeIn,
                    opacity: isDark ? 1 : 0,
                    child: isDark
                        ? ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.contrast,
                              color: theme.colorScheme.primary,
                            ),
                            title: const Text('Enable OLED theme'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  tooltip: 'About OLED theme',
                                  onPressed: () => InfoSheet.show(
                                    context,
                                    icon: Icons.contrast,
                                    title: 'OLED theme',
                                    body:
                                        'Replaces dark mode\'s usual dark '
                                        'grey with pure black across every '
                                        'surface. On OLED and AMOLED '
                                        'screens, black pixels are turned '
                                        'off entirely, so this can '
                                        'noticeably extend battery life '
                                        'alongside a cleaner, '
                                        'higher-contrast look.\n\n'
                                        'Has no effect while the app is in '
                                        'light mode.',
                                  ),
                                ),
                                Switch(
                                  value: ref.watch(oledControllerProvider),
                                  onChanged: (bool value) => ref
                                      .read(oledControllerProvider.notifier)
                                      .set(value),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.blur_on, color: theme.colorScheme.primary),
                title: const Text('Ambient backdrop'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.info_outline),
                      tooltip: 'About the ambient backdrop',
                      onPressed: () => InfoSheet.show(
                        context,
                        icon: Icons.blur_on,
                        title: 'Ambient backdrop',
                        body:
                            'Two soft, drifting color blobs shown behind '
                            'every screen while the app is open.\n\n'
                            'The cost is not the blobs themselves; a '
                            'couple of blurred circles are cheap to draw. '
                            'It comes from keeping the screen animating '
                            'continuously, which stops the display from '
                            'settling into the lower-power idle state it '
                            'reaches when nothing on screen is moving. '
                            'That raises battery use slightly while a '
                            'screen showing it is open and visible.\n\n'
                            'The effect stops the moment the app is '
                            'closed or the screen turns off. It is not a '
                            'background or always-on drain.',
                      ),
                    ),
                    Switch(
                      value: ref.watch(ambientBackdropControllerProvider),
                      onChanged: (bool value) => ref
                          .read(ambientBackdropControllerProvider.notifier)
                          .set(value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const _SectionLabel('Tabs'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.folder_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Files tab'),
                value: ref.watch(filesTabVisibleProvider),
                onChanged: (bool value) =>
                    ref.read(filesTabVisibleProvider.notifier).set(value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.terminal_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Terminal tab'),
                value: ref.watch(terminalTabVisibleProvider),
                onChanged: (bool value) =>
                    ref.read(terminalTabVisibleProvider.notifier).set(value),
              ),
              const SizedBox(height: 12),
              const _SectionLabel('General'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('About'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => AboutSheet.show(context),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.replay_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Show intro again'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) =>
                        const OnboardingPage(isReplay: true),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: version.when(
                  // Codename first, then the shipped name, then the
                  // version as its own separate segment rather than
                  // grouped under either name.
                  data: (String v) => Text(
                    'Aphanes · a webOS Dev Mode Manager · '
                    '$v (${kReleaseMode ? 'release' : 'dev'})',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (Object _, StackTrace _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small, muted caption grouping a cluster of settings rows below it -
/// the standard Material list-section-header treatment, chosen over a
/// hard divider line since it reads lighter in a compact bottom sheet.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Ported from Rivus's `_AnimatedGradientText`.
class _AnimatedGradientText extends StatefulWidget {
  const _AnimatedGradientText(this.text);

  final String text;

  @override
  State<_AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<_AnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // A simple two-color violet->indigo sweep, mid-toned so it reads on both
  // the light and dark sheet surface without needing separate palettes.
  // Laid out as a palindrome (violet->indigo->violet) so the tiled gradient
  // loops seamlessly and eases back and forth between just the two hues,
  // with no hard jump at the wrap and no third color muddying it.
  static const List<Color> _palette = <Color>[
    Color(0xFF8B5CF6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
  ];

  static const List<double> _stops = <double>[0, 0.5, 1];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Text text = Text(widget.text, style: theme.textTheme.labelSmall);

    return AnimatedBuilder(
      animation: _controller,
      child: text,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: _palette,
              stops: _stops,
              tileMode: TileMode.repeated,
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}
