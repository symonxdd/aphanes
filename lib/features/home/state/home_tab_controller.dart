import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The four bottom-nav destinations, and the [PageView] positions they map
/// to. Kept as separate index spaces (rather than reusing one enum) so a
/// future sub-tab (mirroring Rivus's Library tracks/folders split) can be
/// inserted as extra page positions without renumbering destinations.
const int devicesTabIndex = 0;
const int appsTabIndex = 1;
const int filesTabIndex = 2;
const int terminalTabIndex = 3;

const int devicesPage = 0;
const int appsPage = 1;
const int filesPage = 2;
const int terminalPage = 3;
const int homePageCount = 4;

/// Single source of truth for "which page is current". Bottom-nav taps and
/// user swipes both funnel through this controller so the app bar title,
/// nav-bar highlight, and [PageView] position never disagree.
class HomeTabController extends Notifier<int> {
  @override
  int build() => devicesPage;

  /// Called when the bottom nav bar is tapped.
  void select(int tabIndex) {
    state = tabIndex;
  }

  /// Called only for a genuine user swipe, never for the intermediate pages
  /// a tap-driven [PageController.animateToPage] scrolls past.
  void onPageChanged(int page) {
    state = page;
  }
}

final NotifierProvider<HomeTabController, int> homeTabProvider =
    NotifierProvider<HomeTabController, int>(HomeTabController.new);
