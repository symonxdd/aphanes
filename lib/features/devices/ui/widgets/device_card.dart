import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/device.dart';
import '../../state/device_reachability_controller.dart';
import 'reachability_dot.dart';

class DeviceCard extends ConsumerWidget {
  const DeviceCard({required this.device, required this.selected, required this.onTap, required this.onInfoTap, super.key});

  final Device device;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onInfoTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<bool> reachable = ref.watch(deviceReachabilityProvider(device.id));
    // Always one of these three, never hidden: a card that goes quiet
    // once a healthy TV resolves gives no visible confirmation the check
    // ever ran at all, which reads as broken even when it isn't. Colors
    // match ReachabilityDot's own, so the dot and this label never
    // disagree about what state they're both reporting.
    final (String, Color) reachabilityStatus = switch (reachable) {
      AsyncData(:final bool value) when value => ('TV is reachable', Colors.green),
      AsyncData() || AsyncError() => ('TV not reachable. Is it turned on?', theme.colorScheme.error),
      _ => ('Checking availability...', theme.colorScheme.onSurfaceVariant),
    };
    final List<Widget> subtitleLines = [
      if (device.model != null) Text(device.model!),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReachabilityDot(deviceId: device.id),
          const SizedBox(width: 6),
          Flexible(
            child: Text(reachabilityStatus.$1, style: theme.textTheme.bodySmall?.copyWith(color: reachabilityStatus.$2)),
          ),
        ],
      ),
    ];
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.tv, color: selected ? theme.colorScheme.primary : null),
            if (selected)
              Positioned(
                // Top-left, not bottom-right: Icons.tv's stand/feet sit
                // at the bottom of the glyph, and a badge this size
                // covered them there - the top corner only clips into
                // the screen area, which reads fine without it.
                left: -4,
                top: -6,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    // Matches the card's own background, so the badge
                    // reads as cut into the icon rather than just
                    // floating on top of it.
                    border: Border.all(color: theme.cardTheme.color ?? theme.colorScheme.surface, width: 2),
                  ),
                  // Material's Icons.check is a single fixed-weight
                  // glyph with no way to make its stroke bolder.
                  // LucideIcons.check600 is the same checkmark baked at
                  // a heavier stroke width (3.0) as a genuinely separate
                  // bundled font weight - already shipped by
                  // lucide_icons_flutter, no extra dependency or
                  // hand-drawn path needed. The heaviest one actually
                  // bundled - the package's own pubspec.yaml has a
                  // Lucide700 commented out, so 600 is the ceiling.
                  child: Icon(LucideIcons.check600, size: 13, color: theme.colorScheme.onPrimary),
                ),
              ),
          ],
        ),
        title: Text(device.name, overflow: TextOverflow.ellipsis),
        subtitle: subtitleLines.isEmpty ? null : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: subtitleLines),
        trailing: Tooltip(
          message: 'Device details',
          child: InkWell(onTap: onInfoTap, customBorder: const CircleBorder(), child: const Icon(Icons.info_outline)),
        ),
      ),
    );
  }
}
