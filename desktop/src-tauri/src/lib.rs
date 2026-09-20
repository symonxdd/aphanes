//! The Tauri shell. Commands here stay thin: they call into
//! `aphanes_protocol` and the device store and return. No protocol logic
//! lives in this crate.

mod commands;
mod pool;
mod store;

use tauri::Manager;

use commands::AppState;
use store::DeviceStore;

/// Builds and runs the app. Called from `main.rs`.
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_dialog::init())
        .setup(|app| {
            let dir = app.path().app_data_dir()?;
            app.manage(AppState {
                store: DeviceStore::new(dir),
                pool: pool::SessionPool::default(),
            });
            mark_dev_window(app);
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
            commands::update_device_host,
            commands::device_private_key,
            commands::device_passphrase,
            commands::fetch_device_detail,
            commands::list_installed_apps,
            commands::renew_dev_mode,
            commands::fetch_catalog,
            commands::fetch_app_description,
            commands::list_running_apps,
            commands::launch_app,
            commands::remove_app,
            commands::install_from_catalog,
            commands::install_from_file,
            commands::remove_device,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

/// Appends a "(dev)" marker to the window title of a debug build, so a
/// window opened by `tauri dev` is never mistaken for an installed
/// release. A release build keeps the title from `tauri.conf.json`.
fn mark_dev_window(app: &tauri::App) {
    if !cfg!(debug_assertions) {
        return;
    }
    if let Some(window) = app.get_webview_window("main") {
        let title = window.title().unwrap_or_default();
        // A window that cannot be retitled still works; the missing
        // marker is not worth refusing to start over.
        let _ = window.set_title(&format!("{title} (dev)"));
    }
}
