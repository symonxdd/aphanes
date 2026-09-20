//! Where paired TVs live on this computer, split the way the constraints
//! demand: the private key and the passphrase in the OS keychain through
//! `keyring`, never in a file; everything that is not a secret (name,
//! address, when it was paired, what the TV last said about itself) in
//! one JSON file in the app data directory. Mobile keeps the whole record
//! in secure storage; here the keychain's per-entry size limits make the
//! split the safer shape.
//!
//! No Tauri types in this module: it takes the directory as a path, so it
//! can be tested against a temporary one.

use std::fs;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use aphanes_protocol::devmode::DeviceInfo;
use serde::{Deserialize, Serialize};

/// The keychain service name, a technical identifier, so the codename.
const KEYCHAIN_SERVICE: &str = "me.symon.aphanes";
const DEVICES_FILE: &str = "devices.json";

/// A paired TV, without its key.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
pub struct DeviceRecord {
    pub id: String,
    pub name: String,
    pub host: String,
    pub port: u16,
    pub username: String,
    /// Milliseconds since the Unix epoch, formatted by the frontend.
    pub paired_at: u64,
    /// What the TV reported about itself on the last successful fetch,
    /// so the details tab renders at once on later visits while a fresh
    /// fetch runs behind it. None of it changes without a firmware
    /// update. The Developer Mode session is deliberately not kept here:
    /// it is a countdown, so a stored copy would be wrong rather than
    /// stale.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub info: Option<DeviceInfo>,
}

#[derive(Debug, thiserror::Error)]
pub enum StoreError {
    #[error("Couldn't read the saved devices.")]
    Read(#[source] std::io::Error),
    #[error("Couldn't save the device list.")]
    Write(#[source] std::io::Error),
    #[error("The saved device list is damaged.")]
    Parse(#[source] serde_json::Error),
    #[error("This computer's keychain refused the pairing key: {0}")]
    Keychain(#[source] keyring::Error),
    #[error("No paired TV with that id.")]
    NotFound,
    #[error("The stored pairing key is damaged. Remove the device and pair it again.")]
    KeyDamaged,
}

pub type StoreResult<T> = Result<T, StoreError>;

/// Everything needed to open an SSH session to one device.
pub struct Connection {
    pub host: String,
    pub port: u16,
    pub username: String,
    pub private_key_pem: String,
}

/// The device list plus the keychain, rooted at one directory.
pub struct DeviceStore {
    dir: PathBuf,
}

impl DeviceStore {
    pub fn new(dir: impl Into<PathBuf>) -> Self {
        Self { dir: dir.into() }
    }

    pub fn load_all(&self) -> StoreResult<Vec<DeviceRecord>> {
        let path = self.file();
        if !path.exists() {
            return Ok(Vec::new());
        }
        let raw = fs::read_to_string(&path).map_err(StoreError::Read)?;
        serde_json::from_str(&raw).map_err(StoreError::Parse)
    }

    /// Adds a new record with a fresh id and the current time, storing the
    /// secrets first so a record never exists without them.
    pub fn add(
        &self,
        name: &str,
        host: &str,
        port: u16,
        username: &str,
        private_key_pem: &str,
        passphrase: &str,
    ) -> StoreResult<DeviceRecord> {
        let record = DeviceRecord {
            id: uuid::Uuid::new_v4().to_string(),
            name: name.to_string(),
            host: host.to_string(),
            port,
            username: username.to_string(),
            paired_at: now_millis(),
            info: None,
        };
        // As bytes, not text: the Windows store keeps text as UTF-16 and
        // caps an entry at 2560 bytes, which a 2048-bit RSA PEM overshoots
        // once doubled. As UTF-8 the same key fits with room to spare.
        key_entry(&record.id)?
            .set_secret(private_key_pem.as_bytes())
            .map_err(StoreError::Keychain)?;
        // The passphrase is not needed again by the app, which keeps the
        // decrypted key; it is kept only so the details page can show it.
        passphrase_entry(&record.id)?
            .set_password(passphrase)
            .map_err(StoreError::Keychain)?;
        let mut all = self.load_all()?;
        all.push(record.clone());
        self.write_all(&all)?;
        Ok(record)
    }

    pub fn rename(&self, id: &str, name: &str) -> StoreResult<DeviceRecord> {
        let mut all = self.load_all()?;
        let record = all
            .iter_mut()
            .find(|d| d.id == id)
            .ok_or(StoreError::NotFound)?;
        record.name = name.to_string();
        let updated = record.clone();
        self.write_all(&all)?;
        Ok(updated)
    }

    /// Changes the address a device is reached at. The pairing key does
    /// not depend on it, so this is the recovery path for a TV that was
    /// handed a new address (usually by DHCP) without pairing again.
    pub fn update_host(&self, id: &str, host: &str) -> StoreResult<DeviceRecord> {
        let mut all = self.load_all()?;
        let record = all
            .iter_mut()
            .find(|d| d.id == id)
            .ok_or(StoreError::NotFound)?;
        record.host = host.to_string();
        let updated = record.clone();
        self.write_all(&all)?;
        Ok(updated)
    }

    /// Records what a TV just reported. A no-op when it reported nothing
    /// usable, and when it matches what is already stored, which is the
    /// normal outcome.
    pub fn save_info(&self, id: &str, info: &DeviceInfo) -> StoreResult<()> {
        if info.is_empty() {
            return Ok(());
        }
        let mut all = self.load_all()?;
        let record = all
            .iter_mut()
            .find(|d| d.id == id)
            .ok_or(StoreError::NotFound)?;
        if record.info.as_ref() == Some(info) {
            return Ok(());
        }
        record.info = Some(info.clone());
        self.write_all(&all)
    }

    /// The connection details for a device, key included, for the protocol
    /// crate. The key is read from the keychain at the moment of the call
    /// and goes no further than the connection it opens.
    pub fn connection(&self, id: &str) -> StoreResult<Connection> {
        let record = self
            .load_all()?
            .into_iter()
            .find(|d| d.id == id)
            .ok_or(StoreError::NotFound)?;
        Ok(Connection {
            host: record.host,
            port: record.port,
            username: record.username,
            private_key_pem: self.private_key(id)?,
        })
    }

    pub fn remove(&self, id: &str) -> StoreResult<()> {
        let mut all = self.load_all()?;
        let before = all.len();
        all.retain(|d| d.id != id);
        if all.len() == before {
            return Err(StoreError::NotFound);
        }
        self.write_all(&all)?;
        // A secret with no record is harmless but pointless; a missing one
        // is not an error here, the record is already gone.
        if let Ok(entry) = key_entry(id) {
            let _ = entry.delete_credential();
        }
        if let Ok(entry) = passphrase_entry(id) {
            let _ = entry.delete_credential();
        }
        Ok(())
    }

    /// The private key for a device, straight from the keychain. Handed to
    /// the protocol crate, and to the frontend only when the person asks
    /// to see it on the device details page. Never logged.
    pub fn private_key(&self, id: &str) -> StoreResult<String> {
        let bytes = key_entry(id)?.get_secret().map_err(StoreError::Keychain)?;
        String::from_utf8(bytes).map_err(|_| StoreError::KeyDamaged)
    }

    /// The passphrase that unlocked the key at pairing time, for the reveal
    /// on the device details page. Never logged.
    pub fn passphrase(&self, id: &str) -> StoreResult<String> {
        passphrase_entry(id)?
            .get_password()
            .map_err(StoreError::Keychain)
    }

    fn file(&self) -> PathBuf {
        self.dir.join(DEVICES_FILE)
    }

    fn write_all(&self, all: &[DeviceRecord]) -> StoreResult<()> {
        fs::create_dir_all(&self.dir).map_err(StoreError::Write)?;
        let raw = serde_json::to_string_pretty(all).map_err(StoreError::Parse)?;
        write_atomically(&self.file(), raw.as_bytes()).map_err(StoreError::Write)
    }
}

fn key_entry(id: &str) -> StoreResult<keyring::Entry> {
    keyring::Entry::new(KEYCHAIN_SERVICE, &format!("device-key-{id}")).map_err(StoreError::Keychain)
}

fn passphrase_entry(id: &str) -> StoreResult<keyring::Entry> {
    keyring::Entry::new(KEYCHAIN_SERVICE, &format!("device-passphrase-{id}"))
        .map_err(StoreError::Keychain)
}

fn now_millis() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| u64::try_from(d.as_millis()).unwrap_or(u64::MAX))
        .unwrap_or(0)
}

/// Writes to a sibling temp file and renames it over the target, so a crash
/// mid-write leaves the old list intact rather than a truncated one.
fn write_atomically(path: &Path, bytes: &[u8]) -> std::io::Result<()> {
    let tmp = path.with_extension("json.tmp");
    fs::write(&tmp, bytes)?;
    fs::rename(&tmp, path)
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;

    fn temp_dir() -> PathBuf {
        let dir = std::env::temp_dir().join(format!("aphanes-store-test-{}", uuid::Uuid::new_v4()));
        fs::create_dir_all(&dir).unwrap();
        dir
    }

    #[test]
    fn an_empty_store_lists_nothing() {
        let store = DeviceStore::new(temp_dir());
        assert!(store.load_all().unwrap().is_empty());
    }

    #[test]
    fn the_list_round_trips_through_the_file() {
        let store = DeviceStore::new(temp_dir());
        let all = vec![DeviceRecord {
            id: "a".into(),
            name: "Living room".into(),
            host: "10.0.0.3".into(),
            port: 9922,
            username: "prisoner".into(),
            paired_at: 1_700_000_000_000,
            info: None,
        }];
        store.write_all(&all).unwrap();
        assert_eq!(store.load_all().unwrap(), all);
        let info = DeviceInfo {
            model_name: Some("65UN70006LA".into()),
            ..DeviceInfo::default()
        };
        store.save_info("a", &info).unwrap();
        assert_eq!(store.load_all().unwrap()[0].info.as_ref(), Some(&info));
        store.save_info("a", &DeviceInfo::default()).unwrap();
        assert_eq!(store.load_all().unwrap()[0].info.as_ref(), Some(&info));
        assert_eq!(store.rename("a", "Bedroom").unwrap().name, "Bedroom");
        assert_eq!(store.load_all().unwrap()[0].name, "Bedroom");
        assert!(matches!(
            store.rename("zzz", "x"),
            Err(StoreError::NotFound)
        ));
        assert_eq!(
            store.update_host("a", "192.168.1.80").unwrap().host,
            "192.168.1.80"
        );
        assert_eq!(store.load_all().unwrap()[0].host, "192.168.1.80");
        assert!(matches!(
            store.update_host("zzz", "10.0.0.1"),
            Err(StoreError::NotFound)
        ));
        store.remove("a").unwrap();
        assert!(store.load_all().unwrap().is_empty());
        assert!(matches!(store.remove("a"), Err(StoreError::NotFound)));
    }

    /// Against the real keychain, with a key the size a TV serves: a
    /// 2048-bit RSA PKCS#1 PEM is about 1700 characters, which the Windows
    /// store refuses as text (UTF-16 doubles it past its 2560-byte cap)
    /// but takes as bytes. Cleans up after itself.
    #[test]
    fn a_tv_sized_key_round_trips_through_the_keychain() {
        let store = DeviceStore::new(temp_dir());
        let body = "A".repeat(1_600);
        let pem = format!(
            "-----BEGIN RSA PRIVATE KEY-----
{body}
-----END RSA PRIVATE KEY-----
"
        );
        let record = store
            .add("Test", "10.0.0.4", 9922, "prisoner", &pem, "AB12CD")
            .unwrap();
        let read_back = store.private_key(&record.id);
        let passphrase = store.passphrase(&record.id);
        store.remove(&record.id).unwrap();
        assert_eq!(read_back.unwrap(), pem);
        assert_eq!(passphrase.unwrap(), "AB12CD");
        assert!(matches!(
            store.private_key(&record.id),
            Err(StoreError::Keychain(_))
        ));
        assert!(matches!(
            store.passphrase(&record.id),
            Err(StoreError::Keychain(_))
        ));
    }
}
