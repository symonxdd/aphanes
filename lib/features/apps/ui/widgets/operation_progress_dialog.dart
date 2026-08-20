import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/luna_operation_progress.dart';
import '../../state/app_operation_controller.dart';
import '../../state/app_operation_state.dart';

/// Shared progress UI for both install and uninstall: a non-dismissible
/// dialog while the operation is running (the TV is mid-write, closing
/// this shouldn't feel like it cancelled anything), a Close button once it
/// reaches a terminal state.
class OperationProgressDialog extends ConsumerWidget {
  const OperationProgressDialog({
    required this.provider,
    required this.title,
    super.key,
  });

  final NotifierProvider<AppOperationController, AppOperationState> provider;
  final String title;

  /// Starts [run] and shows the dialog for [provider]'s progress. [run] is
  /// expected to be `ref.read(provider.notifier).run(someStream)` - started
  /// here rather than inside `build()` so it fires exactly once regardless
  /// of how many times this dialog rebuilds.
  static Future<void> show(
    BuildContext context, {
    required NotifierProvider<AppOperationController, AppOperationState>
    provider,
    required String title,
    required VoidCallback run,
  }) {
    run();
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext _) =>
          OperationProgressDialog(provider: provider, title: title),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppOperationState state = ref.watch(provider);
    final bool running = state is AppOperationIdle || state is AppOperationRunning;
    return PopScope(
      canPop: !running,
      child: AlertDialog(
        title: Text(title),
        content: _content(context, state),
        actions: running
            ? null
            : [
                TextButton(
                  onPressed: () {
                    ref.read(provider.notifier).reset();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
      ),
    );
  }

  Widget _content(BuildContext context, AppOperationState state) {
    final ThemeData theme = Theme.of(context);
    return switch (state) {
      AppOperationIdle() => const _ProgressRow(label: 'Starting...'),
      AppOperationRunning(:final LunaOperationProgress progress) => switch (progress) {
        LunaOperationUploading(:final sentBytes, :final totalBytes) => _ProgressRow(
          label:
              'Uploading... '
              '${totalBytes == 0 ? 0 : ((sentBytes / totalBytes) * 100).clamp(0, 100).toStringAsFixed(0)}%',
          value: totalBytes == 0 ? null : sentBytes / totalBytes,
        ),
        LunaOperationVerifying() => const _ProgressRow(
          label: 'Verifying upload...',
        ),
        LunaOperationWorking(:final message) => _ProgressRow(label: message),
        LunaOperationSucceeded() => const _ProgressRow(label: 'Finishing...'),
      },
      AppOperationSucceeded() => Row(
        children: [
          Icon(Icons.check_circle, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          const Expanded(child: Text('Done')),
        ],
      ),
      AppOperationFailed(:final message) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    };
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(value: value),
        const SizedBox(height: 12),
        Text(label),
      ],
    );
  }
}
