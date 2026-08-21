import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/device.dart';
import '../../state/device_reachability_controller.dart';
import 'reachability_dot.dart';

class DeviceCard extends ConsumerWidget {
  const DeviceCard({
    required this.device,
    required this.selected,
    required this.onTap,
    required this.onInfoTap,
    super.key,
  });

  final Device device;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<bool> reachable = ref.watch(
      deviceReachabilityProvider(device.id),
    );
    // Something's shown here the instant this card appears, not only
    // once a check resolves negative: a bare gap for a second or two
    // (while the check that fills it in is still running) read as
    // broken/inconsistent on its own. Quiet only for the actually-healthy
    // case, which is the common one.
    final (String, Color)? reachabilityStatus = switch (reachable) {
      AsyncData(:final bool value) when !value => (
        'TV not reachable. Is it turned on?',
        theme.colorScheme.error,
      ),
      AsyncError() => (
        'TV not reachable. Is it turned on?',
        theme.colorScheme.error,
      ),
      AsyncData() => null,
      _ => ('Checking availability...', theme.colorScheme.onSurfaceVariant),
    };
    final List<Widget> subtitleLines = [
      if (device.model != null) Text(device.model!),
      if (reachabilityStatus != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReachabilityDot(deviceId: device.id),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                reachabilityStatus.$1,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: reachabilityStatus.$2,
                ),
              ),
            ),
          ],
        ),
    ];
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.tv, color: selected ? theme.colorScheme.primary : null),
            if (selected)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    // Matches the card's own background, so the badge
                    // reads as cut into the icon rather than just
                    // floating on top of it.
                    border: Border.all(
                      color: theme.cardTheme.color ?? theme.colorScheme.surface,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 9,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
        title: Text(device.name, overflow: TextOverflow.ellipsis),
        subtitle: subtitleLines.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: subtitleLines,
              ),
        trailing: Tooltip(
          message: 'Device details',
          child: InkWell(
            onTap: onInfoTap,
            customBorder: const CircleBorder(),
            child: const Icon(Icons.info_outline),
          ),
        ),
      ),
    );
  }
}
