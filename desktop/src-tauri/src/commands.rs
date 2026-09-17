//! Commands the frontend can invoke. Each one is a thin call into
//! `aphanes_protocol` or the device store, with errors forwarded as their
//! display text so the UI can show them inline. Every command runs only
//! because a person clicked or typed something; none runs on its own.

use aphanes_protocol::apps::{InstalledApp, OperationProgress};
use aphanes_protocol::catalog::CatalogPackage;
use aphanes_protocol::devmode::DeviceDetail;
use aphanes_protocol::ssh::Session;
use aphanes_protocol::{apps, catalog, devmode, pairing, reachability};
use tauri::ipc::Channel;
use tauri::State;

use crate::store::{Connection, DeviceRecord, DeviceStore};

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

/// Saves a new address for an already-paired TV, from the edit on the
/// device details page. Nothing is sent to the TV; the next connection
/// simply goes to the new address with the same key.
#[tauri::command]
pub fn update_device_host(
    state: State<'_, AppState>,
    id: String,
    host: String,
) -> CommandResult<DeviceRecord> {
    state.store.update_host(&id, &host).map_err(shown)
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

/// What the TV reports about itself and its Developer Mode session, over
/// one connection, as the mobile app's `DeviceDetailService.fetch` does.
/// The facts are stored for the next visit; the session never is.
#[tauri::command]
pub async fn fetch_device_detail(
    state: State<'_, AppState>,
    id: String,
) -> CommandResult<DeviceDetail> {
    let session = open_session(&state.store, &id).await?;
    let detail = devmode::fetch_detail(&session).await;
    session.close().await;
    let detail = detail.map_err(shown)?;
    state.store.save_info(&id, &detail.info).map_err(shown)?;
    Ok(detail)
}

/// The visible apps installed on the TV, on a connection of its own.
#[tauri::command]
pub async fn list_installed_apps(
    state: State<'_, AppState>,
    id: String,
) -> CommandResult<Vec<InstalledApp>> {
    let session = open_session(&state.store, &id).await?;
    let apps = apps::list_installed(&session).await;
    session.close().await;
    apps.map_err(shown)
}

/// Asks the TV to extend its Developer Mode session. Opens the Developer
/// Mode app on the TV's screen; only ever runs from the Renew button.
#[tauri::command]
pub async fn renew_dev_mode(state: State<'_, AppState>, id: String) -> CommandResult<()> {
    let session = open_session(&state.store, &id).await?;
    let result = devmode::renew(&session).await;
    session.close().await;
    result.map_err(shown)
}

/// The public Homebrew catalog listing. Fetched when the catalog dialog
/// opens, never in the background.
#[tauri::command]
pub async fn fetch_catalog() -> CommandResult<Vec<CatalogPackage>> {
    catalog::fetch_catalog().await.map_err(shown)
}

/// One app's README fragment from the catalog. Fetched when the app's
/// page opens, never ahead of time.
#[tauri::command]
pub async fn fetch_app_description(url: String) -> CommandResult<String> {
    catalog::fetch_description(&url).await.map_err(shown)
}

/// The ids of the apps running on the TV, read when an app's page opens.
#[tauri::command]
pub async fn list_running_apps(
    state: State<'_, AppState>,
    id: String,
) -> CommandResult<Vec<String>> {
    let session = open_session(&state.store, &id).await?;
    let result = apps::list_running(&session).await;
    session.close().await;
    result.map_err(shown)
}

/// Opens an app on the TV's screen. Only ever runs from the Launch button.
#[tauri::command]
pub async fn launch_app(
    state: State<'_, AppState>,
    id: String,
    app_id: String,
) -> CommandResult<()> {
    let session = open_session(&state.store, &id).await?;
    let result = apps::launch(&session, &app_id).await;
    session.close().await;
    result.map_err(shown)
}

/// Uninstalls an app. Only ever called after the confirmation dialog;
/// each step is reported on `on_progress` as the TV reports it.
#[tauri::command]
pub async fn remove_app(
    state: State<'_, AppState>,
    id: String,
    package_id: String,
    on_progress: Channel<OperationProgress>,
) -> CommandResult<()> {
    let session = open_session(&state.store, &id).await?;
    let result = apps::remove(&session, &package_id, &mut forward_to(&on_progress)).await;
    session.close().await;
    result.map_err(shown)
}

/// Installs a catalog package: downloaded, checked against the published
/// SHA-256 (refused on a mismatch or when there is none), then uploaded
/// and installed. Runs only from the Install button on a catalog entry.
#[tauri::command]
pub async fn install_from_catalog(
    state: State<'_, AppState>,
    id: String,
    ipk_url: String,
    ipk_sha256: Option<String>,
    on_progress: Channel<OperationProgress>,
) -> CommandResult<()> {
    let _ = on_progress.send(OperationProgress::Working {
        message: "Downloading...".into(),
    });
    let bytes = catalog::download_and_verify(&ipk_url, ipk_sha256.as_deref())
        .await
        .map_err(shown)?;
    install_bytes(&state.store, &id, &bytes, &on_progress).await
}

/// Installs a .ipk the person picked from this computer's disk.
#[tauri::command]
pub async fn install_from_file(
    state: State<'_, AppState>,
    id: String,
    path: String,
    on_progress: Channel<OperationProgress>,
) -> CommandResult<()> {
    let bytes = tokio::fs::read(&path)
        .await
        .map_err(|_| "Couldn't read that file.".to_string())?;
    install_bytes(&state.store, &id, &bytes, &on_progress).await
}

async fn install_bytes(
    store: &DeviceStore,
    id: &str,
    bytes: &[u8],
    on_progress: &Channel<OperationProgress>,
) -> CommandResult<()> {
    let session = open_session(store, id).await?;
    let result = apps::install(&session, bytes, &mut forward_to(on_progress)).await;
    session.close().await;
    result.map_err(shown)
}

/// Relays protocol progress to the frontend. A send failure means the
/// window is gone; the operation itself is not interrupted over it.
fn forward_to(channel: &Channel<OperationProgress>) -> impl FnMut(OperationProgress) + Send + '_ {
    move |progress| {
        let _ = channel.send(progress);
    }
}

/// One connection for one command. The key is read from the keychain
/// here and handed straight to the protocol crate.
async fn open_session(store: &DeviceStore, id: &str) -> CommandResult<Session> {
    let Connection {
        host,
        port,
        username,
        private_key_pem,
    } = store.connection(id).map_err(shown)?;
    Session::connect(&host, port, &username, &private_key_pem)
        .await
        .map_err(shown)
}

/// Forgets a TV: its record and its secrets. Only ever called after the
/// confirmation dialog; the TV itself is not touched.
#[tauri::command]
pub fn remove_device(state: State<'_, AppState>, id: String) -> CommandResult<()> {
    state.store.remove(&id).map_err(shown)
}
