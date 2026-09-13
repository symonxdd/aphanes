//! The Tauri shell. Commands here stay thin: they call into
//! `aphanes_protocol` and return. No protocol logic lives in this crate.

mod commands;

/// Builds and runs the app. Called from `main.rs`.
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![commands::app_version])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
