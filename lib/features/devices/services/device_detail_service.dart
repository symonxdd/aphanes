import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:http/http.dart' as http;

import '../../../core/ssh/luna_command_service.dart';
import '../../../core/ssh/ssh_connection_service.dart';
import '../models/device.dart';
import '../models/device_detail.dart';
import '../models/device_info.dart';
import '../models/devmode_status.dart';

/// Fetches live info from a paired TV for its detail page: static
/// device/firmware facts and its current webOS Developer Mode session
/// status. Reference: dev-manager-desktop's own Info tab
/// (DeviceManagerService.getDeviceInfo, DevModeService.status,
/// src-tauri/src/plugins/devmode.rs), verified directly against its
/// source rather than assumed.
class DeviceDetailService {
  DeviceDetailService({
    SshConnectionService? connectionService,
    LunaCommandService? lunaCommandService,
    http.Client? httpClient,
  }) : _connectionService = connectionService ?? SshConnectionService(),
       _luna = lunaCommandService ?? LunaCommandService(),
       _http = httpClient ?? http.Client();

  final SshConnectionService _connectionService;
  final LunaCommandService _luna;
  final http.Client _http;

  static const String _devModeTokenPath = '/var/luna/preferences/devmode_enabled';
  static final RegExp _tokenPattern = RegExp(r'^[0-9a-zA-Z]+$');

  Future<DeviceDetail> fetch(Device device) async {
    final SSHClient client = await _connect(device);
    try {
      final DeviceInfo info = await _fetchDeviceInfo(client);
      final DevModeStatus devMode = await _fetchDevModeStatus(client);
      return DeviceDetail(info: info, devMode: devMode);
    } finally {
      await client.close();
    }
  }

  /// Tells the TV to open its own Developer Mode app with a flag that
  /// makes it extend the current session on launch - the same mechanism
  /// as manually reopening that app on the TV, just triggered remotely.
  /// This visibly foregrounds that app on the TV; there is no quieter
  /// way to extend a session, confirmed directly from
  /// dev-manager-desktop's own implementation
  /// (applicationManager/launch, no other path exists there either).
  Future<void> renew(Device device) async {
    final SSHClient client = await _connect(device);
    try {
      await _luna.call(
        client,
        'luna://com.webos.applicationManager/launch',
        const {
          'id': 'com.palmdts.devmode',
          'subscribe': false,
          'params': {'extend': true},
        },
      );
    } finally {
      await client.close();
    }
  }

  Future<SSHClient> _connect(Device device) {
    return _connectionService.connect(
      host: device.host,
      port: device.port,
      username: device.username,
      privateKeyPem: device.privateKeyPem,
    );
  }

  Future<DeviceInfo> _fetchDeviceInfo(SSHClient client) async {
    final Map<String, dynamic> systemInfo = await _luna.call(
      client,
      'luna://com.webos.service.tv.systemproperty/getSystemInfo',
      const {
        'keys': ['firmwareVersion', 'modelName', 'sdkVersion', 'otaId'],
      },
    );
    Map<String, dynamic>? osInfo;
    try {
      osInfo = await _luna.call(
        client,
        'luna://com.palm.systemservice/osInfo/query',
        const {
          'parameters': [
            'device_name',
            'webos_manufacturing_version',
            'webos_release',
          ],
        },
      );
    } on LunaCallException {
      osInfo = null;
    }

    String? otaId = systemInfo['otaId'] as String?;
    if (otaId == null || otaId.isEmpty) {
      otaId = await _fetchOtaIdFallback(client);
    }

    String? socName = osInfo?['device_name'] as String?;
    if (socName == null || socName.isEmpty) {
      socName = await _fetchSocNameFallback(client);
    }

    return DeviceInfo(
      modelName: systemInfo['modelName'] as String?,
      firmwareVersion: systemInfo['firmwareVersion'] as String?,
      webosVersion:
          (osInfo?['webos_release'] as String?) ??
          systemInfo['sdkVersion'] as String?,
      otaId: otaId,
      socName: socName,
    );
  }

  /// A handful of devices do not report otaId directly - falls back to
  /// parsing it out of getDeviceUuid's billingId, matching
  /// dev-manager-desktop's own fallback exactly. Best-effort: this is
  /// already a fallback for a fairly minor field, so any failure here
  /// just means the field stays blank rather than failing the whole
  /// page load.
  Future<String?> _fetchOtaIdFallback(SSHClient client) async {
    try {
      final Map<String, dynamic> result = await _luna.call(
        client,
        'luna://com.webos.service.sdx/getDeviceUuid',
        const {},
      );
      final String? billingId = result['billingId'] as String?;
      if (billingId == null) {
        return null;
      }
      return Uri.splitQueryString(billingId)['modelName'];
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fetchSocNameFallback(SSHClient client) async {
    try {
      final Uint8List output = await client.run(
        'cat ${LunaCommandService.shellEscape('/etc/prefs/properties/machineName')}',
      );
      final String text = utf8.decode(output, allowMalformed: true).trim();
      return text.isEmpty ? null : text;
    } catch (_) {
      return null;
    }
  }

  Future<DevModeStatus> _fetchDevModeStatus(SSHClient client) async {
    final String? token = await _readDevModeToken(client);
    if (token == null) {
      return const DevModeStatus();
    }
    try {
      final String? remaining = await _checkRemainingTime(token);
      return DevModeStatus(token: token, remaining: remaining);
    } catch (_) {
      return DevModeStatus(token: token);
    }
  }

  Future<String?> _readDevModeToken(SSHClient client) async {
    try {
      final Uint8List output = await client.run(
        'cat ${LunaCommandService.shellEscape(_devModeTokenPath)}',
      );
      final String token = utf8.decode(output, allowMalformed: true).trim();
      return _tokenPattern.hasMatch(token) ? token : null;
    } catch (_) {
      return null;
    }
  }

  /// The one call in this app that talks to a server other than the
  /// paired TV itself: LG's own official Developer Mode session
  /// endpoint, mirroring dev-manager-desktop's own implementation
  /// exactly (there is no local-only way to learn a session's
  /// remaining time). A deliberate, scoped, explicitly-approved
  /// exception to this project's local-network-only rule - documented
  /// in CLAUDE.md. The session token is sent to LG's own endpoint for
  /// this purpose only; it is not sent anywhere else.
  Future<String?> _checkRemainingTime(String token) async {
    final Uri uri = Uri.https(
      'developer.lge.com',
      '/secure/CheckDevModeSession.dev',
      {'sessionToken': token},
    );
    final http.Response response = await _http
        .get(uri)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      return null;
    }
    final Map<String, dynamic> body =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (body['result'] != 'success') {
      return null;
    }
    return body['errorMsg'] as String?;
  }
}
