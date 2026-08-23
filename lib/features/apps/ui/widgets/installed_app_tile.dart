import 'package:flutter/material.dart';

import '../../models/installed_app.dart';

class InstalledAppTile extends StatelessWidget {
  const InstalledAppTile({
    required this.app,
    required this.onUninstall,
    super.key,
  });

  final InstalledApp app;
  final VoidCallback onUninstall;

  @override
  Widget build(BuildContext context) {
    // No Card, no surface of its own: the row sits on the page
    // background, and `shape` only clips the tap ripple.
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.apps),
      title: Text(app.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        app.vendor == null ? app.version : '${app.version} · ${app.vendor}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Tooltip(
        message: 'Uninstall',
        child: InkWell(
          onTap: onUninstall,
          customBorder: const CircleBorder(),
          child: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}
