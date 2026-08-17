import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/aphanes_title.dart';
import '../../../core/ui/keep_alive_page.dart';
import '../../apps/ui/apps_page.dart';
import '../../devices/ui/devices_page.dart';
import '../../files/ui/files_page.dart';
import '../../settings/ui/settings_sheet.dart';
import '../../terminal/ui/terminal_page.dart';
import '../state/home_tab_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final PageController _pageController = PageController(
    initialPage: ref.read(homeTabProvider),
  );

  // Guards PageView.onPageChanged, which fires for every intermediate page
  // during a tap-driven animateToPage scroll, against re-writing
  // homeTabProvider mid-flight (which would flicker the app bar title and
  // nav-bar highlight through every tab in between). Only a genuine swipe
  // (this flag false) should update the provider from onPageChanged.
  bool _isTapDrivenTransition = false;
  int _tapTransitionToken = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _animateToPage(int page) async {
    final int token = ++_tapTransitionToken;
    _isTapDrivenTransition = true;
    final int distance = (page - _pageController.page!.round()).abs();
    await _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 180 * distance.clamp(1, homePageCount)),
      curve: Curves.easeOutCubic,
    );
    // A second tap can interrupt this animation before it completes; only
    // the call that started the latest (still-current) transition should
    // clear the guard.
    if (token == _tapTransitionToken) {
      _isTapDrivenTransition = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int tabIndex = ref.watch(homeTabProvider);

    ref.listen<int>(homeTabProvider, (int? previous, int next) {
      final int current = _pageController.page?.round() ?? next;
      if (current != next) {
        unawaited(_animateToPage(next));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: switch (tabIndex) {
          devicesTabIndex => const AphanesTitle(),
          appsTabIndex => const Text('Apps'),
          filesTabIndex => const Text('Files'),
          _ => const Text('Terminal'),
        },
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => SettingsSheet.show(context),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (int page) {
          if (!_isTapDrivenTransition) {
            ref.read(homeTabProvider.notifier).onPageChanged(page);
          }
        },
        children: const [
          KeepAlivePage(child: DevicesPage()),
          KeepAlivePage(child: AppsPage()),
          KeepAlivePage(child: FilesPage()),
          KeepAlivePage(child: TerminalPage()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        selectedIndex: tabIndex,
        onDestinationSelected: (int index) =>
            ref.read(homeTabProvider.notifier).select(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.tv_outlined),
            selectedIcon: Icon(Icons.tv),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps),
            label: 'Apps',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal_outlined),
            selectedIcon: Icon(Icons.terminal),
            label: 'Terminal',
          ),
        ],
      ),
    );
  }
}
