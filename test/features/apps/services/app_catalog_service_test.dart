import 'dart:convert';
import 'dart:typed_data';

import 'package:aphanes/features/apps/models/catalog_package.dart';
import 'package:aphanes/features/apps/services/app_catalog_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

CatalogManifest _manifestFor(Uint8List bytes, {String? shaOverride}) {
  return CatalogManifest(
    version: '1.0.0',
    appDescription: '',
    sourceUrl: null,
    ipkUrl: 'https://repo.webosbrew.org/apps/example.ipk',
    ipkSha256: shaOverride ?? sha256.convert(bytes).toString(),
    ipkSize: bytes.length,
    installedSize: null,
    rootRequired: false,
  );
}

void main() {
  test('fetchCatalog parses the packages array', () async {
    final MockClient client = MockClient((http.Request request) async {
      expect(request.url.toString(), 'https://repo.webosbrew.org/api/apps.json');
      return http.Response(
        jsonEncode({
          'paging': {'page': 0},
          'packages': [
            {
              'id': 'org.webosbrew.hbchannel',
              'title': 'Homebrew Channel',
              'manifest': {
                'version': '0.7.3',
                'ipkUrl': 'https://repo.webosbrew.org/apps/example.ipk',
                'ipkHash': {'sha256': 'deadbeef'},
                'ipkSize': 123,
              },
            },
          ],
        }),
        200,
      );
    });
    final AppCatalogService service = AppCatalogService(client: client);

    final List<CatalogPackage> packages = await service.fetchCatalog();

    expect(packages, hasLength(1));
    expect(packages.single.id, 'org.webosbrew.hbchannel');
  });

  test('fetchCatalog throws CatalogException on a non-200 response', () async {
    final MockClient client = MockClient(
      (http.Request request) async => http.Response('nope', 503),
    );
    final AppCatalogService service = AppCatalogService(client: client);

    expect(service.fetchCatalog(), throwsA(isA<CatalogException>()));
  });

  test('downloadAndVerify returns the bytes when the hash matches', () async {
    final Uint8List bytes = Uint8List.fromList('a valid ipk'.codeUnits);
    final MockClient client = MockClient(
      (http.Request request) async => http.Response.bytes(bytes, 200),
    );
    final AppCatalogService service = AppCatalogService(client: client);

    final Uint8List result = await service.downloadAndVerify(
      _manifestFor(bytes),
    );

    expect(result, bytes);
  });

  test(
    'downloadAndVerify throws CatalogIntegrityException on a hash mismatch',
    () async {
      final Uint8List bytes = Uint8List.fromList('tampered ipk'.codeUnits);
      final MockClient client = MockClient(
        (http.Request request) async => http.Response.bytes(bytes, 200),
      );
      final AppCatalogService service = AppCatalogService(client: client);

      expect(
        service.downloadAndVerify(
          _manifestFor(bytes, shaOverride: 'not-the-real-hash'),
        ),
        throwsA(isA<CatalogIntegrityException>()),
      );
    },
  );

  test(
    'downloadAndVerify refuses a manifest with no published hash, without '
    'downloading anything (regression: some live catalog entries have no '
    'ipkHash at all)',
    () async {
      final MockClient client = MockClient(
        (http.Request request) async =>
            throw StateError('should never fetch a manifest with no hash'),
      );
      final AppCatalogService service = AppCatalogService(client: client);
      const CatalogManifest manifest = CatalogManifest(
        version: '1.0.0',
        appDescription: '',
        sourceUrl: null,
        ipkUrl: 'https://example.com/no-hash.ipk',
        ipkSha256: null,
        ipkSize: 42,
        installedSize: null,
        rootRequired: false,
      );

      expect(
        service.downloadAndVerify(manifest),
        throwsA(isA<CatalogIntegrityException>()),
      );
    },
  );
}
