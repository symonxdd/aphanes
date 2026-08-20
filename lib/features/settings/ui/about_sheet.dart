import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/ui/app_icon_glyph.dart';
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
            const Center(child: AppIconGlyph(size: 40)),
            const SizedBox(height: 16),
            Text('About', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'Aphanes - a webOS Dev Mode Manager, is not affiliated with '
              'LG Electronics Inc. or the webOS Open Source Edition project.',
              style: theme.textTheme.bodyMedium,
            ),
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
