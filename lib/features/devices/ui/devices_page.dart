import 'package:flutter/material.dart';

/// Placeholder for Milestone 2 (device pairing, add/list/delete devices).
///
/// Devices is the landing tab, so it doubles as the app's first-run screen
/// until a dedicated onboarding flow exists. The unaffiliated-with-LG
/// disclaimer must stay visible here regardless.
class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          color: colorScheme.surfaceContainerHigh,
          child: Text(
            'Unofficial and unaffiliated with LG Electronics Inc. or the '
            'webOS Open Source Edition project.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Center(child: Text('No devices paired yet'))),
      ],
    );
  }
}
