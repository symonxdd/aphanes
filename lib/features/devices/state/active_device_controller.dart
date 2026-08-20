import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The device Apps/Files/Terminal act on. Tapping a device card sets it;
/// there is no dedicated switcher UI yet (planned for Milestone 6), so
/// "most recently tapped" is simply the active device for now.
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
