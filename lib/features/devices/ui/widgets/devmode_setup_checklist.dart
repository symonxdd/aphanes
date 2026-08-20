import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DevmodeSetupSheet extends StatelessWidget {
  const DevmodeSetupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext _) => const DevmodeSetupSheet(),
    );
  }

  static const List<_Step> _steps = [
    _Step('Create an LG developer account', 'If you don’t already have one.'),
    _Step(
      'Install the Developer Mode app',
      'On the TV: open the LG Content Store, search for "Developer Mode", '
          'and install it.',
    ),
    _Step(
      'Turn on Developer Mode',
      'Open the Developer Mode app, sign in with the developer account, '
          'and enable Developer Mode. The TV will restart.',
    ),
    _Step(
      'Turn on the Key Server',
      'Open the Developer Mode app again, confirm Dev Mode Status is on, '
          'and enable Key Server.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Before pairing', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            for (int i = 0; i < _steps.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _steps[i].title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _steps[i].detail,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'One-time setup. Not needed again unless Developer '
                    'Mode\'s session (about 1000 hours) expires.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => launchUrl(
                  Uri.parse('https://www.webosbrew.org/devmode/'),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Read the full guide'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The small tappable trigger for [DevmodeSetupSheet], shown inline on the
/// pairing form. Highlighted after a failed pairing attempt, since that's
/// the moment someone is most likely to actually need it - without
/// popping the sheet open unasked, which would be pushier than a plain
/// color change.
class DevmodeSetupLink extends StatelessWidget {
  const DevmodeSetupLink({this.highlighted = false, super.key});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = highlighted
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return TextButton(
      onPressed: () => DevmodeSetupSheet.show(context),
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: TextStyle(
          fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      child: const Text('New here? See setup steps.'),
    );
  }
}

class _Step {
  const _Step(this.title, this.detail);

  final String title;
  final String detail;
}
