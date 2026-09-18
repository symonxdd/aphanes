import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dartssh2/dartssh2.dart';

import '../../../core/ssh/luna_command_service.dart';
import '../../../core/ssh/ssh_connection_service.dart';
import '../../devices/models/device.dart';
import '../models/installed_app.dart';
import '../models/luna_operation_progress.dart';

/// Thrown when an install or uninstall fails for a reason specific enough
/// to show inline (a rejected install, a corrupted upload), never a raw
/// exception's toString().
class AppInstallException implements Exception {
  const AppInstallException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Lists, launches, installs, and uninstalls apps on a paired TV over the same
/// luna-bus protocol webosbrew/ares-cli-rs (Apache-2.0) uses, verified
/// directly against its `ares-install/src/{list,install,remove}.rs`.
///
/// Every install/uninstall opens its own SSH connection for the length of
/// that one action and closes it when done - there's no cached session
/// here, matching how the reference CLI itself behaves per invocation.
class AppsService {
  AppsService({
    SshConnectionService? connectionService,
    LunaCommandService? lunaCommandService,
  }) : _connectionService = connectionService ?? SshConnectionService(),
       _luna = lunaCommandService ?? LunaCommandService();

  final SshConnectionService _connectionService;
  final LunaCommandService _luna;

  static const String _remoteTempDir = '/media/developer/temp';

  /// The installed apps, each marked running or not, from two calls on
  /// the one connection: asking for the running list here costs nothing
  /// extra, so the list opens already knowing.
  Future<List<InstalledApp>> listInstalled(Device device) async {
    final SSHClient client = await _connect(device);
    try {
      final Map<String, dynamic> response = await _luna.call(
        client,
        'luna://com.webos.applicationManager/dev/listApps',
        const {},
      );
      final List<dynamic> apps = (response['apps'] as List<dynamic>?) ?? [];
      // A running list that fails leaves every app marked not running;
      // the list itself still shows.
      Set<String> running = const {};
      try {
        running = (await _listRunning(client)).toSet();
      } on LunaCallException {
        // Not worth failing the whole list over.
      }
      return apps
          .cast<Map<String, dynamic>>()
          .where((Map<String, dynamic> app) => app['visible'] == true)
          .map(InstalledApp.fromJson)
          .map(
            (InstalledApp app) =>
                app.copyWith(running: running.contains(app.id)),
          )
          .toList();
    } finally {
      await client.close();
    }
  }

  /// Opens an app on the TV's screen, as pressing it on the TV would, and
  /// returns the ids of the apps running afterwards. The TV accepts a
  /// launch a moment before it lists the app as running, so the list is
  /// read a few times until the app shows up in it; a launch the TV
  /// accepted is reported as running even if it never did. Only ever runs
  /// from the Launch button.
  Future<List<String>> launch(Device device, String appId) async {
    final SSHClient client = await _connect(device);
    try {
      final Map<String, dynamic> response = await _luna.call(
        client,
        'luna://com.webos.applicationManager/launch',
        {'id': appId},
      );
      if (response['returnValue'] == false) {
        throw LunaCallException(
          response['errorText'] as String? ?? "The TV couldn't open that app.",
        );
      }
      List<String> running = const [];
      for (int attempt = 0; attempt < _launchListAttempts; attempt++) {
        if (attempt > 0) {
          await Future<void>.delayed(_launchListInterval);
        }
        try {
          running = await _listRunning(client);
        } on LunaCallException {
          running = const [];
        }
        if (running.contains(appId)) {
          return running;
        }
      }
      return [...running, appId];
    } finally {
      await client.close();
    }
  }

  /// How often, and how far apart, the running list is read after a launch.
  static const int _launchListAttempts = 4;
  static const Duration _launchListInterval = Duration(milliseconds: 500);

  /// The ids of the apps running on the TV right now, as
  /// `applicationManager/dev/running` reports them: the one form of that
  /// call the Developer Mode account is allowed to make.
  Future<List<String>> _listRunning(SSHClient client) async {
    final Map<String, dynamic> response = await _luna.call(
      client,
      'luna://com.webos.applicationManager/dev/running',
      const {},
    );
    if (response['returnValue'] == false) {
      throw const LunaCallException("The TV couldn't list its running apps.");
    }
    final List<dynamic> running = (response['running'] as List<dynamic>?) ?? [];
    return running
        .whereType<Map<String, dynamic>>()
        .map((Map<String, dynamic> app) => app['id'])
        .whereType<String>()
        .toList();
  }

  /// Installs a local .ipk file (from the file picker). Read fully into
  /// memory before uploading - ipk packages are small enough (typically
  /// low tens of MB at most) that streaming straight off disk isn't worth
  /// the extra complexity here.
  Stream<LunaOperationProgress> installFromFile(Device device, File file) {
    final StreamController<LunaOperationProgress> controller =
        StreamController<LunaOperationProgress>();
    unawaited(
      _runInstall(controller, device, () => file.readAsBytes()),
    );
    return controller.stream;
  }

  /// Installs already-downloaded-and-verified .ipk bytes, e.g. from
  /// [AppCatalogService.downloadAndVerify]. The caller is responsible for
  /// having checked these bytes against the catalog manifest's hash first -
  /// this method trusts whatever it's handed.
  Stream<LunaOperationProgress> installBytes(Device device, Uint8List bytes) {
    final StreamController<LunaOperationProgress> controller =
        StreamController<LunaOperationProgress>();
    unawaited(_runInstall(controller, device, () async => bytes));
    return controller.stream;
  }

  Stream<LunaOperationProgress> uninstall(Device device, String packageId) {
    final StreamController<LunaOperationProgress> controller =
        StreamController<LunaOperationProgress>();
    unawaited(_runUninstall(controller, device, packageId));
    return controller.stream;
  }

  Future<void> _runInstall(
    StreamController<LunaOperationProgress> controller,
    Device device,
    Future<Uint8List> Function() loadBytes,
  ) async {
    SSHClient? client;
    String? remotePath;
    try {
      final Uint8List bytes = await loadBytes();
      final String checksum = sha256.convert(bytes).toString();

      client = await _connect(device);
      remotePath = '$_remoteTempDir/ares_install_${checksum.substring(0, 10)}.ipk';

      final SftpClient sftp = await client.sftp();
      try {
        await sftp.mkdir(_remoteTempDir);
      } on SftpError {
        // Already exists - fine.
      }
      final SftpFile remoteFile = await sftp.open(
        remotePath,
        mode:
            SftpFileOpenMode.create |
            SftpFileOpenMode.write |
            SftpFileOpenMode.truncate,
      );
      await remoteFile.write(
        Stream.value(bytes),
        onProgress: (int sent) {
          controller.add(LunaOperationUploading(sent, bytes.length));
        },
      );
      await remoteFile.close();

      controller.add(const LunaOperationVerifying());
      final String? remoteChecksum = await _sha256sum(client, remotePath);
      if (remoteChecksum != null && remoteChecksum != checksum) {
        throw const AppInstallException(
          'Upload is corrupted - the TV received different bytes than were sent.',
        );
      }

      await for (final Map<String, dynamic> message in _luna.subscribe(
        client,
        'luna://com.webos.appInstallService/dev/install',
        {
          'id': 'com.ares.defaultName',
          'ipkUrl': remotePath,
          'subscribe': true,
        },
      )) {
        final LunaOperationProgress? progress = _parseInstallerMessage(
          message,
          successPattern: RegExp('installed', caseSensitive: false),
        );
        if (progress == null) {
          continue;
        }
        controller.add(progress);
        if (progress is LunaOperationSucceeded) {
          break;
        }
      }
      await controller.close();
    } catch (e) {
      controller.addError(e);
      await controller.close();
    } finally {
      if (client != null && remotePath != null) {
        try {
          final SftpClient sftp = await client.sftp();
          await sftp.remove(remotePath);
        } catch (_) {
          // Best-effort cleanup only.
        }
      }
      await client?.close();
    }
  }

  Future<void> _runUninstall(
    StreamController<LunaOperationProgress> controller,
    Device device,
    String packageId,
  ) async {
    SSHClient? client;
    try {
      client = await _connect(device);
      await for (final Map<String, dynamic> message in _luna.subscribe(
        client,
        'luna://com.webos.appInstallService/dev/remove',
        {'id': packageId, 'subscribe': true},
      )) {
        final LunaOperationProgress? progress = _parseInstallerMessage(
          message,
          successPattern: RegExp('removed', caseSensitive: false),
        );
        if (progress == null) {
          continue;
        }
        controller.add(progress);
        if (progress is LunaOperationSucceeded) {
          break;
        }
      }
      await controller.close();
    } catch (e) {
      controller.addError(e);
      await controller.close();
    } finally {
      await client?.close();
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

  /// Mirrors the reference CLI's post-upload check: compares the uploaded
  /// file's checksum against the local one, but only if the TV actually has
  /// `sha256sum` - devices that don't just skip this check rather than
  /// failing the install over a missing tool.
  Future<String?> _sha256sum(SSHClient client, String remotePath) async {
    final Uint8List output = await client.run(
      'sha256sum ${LunaCommandService.shellEscape(remotePath)}',
    );
    final String text = utf8.decode(output, allowMalformed: true).trim();
    if (text.isEmpty) {
      return null;
    }
    final List<String> parts = text.split(RegExp(r'\s+'));
    return parts.isEmpty ? null : parts.first;
  }

  /// Mirrors `map_installer_message` in the reference CLI's `install.rs`:
  /// a `FAILED` state throws, a `SUCCESS`-prefixed or [successPattern]
  /// state means done, anything else is progress text.
  LunaOperationProgress? _parseInstallerMessage(
    Map<String, dynamic> message, {
    required RegExp successPattern,
  }) {
    final Map<String, dynamic>? details =
        message['details'] as Map<String, dynamic>?;
    final String? state = details?['state'] as String?;
    if (state == null) {
      return null;
    }
    if (RegExp('FAILED', caseSensitive: false).hasMatch(state)) {
      throw AppInstallException(
        details?['reason'] as String? ?? 'The TV rejected that request.',
      );
    }
    if (RegExp(r'^SUCCESS', caseSensitive: false).hasMatch(state) ||
        successPattern.hasMatch(state)) {
      return LunaOperationSucceeded(details?['packageId'] as String? ?? '');
    }
    return LunaOperationWorking(state);
  }
}
