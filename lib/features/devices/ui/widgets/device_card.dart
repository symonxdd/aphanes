import 'package:flutter/material.dart';

import '../../models/device.dart';

class DeviceCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
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
        title: Text(device.name),
        subtitle: device.model == null ? null : Text(device.model!),
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
