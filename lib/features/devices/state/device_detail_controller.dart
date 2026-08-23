import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ssh/ssh_connection_service.dart';
import '../models/device.dart';
import '../models/device_detail.dart';
import '../services/device_detail_service.dart';
import 'device_info_cache_controller.dart';
import 'device_list_controller.dart';
import 'device_reachability_controller.dart';

final Provider<DeviceDetailService> deviceDetailServiceProvider =
    Provider<DeviceDetailService>((Ref ref) => DeviceDetailService());

/// Live info fetched directly from a paired TV for its detail page:
/// static device/firmware facts plus its current Developer Mode session
/// status. Gated on the same fast reachability probe the Apps tab uses,
/// so an off TV fails fast instead of sitting on the full SSH connect
/// timeout with nothing to show.
///
/// Still `autoDispose`, and so still re-fetched on every visit: the page
/// showing cached facts immediately is not a reason to stop checking
/// them. What the cache changes is only what is on screen while that
/// check runs - see `deviceInfoCacheProvider`, which this writes the
/// static half of every successful fetch into.
final deviceDetailProvider = FutureProvider.autoDispose
    .family<DeviceDetail, String>((Ref ref, String deviceId) async {
      final List<Device> devices = await ref.watch(deviceListProvider.future);
      Device? device;
      for (final Device d in devices) {
        if (d.id == deviceId) {
          device = d;
          break;
        }
      }
      if (device == null) {
        throw const SshConnectionException("Couldn't find that device.");
      }
      final bool reachable = await ref.watch(
        deviceReachabilityProvider(device.id).future,
      );
      if (!reachable) {
        throw const SshConnectionException("Couldn't reach that TV.");
      }
      final DeviceDetail detail = await ref
          .read(deviceDetailServiceProvider)
          .fetch(device);
      // Only the static half is kept. The Developer Mode session is a
      // live countdown and a credential, so it is re-read every time and
      // never stored here.
      //
      // Deliberately not awaited: writing the cache is a side effect for
      // the next visit, and nothing on this one waits on it. Awaiting it
      // put a secure-storage round trip between a finished fetch and the
      // page being told about it, which is latency the user pays for no
      // benefit.
      unawaited(
        ref.read(deviceInfoCacheProvider.notifier).put(deviceId, detail.info),
      );
      return detail;
    });

sealed class DevModeRenewState {
  const DevModeRenewState();
}

class DevModeRenewIdle extends DevModeRenewState {
  const DevModeRenewIdle();
}

class DevModeRenewInProgress extends DevModeRenewState {
  const DevModeRenewInProgress();
}

class DevModeRenewSucceeded extends DevModeRenewState {
  const DevModeRenewSucceeded();
}

class DevModeRenewFailed extends DevModeRenewState {
  const DevModeRenewFailed(this.message);

  final String message;
}

/// Drives the device detail page's "Renew" button. A separate,
/// short-lived SSH connection per tap - matches every other
/// user-triggered TV action in this app (install, uninstall), rather
/// than reusing whatever connection deviceDetailProvider's own load
/// already closed.
class DevModeRenewController extends Notifier<DevModeRenewState> {
  @override
  DevModeRenewState build() => const DevModeRenewIdle();

  Future<void> renew(Device device) async {
    state = const DevModeRenewInProgress();
    try {
      await ref.read(deviceDetailServiceProvider).renew(device);
      state = const DevModeRenewSucceeded();
    } catch (e) {
      state = DevModeRenewFailed('Something went wrong: $e');
    }
  }

  void reset() => state = const DevModeRenewIdle();
}

final NotifierProvider<DevModeRenewController, DevModeRenewState>
devModeRenewProvider =
    NotifierProvider<DevModeRenewController, DevModeRenewState>(
      DevModeRenewController.new,
    );
