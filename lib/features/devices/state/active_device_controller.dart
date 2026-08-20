import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The device Apps/Files/Terminal act on. Tapping a device card on the
/// Devices tab sets it; "most recently tapped" is the active device.
class ActiveDeviceController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String deviceId) {
    state = deviceId;
  }

  void clearIfMatches(String deviceId) {
    if (state == deviceId) {
      state = null;
    }
  }
}

final NotifierProvider<ActiveDeviceController, String?> activeDeviceProvider =
    NotifierProvider<ActiveDeviceController, String?>(
      ActiveDeviceController.new,
    );
