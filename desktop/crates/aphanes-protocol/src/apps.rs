//! Apps on a paired TV, over the same luna-bus protocol ares-cli-rs
//! (Apache-2.0) uses, verified against its `ares-install/src/{list,install,
//! remove}.rs`, and matching the mobile app's `apps_service.dart`.
//!
//! Install and remove change the TV, so each runs only as the direct
//! result of a click, over a connection the caller opened for that one
//! action and closes after it.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use tokio::io::AsyncWriteExt;

use crate::http::sha256_hex;
use crate::luna::{self, shell_escape};
use crate::ssh::Session;
use crate::{Error, Result};

const REMOTE_TEMP_DIR: &str = "/media/developer/temp";

/// The upload goes to the TV in pieces this size so progress can be
/// reported between them.
const UPLOAD_CHUNK: usize = 32 * 1024;

/// A homebrew or system app currently installed on a paired TV, as
/// reported by `luna://com.webos.applicationManager/dev/listApps`. Only
/// apps with `visible: true` become one of these, matching the reference
/// CLI.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct InstalledApp {
    pub id: String,
    pub title: String,
    pub version: String,
    pub vendor: Option<String>,
    /// Whether the TV listed the app as running when this list was
    /// fetched. See [`list_running`] for what running means.
    pub running: bool,
}

/// A step in an install or remove, reported as it happens so the UI can
/// show live progress rather than a spinner until the end.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(tag = "kind", rename_all = "camelCase")]
pub enum OperationProgress {
    /// Uploading the package to the TV over SFTP. Install only.
    Uploading { sent: u64, total: u64 },
    /// Comparing the uploaded file's checksum against what was sent.
    /// Install only, matching the reference CLI's post-upload check.
    Verifying,
    /// A raw status line from the TV's installer, e.g. "installing : 40".
    /// Shown as-is; the TV controls the wording.
    Working { message: String },
    /// The TV reported success. Nothing follows.
    Succeeded { package_id: String },
}

/// The installed apps, each marked running or not, from two calls on the
/// one session: asking for the running list here costs no connection,
/// so an app's page can open already knowing.
pub async fn list_installed(session: &Session) -> Result<Vec<InstalledApp>> {
    let response = luna::call(
        session,
        "luna://com.webos.applicationManager/dev/listApps",
        &json!({}),
    )
    .await?;
    let mut apps = parse_list(&response);
    // A running list that fails leaves every app marked not running,
    // which the page's own check corrects; the list itself still shows.
    let running = list_running(session).await.unwrap_or_default();
    for app in &mut apps {
        app.running = running.contains(&app.id);
    }
    Ok(apps)
}

/// Removes an app by id, reporting each step to `on_progress`.
pub async fn remove(
    session: &Session,
    package_id: &str,
    on_progress: &mut (dyn FnMut(OperationProgress) + Send),
) -> Result<()> {
    let subscription = luna::subscribe(
        session,
        "luna://com.webos.appInstallService/dev/remove",
        &json!({"id": package_id, "subscribe": true}),
    )
    .await?;
    follow_installer(subscription, "removed", on_progress).await
}

/// The ids of the apps running on the TV right now, as
/// `applicationManager/dev/running` reports them: the one form of that
/// call the Developer Mode account is allowed to make. Running is not
/// the same as in the foreground; the TV does not tell that much.
pub async fn list_running(session: &Session) -> Result<Vec<String>> {
    let response = luna::call(
        session,
        "luna://com.webos.applicationManager/dev/running",
        &json!({}),
    )
    .await?;
    if response.get("returnValue").and_then(Value::as_bool) == Some(false) {
        return Err(Error::message("The TV couldn't list its running apps."));
    }
    Ok(response
        .get("running")
        .and_then(Value::as_array)
        .map(|apps| {
            apps.iter()
                .filter_map(|app| app.get("id").and_then(Value::as_str))
                .map(str::to_string)
                .collect()
        })
        .unwrap_or_default())
}

/// Opens an app on the TV's screen, as pressing it on the TV would, and
/// reports which apps are running afterwards, on the same session. The
/// TV accepts a launch a moment before it lists the app as running, so
/// the list is read a few times until the app shows up in it; a launch
/// the TV accepted is reported as running even if it never did. Only
/// ever runs from the Launch button on the app's page.
pub async fn launch(session: &Session, app_id: &str) -> Result<Vec<String>> {
    let response = luna::call(
        session,
        "luna://com.webos.applicationManager/launch",
        &json!({"id": app_id}),
    )
    .await?;
    if response.get("returnValue").and_then(Value::as_bool) == Some(false) {
        let reason = response
            .get("errorText")
            .and_then(Value::as_str)
            .unwrap_or("The TV couldn't open that app.");
        return Err(Error::message(reason));
    }
    let mut running = Vec::new();
    for attempt in 0..LAUNCH_LIST_ATTEMPTS {
        if attempt > 0 {
            tokio::time::sleep(LAUNCH_LIST_INTERVAL).await;
        }
        running = list_running(session).await.unwrap_or_default();
        if running.iter().any(|id| id == app_id) {
            return Ok(running);
        }
    }
    running.push(app_id.to_string());
    Ok(running)
}

/// How often, and how far apart, the running list is read after a launch.
const LAUNCH_LIST_ATTEMPTS: u32 = 4;
const LAUNCH_LIST_INTERVAL: std::time::Duration = std::time::Duration::from_millis(500);

/// Installs a package already in memory: uploaded to the TV's temp
/// directory, checked, handed to the installer, and removed again after.
/// The caller is responsible for where the bytes came from; a catalog
/// download has been checked against its published hash by then.
pub async fn install(
    session: &Session,
    bytes: &[u8],
    on_progress: &mut (dyn FnMut(OperationProgress) + Send),
) -> Result<()> {
    let checksum = sha256_hex(bytes);
    let remote_path = format!("{REMOTE_TEMP_DIR}/ares_install_{}.ipk", &checksum[..10]);

    let sftp = session.sftp().await?;
    let result =
        upload_and_install(session, &sftp, &remote_path, bytes, &checksum, on_progress).await;
    // Best-effort cleanup on every path: a leftover package in the temp
    // directory is clutter, not a failure worth reporting over the real
    // outcome.
    let _ = sftp.remove_file(&remote_path).await;
    let _ = sftp.close().await;
    result
}

async fn upload_and_install(
    session: &Session,
    sftp: &russh_sftp::client::SftpSession,
    remote_path: &str,
    bytes: &[u8],
    checksum: &str,
    on_progress: &mut (dyn FnMut(OperationProgress) + Send),
) -> Result<()> {
    let upload_failed = |e: russh_sftp::client::error::Error| {
        Error::message(format!("Couldn't upload the package to the TV: {e}"))
    };
    // Already existing is the normal case and not an error.
    let _ = sftp.create_dir(REMOTE_TEMP_DIR).await;
    let mut file = sftp.create(remote_path).await.map_err(upload_failed)?;
    let total = bytes.len() as u64;
    on_progress(OperationProgress::Uploading { sent: 0, total });
    let mut sent = 0u64;
    for chunk in bytes.chunks(UPLOAD_CHUNK) {
        file.write_all(chunk)
            .await
            .map_err(|e| Error::message(format!("Couldn't upload the package to the TV: {e}")))?;
        sent += chunk.len() as u64;
        on_progress(OperationProgress::Uploading { sent, total });
    }
    file.shutdown()
        .await
        .map_err(|e| Error::message(format!("Couldn't upload the package to the TV: {e}")))?;

    on_progress(OperationProgress::Verifying);
    if let Some(remote) = remote_sha256(session, remote_path).await {
        if !remote.eq_ignore_ascii_case(checksum) {
            return Err(Error::message(
                "Upload is corrupted: the TV received different bytes than were sent.",
            ));
        }
    }

    let subscription = luna::subscribe(
        session,
        "luna://com.webos.appInstallService/dev/install",
        &json!({"id": "com.ares.defaultName", "ipkUrl": remote_path, "subscribe": true}),
    )
    .await?;
    follow_installer(subscription, "installed", on_progress).await
}

/// Mirrors the reference CLI's post-upload check: the uploaded file's
/// checksum, or None when the TV has no `sha256sum`, in which case the
/// check is skipped rather than failing the install over a missing tool.
async fn remote_sha256(session: &Session, remote_path: &str) -> Option<String> {
    let output = session
        .run(&format!("sha256sum {}", shell_escape(remote_path)))
        .await
        .ok()?;
    output.stdout.split_whitespace().next().map(str::to_string)
}

/// Reads installer messages until one is terminal, mirroring
/// `map_installer_message` in the reference CLI's `install.rs`: a FAILED
/// state is an error, a SUCCESS-prefixed state or one matching
/// `success_word` is done, anything else is progress text.
async fn follow_installer(
    mut subscription: luna::Subscription,
    success_word: &str,
    on_progress: &mut (dyn FnMut(OperationProgress) + Send),
) -> Result<()> {
    let outcome = async {
        while let Some(message) = subscription.next().await? {
            match installer_step(&message, success_word)? {
                Some(progress @ OperationProgress::Succeeded { .. }) => {
                    on_progress(progress);
                    return Ok(());
                }
                Some(progress) => on_progress(progress),
                None => {}
            }
        }
        Err(Error::message(
            "The TV closed the connection before finishing.",
        ))
    }
    .await;
    subscription.close().await;
    outcome
}

fn installer_step(message: &Value, success_word: &str) -> Result<Option<OperationProgress>> {
    let details = message.get("details");
    let Some(state) = details.and_then(|d| d.get("state")).and_then(Value::as_str) else {
        return Ok(None);
    };
    let lower = state.to_ascii_lowercase();
    if lower.contains("failed") {
        let reason = details
            .and_then(|d| d.get("reason"))
            .and_then(Value::as_str)
            .unwrap_or("The TV rejected that request.");
        return Err(Error::message(reason));
    }
    if lower.starts_with("success") || lower.contains(success_word) {
        let package_id = details
            .and_then(|d| d.get("packageId"))
            .and_then(Value::as_str)
            .unwrap_or_default()
            .to_string();
        return Ok(Some(OperationProgress::Succeeded { package_id }));
    }
    Ok(Some(OperationProgress::Working {
        message: state.to_string(),
    }))
}

/// The visible apps out of a `dev/listApps` response. An entry missing one
/// of the required fields is skipped rather than failing the whole list.
fn parse_list(response: &Value) -> Vec<InstalledApp> {
    let Some(apps) = response.get("apps").and_then(Value::as_array) else {
        return Vec::new();
    };
    apps.iter()
        .filter(|app| app.get("visible").and_then(Value::as_bool) == Some(true))
        .filter_map(|app| {
            Some(InstalledApp {
                id: app.get("id")?.as_str()?.to_string(),
                title: app.get("title")?.as_str()?.to_string(),
                version: app.get("version")?.as_str()?.to_string(),
                vendor: app
                    .get("vendor")
                    .and_then(Value::as_str)
                    .map(str::to_string),
                running: false,
            })
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_visible_apps_are_listed() {
        let response = json!({
            "returnValue": true,
            "apps": [
                {"id": "org.webosbrew.hbchannel", "title": "Homebrew Channel", "version": "0.6.3",
                 "vendor": "webosbrew.org", "visible": true},
                {"id": "com.webos.app.hidden", "title": "Hidden", "version": "1.0", "visible": false},
                {"id": "org.jellyfin.webos", "title": "Jellyfin", "version": "1.2.0", "visible": true},
                {"id": "broken", "visible": true}
            ]
        });
        let apps = parse_list(&response);
        assert_eq!(apps.len(), 2);
        assert_eq!(apps[0].id, "org.webosbrew.hbchannel");
        assert_eq!(apps[0].vendor.as_deref(), Some("webosbrew.org"));
        assert_eq!(apps[1].title, "Jellyfin");
        assert_eq!(apps[1].vendor, None);
    }

    #[test]
    fn a_response_without_apps_is_an_empty_list() {
        assert!(parse_list(&json!({"returnValue": true})).is_empty());
    }

    #[test]
    fn installer_messages_map_like_the_reference() {
        let step = |state: &str| installer_step(&json!({"details": {"state": state}}), "installed");
        assert_eq!(
            step("installing : 40").expect("ok"),
            Some(OperationProgress::Working {
                message: "installing : 40".into()
            })
        );
        assert!(matches!(
            step("SUCCESS").expect("ok"),
            Some(OperationProgress::Succeeded { .. })
        ));
        assert!(matches!(
            step("installed").expect("ok"),
            Some(OperationProgress::Succeeded { .. })
        ));
        assert!(step("FAILED").is_err());
        assert_eq!(
            installer_step(&json!({"returnValue": true}), "installed").expect("ok"),
            None
        );
    }

    #[test]
    fn a_failure_carries_the_reason_the_tv_gave() {
        let message = json!({"details": {"state": "FAILED", "reason": "Not enough space"}});
        let err = installer_step(&message, "installed").expect_err("fails");
        assert_eq!(err.to_string(), "Not enough space");
    }

    #[test]
    fn success_reports_the_package_id() {
        let message = json!({"details": {"state": "SUCCESS", "packageId": "org.xbmc.kodi"}});
        assert_eq!(
            installer_step(&message, "installed").expect("ok"),
            Some(OperationProgress::Succeeded {
                package_id: "org.xbmc.kodi".into()
            })
        );
    }
}
