import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/device_reachability_controller.dart';

/// A small colored dot showing whether a paired device currently answers
/// on its SSH port - grey while checking, green when reachable, the
/// theme's error color when not (TV off, wrong network, etc.).
class ReachabilityDot extends ConsumerWidget {
  const ReachabilityDot({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<bool> reachable = ref.watch(
      deviceReachabilityProvider(deviceId),
    );
    final ThemeData theme = Theme.of(context);

    final (Color color, String message) = switch (reachable) {
      AsyncData(:final bool value) when value => (
        Colors.green,
        'TV is reachable',
      ),
      AsyncData() => (theme.colorScheme.error, "Can't reach the TV right now"),
      AsyncError() => (theme.colorScheme.error, "Can't reach the TV right now"),
      _ => (theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4), 'Checking...'),
    };

    return Tooltip(
      message: message,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
