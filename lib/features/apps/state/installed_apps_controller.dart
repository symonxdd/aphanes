import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../devices/models/device.dart';
import '../../devices/state/active_device_controller.dart';
import '../../devices/state/device_list_controller.dart';
import '../models/installed_app.dart';
import '../services/apps_service.dart';

final Provider<AppsService> appsServiceProvider = Provider<AppsService>(
  (Ref ref) => AppsService(),
);

/// The active device's installed apps. Resolves quietly to an empty list
/// when there's no active device (rather than an error) - the page itself
/// is what decides whether to show a "pick a device" prompt instead of
/// this list at all, same split as `DevicesPage` handling its own empty
/// state around `deviceListProvider`.
class InstalledAppsController extends AsyncNotifier<List<InstalledApp>> {
  @override
  Future<List<InstalledApp>> build() async {
    final String? activeId = ref.watch(activeDeviceProvider);
    if (activeId == null) {
      return const [];
    }
    final List<Device> devices = await ref.watch(deviceListProvider.future);
    final Device? device = _findDevice(devices, activeId);
    if (device == null) {
      return const [];
    }
    return ref.watch(appsServiceProvider).listInstalled(device);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Device? _findDevice(List<Device> devices, String id) {
    for (final Device device in devices) {
      if (device.id == id) {
        return device;
      }
    }
    return null;
  }
}

final AsyncNotifierProvider<InstalledAppsController, List<InstalledApp>>
installedAppsProvider =
    AsyncNotifierProvider<InstalledAppsController, List<InstalledApp>>(
      InstalledAppsController.new,
    );
