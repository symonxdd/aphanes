import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;

import 'legacy_pem_decryptor.dart';

// A top-level function, not a method: compute() spawns an isolate and
// needs a plain function reference it can send across, not a closure
// bound to a service instance.
bool _tryDecrypt((String pem, String passphrase) args) {
  try {
    LegacyPemDecryptor.decryptToPkcs1Pem(args.$1, args.$2);
    return true;
  } on PemDecryptionException {
    return false;
  }
}

/// Thrown with a message specific enough to show inline on the pairing
/// screen (wrong passphrase, unreachable host, etc.), never a raw
/// exception's toString().
class DevmodePairingException implements Exception {
  const DevmodePairingException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PairedDevmodeCredentials {
  const PairedDevmodeCredentials({required this.privateKeyPem, this.model});

  final String privateKeyPem;
  final String? model;
}

/// Performs the Developer Mode key-exchange handshake: trades the TV's
/// on-screen passphrase for a permanent SSH private key, usable as user
/// [devModeUsername] on [devModePort] from then on.
///
/// The passphrase is not a fresh one-time code: per LG's own webOS Open
/// Source Edition source (`com.palm.service.devmode`), it's the first six
/// characters of the device's NDUID, so it's fixed for a given TV and
/// will read the same every time that TV's Developer Mode app is opened.
///
/// Protocol, informed by webosbrew/ares-cli-rs's
/// (Apache-2.0) `common/connection/src/setup.rs`: the TV runs a plain-HTTP
/// "key server" on [keyServerPort], separate from the SSH port. A bare
/// `GET /webos_rsa HTTP/1.0` returns a legacy OpenSSL-encrypted RSA private
/// key PEM in the response body (confirmed directly against a real TV;
/// ares-cli-rs itself doesn't hardcode the format, it defers to libssh,
/// which reads both that and PKCS8 transparently) - unauthenticated, since
/// the passphrase is never sent over the wire at all. It's used purely
/// client-side afterward, to decrypt that PEM into something usable for
/// SSH auth. There is deliberately no TLS here (the TV's key server has
/// none) and no SSH host-key pinning (webOS devices don't keep a stable
/// host key across resets), matching the reference implementation's own
/// choices.
class DevmodePairingService {
  DevmodePairingService({this._keyServerPort = keyServerPort});

  static const int devModePort = 9922;
  static const String devModeUsername = 'prisoner';
  static const int keyServerPort = 9991;

  final int _keyServerPort;

  /// [cachedEncryptedPem], when given, is reused as-is instead of fetching
  /// the key from the TV again. The UI already fetches and caches this
  /// once, to validate the passphrase live as it's typed; reusing that
  /// same blob here (rather than a second, independent fetch) is what
  /// guarantees this decrypts the exact bytes the live check already
  /// approved.
  Future<PairedDevmodeCredentials> pair({
    required String host,
    required String passphrase,
    String? cachedEncryptedPem,
  }) async {
    final String encryptedPem = cachedEncryptedPem ?? await _fetchKey(host);

    final String privateKeyPem;
    try {
      privateKeyPem = LegacyPemDecryptor.decryptToPkcs1Pem(
        encryptedPem,
        passphrase,
      );
    } on PemDecryptionException catch (e) {
      throw DevmodePairingException(e.message);
    }

    return PairedDevmodeCredentials(privateKeyPem: privateKeyPem);
  }

  /// A soft, best-effort check for whether [host] is currently serving the
  /// devmode key server - i.e. whether pairing would have a chance of
  /// succeeding. Never throws: connection failures, timeouts, and
  /// malformed responses all just mean false. Meant to run frequently
  /// (e.g. as the user types an IP address), so timeouts are short and
  /// nothing here is the authoritative pairing attempt itself.
  Future<bool> probe(String host) async {
    try {
      final Uint8List response = await _requestKeyServer(
        host,
        connectTimeout: const Duration(seconds: 1),
        responseTimeout: const Duration(seconds: 1),
      );
      return _statusCodeOf(response) == 200;
    } catch (_) {
      return false;
    }
  }

  /// Fetches the TV's encrypted key blob without attempting to decrypt it.
  /// Exposed separately from [pair] so the UI can fetch once (e.g. as soon
  /// as [probe] finds a TV) and validate several passphrase attempts
  /// against that same cached blob afterward, entirely locally, without a
  /// network round trip per keystroke.
  Future<String> fetchEncryptedKey(String host) => _fetchKey(host);

  /// Checks whether [passphrase] would successfully decrypt
  /// [encryptedPem] - no network involved, just the same decrypt [pair]
  /// would eventually do. Runs off the UI thread via [compute]: the key
  /// derivation (OpenSSL's EVP_BytesToKey, see [LegacyPemDecryptor]) is
  /// CPU-bound and can take long enough to jank a frame if run inline.
  Future<bool> validatePassphrase(String encryptedPem, String passphrase) {
    return compute(_tryDecrypt, (encryptedPem, passphrase));
  }

  Future<String> _fetchKey(String host) async {
    final Uint8List response = await _requestKeyServer(
      host,
      connectTimeout: const Duration(seconds: 10),
      responseTimeout: const Duration(seconds: 10),
    );
    return _parseKeyServerResponse(response);
  }

  Future<Uint8List> _requestKeyServer(
    String host, {
    required Duration connectTimeout,
    required Duration responseTimeout,
  }) async {
    final Socket socket;
    try {
      socket = await Socket.connect(
        host,
        _keyServerPort,
        timeout: connectTimeout,
      );
    } on SocketException {
      throw const DevmodePairingException(
        "Couldn't reach that IP address. Check it's correct and that "
        'the phone and TV are on the same network.',
      );
    } on TimeoutException {
      throw const DevmodePairingException(
        'Connection timed out. Check the IP address and that the phone '
        'and TV are on the same network.',
      );
    }

    try {
      final BytesBuilder buffer = BytesBuilder();
      final Completer<void> done = Completer<void>();
      socket
        ..write('GET /webos_rsa HTTP/1.0\r\n')
        ..write('Connection: close\r\n')
        ..write('\r\n');
      socket.listen(
        buffer.add,
        onDone: () {
          if (!done.isCompleted) {
            done.complete();
          }
        },
        onError: (Object _) {
          if (!done.isCompleted) {
            done.complete();
          }
        },
        cancelOnError: true,
      );
      await done.future.timeout(
        responseTimeout,
        onTimeout: () => throw const DevmodePairingException(
          'The TV stopped responding while fetching the pairing key.',
        ),
      );
      return buffer.toBytes();
    } finally {
      unawaited(socket.close());
    }
  }

  int? _statusCodeOf(Uint8List response) {
    final String raw = latin1.decode(response);
    final int firstLineEnd = raw.indexOf('\r\n');
    if (firstLineEnd == -1) {
      return null;
    }
    final RegExpMatch? statusMatch = RegExp(
      r'^HTTP/\d\.\d (\d{3})',
    ).firstMatch(raw.substring(0, firstLineEnd));
    return statusMatch == null ? null : int.tryParse(statusMatch.group(1)!);
  }

  String _parseKeyServerResponse(Uint8List response) {
    final String raw = latin1.decode(response);
    final int headerEnd = raw.indexOf('\r\n\r\n');
    if (headerEnd == -1) {
      throw const DevmodePairingException(
        'The TV sent an unexpected response. Make sure Developer Mode '
        'and its key server are turned on.',
      );
    }
    if (_statusCodeOf(response) != 200) {
      throw const DevmodePairingException(
        'No pairing key is available. Make sure Developer Mode is on '
        'and the key server is enabled in the Developer Mode app.',
      );
    }

    return raw.substring(headerEnd + 4);
  }
}
