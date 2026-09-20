//! The HTTPS clients for the few hosts this crate reaches besides the TV:
//! repo.webosbrew.org for the catalog, whatever host a catalog entry names
//! for its package, and developer.lge.com for the Developer Mode session
//! check. That list is closed; it is spelled out in CLAUDE.md.
//!
//! TLS runs on rustls with `ring` doing the cryptography, the same backend
//! russh uses, chosen so the app builds with cargo alone on every desktop
//! target (reqwest's default provider, aws-lc-rs, needs NASM and CMake on
//! Windows). rustls learns which provider to use through a process-wide
//! registration, which is what `install_default` is: a function call
//! inside this program, made once, that touches nothing outside it.
//! Server certificates are checked against the operating system's own
//! trust store.

use std::sync::OnceLock;
use std::time::Duration;

/// For small, quick requests: the catalog listing and the session check.
/// The whole request must finish within the timeout.
pub fn client() -> Option<&'static reqwest::Client> {
    static CLIENT: OnceLock<Option<reqwest::Client>> = OnceLock::new();
    CLIENT
        .get_or_init(|| {
            register_provider();
            reqwest::Client::builder()
                .timeout(Duration::from_secs(15))
                .build()
                .ok()
        })
        .as_ref()
}

/// For package downloads, which can run to tens of megabytes: a bounded
/// connect, but no bound on the transfer itself.
pub fn download_client() -> Option<&'static reqwest::Client> {
    static CLIENT: OnceLock<Option<reqwest::Client>> = OnceLock::new();
    CLIENT
        .get_or_init(|| {
            register_provider();
            reqwest::Client::builder()
                .connect_timeout(Duration::from_secs(15))
                .build()
                .ok()
        })
        .as_ref()
}

fn register_provider() {
    // Err means a provider is already registered, which is fine.
    let _ = rustls::crypto::ring::default_provider().install_default();
}

/// Lowercase hex SHA-256 of `bytes`, the form catalog manifests publish.
pub fn sha256_hex(bytes: &[u8]) -> String {
    use sha2::Digest;
    data_encoding::HEXLOWER.encode(&sha2::Sha256::digest(bytes))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sha256_matches_the_published_form() {
        assert_eq!(
            sha256_hex(b"abc"),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        );
    }
}
