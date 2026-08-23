import 'device_info.dart';
import 'devmode_status.dart';

/// The combined live-fetched payload for a device's detail page: static
/// device/firmware facts plus its current Developer Mode session status.
/// Fetched together over one SSH connection, not two - see
/// DeviceDetailService.fetch.
class DeviceDetail {
  const DeviceDetail({required this.info, required this.devMode});

  final DeviceInfo info;
  final DevModeStatus devMode;
}
