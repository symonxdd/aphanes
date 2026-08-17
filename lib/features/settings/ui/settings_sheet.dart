import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/ui/aphanes_title.dart';
import '../state/package_info_provider.dart';
import 'about_sheet.dart';
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
                  DefaultTextStyle(
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    child: const AphanesTitle(),
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
              Center(
                child: Text(
                  'webOS Dev Mode Manager',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: _AnimatedGradientText('A Symon Software Experience'),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info_outline),
                title: const Text('About'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => AboutSheet.show(context),
              ),
              const SizedBox(height: 12),
              Center(
                child: version.when(
                  data: (String v) => Text(
                    'Aphanes $v',
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

/// A short line of text with a soft highlight band drifting continuously
/// left to right through it, forever, with no visible jump at the loop
/// point. Ported verbatim from Rivus's `_AnimatedGradientText`.
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
    Color(0xFF8B5CF6), // violet
    Color(0xFF6366F1), // indigo
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
