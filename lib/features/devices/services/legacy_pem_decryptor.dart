import 'dart:convert';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:pointycastle/export.dart';

class PemDecryptionException implements Exception {
  const PemDecryptionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _CipherSpec {
  const _CipherSpec(this.keyBytes, this.engine);

  final int keyBytes;
  final BlockCipher Function() engine;
}

/// Decrypts the "traditional" OpenSSL encrypted PEM format webOS's devmode
/// key server actually returns: a `RSA PRIVATE KEY` block carrying
/// `Proc-Type: 4,ENCRYPTED` / `DEK-Info: <cipher>,<hex iv>` header lines,
/// confirmed by querying a real TV's key server directly (`GET /webos_rsa`
/// on port 9991). This predates PKCS8/PBES2 entirely: the key is derived
/// from the passphrase with OpenSSL's classic EVP_BytesToKey (iterated MD5),
/// salted with the first 8 bytes of the IV given in DEK-Info, rather than
/// PBKDF2 with its own salt/iteration count. Neither webosbrew/ares-cli-rs
/// nor dev-manager-desktop implement this decryption themselves - they hand
/// the raw response to libssh, which supports this legacy format natively -
/// so there is no reference source to port from; this reimplements
/// OpenSSL's own documented EVP_BytesToKey/PEM-header algorithm directly
/// against Dart's ASN.1/crypto primitives.
abstract final class LegacyPemDecryptor {
  static final Map<String, _CipherSpec> _ciphers = {
    'AES-128-CBC': const _CipherSpec(16, AESEngine.new),
    'AES-192-CBC': const _CipherSpec(24, AESEngine.new),
    'AES-256-CBC': const _CipherSpec(32, AESEngine.new),
    'DES-EDE3-CBC': const _CipherSpec(24, DESedeEngine.new),
  };

  static String decryptToPkcs1Pem(String encryptedPem, String passphrase) {
    final _PemHeaderBlock block = _splitHeadersAndBody(encryptedPem);

    final String? dekInfo = block.headers['DEK-Info'];
    if (dekInfo == null) {
      throw const PemDecryptionException(
        "That didn't look like a pairing key. Make sure Developer Mode "
        'and Key Server are both currently on, then try again.',
      );
    }

    final List<String> dekParts = dekInfo.split(',');
    if (dekParts.length != 2) {
      throw const PemDecryptionException(
        "That didn't look like a pairing key. Make sure Developer Mode "
        'and Key Server are both currently on, then try again.',
      );
    }
    final String cipherName = dekParts[0].trim().toUpperCase();
    final Uint8List iv = _hexDecode(dekParts[1].trim());

    final _CipherSpec? cipherSpec = _ciphers[cipherName];
    if (cipherSpec == null) {
      throw const PemDecryptionException(
        'Unsupported private key encryption cipher.',
      );
    }

    // OpenSSL's classic PEM encryption always salts EVP_BytesToKey with
    // just the first 8 bytes of the IV, no separate salt field, regardless
    // of how long the IV itself is for the chosen cipher.
    final Uint8List salt = iv.sublist(0, 8);
    final Uint8List key = _evpBytesToKey(
      passphrase: passphrase,
      salt: salt,
      keyLength: cipherSpec.keyBytes,
    );

    final Uint8List encryptedBytes;
    try {
      encryptedBytes = base64.decode(block.body);
    } on FormatException {
      throw const PemDecryptionException(
        "That didn't look like a pairing key. Make sure Developer Mode "
        'and Key Server are both currently on, then try again.',
      );
    }

    final Uint8List decrypted;
    try {
      decrypted = _decryptCbc(cipherSpec.engine(), key, iv, encryptedBytes);
      // A wrong passphrase can still produce bytes that happen to satisfy
      // PKCS7 padding; parsing as the expected ASN.1 structure catches
      // that case too rather than handing back garbage as a "valid" key.
      ASN1Parser(decrypted).nextObject();
    } catch (_) {
      throw const PemDecryptionException(
        'Passphrase is incorrect, or the key is corrupted.',
      );
    }

    return _derToPem(decrypted, 'RSA PRIVATE KEY');
  }

  static Uint8List _evpBytesToKey({
    required String passphrase,
    required Uint8List salt,
    required int keyLength,
  }) {
    final Uint8List passphraseBytes = Uint8List.fromList(
      utf8.encode(passphrase),
    );
    final MD5Digest digest = MD5Digest();
    final BytesBuilder derived = BytesBuilder();
    Uint8List previous = Uint8List(0);
    while (derived.length < keyLength) {
      digest.reset();
      digest.update(previous, 0, previous.length);
      digest.update(passphraseBytes, 0, passphraseBytes.length);
      digest.update(salt, 0, salt.length);
      final Uint8List block = Uint8List(digest.digestSize);
      digest.doFinal(block, 0);
      derived.add(block);
      previous = block;
    }
    return derived.toBytes().sublist(0, keyLength);
  }

  static Uint8List _decryptCbc(
    BlockCipher engine,
    Uint8List key,
    Uint8List iv,
    Uint8List ciphertext,
  ) {
    final PaddedBlockCipher cipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(engine),
    )..init(false, PaddedBlockCipherParameters(ParametersWithIV(KeyParameter(key), iv), null));
    return cipher.process(ciphertext);
  }

  static Uint8List _hexDecode(String hex) {
    final Uint8List bytes = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  static _PemHeaderBlock _splitHeadersAndBody(String pem) {
    const String begin = '-----BEGIN RSA PRIVATE KEY-----';
    const String end = '-----END RSA PRIVATE KEY-----';
    final int start = pem.indexOf(begin);
    final int stop = pem.indexOf(end);
    if (start == -1 || stop == -1) {
      throw const PemDecryptionException(
        "That didn't look like a pairing key. Make sure Developer Mode "
        'and Key Server are both currently on, then try again.',
      );
    }

    final List<String> lines = pem
        .substring(start + begin.length, stop)
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .toList();

    final Map<String, String> headers = {};
    final StringBuffer body = StringBuffer();
    bool inHeaders = true;
    for (final String line in lines) {
      if (inHeaders && line.contains(':')) {
        final int colon = line.indexOf(':');
        headers[line.substring(0, colon).trim()] = line
            .substring(colon + 1)
            .trim();
        continue;
      }
      inHeaders = false;
      body.write(line);
    }

    return _PemHeaderBlock(headers: headers, body: body.toString());
  }

  static String _derToPem(Uint8List der, String type) {
    final String body = base64.encode(der);
    final StringBuffer pem = StringBuffer('-----BEGIN $type-----\n');
    for (int i = 0; i < body.length; i += 64) {
      pem.writeln(body.substring(i, i + 64 > body.length ? body.length : i + 64));
    }
    pem.write('-----END $type-----\n');
    return pem.toString();
  }
}

class _PemHeaderBlock {
  const _PemHeaderBlock({required this.headers, required this.body});

  final Map<String, String> headers;
  final String body;
}
