import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../state/package_info_provider.dart';

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
    final AsyncValue<String> version = ref.watch(
      packageInfoProvider.select(
        (AsyncValue<PackageInfo> info) =>
            info.whenData((PackageInfo p) => p.version),
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'Aphanes - a webOS Dev Mode Manager, is not affiliated with '
              'LG Electronics Inc. or the webOS Open Source Edition project.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Center(
              child: version.when(
                data: (String v) => Text(
                  'Version $v',
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
    );
  }
}
