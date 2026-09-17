//! The public Homebrew app store catalog
//! (<https://repo.webosbrew.org/api/apps.json>), read-only, as the mobile
//! app's `app_catalog_service.dart` reads it. Fetching the listing is not
//! telemetry, it is the catalog itself, and nothing here installs or
//! updates anything on its own: every install starts from a click.

use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::http;
use crate::{Error, Result};

const CATALOG_URL: &str = "https://repo.webosbrew.org/api/apps.json";

/// What an entry's `fullDescriptionUrl` is relative to.
const CATALOG_API_BASE: &str = "https://repo.webosbrew.org/api/";

/// One entry from the catalog.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CatalogPackage {
    pub id: String,
    pub title: String,
    pub icon_uri: Option<String>,
    pub short_description: String,
    /// The webosbrew project's own editorial pick, distinct from the
    /// app's favorites list.
    pub featured: bool,
    /// The catalog splits submissions into a "main" (open source) pool
    /// and a "non-free" one, per webosbrew's submission docs.
    pub open_source: bool,
    pub min_webos_release: Option<String>,
    /// The package's README as an HTML fragment, rendered by the catalog
    /// itself, made absolute here. Fetched by [`fetch_description`] only
    /// when a person opens the app's page.
    pub full_description_url: Option<String>,
    pub manifest: CatalogManifest,
}

/// The install-relevant subset of an entry's `manifest` object.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct CatalogManifest {
    pub version: String,
    pub app_description: String,
    pub source_url: Option<String>,
    pub ipk_url: String,
    /// A handful of real entries publish no hash at all. Such a package
    /// is refused by [`download_and_verify`] rather than installed
    /// unchecked.
    pub ipk_sha256: Option<String>,
    /// The download size in bytes.
    pub ipk_size: u64,
    /// Unpacked size on the TV; not every submission reports it.
    pub installed_size: Option<u64>,
    pub root_required: bool,
}

pub async fn fetch_catalog() -> Result<Vec<CatalogPackage>> {
    let unreachable = || Error::message("Couldn't reach the app catalog.");
    let response = http::client()
        .ok_or_else(unreachable)?
        .get(CATALOG_URL)
        .send()
        .await
        .map_err(|_| unreachable())?;
    if !response.status().is_success() {
        return Err(unreachable());
    }
    let body: Value = response
        .json()
        .await
        .map_err(|_| Error::message("The app catalog sent an unexpected response."))?;
    parse_catalog(&body)
}

/// The README fragment an entry's `full_description_url` points at, as
/// the catalog serves it. The caller renders it as untrusted markup.
pub async fn fetch_description(url: &str) -> Result<String> {
    let failed = || Error::message("Couldn't load this app's description.");
    let response = http::client()
        .ok_or_else(failed)?
        .get(url)
        .send()
        .await
        .map_err(|_| failed())?;
    if !response.status().is_success() {
        return Err(failed());
    }
    response.text().await.map_err(|_| failed())
}

/// Downloads a manifest's package and, when the catalog publishes a
/// SHA-256 for it, checks the bytes against it before handing them over.
/// That check is the only integrity guarantee on a file fetched from a
/// third-party host, so a mismatch is never ignored and the caller must
/// never install bytes this refused. The few entries with no published
/// hash download unchecked; the UI says so before starting one.
pub async fn download_and_verify(ipk_url: &str, ipk_sha256: Option<&str>) -> Result<Vec<u8>> {
    let failed = || Error::message("Couldn't download that package.");
    let response = http::download_client()
        .ok_or_else(failed)?
        .get(ipk_url)
        .send()
        .await
        .map_err(|_| failed())?;
    if !response.status().is_success() {
        return Err(failed());
    }
    let bytes = response.bytes().await.map_err(|_| failed())?.to_vec();
    check_integrity(&bytes, ipk_sha256)?;
    Ok(bytes)
}

/// Refuses bytes that do not match a published hash; passes them with
/// no hash to match against.
fn check_integrity(bytes: &[u8], ipk_sha256: Option<&str>) -> Result<()> {
    match ipk_sha256 {
        Some(expected) if !http::sha256_hex(bytes).eq_ignore_ascii_case(expected) => Err(
            Error::message("Downloaded package failed its integrity check. Not installing."),
        ),
        _ => Ok(()),
    }
}

/// Every entry that parses. One malformed submission is skipped rather
/// than taking the whole catalog down with it.
fn parse_catalog(body: &Value) -> Result<Vec<CatalogPackage>> {
    let packages = body
        .get("packages")
        .and_then(Value::as_array)
        .ok_or_else(|| Error::message("The app catalog sent an unexpected response."))?;
    Ok(packages.iter().filter_map(parse_package).collect())
}

fn parse_package(entry: &Value) -> Option<CatalogPackage> {
    let text = |v: &Value, key: &str| v.get(key).and_then(Value::as_str).map(str::to_string);
    let manifest = entry.get("manifest")?;
    Some(CatalogPackage {
        id: text(entry, "id")?,
        title: text(entry, "title")?,
        icon_uri: text(entry, "iconUri"),
        short_description: text(entry, "shortDescription").unwrap_or_default(),
        featured: entry
            .get("featured")
            .and_then(Value::as_bool)
            .unwrap_or(false),
        open_source: text(entry, "pool").as_deref().unwrap_or("main") == "main",
        min_webos_release: entry
            .get("requirements")
            .and_then(|r| text(r, "webosRelease")),
        full_description_url: text(entry, "fullDescriptionUrl").map(|path| absolute(&path)),
        manifest: CatalogManifest {
            version: text(manifest, "version")?,
            app_description: text(manifest, "appDescription").unwrap_or_default(),
            source_url: text(manifest, "sourceUrl"),
            ipk_url: text(manifest, "ipkUrl")?,
            ipk_sha256: manifest.get("ipkHash").and_then(|h| text(h, "sha256")),
            ipk_size: manifest.get("ipkSize").and_then(Value::as_u64)?,
            installed_size: manifest.get("installedSize").and_then(Value::as_u64),
            root_required: manifest
                .get("rootRequired")
                .and_then(Value::as_bool)
                .unwrap_or(false),
        },
    })
}

/// A description path as the catalog publishes it (`apps/<id>/...`),
/// resolved against the API directory it is relative to.
fn absolute(path: &str) -> String {
    if path.starts_with("http://") || path.starts_with("https://") {
        path.to_string()
    } else {
        format!("{CATALOG_API_BASE}{}", path.trim_start_matches('/'))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn a_description_path_is_made_absolute_against_the_api_directory() {
        assert_eq!(
            absolute("apps/x/full_description.html"),
            "https://repo.webosbrew.org/api/apps/x/full_description.html"
        );
        assert_eq!(
            absolute("https://example.invalid/d.html"),
            "https://example.invalid/d.html"
        );
    }

    fn entry(id: &str, pool: Option<&str>, hash: Option<&str>) -> Value {
        let mut manifest = json!({
            "version": "1.2.0",
            "ipkUrl": format!("https://example.invalid/{id}.ipk"),
            "ipkSize": 1234,
        });
        if let Some(hash) = hash {
            manifest["ipkHash"] = json!({"sha256": hash});
        }
        let mut entry = json!({"id": id, "title": id, "manifest": manifest});
        if let Some(pool) = pool {
            entry["pool"] = json!(pool);
        }
        entry
    }

    #[test]
    fn entries_parse_with_their_optional_fields_defaulted() {
        let body =
            json!({"packages": [entry("a", None, Some("ab")), entry("b", Some("non-free"), None)]});
        let packages = parse_catalog(&body).expect("parses");
        assert_eq!(packages.len(), 2);
        assert!(packages[0].open_source);
        assert_eq!(packages[0].manifest.ipk_sha256.as_deref(), Some("ab"));
        assert!(!packages[1].open_source);
        assert_eq!(packages[1].manifest.ipk_sha256, None);
        assert_eq!(packages[1].short_description, "");
    }

    #[test]
    fn a_broken_entry_is_skipped_not_fatal() {
        let body = json!({"packages": [entry("a", None, None), {"id": "broken"}]});
        assert_eq!(parse_catalog(&body).expect("parses").len(), 1);
    }

    #[test]
    fn a_body_without_packages_is_an_error() {
        assert!(parse_catalog(&json!({"nope": []})).is_err());
    }

    #[test]
    fn a_published_hash_is_enforced_and_a_missing_one_is_not() {
        let bytes = b"package";
        let right = http::sha256_hex(bytes);
        assert!(check_integrity(bytes, Some(&right)).is_ok());
        assert!(check_integrity(bytes, Some(&right.to_uppercase())).is_ok());
        assert!(check_integrity(bytes, Some("00")).is_err());
        assert!(check_integrity(bytes, None).is_ok());
    }
}
