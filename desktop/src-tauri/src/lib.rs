//! The Tauri shell. Commands here stay thin: they call into
//! `aphanes_protocol` and the device store and return. No protocol logic
//! lives in this crate.

mod commands;
mod store;

use tauri::Manager;

use commands::AppState;
use store::DeviceStore;

/// Builds and runs the app. Called from `main.rs`.
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .setup(|app| {
            let dir = app.path().app_data_dir()?;
            app.manage(AppState {
                store: DeviceStore::new(dir),
            });
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::app_version,
            commands::list_devices,
            commands::check_reachable,
            commands::probe_key_server,
            commands::fetch_encrypted_key,
            commands::validate_passphrase,
            commands::pair_device,
            commands::rename_device,
            commands::device_private_key,
            commands::device_passphrase,
            commands::remove_device,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
