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
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: const Icon(Icons.apps),
        title: Text(app.title),
        subtitle: Text(
          app.vendor == null ? app.version : '${app.version} · ${app.vendor}',
        ),
        trailing: Tooltip(
          message: 'Uninstall',
          child: InkWell(
            onTap: onUninstall,
            customBorder: const CircleBorder(),
            child: const Icon(Icons.delete_outline),
          ),
        ),
      ),
    );
  }
}
