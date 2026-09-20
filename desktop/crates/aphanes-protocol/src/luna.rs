//! `luna-send-pub` calls over an open [`Session`], matching ares-cli-rs's
//! (Apache-2.0) `common/connection/src/luna/luna.rs` and the mobile app's
//! `luna_command_service.dart`: the one-shot call goes over the *public*
//! bus (`luna-send-pub`, not `luna-send`), confirmed by reading that file
//! rather than assuming from the command name.
//!
//! Both forms are here: the one-shot call, and the subscribed call that
//! install and remove use, whose messages arrive one JSON object per line
//! for as long as the TV keeps the subscription open.

use std::time::Duration;

use serde_json::Value;

use crate::ssh::{CommandStream, Session};
use crate::{Error, Result};

/// How long a subscription may go quiet before it is given up on. The
/// installer reports every step, so a silence this long means a hang.
const SUBSCRIPTION_TIMEOUT: Duration = Duration::from_secs(60);

/// A single-response call (`luna-send-pub -n 1 <uri> <payload>`), for
/// `dev/listApps`, `getSystemInfo` and the like. Returns the decoded JSON
/// response. A call that succeeds but reports an application-level error
/// is not a failure here; callers read that from the response.
pub async fn call(session: &Session, uri: &str, payload: &Value) -> Result<Value> {
    let command = format!(
        "luna-send-pub -n 1 {} {}",
        shell_escape(uri),
        shell_escape(&payload.to_string())
    );
    let output = session.run(&command).await?;
    if output.exit_code != 0 {
        let stderr = output.stderr.trim();
        return Err(Error::message(if stderr.is_empty() {
            "The TV rejected that request."
        } else {
            stderr
        }));
    }
    match serde_json::from_str::<Value>(&output.stdout) {
        Ok(value) if value.is_object() => Ok(value),
        _ => Err(Error::message("The TV sent an unexpected response.")),
    }
}

/// A subscribed call (`luna-send-pub -i <uri> <payload>`), for
/// `dev/install` and `dev/remove`. Messages are read with
/// [`Subscription::next`] as they arrive.
pub async fn subscribe(session: &Session, uri: &str, payload: &Value) -> Result<Subscription> {
    let command = format!(
        "luna-send-pub -i {} {}",
        shell_escape(uri),
        shell_escape(&payload.to_string())
    );
    Ok(Subscription {
        stream: session.stream(&command).await?,
    })
}

/// An open luna subscription. Closing it ends the `luna-send-pub` process
/// on the TV; the operation it reported on carries on regardless.
pub struct Subscription {
    stream: CommandStream,
}

impl Subscription {
    /// The next JSON message, or None once the TV has closed the
    /// subscription. A line that is not JSON is skipped rather than
    /// aborting the whole subscription over one malformed message.
    pub async fn next(&mut self) -> Result<Option<Value>> {
        loop {
            let Some(line) = self.stream.next_line(SUBSCRIPTION_TIMEOUT).await? else {
                return Ok(None);
            };
            if line.trim().is_empty() {
                continue;
            }
            if let Ok(value) = serde_json::from_str::<Value>(&line) {
                if value.is_object() {
                    return Ok(Some(value));
                }
            }
        }
    }

    pub async fn close(self) {
        self.stream.close().await;
    }
}

/// Standard POSIX single-quote shell escaping: wraps in `'...'`, replacing
/// any embedded `'` with `'\''`. A stricter superset of what the
/// reference's `snailquote::escape` produces for the values this app ever
/// sends, and correct for arbitrary content besides.
pub fn shell_escape(value: &str) -> String {
    format!("'{}'", value.replace('\'', "'\\''"))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn plain_values_are_wrapped() {
        assert_eq!(shell_escape("luna://a/b"), "'luna://a/b'");
        assert_eq!(shell_escape(r#"{"keys":["a"]}"#), r#"'{"keys":["a"]}'"#);
    }

    #[test]
    fn a_single_quote_is_closed_escaped_and_reopened() {
        assert_eq!(shell_escape("it's"), r"'it'\''s'");
    }
}
