//! What a paired TV reports about itself, and the state of its Developer
//! Mode session, for the device details page. Mirrors the mobile app's
//! `device_detail_service.dart`, which in turn follows dev-manager-desktop's
//! Info tab (`DeviceManagerService.getDeviceInfo`, `DevModeService.status`,
//! `src-tauri/src/plugins/devmode.rs`), verified against its source.

use serde::{Deserialize, Serialize};
use serde_json::{json, Value};

use crate::http;
use crate::luna::{self, shell_escape};
use crate::ssh::Session;
use crate::Result;

const DEV_MODE_TOKEN_PATH: &str = "/var/luna/preferences/devmode_enabled";
const MACHINE_NAME_PATH: &str = "/etc/prefs/properties/machineName";

/// Static hardware/firmware facts, read directly from the TV over the luna
/// bus. None of this changes without a firmware update, so the app keeps
/// the last copy and shows it while a fresh one is fetched.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceInfo {
    pub model_name: Option<String>,
    pub firmware_version: Option<String>,
    pub webos_version: Option<String>,
    pub ota_id: Option<String>,
    pub soc_name: Option<String>,
}

impl DeviceInfo {
    /// True when the TV reported nothing usable at all, in which case there
    /// is no point storing it.
    pub fn is_empty(&self) -> bool {
        *self == Self::default()
    }
}

/// Whether the TV currently has a Developer Mode session, and how long is
/// left on it. The session token itself stays in this crate: the UI only
/// needs to know that there is one.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DevModeStatus {
    pub has_session: bool,
    /// Exactly what LG's session endpoint returned, unparsed, e.g.
    /// "999:52:55". None when there is no session or the check failed.
    pub remaining: Option<String>,
}

/// The facts and the session, fetched together over one connection.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceDetail {
    pub info: DeviceInfo,
    pub dev_mode: DevModeStatus,
}

pub async fn fetch_detail(session: &Session) -> Result<DeviceDetail> {
    let info = fetch_device_info(session).await?;
    let dev_mode = fetch_dev_mode_status(session).await;
    Ok(DeviceDetail { info, dev_mode })
}

/// Tells the TV to open its own Developer Mode app with a flag that makes
/// it extend the current session on launch: the same mechanism as
/// reopening that app on the TV, triggered remotely. It visibly
/// foregrounds that app on the TV; there is no quieter way, confirmed
/// from dev-manager-desktop's implementation (`applicationManager/launch`
/// is the only path there too).
pub async fn renew(session: &Session) -> Result<()> {
    luna::call(
        session,
        "luna://com.webos.applicationManager/launch",
        &json!({
            "id": "com.palmdts.devmode",
            "subscribe": false,
            "params": {"extend": true},
        }),
    )
    .await?;
    Ok(())
}

async fn fetch_device_info(session: &Session) -> Result<DeviceInfo> {
    let system_info = luna::call(
        session,
        "luna://com.webos.service.tv.systemproperty/getSystemInfo",
        &json!({"keys": ["firmwareVersion", "modelName", "sdkVersion", "otaId"]}),
    )
    .await?;
    // Not every firmware answers this one; the fields it would have
    // filled in fall back to getSystemInfo's or stay blank.
    let os_info = luna::call(
        session,
        "luna://com.palm.systemservice/osInfo/query",
        &json!({"parameters": ["device_name", "webos_manufacturing_version", "webos_release"]}),
    )
    .await
    .ok();

    let mut info = merge_info(&system_info, os_info.as_ref());
    if info.ota_id.is_none() {
        info.ota_id = fetch_ota_id_fallback(session).await;
    }
    if info.soc_name.is_none() {
        info.soc_name = fetch_soc_name_fallback(session).await;
    }
    Ok(info)
}

/// The two luna responses folded into one record, blanks left as None.
fn merge_info(system_info: &Value, os_info: Option<&Value>) -> DeviceInfo {
    let system = |key: &str| non_empty(system_info.get(key));
    let os = |key: &str| os_info.and_then(|v| non_empty(v.get(key)));
    DeviceInfo {
        model_name: system("modelName"),
        firmware_version: system("firmwareVersion"),
        webos_version: os("webos_release").or_else(|| system("sdkVersion")),
        ota_id: system("otaId"),
        soc_name: os("device_name"),
    }
}

/// A handful of devices do not report otaId directly; this parses it out
/// of getDeviceUuid's billingId, matching dev-manager-desktop's fallback.
/// Best effort: any failure just leaves the field blank.
async fn fetch_ota_id_fallback(session: &Session) -> Option<String> {
    let response = luna::call(
        session,
        "luna://com.webos.service.sdx/getDeviceUuid",
        &json!({}),
    )
    .await
    .ok()?;
    let billing_id = response.get("billingId")?.as_str()?;
    ota_id_from_billing_id(billing_id)
}

/// `billingId` is a query string, e.g. `modelName=HE_DTV_W20P_AFADABAA&...`.
fn ota_id_from_billing_id(billing_id: &str) -> Option<String> {
    let url = reqwest::Url::parse(&format!("billing:?{billing_id}")).ok()?;
    url.query_pairs()
        .find(|(key, _)| key == "modelName")
        .map(|(_, value)| value.into_owned())
        .filter(|value| !value.is_empty())
}

async fn fetch_soc_name_fallback(session: &Session) -> Option<String> {
    let output = session
        .run(&format!("cat {}", shell_escape(MACHINE_NAME_PATH)))
        .await
        .ok()?;
    let text = output.stdout.trim();
    (!text.is_empty()).then(|| text.to_string())
}

async fn fetch_dev_mode_status(session: &Session) -> DevModeStatus {
    let Some(token) = read_session_token(session).await else {
        return DevModeStatus::default();
    };
    DevModeStatus {
        has_session: true,
        remaining: check_remaining_time(&token).await,
    }
}

/// The session token the Developer Mode app wrote to the TV. Read only
/// so it can be handed to LG's session check; never stored, never logged.
async fn read_session_token(session: &Session) -> Option<String> {
    let output = session
        .run(&format!("cat {}", shell_escape(DEV_MODE_TOKEN_PATH)))
        .await
        .ok()?;
    let token = output.stdout.trim();
    looks_like_token(token).then(|| token.to_string())
}

fn looks_like_token(text: &str) -> bool {
    !text.is_empty() && text.chars().all(|c| c.is_ascii_alphanumeric())
}

/// The one call in this crate that talks to a server other than the
/// paired TV: LG's own Developer Mode session endpoint, mirroring
/// dev-manager-desktop's implementation exactly (there is no local-only
/// way to learn a session's remaining time). A deliberate, scoped
/// exception to the project's local-network-only rule, documented in
/// CLAUDE.md. The token goes to this endpoint for this purpose only.
///
/// Best effort: a network failure or an unexpected answer means the time
/// is simply unknown, not that the page fails.
async fn check_remaining_time(token: &str) -> Option<String> {
    let url = reqwest::Url::parse_with_params(
        "https://developer.lge.com/secure/CheckDevModeSession.dev",
        [("sessionToken", token)],
    )
    .ok()?;
    let response = http::client()?.get(url).send().await.ok()?;
    if !response.status().is_success() {
        return None;
    }
    let body: Value = response.json().await.ok()?;
    remaining_from_response(&body)
}

fn remaining_from_response(body: &Value) -> Option<String> {
    if body.get("result").and_then(Value::as_str) != Some("success") {
        return None;
    }
    non_empty(body.get("errorMsg"))
}

fn non_empty(value: Option<&Value>) -> Option<String> {
    value
        .and_then(Value::as_str)
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(str::to_string)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn info_prefers_os_info_for_webos_and_soc_and_falls_back_to_sdk_version() {
        let system = json!({
            "modelName": "65UN70006LA", "firmwareVersion": "04.64.00",
            "sdkVersion": "5.6.0", "otaId": "HE_DTV_W20P_AFADABAA"
        });
        let os = json!({"device_name": "k6lp", "webos_release": "5.6.2"});
        let info = merge_info(&system, Some(&os));
        assert_eq!(info.model_name.as_deref(), Some("65UN70006LA"));
        assert_eq!(info.webos_version.as_deref(), Some("5.6.2"));
        assert_eq!(info.soc_name.as_deref(), Some("k6lp"));
        assert_eq!(info.ota_id.as_deref(), Some("HE_DTV_W20P_AFADABAA"));

        let info = merge_info(&system, None);
        assert_eq!(info.webos_version.as_deref(), Some("5.6.0"));
        assert_eq!(info.soc_name, None);
    }

    #[test]
    fn blank_strings_count_as_missing() {
        let system = json!({"modelName": "", "otaId": "  "});
        let info = merge_info(&system, None);
        assert!(info.is_empty());
    }

    #[test]
    fn ota_id_is_read_out_of_the_billing_id_query_string() {
        assert_eq!(
            ota_id_from_billing_id("modelName=HE_DTV_W20P_AFADABAA&serial=abc").as_deref(),
            Some("HE_DTV_W20P_AFADABAA")
        );
        assert_eq!(ota_id_from_billing_id("serial=abc"), None);
        assert_eq!(ota_id_from_billing_id("modelName="), None);
    }

    #[test]
    fn a_token_is_a_run_of_ascii_letters_and_digits() {
        assert!(looks_like_token("a1B2c3"));
        assert!(!looks_like_token(""));
        assert!(!looks_like_token("cat: no such file"));
    }

    #[test]
    fn remaining_time_is_taken_only_from_a_successful_answer() {
        assert_eq!(
            remaining_from_response(&json!({"result": "success", "errorMsg": "999:52:55"}))
                .as_deref(),
            Some("999:52:55")
        );
        assert_eq!(
            remaining_from_response(&json!({"result": "fail", "errorMsg": "invalid token"})),
            None
        );
    }
}
