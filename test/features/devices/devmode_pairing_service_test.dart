import 'dart:async';
import 'dart:io';

import 'package:aphanes/features/devices/services/devmode_pairing_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Generated with real OpenSSL 3.2.3: `openssl rsa -traditional -aes128
// -passout pass:correct-horse` on a `genrsa -traditional` key. This is the
// legacy OpenSSL PEM format confirmed against a real webOS TV's key
// server, not PKCS8.
const String _encryptedPem = '''
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: AES-128-CBC,65E41A35845545F9F6EEA0F87730BEA5

pfAbJSRANwdqX1Ap/y9kxSnxrbRdFPHKlSMrDf7hEgfHbFMHNV0XALaKNzdL4wfc
n7wog9AndLIn0AmgNp+RX/VCdq6Z8ROJCtugGtdUNCIqRHj5g0aBxL3+J/CF0Llr
zAN9PxDia8K4uiM0KJn5e8i+JEXKwR2mhC97m7psAafzw+6EceSUJnqxrQjMbuR3
i1WShPL7wgH9PSo5s/seLHCnu5RSnYebu6YqI1G7t5B3+/OQVCpDqKGMjJAXthPh
iIQeusiHTiIW4fPGhwOVYueiQtk6p8qRhTi4SjVv69P9paOIfupeQQweUETtSe3P
SmqtGbqpwB9O+7Z+ce6b+iW4pQrt4p9xbQVvcwcS7hV+alt0V9bb8ujH4jTwudb2
7C6opi+Uzt3Qss2IQrkVbIaZQhu8/+Ku/70iwxn8tf412NtRYq+64BsVF5dJQpjs
wBMF5penhgu5i/lrHP2aOajEaJ0pOrS7TbZsBOqE4IINh+GkmbRDNtMkrNckKP0b
Uw+ynOh4Y17FxXad1siHu6dWCG0vcDf4razCorw/eUKLvfMfhP2p0mJtd+ojdOrJ
aTIaXtHFBafpUJrrYcESGw0FPKxe3UgjTWn8PaLY2ehryTX+RIH9JtEhqJTlEe75
ky2efBvRSTWlbzUjH+svdriBRwT944AMPb7YQ7puRIh/lbNMjVwkHNrCATZfpnhR
7YTA+YGoqJUMG1wALg6UUc5H2QYfv60PHeyrydD7nDeYF2bHzCWOwhI32l3k8fwA
90oi2AWAsBfC+ZBb+sUzcpD5n1w3RKTSgojMywFSq942tcniTABKnClqkCZlICBU
T6Osazd4/8F4fzs7+Bi8y4WA6X5LK6PzgBFIaNJ1O8cBAA5mw4OqMdhMCrDRMf4s
aQ0s0Y2zPNr48y+ldMTy26jd7tMIJP6CTu04f9q+PImPBGhxjaz2E2OGpzRgrVtX
8U928WjAB+6PNOtlNfA99KXujLYM3tTPhScgFT60pbXBN3bG7qAL1ENrT106dgka
/uSaaRJDPszta2s1H8G1NZn1Xw0yeLX/6vRbKYQTFrF3XsnI5v1eO1XM9ZtbzGZN
hzPMZwHtzoy1mYFji2rJ4E6aN43PKE0wikS3SF83G2wDu9oYaIx5BhEMXI4H+Cna
CFUm5EPgOfvGYuDDbu27bKUPKRcCGs82TYg2vryXf5FW6N7ZZSk/Zccx0A25VE83
O6OKfDEpioI+vX8ulCVgLrrUgKM4Qaez+jKA6W+j/skXh5ZAsrGTzKV4Jg1bvjdK
GCnMn1cV9sVRPlQosSswA+dAZA0elaQYCRNRIpYuBOhyVd+jJdQF6Q8pncF972xf
AC/qM5fY+uPX6giK6N7dwVjRGQ7VKGmES5LJ61e68RX6h9agsPv4kdCwO/Z/yH2K
aMLg5EIrdEZrZ8FMYeYXCwBsRgFGsfDKQTmQnv6Nq6zJTocVrKc4ESS8NbeG1ywD
ne+gBxSDV28YtZdi/5yc/JQEXAIIjak931aO/uL+RUgC7Ad8o1J1ghpCszLelReS
BkJhFDE23rMpsJjJZfZ7FRLokN9rr4PC81bTTHY4hq1PVrX8IR7taViBuvD1QcxC
-----END RSA PRIVATE KEY-----
''';

Future<ServerSocket> _serveOnce(
  Future<void> Function(Socket client) handle,
) async {
  final ServerSocket server = await ServerSocket.bind(
    InternetAddress.loopbackIPv4,
    0,
  );
  unawaited(server.first.then(handle));
  return server;
}

void main() {
  test('fetches and decrypts the key from a real HTTP/1.0 response', () async {
    final ServerSocket server = await _serveOnce((Socket client) async {
      client.write('HTTP/1.0 200 OK\r\n');
      client.write('Content-Type: text/plain\r\n');
      client.write('\r\n');
      client.write(_encryptedPem);
      await client.flush();
      await client.close();
    });
    addTearDown(server.close);

    final DevmodePairingService service = DevmodePairingService(
      keyServerPort: server.port,
    );
    final PairedDevmodeCredentials credentials = await service.pair(
      host: '127.0.0.1',
      passphrase: 'correct-horse',
    );

    expect(credentials.privateKeyPem, contains('BEGIN RSA PRIVATE KEY'));
  });

  test('a non-200 response means no key is available', () async {
    final ServerSocket server = await _serveOnce((Socket client) async {
      client.write('HTTP/1.0 404 Not Found\r\n\r\n');
      await client.flush();
      await client.close();
    });
    addTearDown(server.close);

    final DevmodePairingService service = DevmodePairingService(
      keyServerPort: server.port,
    );

    expect(
      () => service.pair(host: '127.0.0.1', passphrase: 'anything'),
      throwsA(isA<DevmodePairingException>()),
    );
  });

  test('an unreachable host reports a specific error', () async {
    // Port 1 is a reserved, never-listening port - connection refused fast.
    final DevmodePairingService service = DevmodePairingService(
      keyServerPort: 1,
    );

    expect(
      () => service.pair(host: '127.0.0.1', passphrase: 'anything'),
      throwsA(isA<DevmodePairingException>()),
    );
  });

  test('probe returns true when the key server responds 200', () async {
    final ServerSocket server = await _serveOnce((Socket client) async {
      client.write('HTTP/1.0 200 OK\r\n\r\n');
      client.write(_encryptedPem);
      await client.flush();
      await client.close();
    });
    addTearDown(server.close);

    final DevmodePairingService service = DevmodePairingService(
      keyServerPort: server.port,
    );

    expect(await service.probe('127.0.0.1'), isTrue);
  });

  test('probe returns false when the key server responds non-200', () async {
    final ServerSocket server = await _serveOnce((Socket client) async {
      client.write('HTTP/1.0 404 Not Found\r\n\r\n');
      await client.flush();
      await client.close();
    });
    addTearDown(server.close);

    final DevmodePairingService service = DevmodePairingService(
      keyServerPort: server.port,
    );

    expect(await service.probe('127.0.0.1'), isFalse);
  });

  test('probe returns false, not an exception, for an unreachable host', () async {
    final DevmodePairingService service = DevmodePairingService(
      keyServerPort: 1,
    );

    expect(await service.probe('127.0.0.1'), isFalse);
  });

  test('validatePassphrase returns true for the correct passphrase', () async {
    final DevmodePairingService service = DevmodePairingService();

    expect(
      await service.validatePassphrase(_encryptedPem, 'correct-horse'),
      isTrue,
    );
  });

  test('validatePassphrase returns false for a wrong passphrase', () async {
    final DevmodePairingService service = DevmodePairingService();

    expect(
      await service.validatePassphrase(_encryptedPem, 'wrong-passphrase'),
      isFalse,
    );
  });

  test('fetchEncryptedKey returns the raw body from the key server', () async {
    final ServerSocket server = await _serveOnce((Socket client) async {
      client.write('HTTP/1.0 200 OK\r\n\r\n');
      client.write(_encryptedPem);
      await client.flush();
      await client.close();
    });
    addTearDown(server.close);

    final DevmodePairingService service = DevmodePairingService(
      keyServerPort: server.port,
    );

    final String fetched = await service.fetchEncryptedKey('127.0.0.1');
    expect(fetched, contains('BEGIN RSA PRIVATE KEY'));
    expect(await service.validatePassphrase(fetched, 'correct-horse'), isTrue);
  });
}
