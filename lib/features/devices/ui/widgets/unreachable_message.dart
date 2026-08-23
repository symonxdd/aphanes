import 'package:flutter/material.dart';

/// Shared "TV not reachable" messaging - one wording and one styling for
/// this state everywhere it can show up (Apps tab, device detail page),
/// not scattered across call sites. Two separately-styled lines: the
/// first reads as the actual problem, the second is a secondary hint,
/// muted rather than given the same weight as the first.
class UnreachableMessage extends StatelessWidget {
  const UnreachableMessage({required this.deviceName, super.key});

  final String deviceName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '"$deviceName" not reachable. Is it turned on?',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Also, make sure this phone is on the same network as the TV.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
