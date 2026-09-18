import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/installed_app.dart';
import 'app_explainers.dart';

class InstalledAppTile extends StatelessWidget {
  const InstalledAppTile({
    required this.app,
    required this.launching,
    required this.onLaunch,
    required this.onUninstall,
    super.key,
  });

  final InstalledApp app;

  /// True while a launch of this app is in flight; the Launch glyph
  /// becomes a spinner for as long as it is.
  final bool launching;
  final VoidCallback onLaunch;
  final VoidCallback onUninstall;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    // No Card, no surface of its own: the row sits on the page
    // background, and `shape` only clips the tap ripple.
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(Icons.apps),
      title: Text(app.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: app.vendor == null
                  ? app.version
                  : '${app.version} · ${app.vendor}',
            ),
            // The same "· Running" the desktop list appends, in the
            // accent so it reads as state rather than as more metadata.
            if (app.running)
              TextSpan(
                text: ' · Running',
                style: TextStyle(color: theme.colorScheme.primary),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LaunchSlot(app: app, launching: launching, onLaunch: onLaunch),
          IconButton(
            tooltip: 'Uninstall',
            icon: const Icon(Icons.delete_outline),
            onPressed: onUninstall,
          ),
        ],
      ),
    );
  }
}

/// The row's launch slot, one of three ways: a Launch button, a spinner
/// while a launch is in flight, or, once the app is running, the marker
/// the desktop app shows in place of its Launch button, tappable for
/// what "running" means here.
class _LaunchSlot extends StatelessWidget {
  const _LaunchSlot({
    required this.app,
    required this.launching,
    required this.onLaunch,
  });

  final InstalledApp app;
  final bool launching;
  final VoidCallback onLaunch;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (launching) {
      // The same footprint as the IconButton it stands in for, so the
      // uninstall glyph beside it does not shift while the spinner shows.
      return const SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (app.running) {
      return IconButton(
        tooltip: 'Running on the TV',
        icon: Icon(LucideIcons.circlePlay, color: theme.colorScheme.primary),
        onPressed: () => AppExplainers.running(context),
      );
    }
    return IconButton(
      tooltip: 'Launch on the TV',
      icon: const Icon(Icons.play_arrow_outlined),
      onPressed: onLaunch,
    );
  }
}
