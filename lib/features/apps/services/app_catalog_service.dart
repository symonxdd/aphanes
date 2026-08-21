import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../models/catalog_package.dart';

class CatalogException implements Exception {
  const CatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when a downloaded .ipk's SHA-256 doesn't match the catalog
/// manifest's published hash - the only integrity guarantee on a file
/// fetched from a third-party server, so a mismatch is never ignored.
class CatalogIntegrityException implements Exception {
  const CatalogIntegrityException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads the public Homebrew app store catalog
/// (https://repo.webosbrew.org/api/apps.json). Read-only: fetching this
/// listing is not telemetry, it's the catalog itself, but nothing here
/// installs or updates anything on its own - every install still starts
/// from a direct tap in the UI.
class AppCatalogService {
  AppCatalogService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final Uri _catalogUri = Uri.parse(
    'https://repo.webosbrew.org/api/apps.json',
  );

  Future<List<CatalogPackage>> fetchCatalog() async {
    final http.Response response;
    try {
      response = await _client
          .get(_catalogUri)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const CatalogException("Couldn't reach the app catalog.");
    }
    if (response.statusCode != 200) {
      throw const CatalogException("Couldn't reach the app catalog.");
    }
    try {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> packages = body['packages'] as List<dynamic>;
      return packages
          .cast<Map<String, dynamic>>()
          .map(CatalogPackage.fromJson)
          .toList();
    } catch (_) {
      throw const CatalogException('The app catalog sent an unexpected response.');
    }
  }

  /// Downloads [manifest]'s .ipk and verifies it against the manifest's
  /// published SHA-256 before returning it. Throws
  /// [CatalogIntegrityException] on a mismatch - the caller must never
  /// install bytes this rejected.
  Future<Uint8List> downloadAndVerify(CatalogManifest manifest) async {
    final String? expectedSha256 = manifest.ipkSha256;
    if (expectedSha256 == null) {
      throw const CatalogIntegrityException(
        "This package doesn't publish a checksum, so it can't be "
        'installed from here.',
      );
    }
    final http.Response response;
    try {
      response = await _client.get(Uri.parse(manifest.ipkUrl));
    } catch (_) {
      throw const CatalogException("Couldn't download that package.");
    }
    if (response.statusCode != 200) {
      throw const CatalogException("Couldn't download that package.");
    }
    final Uint8List bytes = response.bodyBytes;
    final String actual = sha256.convert(bytes).toString();
    if (actual.toLowerCase() != expectedSha256.toLowerCase()) {
      throw const CatalogIntegrityException(
        'Downloaded package failed its integrity check - not installing.',
      );
    }
    return bytes;
  }
}
