import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ssh/luna_command_service.dart';
import '../../../core/ssh/ssh_connection_service.dart';
import '../../devices/models/device.dart';
import 'installed_apps_controller.dart';

/// Drives the Launch button on an installed app's row: one short-lived
/// SSH connection per tap, like every other user-triggered TV action.
/// The state is the set of app ids with a launch in flight, so each row
/// can show its own spinner while the rest stay tappable.
class AppLaunchController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Opens [appId] on [device]'s screen. Returns null on success, or the
  /// message to show when the TV refused or could not be reached. The
  /// running list the TV reports afterwards is pushed into the installed
  /// apps list, so the row flips to "Running" without a refetch.
  Future<String?> launch(Device device, String appId) async {
    if (state.contains(appId)) {
      return null;
    }
    state = {...state, appId};
    try {
      final List<String> running = await ref
          .read(appsServiceProvider)
          .launch(device, appId);
      ref.read(installedAppsProvider.notifier).setRunning(running);
      return null;
    } on LunaCallException catch (e) {
      return e.message;
    } on SshConnectionException catch (e) {
      return e.message;
    } catch (e) {
      // An unclassified exception is a bug in what this catches, not a
      // real-world condition to word nicely. Shown in full rather than a
      // generic message: there's no crash reporting in this app, so this
      // is the only way a failure like this is ever diagnosable at all.
      return 'Something went wrong: $e';
    } finally {
      state = {...state}..remove(appId);
    }
  }
}

final NotifierProvider<AppLaunchController, Set<String>> appLaunchProvider =
    NotifierProvider<AppLaunchController, Set<String>>(AppLaunchController.new);
