import 'package:aphanes/features/devices/services/legacy_pem_decryptor.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_test/flutter_test.dart';

// Fixtures generated with real OpenSSL 3.2.3 (not hand-written), so this
// test exercises the actual traditional OpenSSL PEM header/EVP_BytesToKey
// wire format, not an idealized one: `openssl genrsa -traditional` for the
// plain key, then `openssl rsa -traditional -aes128/-des3 -passout ...` on
// that same key for each encrypted variant, so both are expected to
// decrypt back to the one plain key below. This is the format actually
// confirmed against a real webOS TV's key server, not PKCS8.

const String _encryptedAes128 = '''
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

const String _encryptedDes3 = '''
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,B083D0E6C20E3C39

hergwN/5u9nqGxqAxHo3Kn5Ykk2ZfXKJWltj0CXL0Z0LVUrGntef5w7cSyf8Ce0b
2xelnEM371iW0r7eeE4/JRV2Ih1ccuSMsu1xg4gwYp7TTsmMfx/1tl4uIPShxtKb
hDuXcfsMQlsat27yQj7xekBK8VxNS6Y3LjzePjP5u2qX4xE1t4beFt0cBTgUmkB5
xSOV6ucOrH5YfOqfFRc0CaRudL/2u97ov/GBsqdryhyUv1rOwDnEegJXIutqJKru
17AsKT9usOgZOKS7nr2FhLvBSnbVXSLKBUkJEsajmf8NGmuffxsmRBhDiw/BwF8K
XrCEAGAyZIYVeIYy34MdVlTBqElZfCx3K0bs9aBuTmlthYg1PC01FZvEnxVwglT+
Y24l3gySajHSdL9tTWzprzNE7ao7cxWPigovs9F1141vOKQpB4FdufdKF6NaR/57
eiEOEYIxPkjq6xq4HHTT7YYVwA8uNwdGJ4blpe5OcAkuJGzXNzav9vXiyxb15iNL
uFnoY1Vt+1VhLsxlUr1boRuf2B/tX00efcFwHPDt/ZEZONQ5TXAWA99MTTsnp5zL
vjKXqh6VS8V5wEvBHhZE//pw/x2rfRRiOa6hVU4N2UhrL213dDgBXrkJd63ec7zP
lfpy8zhHulrz5nW7fU9IWbwZ+hmr+mlHhrCLUqebhLA0MeGSpvxer/b7TRTVg6S7
LjY1ietasLWnr6kNLAva+5JQw16ZicTAGTE9QmbgRqzeQs+BzPIQSDc6DiKYalbn
dbgrwZq0f5V+cHy9sTZY/QJbH1xzqW5L3XmX+I/EwDKlNwrLHZGTQ1bqZwp2cDul
Zw6lk+iFwJY7DKyJAknRppMOyalRvmpAITntJ57oSLLSAQbBp/9Q1sE8dG8nnyr8
1WP3J4weJ85UYTd9Bvb4LmKMY2+xL1ZBMWJVBd80JED95ZLsWzaFwK9fV2YKZPrY
RkXgRIVJAZUF1Nqh2CM+lzSJ2Eewzr4BEMuhOy2JCB6a+qfPBGrV3O6PbN4Qg0jW
PvJ5k3uxR0P7/NMrSS+3niFYB7gyJ1bwgbf5s0OK97aLwQqKccfQK3uN2S90268X
jOS0njgF+NY9UJhJZg/nYZQUJH8mjq6sqBfaf3z7mCFCKpQDVo0L5Dg2li++f/RQ
ehLxxtzhUabvA3gzwaVzIDaN9W9cx+MIA9zUWt/QWKmwE1mNVYN85TnrReXQS+lO
cGyixR4EPilxBUtrE0QqvMEDuXZf1rWDWjCn7XH3U5OapKSRfZLnXfTEv44oSL6U
CW1sv93oWE3zYBgZiz3DHRlRmVYVPq1uSrr+RbLco7EnO7R12BJ9SEjfse3a9qg2
Uc7CWXWWbyMG8WK/ADpYZue3eC5T34lCao7OfsgzkFIq45j1EiqfbvFIp7YbYigw
2WobRqPzTucJOus/Be20dPhGFlWg/ISk1am/5kcb48Ic3d3NwCG6Ox/0xShzVcDJ
UObgfI730rz6mE2nX/7gIFIZO0r9d7XzQkhcEbb8velrupobDMUYgVYQnfduYJz2
7wStax3w47Wva/g2nMMU/LgY0WsAfCC/tyzTVoS6jAFcrAisTBKQOp9YFFJUMtra
-----END RSA PRIVATE KEY-----
''';

// The un-encrypted form of the same key both variants above wrap, produced
// by `openssl genrsa -traditional`, used here only to check the decrypted
// modulus matches - not compared byte-for-byte, since re-DER-encoding can
// legally differ.
const String _expectedPkcs1 = '''
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAmR8dkZ1RalYt28YHwy8HWSM7xe/hamQgiwy3taJ0zUe2Ds1K
UN4wAkjAnKbsUzZeFCHlcBKg7o9IsxFzBhdWxR/N1vvQh4r9PdzFBpzvpxQhMgjR
ihzL30xJGJ2r2yUohkUbKyY1uMjoKDBMHDJEJzTB3zHwL5GAn8jpEGM4GQxujzqq
8qVyoepaj3/Yt+dIYroyNPWC7vbNExitrKXqkB2AhhFSZ0+hu7QlSjFN3YuKnMg2
yDgLjSMGFtlNgKAjAMPQSuTah7VwmEzEZv79s6HctymCcq/jDpLRDLQh2ucXOtqR
IbwjbNUbpd5ru4xOwEpEljUMQsFQoHa2EMQRqwIDAQABAoIBABUZo5J4UkrL+1/I
pzMvXNzcrRT2nGJzz8Q5iWs/KsdK9XyOr4n7RDRcYCZ2HiTNXiN6FErgVkrpdcQv
SGFzf+KEInJYmwDCl2kZ7hCeOawVawmhC3bzxuhLc9svhwoY0b/G8Bp/FnITRWKc
XTCZgKjCbWDbWdTEQSxDnFJEyesxg8AU17LDYfEiUsW7tnYStYBksXvgdMKejqiX
YqW6zDNCtFAyEcFT2Y08/bBaAv4EX/hUgT9w9H6lvOqhacIdBSPglH1kfek+p9on
Tjoetex8dIheugQZtUOsZSin77Xo9IIXysvyy2+yHiKCQbF+vPlScHA/OfzVtBmz
BRfYjkkCgYEAzvMdfLzzsmvbQRTN744/hgNzq2yyvsoadTFk9gSKUhTsf85rZWjp
Jw3qY8UmRZKmrbt0UI5NnU5g8d1g/nJw880Br9wI9nyZx0cnv2a47vm9GkfGLCMy
F3Z03DMxuSVnTt6k1HilD0m5uYYBFrm1268qboDhy2eRtRfoNPt0tE8CgYEAvWns
X6EgXlCkCUqpZrd/dlCWGXX4w1HdzzetOB8CkUBKGg/wBpRk+vIWqbLcKlYUoKbO
dFvQEecL6Ay6tt/0+zBO1G+f9QCTSDwM1DRDcsjoGpk/uP2a9C0Pj58rQrNE7D7y
juNE9hNb2UbUkTHJyyOCfWxjQzxPlad6x954CeUCgYEAwgwOCyd1bkhZ5xVl4AjG
oZdc/1FF7UW+N0MggtpRBJQgCdr4srcDX55ZuEFlGHlhFqgdcWdteWHD3yYQS6Xt
KX2B5m7wbIb6/nNG3t6n61R6r0i7lilOT9e/zbWnGw7qZna3oY6aXtJndoEjRjbO
QfZmWAU7Mymi42ZOUlex31sCgYAZpEVDjOR84B3UxC66oQy4T6CCQd4zUtncO4VP
m6MVVsaxUIcF3QDul+dJgdUcRhr0xKAeUG+SfNy3xUFhkF/xwVBqodHdsP4/QSHb
eFfJKjmBoE1oFazscU0x/DI3DV2/PaZIgavMREKi31vXbA4NWflIUWv+piN/9vRA
KnXFoQKBgQDK1vrDcCK4RrjBWXC8Ww80ZTj1y56fRhMR1Pgk6ynujb3U9UqCmXtp
FRfRFuEZ/vvoSQlSZ/Tx99xgRyoXe/ssjljW0o2AKejdekObQSAd3F6I91vhX1JE
xJ7RSHHAextnv6Tp6NglOKkiz3BhEEs2a2W7XYzt6bZMYtt80ONF6Q==
-----END RSA PRIVATE KEY-----
''';

void main() {
  test('decrypts a real AES-128-CBC legacy PEM key', () {
    final String pkcs1Pem = LegacyPemDecryptor.decryptToPkcs1Pem(
      _encryptedAes128,
      'correct-horse',
    );

    // Round-trip through dartssh2 itself: this is what actually matters,
    // since it's the consumer of this output in the real pairing flow.
    final List<SSHKeyPair> keyPairs = SSHKeyPair.fromPem(pkcs1Pem);
    expect(keyPairs, hasLength(1));

    final List<SSHKeyPair> expectedKeyPairs = SSHKeyPair.fromPem(
      _expectedPkcs1,
    );
    expect(
      keyPairs.single.toPublicKey().encode(),
      expectedKeyPairs.single.toPublicKey().encode(),
    );
  });

  test('decrypts a real DES-EDE3-CBC legacy PEM key', () {
    final String pkcs1Pem = LegacyPemDecryptor.decryptToPkcs1Pem(
      _encryptedDes3,
      'another-pass',
    );

    final List<SSHKeyPair> keyPairs = SSHKeyPair.fromPem(pkcs1Pem);
    final List<SSHKeyPair> expectedKeyPairs = SSHKeyPair.fromPem(
      _expectedPkcs1,
    );
    expect(
      keyPairs.single.toPublicKey().encode(),
      expectedKeyPairs.single.toPublicKey().encode(),
    );
  });

  test('throws PemDecryptionException on a wrong passphrase', () {
    expect(
      () => LegacyPemDecryptor.decryptToPkcs1Pem(
        _encryptedAes128,
        'wrong-passphrase',
      ),
      throwsA(isA<PemDecryptionException>()),
    );
  });

  test('throws PemDecryptionException on a response with no PEM markers', () {
    expect(
      () => LegacyPemDecryptor.decryptToPkcs1Pem(
        'not a pem at all',
        'correct-horse',
      ),
      throwsA(isA<PemDecryptionException>()),
    );
  });
}
