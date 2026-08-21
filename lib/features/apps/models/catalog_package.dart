/// One entry from the Homebrew app store catalog
/// (`https://repo.webosbrew.org/api/apps.json`).
class CatalogPackage {
  const CatalogPackage({
    required this.id,
    required this.title,
    required this.iconUri,
    required this.shortDescription,
    required this.featured,
    required this.manifest,
  });

  factory CatalogPackage.fromJson(Map<String, dynamic> json) {
    return CatalogPackage(
      id: json['id'] as String,
      title: json['title'] as String,
      iconUri: json['iconUri'] as String?,
      shortDescription: json['shortDescription'] as String? ?? '',
      featured: json['featured'] as bool? ?? false,
      manifest: CatalogManifest.fromJson(
        json['manifest'] as Map<String, dynamic>,
      ),
    );
  }

  final String id;
  final String title;
  final String? iconUri;
  final String shortDescription;
  final bool featured;
  final CatalogManifest manifest;
}

/// The install-relevant subset of a catalog entry's `manifest` object.
class CatalogManifest {
  const CatalogManifest({
    required this.version,
    required this.appDescription,
    required this.sourceUrl,
    required this.ipkUrl,
    required this.ipkSha256,
    required this.ipkSize,
  });

  factory CatalogManifest.fromJson(Map<String, dynamic> json) {
    return CatalogManifest(
      version: json['version'] as String,
      appDescription: json['appDescription'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String?,
      ipkUrl: json['ipkUrl'] as String,
      // A handful of real catalog entries publish no ipkHash at all (e.g.
      // com.github.cfernande1470.wireguard, confirmed live) - nullable
      // rather than required, so one such entry doesn't take down parsing
      // of the whole catalog. AppsService/the install UI refuse to install
      // a package with no hash to verify against, rather than silently
      // skipping the integrity check for it.
      ipkSha256: (json['ipkHash'] as Map<String, dynamic>?)?['sha256'] as String?,
      ipkSize: json['ipkSize'] as int,
    );
  }

  final String version;
  final String appDescription;
  final String? sourceUrl;
  final String ipkUrl;
  final String? ipkSha256;
  final int ipkSize;
}
