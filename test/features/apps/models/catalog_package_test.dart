import 'package:aphanes/features/apps/models/catalog_package.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses a catalog entry matching the live apps.json shape', () {
    final CatalogPackage package = CatalogPackage.fromJson({
      'id': 'org.webosbrew.hbchannel',
      'title': 'Homebrew Channel',
      'iconUri': 'https://repo.webosbrew.org/apps/icons/org.webosbrew.hbchannel.png',
      'manifestUrl':
          'https://github.com/example/org.webosbrew.hbchannel.manifest.json',
      'manifest': {
        'id': 'org.webosbrew.hbchannel',
        'version': '0.7.3',
        'appDescription': 'webOS Homebrew installer',
        'sourceUrl': 'https://github.com/webosbrew/webos-homebrew-channel',
        'rootRequired': false,
        'ipkUrl': 'https://repo.webosbrew.org/apps/example.ipk',
        'ipkHash': {'sha256': 'deadbeef'},
        'ipkSize': 1699858,
      },
      'pool': 'main',
      'shortDescription': 'webOS Homebrew installer',
      'featured': true,
      'fullDescriptionUrl': 'apps/org.webosbrew.hbchannel/full_description.html',
    });

    expect(package.id, 'org.webosbrew.hbchannel');
    expect(package.title, 'Homebrew Channel');
    expect(package.featured, true);
    expect(package.manifest.version, '0.7.3');
    expect(package.manifest.ipkUrl, 'https://repo.webosbrew.org/apps/example.ipk');
    expect(package.manifest.ipkSha256, 'deadbeef');
    expect(package.manifest.ipkSize, 1699858);
  });

  test('defaults featured and shortDescription when absent', () {
    final CatalogPackage package = CatalogPackage.fromJson({
      'id': 'org.example.app',
      'title': 'Example',
      'manifest': {
        'version': '1.0.0',
        'ipkUrl': 'https://example.com/app.ipk',
        'ipkHash': {'sha256': 'abc123'},
        'ipkSize': 42,
      },
    });

    expect(package.featured, false);
    expect(package.shortDescription, '');
    expect(package.iconUri, isNull);
    expect(package.manifest.sourceUrl, isNull);
  });

  test(
    'parses a manifest with no ipkHash instead of throwing '
    '(regression: com.github.cfernande1470.wireguard, live in the '
    'catalog with no ipkHash field at all)',
    () {
      final CatalogPackage package = CatalogPackage.fromJson({
        'id': 'com.github.cfernande1470.wireguard',
        'title': 'WireGuard',
        'manifest': {
          'version': '1.0.0',
          'ipkUrl': 'https://example.com/wireguard.ipk',
          'ipkSize': 42,
        },
      });

      expect(package.manifest.ipkSha256, isNull);
    },
  );

  test('parses detailIconUri, requirements, rootRequired and installedSize', () {
    final CatalogPackage package = CatalogPackage.fromJson({
      'id': 'com.example.rooted',
      'title': 'Rooted App',
      'detailIconUri': 'https://example.com/big-icon.png',
      'requirements': {'webosRelease': '>=5.0'},
      'manifest': {
        'version': '1.0.0',
        'ipkUrl': 'https://example.com/rooted.ipk',
        'ipkHash': {'sha256': 'abc123'},
        'ipkSize': 1024,
        'installedSize': 2048,
        'rootRequired': true,
      },
    });

    expect(package.detailIconUri, 'https://example.com/big-icon.png');
    expect(package.minWebosRelease, '>=5.0');
    expect(package.manifest.installedSize, 2048);
    expect(package.manifest.rootRequired, true);
  });

  test('defaults rootRequired to false and installedSize/detailIconUri to null', () {
    final CatalogPackage package = CatalogPackage.fromJson({
      'id': 'com.example.plain',
      'title': 'Plain App',
      'manifest': {
        'version': '1.0.0',
        'ipkUrl': 'https://example.com/plain.ipk',
        'ipkHash': {'sha256': 'abc123'},
        'ipkSize': 1024,
      },
    });

    expect(package.detailIconUri, isNull);
    expect(package.minWebosRelease, isNull);
    expect(package.manifest.installedSize, isNull);
    expect(package.manifest.rootRequired, false);
  });
}
