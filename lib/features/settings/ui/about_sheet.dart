import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/ui/app_icon_glyph.dart';
import '../../../core/ui/app_splash_overlay.dart';
import '../state/package_info_provider.dart';
import 'version_explainer_sheet.dart';

class AboutSheet extends ConsumerWidget {
  const AboutSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext _) => const AboutSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<({String version, String buildNumber})> versionInfo =
        ref.watch(
      packageInfoProvider.select(
        (AsyncValue<PackageInfo> info) => info.whenData(
          (PackageInfo p) => (version: p.version, buildNumber: p.buildNumber),
        ),
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tappable like every other app icon in the app, and
            // deliberately so: the list further down mentions this
            // gesture, and the icon it is talking about is right here to
            // try it on.
            const Center(
              child: SplashTapTarget(child: AppIconGlyph(size: 40)),
            ),
            const SizedBox(height: 16),
            Text('About', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'Aphanes - a webOS Dev Mode Manager, is not affiliated with '
              'LG Electronics Inc. or the webOS Open Source Edition project.',
              style: theme.textTheme.bodyMedium,
            ),
            const _ThingsToTry(),
            const SizedBox(height: 24),
            Center(
              child: versionInfo.when(
                data: (({String version, String buildNumber}) v) => InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => VersionExplainerSheet.show(context),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      '${v.version} (${v.buildNumber}) '
                      '· ${kReleaseMode ? 'release' : 'dev'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (Object _, StackTrace _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The gestures the app hides, written down in the one place a person
/// who wants to find them would actually look.
///
/// Two taps deep (Settings, then About) on purpose. Nobody is nudged
/// towards this, nothing pops up to announce it, and the app is entirely
/// usable by someone who never opens it. It is here so that curiosity is
/// rewarded rather than left guessing, which is the difference between a
/// hidden feature and one nobody ever knows exists.
///
/// The gestures are named; what they do is not. Saying "tap the app icon"
/// gives someone a reason to tap it. Saying what happens next removes it.
///
/// The version line below is in the list for a different reason: it does
/// not look tappable at all, being the sort of small grey text that reads
/// as a footer, so it would otherwise never be tried.
class _ThingsToTry extends StatelessWidget {
  const _ThingsToTry();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        Text(
          'Things to try',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        const _TryRow(
          // The glyph itself, not a stand-in for it, and tappable like
          // every other one in the app - so this row is not merely
          // describing the gesture, it is somewhere to perform it.
          leading: SplashTapTarget(
            // Padded out to fill the row's leading slot rather than left
            // at the glyph's own 18: an 18-square tap target is a mean
            // thing to ask anyone to hit.
            child: SizedBox.square(
              dimension: _TryRow.leadingSlot,
              child: Center(child: AppIconGlyph(size: 18)),
            ),
          ),
          text: 'Tap the app icon',
        ),
        const _TryRow(
          leading: Icon(Icons.touch_app_outlined, size: 18),
          text: 'Tap the Aphanes name',
        ),
        const _TryRow(
          leading: Icon(Icons.pan_tool_outlined, size: 18),
          text: 'Hold the Aphanes name',
        ),
        const _TryRow(
          leading: Icon(Icons.numbers, size: 18),
          text: 'Tap the version below',
        ),
      ],
    );
  }
}

class _TryRow extends StatelessWidget {
  const _TryRow({required this.leading, required this.text});

  /// Width of the leading glyph slot. Public to this file so a leading
  /// widget that wants the whole slot as a tap target can ask for it
  /// rather than repeat the number.
  static const double leadingSlot = 24;

  final Widget leading;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // A fixed slot, so glyphs of different intrinsic widths still
          // leave the labels beside them on one vertical line.
          SizedBox(
            width: leadingSlot,
            child: Center(
              child: IconTheme.merge(
                data: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
                child: leading,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
