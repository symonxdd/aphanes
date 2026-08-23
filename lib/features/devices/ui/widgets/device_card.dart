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
    // No Card, no surface color of its own: the row sits directly on the
    // page background. The rounded `shape` is only what the tap ripple is
    // clipped to, not a painted background.
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(Icons.tv, color: selected ? theme.colorScheme.primary : null),
      title: Text(device.name, overflow: TextOverflow.ellipsis),
      subtitle: subtitleLines.isEmpty ? null : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: subtitleLines),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[const _SelectedBadge(), const SizedBox(width: 12)],
          Tooltip(
            message: 'Device details',
            child: InkWell(onTap: onInfoTap, customBorder: const CircleBorder(), child: const Icon(Icons.info_outline)),
          ),
        ],
      ),
    );
  }
}

/// Marks the device the other tabs currently act on. Sized to the info
/// icon it sits beside, so the two read as one pair of trailing marks
/// rather than a badge that wandered in from somewhere else.
///
/// It used to sit on top of the TV icon, which meant it had to be drawn
/// with a background-colored ring to cut itself out of the glyph
/// underneath. Standing on its own here, it needs none of that.
class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  /// The box the adjacent info icon occupies. Matched so the two sit on
  /// the same center line and the row's spacing does not depend on which
  /// of them is present.
  static const double _box = 24;

  /// The circle actually painted inside that box. Smaller than the box on
  /// purpose: Icons.info_outline draws a thin outline that stops short of
  /// its own edges, so a solid circle filling the full 24 read as clearly
  /// the larger of the two. This is roughly the diameter that outline
  /// encloses, which is what makes them look like a matched pair.
  static const double _circle = 20;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Tooltip(
      message: 'Selected device',
      child: SizedBox(
        width: _box,
        height: _box,
        child: Center(
          child: Container(
            width: _circle,
            height: _circle,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
        // Material's Icons.check is a single fixed-weight glyph with no
        // way to make its stroke bolder. LucideIcons.check600 is the same
        // checkmark baked at a heavier stroke width (3.0) as a genuinely
        // separate bundled font weight - already shipped by
        // lucide_icons_flutter, no extra dependency or hand-drawn path
        // needed. The heaviest one actually bundled: the package's own
        // pubspec.yaml has a Lucide700 commented out, so 600 is the
        // ceiling.
            child: Icon(LucideIcons.check600, size: 13, color: theme.colorScheme.onPrimary),
          ),
        ),
      ),
    );
  }
}
