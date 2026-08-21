import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/ambient_backdrop.dart';
import '../../../core/ui/aphanes_title.dart';
import '../../../core/ui/app_icon_glyph.dart';
import '../../../core/ui/keep_alive_page.dart';
import '../../../core/ui/shader_warmup.dart';
import '../../apps/ui/apps_page.dart';
import '../../devices/models/device.dart';
import '../../devices/state/active_device_controller.dart';
import '../../devices/state/device_list_controller.dart';
import '../../devices/ui/devices_page.dart';
import '../../devices/ui/pair_device_page.dart';
import '../../devices/ui/widgets/reachability_dot.dart';
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
    initialPage: _indexOf(
      ref.read(homeTabProvider),
      ref.read(visibleHomeTabsProvider),
    ),
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

  static int _indexOf(HomeTab tab, List<HomeTab> visibleTabs) {
    final int index = visibleTabs.indexOf(tab);
    return index == -1 ? 0 : index;
  }

  Future<void> _animateToPage(int page, int tabCount) async {
    final int token = ++_tapTransitionToken;
    _isTapDrivenTransition = true;
    final int distance = (page - _pageController.page!.round()).abs();
    await _pageController.animateToPage(
      page,
      duration: Duration(milliseconds: 180 * distance.clamp(1, tabCount)),
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
    final List<HomeTab> visibleTabs = ref.watch(visibleHomeTabsProvider);
    final HomeTab selectedTab = ref.watch(homeTabProvider);
    final int tabIndex = _indexOf(selectedTab, visibleTabs);
    final ThemeData theme = Theme.of(context);

    ref.listen<HomeTab>(homeTabProvider, (HomeTab? previous, HomeTab next) {
      final int index = visibleTabs.indexOf(next);
      if (index == -1) {
        return;
      }
      final int current = _pageController.page?.round() ?? index;
      if (current != index) {
        unawaited(_animateToPage(index, visibleTabs.length));
      }
    });

    // A tab the user is currently on can disappear out from under them if
    // Files/Terminal gets toggled off in Settings while this page is still
    // open behind that sheet. Falls back to Devices rather than leaving
    // the selection pointed at a tab no longer in visibleTabs.
    ref.listen<List<HomeTab>>(visibleHomeTabsProvider, (
      List<HomeTab>? previous,
      List<HomeTab> next,
    ) {
      if (!next.contains(selectedTab)) {
        ref.read(homeTabProvider.notifier).select(HomeTab.devices);
      }
    });

    return Scaffold(
      appBar: AppBar(
        // Fixed regardless of tab (not just taller for Devices' two-line
        // title): a height that changed mid-swipe between tabs would be
        // visibly janky.
        toolbarHeight: 64,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        title: switch (selectedTab) {
          HomeTab.devices => const _DevicesTitle(),
          HomeTab.apps => const _TabTitle('Apps'),
          HomeTab.files => const _TabTitle('Files'),
          HomeTab.terminal => const _TabTitle('Terminal'),
        },
        actions: [
          if (selectedTab == HomeTab.devices)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Pair another device',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => const PairDevicePage(),
                ),
              ),
            ),
          if (selectedTab == HomeTab.apps) const _AddAppAction(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => SettingsSheet.show(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          const AmbientBackdrop(),
          const ShaderWarmup(),
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              if (!_isTapDrivenTransition) {
                ref.read(homeTabProvider.notifier).select(visibleTabs[page]);
              }
            },
            children: [
              for (final HomeTab tab in visibleTabs)
                KeepAlivePage(child: _pageFor(tab)),
            ],
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        selectedIndex: tabIndex,
        onDestinationSelected: (int index) =>
            ref.read(homeTabProvider.notifier).select(visibleTabs[index]),
        destinations: [
          for (final HomeTab tab in visibleTabs) _destinationFor(tab),
        ],
      ),
    );
  }

  Widget _pageFor(HomeTab tab) {
    return switch (tab) {
      HomeTab.devices => const DevicesPage(),
      HomeTab.apps => const AppsPage(),
      HomeTab.files => const FilesPage(),
      HomeTab.terminal => const TerminalPage(),
    };
  }

  NavigationDestination _destinationFor(HomeTab tab) {
    return switch (tab) {
      HomeTab.devices => const NavigationDestination(
        icon: Icon(Icons.tv_outlined),
        selectedIcon: Icon(Icons.tv),
        label: 'Devices',
      ),
      HomeTab.apps => const NavigationDestination(
        icon: Icon(Icons.apps_outlined),
        selectedIcon: Icon(Icons.apps),
        label: 'Apps',
      ),
      HomeTab.files => const NavigationDestination(
        icon: Icon(Icons.folder_outlined),
        selectedIcon: Icon(Icons.folder),
        label: 'Files',
      ),
      HomeTab.terminal => const NavigationDestination(
        icon: Icon(Icons.terminal_outlined),
        selectedIcon: Icon(Icons.terminal),
        label: 'Terminal',
      ),
    };
  }
}

Device? _findDeviceById(List<Device> devices, String id) {
  for (final Device device in devices) {
    if (device.id == id) {
      return device;
    }
  }
  return null;
}

/// The Apps tab's "+" app-bar action: opens the install-source chooser for
/// whichever device is active, hidden entirely when none is (matching
/// `AppsPage`'s own empty state for that case).
class _AddAppAction extends ConsumerWidget {
  const _AddAppAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? activeId = ref.watch(activeDeviceProvider);
    final List<Device>? devices = ref.watch(deviceListProvider).value;
    final Device? device = activeId == null || devices == null
        ? null
        : _findDeviceById(devices, activeId);
    if (device == null) {
      return const SizedBox.shrink();
    }
    return IconButton(
      icon: const Icon(Icons.add),
      tooltip: 'Install an app',
      onPressed: () => AddAppSheet.show(context, device),
    );
  }
}

/// The Apps/Files/Terminal tabs' app bar title: the tab name, plus a
/// small, muted subtitle naming whichever paired device those tabs act
/// on - the only place that's ever shown once a device is selected, since
/// the Devices tab's own card highlighting already covers the moment of
/// picking one. No subtitle at all while nothing is selected yet.
class _TabTitle extends ConsumerWidget {
  const _TabTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final String? activeId = ref.watch(activeDeviceProvider);
    final AsyncValue<List<Device>> devices = ref.watch(deviceListProvider);
    final String? deviceName = devices.value == null || activeId == null
        ? null
        : _findDeviceById(devices.value!, activeId)?.name;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        if (deviceName != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                deviceName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 6),
              ReachabilityDot(deviceId: activeId!),
            ],
          ),
      ],
    );
  }
}

/// The Devices tab's app bar title: the app icon glyph, the tappable
/// codename, and a small, muted subtitle naming the shipped app, so the
/// codename never appears on its own without the name a returning user
/// actually recognizes.
class _DevicesTitle extends StatelessWidget {
  const _DevicesTitle();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        // Stretches the icon to the exact height the title+subtitle
        // column ends up needing, rather than a guessed fixed size - the
        // AspectRatio then keeps it square at whatever that height is.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // AspectRatio + FittedBox, not LayoutBuilder: LayoutBuilder
          // can't sit inside anything computing intrinsic dimensions
          // (IntrinsicHeight here) - it throws rather than measure. This
          // gets the same "render at whatever height stretch hands it"
          // result without needing to know that height up front.
          const AspectRatio(
            aspectRatio: 1,
            child: FittedBox(child: AppIconGlyph(size: 40)),
          ),
          const SizedBox(width: 10),
          _DevicesTitleText(theme: theme),
        ],
      ),
    );
  }
}

class _DevicesTitleText extends StatelessWidget {
  const _DevicesTitleText({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AphanesTitle(),
        Text(
          'A webOS Dev Mode Manager',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
