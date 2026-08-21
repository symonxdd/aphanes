import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ssh/ssh_connection_service.dart';
import '../models/luna_operation_progress.dart';
import '../services/app_catalog_service.dart';
import '../services/apps_service.dart';
import '../services/luna_command_service.dart';
import 'app_operation_state.dart';
import 'installed_apps_controller.dart';

/// Drives one install or uninstall action's progress. Install and
/// uninstall each get their own provider instance of this same class
/// (below) so running one never clobbers the other's visible state, even
/// though the state shape and error handling are identical either way.
class AppOperationController extends Notifier<AppOperationState> {
  @override
  AppOperationState build() => const AppOperationIdle();

  Future<void> run(Stream<LunaOperationProgress> stream) async {
    state = const AppOperationRunning(LunaOperationWorking('Starting...'));
    try {
      await for (final LunaOperationProgress progress in stream) {
        state = AppOperationRunning(progress);
      }
      state = const AppOperationSucceeded();
      unawaited(ref.read(installedAppsProvider.notifier).refresh());
    } on AppInstallException catch (e) {
      state = AppOperationFailed(e.message);
    } on SshConnectionException catch (e) {
      state = AppOperationFailed(e.message);
    } on LunaCallException catch (e) {
      state = AppOperationFailed(e.message);
    } on CatalogIntegrityException catch (e) {
      state = AppOperationFailed(e.message);
    } on CatalogException catch (e) {
      state = AppOperationFailed(e.message);
    } catch (e) {
      // An unclassified exception is a bug in what this catches, not a
      // real-world condition to word nicely. Shown in full rather than a
      // generic message: there's no crash reporting in this app, so this
      // is the only way a failure like this is ever diagnosable at all.
      state = AppOperationFailed('Something went wrong: $e');
    }
  }

  void reset() => state = const AppOperationIdle();
}

final NotifierProvider<AppOperationController, AppOperationState>
installOperationProvider =
    NotifierProvider<AppOperationController, AppOperationState>(
      AppOperationController.new,
    );

final NotifierProvider<AppOperationController, AppOperationState>
uninstallOperationProvider =
    NotifierProvider<AppOperationController, AppOperationState>(
      AppOperationController.new,
    );
