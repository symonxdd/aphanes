import 'dart:async';
import 'dart:io';

import 'package:dartssh2/dartssh2.dart';

/// Thrown with a message specific enough to show inline in the UI, never a
/// raw exception's toString().
class SshConnectionException implements Exception {
  const SshConnectionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Opens an authenticated SSH connection to a paired TV. Takes discrete
/// connection details rather than the `Device` model itself, so this stays
/// usable by any feature (Apps, Files, Terminal) without core/ depending on
/// a specific feature's model.
///
/// One connection per call, closed by the caller when done - there's no
/// cached/shared session here. Apps only ever needs a connection for the
/// length of one user-triggered action; Terminal's very different
/// (interactive, long-lived pty) needs shouldn't be forced through whatever
/// lifecycle this milestone happens to pick.
///
/// No SSH host-key pinning, matching `DevmodePairingService`'s own choice:
/// webOS devices don't keep a stable host key across resets.
class SshConnectionService {
  Future<SSHClient> connect({
    required String host,
    required int port,
    required String username,
    required String privateKeyPem,
  }) async {
    final SSHSocket socket;
    try {
      socket = await SSHSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );
    } on SocketException {
      throw const SshConnectionException(
        "Couldn't reach that TV. Check it's on the same network.",
      );
    } on TimeoutException {
      throw const SshConnectionException(
        'Connection to the TV timed out.',
      );
    }

    final SSHClient client = SSHClient(
      socket,
      username: username,
      identities: SSHKeyPair.fromPem(privateKeyPem),
      disableHostkeyVerification: true,
    );

    try {
      await client.authenticated.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      await client.close();
      throw const SshConnectionException(
        'The TV stopped responding while connecting.',
      );
    } catch (_) {
      await client.close();
      throw const SshConnectionException(
        "Couldn't authenticate with the TV. It may need pairing again.",
      );
    }

    return client;
  }
}
