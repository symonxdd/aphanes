//! Commands the frontend can invoke. Each one is a thin call into
//! `aphanes_protocol` or the device store, with errors forwarded as their
//! display text so the UI can show them inline. Every command runs only
//! because a person clicked or typed something; none runs on its own.

use aphanes_protocol::{pairing, reachability};
use tauri::State;

use crate::store::{DeviceRecord, DeviceStore};

/// Shared with every command: where devices are stored on this computer.
pub struct AppState {
    pub store: DeviceStore,
}

type CommandResult<T> = Result<T, String>;

fn shown<E: std::fmt::Display>(error: E) -> String {
    error.to_string()
}

/// The app version from `tauri.conf.json`, for the About surface.
#[tauri::command]
pub fn app_version(app: tauri::AppHandle) -> String {
    app.package_info().version.to_string()
}

#[tauri::command]
pub fn list_devices(state: State<'_, AppState>) -> CommandResult<Vec<DeviceRecord>> {
    state.store.load_all().map_err(shown)
}

/// Whether the TV answers on its SSH port right now. Runs when a device
/// is shown, never on a schedule.
#[tauri::command]
pub async fn check_reachable(host: String, port: u16) -> bool {
    reachability::is_reachable(&host, port).await
}

/// Whether a key server answers at `host`. Advisory: runs as the address
/// is typed, and a false negative never blocks a real pairing attempt.
#[tauri::command]
pub async fn probe_key_server(host: String) -> bool {
    pairing::probe(&host).await
}

/// Fetches the encrypted key once, so passphrase attempts can be checked
/// locally without further round trips.
#[tauri::command]
pub async fn fetch_encrypted_key(host: String) -> CommandResult<String> {
    pairing::fetch_encrypted_key(&host).await.map_err(shown)
}

/// Purely local: the passphrase never leaves this computer.
#[tauri::command]
pub async fn validate_passphrase(encrypted_pem: String, passphrase: String) -> bool {
    // Key derivation and decryption are CPU work; keep them off the
    // async runtime's threads so the UI's other calls are not held up.
    tokio::task::spawn_blocking(move || pairing::validate_passphrase(&encrypted_pem, &passphrase))
        .await
        .unwrap_or(false)
}

/// Pairs with the TV, stores its key and passphrase in the keychain and
/// its record in the device list, and returns the record.
#[tauri::command]
pub async fn pair_device(
    state: State<'_, AppState>,
    host: String,
    passphrase: String,
    cached_encrypted_pem: Option<String>,
    name: String,
) -> CommandResult<DeviceRecord> {
    let credentials = pairing::pair(&host, &passphrase, cached_encrypted_pem.as_deref())
        .await
        .map_err(shown)?;
    state
        .store
        .add(
            &name,
            &host,
            pairing::DEV_MODE_PORT,
            pairing::DEV_MODE_USERNAME,
            &credentials.private_key_pem,
            &passphrase,
        )
        .map_err(shown)
}

#[tauri::command]
pub fn rename_device(
    state: State<'_, AppState>,
    id: String,
    name: String,
) -> CommandResult<DeviceRecord> {
    state.store.rename(&id, &name).map_err(shown)
}

/// The pairing key, for the reveal on the device details page. Read from
/// the keychain at the moment of the click and nowhere else; the frontend
/// keeps it only while it is on screen.
#[tauri::command]
pub fn device_private_key(state: State<'_, AppState>, id: String) -> CommandResult<String> {
    state.store.private_key(&id).map_err(shown)
}

/// The passphrase, for the same reveal. Read at the moment of the click.
#[tauri::command]
pub fn device_passphrase(state: State<'_, AppState>, id: String) -> CommandResult<String> {
    state.store.passphrase(&id).map_err(shown)
}

/// Forgets a TV: its record and its secrets. Only ever called after the
/// confirmation dialog; the TV itself is not touched.
#[tauri::command]
pub fn remove_device(state: State<'_, AppState>, id: String) -> CommandResult<()> {
    state.store.remove(&id).map_err(shown)
}
