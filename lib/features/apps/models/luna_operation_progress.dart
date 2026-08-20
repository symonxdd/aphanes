/// A step in an install or uninstall operation, as it happens - emitted on
/// a [Stream] so the UI can show live progress rather than just a spinner
/// until the whole thing finishes.
sealed class LunaOperationProgress {
  const LunaOperationProgress();
}

/// Uploading the .ipk to the TV over SFTP. Install only.
class LunaOperationUploading extends LunaOperationProgress {
  const LunaOperationUploading(this.sentBytes, this.totalBytes);

  final int sentBytes;
  final int totalBytes;
}

/// Comparing the uploaded file's checksum against what was sent. Install
/// only - matches the reference CLI's post-upload integrity check.
class LunaOperationVerifying extends LunaOperationProgress {
  const LunaOperationVerifying();
}

/// A raw status line from the TV's install/remove service (e.g.
/// "installing : 40"). Shown as-is; the TV controls the wording.
class LunaOperationWorking extends LunaOperationProgress {
  const LunaOperationWorking(this.message);

  final String message;
}

/// The TV reported success. Terminal state - no further events follow.
class LunaOperationSucceeded extends LunaOperationProgress {
  const LunaOperationSucceeded(this.packageId);

  final String packageId;
}
