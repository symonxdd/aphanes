//! Pairing with a TV in Developer Mode, as ares-cli-rs's
//! `common/connection/src/setup.rs` and the mobile app's
//! `devmode_pairing_service.dart` do it: fetch the encrypted private key
//! from the TV's key server, decrypt it locally with the passphrase shown
//! in the Developer Mode app, and keep the result as the SSH identity for
//! every later connection.
//!
//! The passphrase never goes over the network. It only ever decrypts a
//! key that has already been fetched, so checking one is a purely local
//! computation once the encrypted key is cached.

mod key_server;
mod legacy_pem;

pub use key_server::KEY_SERVER_PORT;

use crate::Result;

/// The port of the TV's sshd in Developer Mode.
pub const DEV_MODE_PORT: u16 = 9922;

/// The built-in, sandboxed account every webOS TV's Developer Mode uses.
pub const DEV_MODE_USERNAME: &str = "prisoner";

/// What a successful pairing yields: the decrypted PKCS#1 private key.
#[derive(Debug, Clone)]
pub struct PairedCredentials {
    pub private_key_pem: String,
}

/// Whether a key server answers at `host`. Advisory only.
pub async fn probe(host: &str) -> bool {
    key_server::probe(host, KEY_SERVER_PORT).await
}

/// Fetches the encrypted key so passphrase attempts can be checked locally.
pub async fn fetch_encrypted_key(host: &str) -> Result<String> {
    key_server::fetch_encrypted_key(host, KEY_SERVER_PORT).await
}

/// Whether `passphrase` decrypts `encrypted_pem`. Local only.
pub fn validate_passphrase(encrypted_pem: &str, passphrase: &str) -> bool {
    legacy_pem::decrypt_to_pkcs1_pem(encrypted_pem, passphrase).is_ok()
}

/// Pairs with the TV at `host`, using a previously fetched encrypted key
/// when one is given rather than fetching it again.
pub async fn pair(
    host: &str,
    passphrase: &str,
    cached_encrypted_pem: Option<&str>,
) -> Result<PairedCredentials> {
    let encrypted_pem = match cached_encrypted_pem {
        Some(pem) => pem.to_string(),
        None => fetch_encrypted_key(host).await?,
    };
    let private_key_pem = legacy_pem::decrypt_to_pkcs1_pem(&encrypted_pem, passphrase)?;
    Ok(PairedCredentials { private_key_pem })
}

#[cfg(test)]
mod tests {
    use super::*;

    const PASSPHRASE: &str = "correct-horse";
    const PLAIN: &str = include_str!("../../tests/fixtures/plain_pkcs1.pem");

    fn normalised(pem: &str) -> String {
        pem.lines()
            .map(str::trim)
            .filter(|l| !l.is_empty())
            .collect::<Vec<_>>()
            .join("\n")
    }

    #[test]
    fn decrypts_aes_128() {
        let pem = include_str!("../../tests/fixtures/encrypted_aes128.pem");
        let plain = legacy_pem::decrypt_to_pkcs1_pem(pem, PASSPHRASE).expect("decrypts");
        assert_eq!(normalised(&plain), normalised(PLAIN));
    }

    #[test]
    fn decrypts_aes_256() {
        let pem = include_str!("../../tests/fixtures/encrypted_aes256.pem");
        let plain = legacy_pem::decrypt_to_pkcs1_pem(pem, PASSPHRASE).expect("decrypts");
        assert_eq!(normalised(&plain), normalised(PLAIN));
    }

    #[test]
    fn decrypts_triple_des() {
        let pem = include_str!("../../tests/fixtures/encrypted_des3.pem");
        let plain = legacy_pem::decrypt_to_pkcs1_pem(pem, PASSPHRASE).expect("decrypts");
        assert_eq!(normalised(&plain), normalised(PLAIN));
    }

    #[test]
    fn rejects_a_wrong_passphrase() {
        let pem = include_str!("../../tests/fixtures/encrypted_aes128.pem");
        assert!(!validate_passphrase(pem, "wrong"));
        assert!(validate_passphrase(pem, PASSPHRASE));
    }

    #[test]
    fn rejects_something_that_is_not_a_key() {
        assert!(!validate_passphrase("<html>not a key</html>", PASSPHRASE));
        assert!(!validate_passphrase(PLAIN, PASSPHRASE));
    }

    #[test]
    fn the_decrypted_key_loads_as_an_ssh_identity() {
        let pem = include_str!("../../tests/fixtures/encrypted_aes128.pem");
        let plain = legacy_pem::decrypt_to_pkcs1_pem(pem, PASSPHRASE).expect("decrypts");
        let key = russh::keys::decode_secret_key(&plain, None).expect("russh reads it");
        assert_eq!(key.algorithm().to_string(), "ssh-rsa");
    }
}
