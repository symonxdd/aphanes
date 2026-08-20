import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/shared_preferences_provider.dart';

const String _filesTabVisiblePrefsKey = 'files_tab_visible';
const String _terminalTabVisiblePrefsKey = 'terminal_tab_visible';

/// Whether the Files tab shows in the bottom nav. Off by default: many
/// users will never touch it, and hiding it (rather than always showing
/// four tabs) keeps the nav bar uncluttered for them.
class FilesTabVisibilityController extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(
          _filesTabVisiblePrefsKey,
        ) ??
        false;
  }

  Future<void> set(bool visible) async {
    state = visible;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_filesTabVisiblePrefsKey, visible);
  }
}

final NotifierProvider<FilesTabVisibilityController, bool>
filesTabVisibleProvider =
    NotifierProvider<FilesTabVisibilityController, bool>(
      FilesTabVisibilityController.new,
    );

/// Whether the Terminal tab shows in the bottom nav. Off by default, for
/// the same reason as [filesTabVisibleProvider].
class TerminalTabVisibilityController extends Notifier<bool> {
  @override
  bool build() {
    return ref.watch(sharedPreferencesProvider).getBool(
          _terminalTabVisiblePrefsKey,
        ) ??
        false;
  }

  Future<void> set(bool visible) async {
    state = visible;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_terminalTabVisiblePrefsKey, visible);
  }
}

final NotifierProvider<TerminalTabVisibilityController, bool>
terminalTabVisibleProvider =
    NotifierProvider<TerminalTabVisibilityController, bool>(
      TerminalTabVisibilityController.new,
    );
