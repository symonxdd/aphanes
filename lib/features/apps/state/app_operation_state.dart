import '../models/luna_operation_progress.dart';

/// The state of one install or uninstall action, as driven by
/// `AppOperationController`.
sealed class AppOperationState {
  const AppOperationState();
}

class AppOperationIdle extends AppOperationState {
  const AppOperationIdle();
}

class AppOperationRunning extends AppOperationState {
  const AppOperationRunning(this.progress);

  final LunaOperationProgress progress;
}

class AppOperationSucceeded extends AppOperationState {
  const AppOperationSucceeded();
}

class AppOperationFailed extends AppOperationState {
  const AppOperationFailed(this.message);

  final String message;
}
