import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ssh/luna_command_service.dart';
import '../../../core/ssh/ssh_connection_service.dart';
import '../../../core/ui/ambient_backdrop.dart';
import '../../devices/models/device.dart';
import '../../devices/state/active_device_controller.dart';
import '../../devices/state/device_list_controller.dart';
import '../../devices/state/device_reachability_controller.dart';
import '../../devices/ui/pair_device_page.dart';
import '../../devices/ui/widgets/unreachable_message.dart';
import '../../home/state/home_tab_controller.dart';
import '../models/installed_app.dart';
import '../state/app_operation_controller.dart';
import '../state/installed_apps_controller.dart';
import 'catalog_page.dart';
import 'widgets/installed_app_tile.dart';
import 'widgets/operation_progress_dialog.dart';

/// Turns a failed apps-list load into the widget that's actually useful.
/// This only ever runs once the reachability gate in [_AppsList] has
/// already passed, so a [SshConnectionException] reaching here can never
/// be the plain "TV is off" case (that's handled entirely by the gate,
/// before this ever loads) - it's always something more specific that
/// happened despite the TV answering, so its own message is shown
/// directly rather than folded into a generic "not reachable" line.
Widget _loadErrorWidget(Object error) {
  final String message = switch (error) {
    SshConnectionException(:final String message) => message,
    LunaCallException(:final String message) => message,
    _ => "Couldn't load this TV's apps.",
  };
  return Text(message, textAlign: TextAlign.center);
}

class AppsPage extends ConsumerWidget {
  const AppsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Device>> devicesAsync = ref.watch(deviceListProvider);

    return devicesAsync.when(
      data: (List<Device> devices) {
        if (devices.isEmpty) {
          return const _NoDevicesEmptyState();
        }
        final String? activeId = ref.watch(activeDeviceProvider);
        Device? active;
        for (final Device d in devices) {
          if (d.id == activeId) {
            active = d;
            break;
          }
        }
        if (active == null) {
          return const _NoActiveDeviceEmptyState();
        }
        return _AppsList(device: active);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object _, StackTrace _) =>
          const Center(child: Text("Couldn't load paired devices.")),
    );
  }
}

class _NoDevicesEmptyState extends StatelessWidget {
  const _NoDevicesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pair a device to manage apps'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext _) => const PairDevicePage(),
                ),
              ),
              child: const Text('Pair a device'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActiveDeviceEmptyState extends ConsumerWidget {
  const _NoActiveDeviceEmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a device on the Devices tab to manage its apps'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(homeTabProvider.notifier).select(HomeTab.devices),
              child: const Text('Go to Devices'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppsList extends ConsumerWidget {
  const _AppsList({required this.device});

  final Device device;

  Future<void> _confirmUninstall(
    BuildContext context,
    WidgetRef ref,
    InstalledApp app,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Uninstall "${app.title}"?'),
        content: const Text(
          "This removes the app and its data from the TV. This can't be "
          'undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) {
      return;
    }
    unawaited(
      OperationProgressDialog.show(
        context,
        provider: uninstallOperationProvider,
        title: 'Uninstalling ${app.title}...',
        run: () => ref
            .read(uninstallOperationProvider.notifier)
            .run(ref.read(appsServiceProvider).uninstall(device, app.id)),
      ),
    );
  }

  Widget _installedAppsBody(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<InstalledApp>> apps = ref.watch(
      installedAppsProvider,
    );
    return RefreshIndicator(
      onRefresh: () => ref.read(installedAppsProvider.notifier).refresh(),
      child: apps.when(
        data: (List<InstalledApp> list) => list.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('No apps installed on this TV yet')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (BuildContext _, int _) =>
                    const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) =>
                    InstalledAppTile(
                      app: list[index],
                      onUninstall: () =>
                          _confirmUninstall(context, ref, list[index]),
                    ),
              ),
        loading: () => ListView(
          children: const [
            SizedBox(height: 160),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (Object error, StackTrace _) => ListView(
          children: [
            const SizedBox(height: 160),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _loadErrorWidget(error),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Gated on a fast reachability probe before ever touching the
    // installed-apps list: that list's own load does a full SSH
    // connect+auth, which has a much longer timeout meant for a
    // deliberate action, not landing on this tab. Without this gate, an
    // off TV meant sitting on a bare spinner for the length of that
    // longer timeout with nothing to look at in the meantime.
    final AsyncValue<bool> reachable = ref.watch(
      deviceReachabilityProvider(device.id),
    );

    return Stack(
      children: [
        const AmbientBackdrop(),
        switch (reachable) {
          AsyncData(:final bool value) when value => _installedAppsBody(
            context,
            ref,
          ),
          AsyncData() || AsyncError() => _UnreachableState(device: device),
          _ => const Center(child: CircularProgressIndicator()),
        },
      ],
    );
  }
}

/// The Apps tab with an off (or unreachable) TV behind it. Offers two
/// ways back: a plainly visible button, and the same pull-to-refresh
/// gesture the loaded list above already answers to.
///
/// Both, not either. The gesture alone would be invisible here - nothing
/// about a screen of centered text suggests it scrolls, so nobody would
/// think to try it - and the button alone would make the gesture work on
/// one of this tab's two states but not the other.
class _UnreachableState extends ConsumerStatefulWidget {
  const _UnreachableState({required this.device});

  final Device device;

  @override
  ConsumerState<_UnreachableState> createState() => _UnreachableStateState();
}

class _UnreachableStateState extends ConsumerState<_UnreachableState> {
  bool _checking = false;

  Future<void> _recheck() async {
    if (_checking) {
      return;
    }
    setState(() => _checking = true);
    ref.invalidate(deviceReachabilityProvider(widget.device.id));
    try {
      // The installed-apps list watches this same probe, so a TV that
      // answers this time is already loading its apps by the time this
      // widget goes away.
      await ref.read(
        deviceReachabilityProvider(widget.device.id).future,
      );
    } catch (_) {
      // A failed probe is a `false` result, not an error, and either way
      // the rebuilt widget below is what reports it.
    }
    // A TV that came back takes this widget off the tree mid-await.
    if (mounted) {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _recheck,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            // This screen is shorter than its viewport and so would not
            // scroll at all by default, which is exactly the case where
            // the pull-to-refresh gesture has to keep working.
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      UnreachableMessage(deviceName: widget.device.name),
                      const SizedBox(height: 32),
                      FilledButton.tonalIcon(
                        onPressed: _checking ? null : _recheck,
                        icon: _checking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(
                          _checking ? 'Checking...' : 'Check again',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The "+" app-bar action's destination on the Apps tab: a choice between
/// the two install sources this milestone supports.
class AddAppSheet extends ConsumerWidget {
  const AddAppSheet({required this.device, super.key});

  final Device device;

  static Future<void> show(BuildContext context, Device device) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext _) => AddAppSheet(device: device),
    );
  }

  Future<void> _pickAndInstall(
    BuildContext context,
    WidgetRef ref,
    Device device,
  ) async {
    final PlatformFile? picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['ipk'],
    );
    final String? path = picked?.path;
    if (path == null || !context.mounted) {
      return;
    }
    unawaited(
      OperationProgressDialog.show(
        context,
        provider: installOperationProvider,
        title: 'Installing...',
        run: () => ref
            .read(installOperationProvider.notifier)
            .run(
              ref.read(appsServiceProvider).installFromFile(device, File(path)),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Install an app', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.storefront_outlined),
              title: const Text('Browse Homebrew catalog'),
              subtitle: const Text(
                'Community apps from the public webOS Homebrew store',
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (BuildContext _) => CatalogPage(device: device),
                  ),
                );
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Install from a file'),
              subtitle: const Text('Pick an .ipk already on this phone'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndInstall(context, ref, device);
              },
            ),
          ],
        ),
      ),
    );
  }
}
