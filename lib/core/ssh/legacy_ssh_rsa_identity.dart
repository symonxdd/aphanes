import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh2/dartssh2.dart';
import 'package:pointycastle/export.dart' as pc;

/// webOS's own embedded sshd predates RFC 8332 (2018): dartssh2 signs every
/// RSA identity with the modern rsa-sha2-256 algorithm only - an
/// unconditional change made in dartssh2 2.7.1 itself ("Upgrade rsa
/// authentication algorithm to rsa-sha2-256"), with no legacy fallback,
/// confirmed still true in 3.1.0 by reading key_pair/pkcs1_rsa_key_pair.dart
/// directly (`RsaPrivateKey.type` is a hardcoded getter). An sshd that old
/// has never heard of rsa-sha2-256 and rejects it outright - exactly what a
/// real TV did here (`SSHAuthFailError`: "All authentication methods
/// failed"), against a key that had already decrypted and ASN.1-parsed
/// successfully during pairing, so the key itself was never in question.
///
/// dartssh2's own auth loop already tries every offered identity in turn
/// before giving up (`ssh_client.dart`: `_identitiesLeft` is a queue, only
/// throwing once it's empty), so offering this alongside - not instead of -
/// the modern identity `SSHKeyPair.fromPem` already produces gives it a
/// second candidate the TV can actually verify, without regressing anything
/// for a server that does support rsa-sha2-256.
///
/// Built directly from the RSA key components dartssh2 already parsed
/// (`key.e/n/d/p/q`, all public on `RsaPrivateKey`) - only the signature
/// algorithm changes, never the key material. The public key and signature
/// are hand-encoded to the plain SSH wire format (RFC 4253 §6.6) rather
/// than reaching into dartssh2's own internal ssh-rsa host key class,
/// which isn't part of its public API - only `SSHRawHostKey`/
/// `SSHRawSignature` (both exported) carry the resulting bytes.
SSHIdentity legacySshRsaIdentity(RsaPrivateKey key) {
  final Uint8List publicKeyBlob = (BytesBuilder()
        ..add(sshString(utf8.encode('ssh-rsa')))
        ..add(sshMpint(key.e))
        ..add(sshMpint(key.n)))
      .toBytes();

  return SSHIdentity.custom(
    type: 'ssh-rsa',
    publicKey: SSHRawHostKey(publicKeyBlob),
    signer: (Uint8List data) {
      // Same PKCS#1 v1.5 signing dartssh2's own rsa-sha2-256 identity uses
      // (pkcs1_rsa_key_pair.dart), only with SHA-1's digest and DigestInfo
      // OID instead of SHA-256's - matching the "ssh-rsa" (classic, SHA-1)
      // algorithm this identity announces.
      final pc.RSASigner signer = pc.RSASigner(
        pc.SHA1Digest(),
        '06052b0e03021a',
      );
      signer.init(
        true,
        pc.PrivateKeyParameter<pc.RSAPrivateKey>(
          pc.RSAPrivateKey(key.n, key.d, key.p, key.q),
        ),
      );
      final Uint8List rawSignature = signer.generateSignature(data).bytes;
      final Uint8List signatureBlob = (BytesBuilder()
            ..add(sshString(utf8.encode('ssh-rsa')))
            ..add(sshString(rawSignature)))
          .toBytes();
      return SSHRawSignature(signatureBlob);
    },
  );
}

/// SSH wire "string" (RFC 4251 §5): a big-endian uint32 length prefix
/// followed by that many raw bytes.
Uint8List sshString(List<int> bytes) {
  // Big-endian is ByteData's own default for setUint32 - confirmed, not
  // assumed, since a wrong byte order here would fail silently.
  final ByteData length = ByteData(4)..setUint32(0, bytes.length);
  return (BytesBuilder()
        ..add(length.buffer.asUint8List())
        ..add(bytes))
      .toBytes();
}

/// SSH wire "mpint" (RFC 4251 §5): a string containing [value]'s
/// two's-complement bytes, MSB first, with a leading zero byte prepended
/// whenever the true magnitude's own high bit is set - RSA public/private
/// components here are always positive, so that's the only case this needs
/// to handle.
Uint8List sshMpint(BigInt value) {
  if (value == BigInt.zero) {
    return sshString(const []);
  }
  final int byteLength = (value.bitLength + 7) ~/ 8;
  final Uint8List magnitude = Uint8List(byteLength);
  BigInt remaining = value;
  for (int i = byteLength - 1; i >= 0; i--) {
    magnitude[i] = (remaining & BigInt.from(0xff)).toInt();
    remaining = remaining >> 8;
  }
  final bool needsLeadingZero = magnitude[0] & 0x80 != 0;
  return sshString(needsLeadingZero ? [0, ...magnitude] : magnitude);
}
