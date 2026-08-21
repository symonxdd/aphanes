import 'dart:convert';
import 'dart:typed_data';

import 'package:aphanes/core/ssh/legacy_ssh_rsa_identity.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart' as pc;

/// Generates a small (fast to produce, not meant to be secure) RSA key
/// pair, wrapped as the same `RsaPrivateKey` type `SSHKeyPair.fromPem`
/// itself returns - so these tests exercise legacySshRsaIdentity exactly
/// as it's actually called.
RsaPrivateKey _generateTestKey() {
  final pc.FortunaRandom random = pc.FortunaRandom();
  random.seed(
    pc.KeyParameter(
      Uint8List.fromList(List<int>.generate(32, (int i) => (i * 37 + 11) % 256)),
    ),
  );
  final pc.RSAKeyGenerator generator = pc.RSAKeyGenerator()
    ..init(
      pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.from(65537), 512, 5),
        random,
      ),
    );
  final pc.AsymmetricKeyPair<pc.PublicKey, pc.PrivateKey> pair = generator
      .generateKeyPair();
  final pc.RSAPrivateKey privateKey = pair.privateKey as pc.RSAPrivateKey;
  final BigInt n = privateKey.n!;
  final BigInt d = privateKey.privateExponent!;
  final BigInt p = privateKey.p!;
  final BigInt q = privateKey.q!;
  final BigInt e = BigInt.from(65537);

  return RsaPrivateKey(
    BigInt.zero,
    n,
    e,
    d,
    p,
    q,
    d % (p - BigInt.one),
    d % (q - BigInt.one),
    q.modInverse(p),
  );
}

/// Reads one SSH wire "string" (RFC 4251 §5) starting at [offset], returning
/// its bytes and the offset just past it - used to independently decode
/// what legacySshRsaIdentity produced, rather than trusting sshString's own
/// round-trip.
(Uint8List, int) _readSshString(Uint8List data, int offset) {
  final ByteData view = ByteData.sublistView(data, offset, offset + 4);
  final int length = view.getUint32(0);
  final int start = offset + 4;
  return (data.sublist(start, start + length), start + length);
}

void main() {
  group('sshString', () {
    test('encodes an empty byte list', () {
      expect(sshString(const []), [0, 0, 0, 0]);
    });

    test('encodes a length prefix followed by the raw bytes', () {
      expect(sshString(utf8.encode('ssh-rsa')), [
        0, 0, 0, 7, //
        0x73, 0x73, 0x68, 0x2d, 0x72, 0x73, 0x61, // "ssh-rsa"
      ]);
    });
  });

  group('sshMpint', () {
    // RFC 4251 §5's own worked examples - the two's-complement encoding
    // this implements is easy to get subtly wrong (off-by-one on the
    // leading-zero rule especially), so this checks against the spec's
    // own reference values rather than only this code's self-consistency.
    test('encodes zero as an empty string', () {
      expect(sshMpint(BigInt.zero), [0, 0, 0, 0]);
    });

    test('encodes a value with no leading zero needed', () {
      expect(sshMpint(BigInt.parse('9a378f9b2e332a7', radix: 16)), [
        0, 0, 0, 8, //
        0x09, 0xa3, 0x78, 0xf9, 0xb2, 0xe3, 0x32, 0xa7,
      ]);
    });

    test('prepends a zero byte when the high bit would otherwise be set', () {
      expect(sshMpint(BigInt.parse('80', radix: 16)), [
        0, 0, 0, 2, //
        0x00, 0x80,
      ]);
    });
  });

  group('legacySshRsaIdentity', () {
    test('announces the classic ssh-rsa algorithm', () {
      final SSHIdentity identity = legacySshRsaIdentity(_generateTestKey());
      expect(identity.type, 'ssh-rsa');
    });

    test('encodes the public key as algorithm name + mpint(e) + mpint(n)', () {
      final RsaPrivateKey key = _generateTestKey();
      final SSHIdentity identity = legacySshRsaIdentity(key);

      final Uint8List encoded = identity.toPublicKey().encode();
      final Uint8List expected = (BytesBuilder()
            ..add(sshString(utf8.encode('ssh-rsa')))
            ..add(sshMpint(key.e))
            ..add(sshMpint(key.n)))
          .toBytes();
      expect(encoded, expected);
    });

    test(
      'signs with a signature the public key can independently verify',
      () async {
        final RsaPrivateKey key = _generateTestKey();
        final SSHIdentity identity = legacySshRsaIdentity(key);
        final Uint8List message = Uint8List.fromList(
          utf8.encode('ssh session exchange hash'),
        );

        final SSHSignature signature = await identity.sign(message);
        final Uint8List encoded = signature.encode();

        // Decode the wire blob the same way a real SSH server would:
        // algorithm name, then the raw signature bytes.
        final (Uint8List algorithmNameBytes, int afterAlgorithm) =
            _readSshString(encoded, 0);
        expect(utf8.decode(algorithmNameBytes), 'ssh-rsa');
        final (Uint8List rawSignature, int afterSignature) = _readSshString(
          encoded,
          afterAlgorithm,
        );
        expect(afterSignature, encoded.length);

        // Independently verify with pointycastle's own SHA-1 RSA verifier
        // against the key's public half - this is the check that actually
        // matters: it fails if the signature is malformed, uses the wrong
        // digest/OID, or was produced with mismatched key components,
        // even though every other check above still passed.
        final pc.RSASigner verifier = pc.RSASigner(
          pc.SHA1Digest(),
          '06052b0e03021a',
        );
        verifier.init(
          false,
          pc.PublicKeyParameter<pc.RSAPublicKey>(
            pc.RSAPublicKey(key.n, key.e),
          ),
        );
        expect(
          verifier.verifySignature(message, pc.RSASignature(rawSignature)),
          isTrue,
        );
      },
    );

    test('a tampered message fails verification', () async {
      final RsaPrivateKey key = _generateTestKey();
      final SSHIdentity identity = legacySshRsaIdentity(key);
      final Uint8List message = Uint8List.fromList(utf8.encode('original'));
      final Uint8List tampered = Uint8List.fromList(utf8.encode('tampered!'));

      final SSHSignature signature = await identity.sign(message);
      final (Uint8List _, int afterAlgorithm) = _readSshString(
        signature.encode(),
        0,
      );
      final (Uint8List rawSignature, int _) = _readSshString(
        signature.encode(),
        afterAlgorithm,
      );

      final pc.RSASigner verifier = pc.RSASigner(
        pc.SHA1Digest(),
        '06052b0e03021a',
      );
      verifier.init(
        false,
        pc.PublicKeyParameter<pc.RSAPublicKey>(pc.RSAPublicKey(key.n, key.e)),
      );
      expect(
        verifier.verifySignature(tampered, pc.RSASignature(rawSignature)),
        isFalse,
      );
    });
  });
}
