//! Commands the frontend can invoke. Each one is a thin call into
//! `aphanes_protocol` (or, as here, into the shell's own metadata), with
//! errors forwarded as their display text so the UI can show them inline.

/// The app version from `tauri.conf.json`, for the About surface.
#[tauri::command]
pub fn app_version(app: tauri::AppHandle) -> String {
    app.package_info().version.to_string()
}
