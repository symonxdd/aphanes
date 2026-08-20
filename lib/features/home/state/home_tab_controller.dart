import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/state/tab_visibility_controller.dart';

/// The four possible bottom-nav destinations. Devices and Apps are always
/// present; Files and Terminal can be hidden from Settings, so this is an
/// identity, not a fixed page position - [visibleHomeTabsProvider] is what
/// maps a subset of these to actual [PageView]/[NavigationBar] positions.
enum HomeTab { devices, apps, files, terminal }

/// The ordered, currently-visible subset of [HomeTab]. Devices and Apps
/// are unconditional; Files and Terminal only appear once their Settings
/// toggle is on.
final Provider<List<HomeTab>> visibleHomeTabsProvider = Provider<List<HomeTab>>(
  (Ref ref) {
    final bool filesVisible = ref.watch(filesTabVisibleProvider);
    final bool terminalVisible = ref.watch(terminalTabVisibleProvider);
    return [
      HomeTab.devices,
      HomeTab.apps,
      if (filesVisible) HomeTab.files,
      if (terminalVisible) HomeTab.terminal,
    ];
  },
);

/// Single source of truth for "which tab is current". Bottom-nav taps and
/// user swipes both funnel through this controller so the app bar title,
/// nav-bar highlight, and [PageView] position never disagree.
class HomeTabController extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.devices;

  void select(HomeTab tab) {
    state = tab;
  }
}

final NotifierProvider<HomeTabController, HomeTab> homeTabProvider =
    NotifierProvider<HomeTabController, HomeTab>(HomeTabController.new);
