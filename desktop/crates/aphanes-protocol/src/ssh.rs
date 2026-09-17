//! One authenticated SSH connection to a paired TV, as the mobile app's
//! `ssh_connection_service.dart` opens it: for the length of one
//! user-triggered action, closed by the caller when done. No cached or
//! shared session, no reconnecting on its own.
//!
//! The TV's sshd is old (OpenSSH 6.1 on the TV this was built against).
//! It has no curve25519, negotiates `ecdh-sha2-nistp256` or the SHA-1
//! Diffie-Hellman groups for key exchange, `hmac-sha1` for integrity, and
//! only verifies user signatures made with the classic `ssh-rsa` (SHA-1)
//! algorithm, never `rsa-sha2-*`. russh compiles all of those in but
//! leaves them out of its default preference lists, so [`Session::connect`]
//! builds its own order (see [`preferred_for_tv`]); a newer server still
//! gets the modern choice. For the user signature it asks the server
//! which RSA hash it accepts and falls back to SHA-1 when auth fails,
//! which gives the same two candidates the mobile app offers side by
//! side (see `legacy_ssh_rsa_identity.dart`).
//!
//! No host key pinning, matching pairing's own choice and the mobile app:
//! webOS devices do not keep a stable host key across resets.

use std::borrow::Cow;
use std::sync::Arc;
use std::time::Duration;

use russh::client::{self, AuthResult, Handle};
use russh::keys::{self, PrivateKeyWithHashAlg};
use russh::{kex, mac, ChannelMsg, Disconnect, Preferred};

use crate::{Error, Result};

/// How long to wait for the TCP connect and, separately, for authentication.
const CONNECT_TIMEOUT: Duration = Duration::from_secs(10);

/// How long one command may run before the TV is considered hung.
const COMMAND_TIMEOUT: Duration = Duration::from_secs(10);

/// What a finished command left behind. Both streams are decoded leniently:
/// the TV's tools write UTF-8, but a stray byte should not turn a result
/// into an error.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct CommandOutput {
    pub exit_code: u32,
    pub stdout: String,
    pub stderr: String,
}

/// An open, authenticated connection.
pub struct Session {
    handle: Handle<AcceptAnyHostKey>,
}

impl Session {
    /// Connects and authenticates with the PKCS#1 key pairing produced.
    pub async fn connect(
        host: &str,
        port: u16,
        username: &str,
        private_key_pem: &str,
    ) -> Result<Self> {
        let key = keys::decode_secret_key(private_key_pem, None).map_err(|_| {
            Error::message(
                "The stored pairing key is damaged. Remove the device and pair it again.",
            )
        })?;
        let key = Arc::new(key);

        let config = Arc::new(client::Config {
            preferred: preferred_for_tv(),
            inactivity_timeout: Some(Duration::from_secs(60)),
            ..client::Config::default()
        });

        let connecting = client::connect(config, (host, port), AcceptAnyHostKey);
        let mut handle = match tokio::time::timeout(CONNECT_TIMEOUT, connecting).await {
            Ok(Ok(handle)) => handle,
            Ok(Err(russh::Error::IO(_))) => return Err(Error::Unreachable),
            Ok(Err(e)) => return Err(Error::message(format!("Couldn't connect to the TV: {e}"))),
            Err(_) => return Err(Error::Timeout),
        };

        let authenticating = authenticate(&mut handle, username, key);
        match tokio::time::timeout(CONNECT_TIMEOUT, authenticating).await {
            Ok(Ok(())) => Ok(Self { handle }),
            Ok(Err(e)) => {
                let _ = handle.disconnect(Disconnect::ByApplication, "", "en").await;
                Err(e)
            }
            Err(_) => {
                let _ = handle.disconnect(Disconnect::ByApplication, "", "en").await;
                Err(Error::message(
                    "The TV stopped responding while connecting.",
                ))
            }
        }
    }

    /// Runs one command to completion and collects what it wrote. The
    /// command string is passed to the TV's shell as-is; callers quote
    /// their arguments with [`crate::luna::shell_escape`].
    pub async fn run(&self, command: &str) -> Result<CommandOutput> {
        tokio::time::timeout(COMMAND_TIMEOUT, self.run_untimed(command))
            .await
            .map_err(|_| Error::message("The TV took too long to respond."))?
    }

    async fn run_untimed(&self, command: &str) -> Result<CommandOutput> {
        let mut channel = self.handle.channel_open_session().await.map_err(io_error)?;
        channel.exec(true, command).await.map_err(io_error)?;

        let mut stdout = Vec::new();
        let mut stderr = Vec::new();
        let mut exit_code = 0;
        // Read until the server closes the channel. The exit status
        // arrives before Eof/Close, so it is recorded and the loop goes on
        // until the streams are drained.
        while let Some(msg) = channel.wait().await {
            match msg {
                ChannelMsg::Data { data } => stdout.extend_from_slice(&data),
                ChannelMsg::ExtendedData { data, ext: 1 } => stderr.extend_from_slice(&data),
                ChannelMsg::ExitStatus { exit_status } => exit_code = exit_status,
                ChannelMsg::Failure => {
                    return Err(Error::message("The TV refused to run that command."))
                }
                ChannelMsg::Close => break,
                _ => {}
            }
        }

        Ok(CommandOutput {
            exit_code,
            stdout: String::from_utf8_lossy(&stdout).into_owned(),
            stderr: String::from_utf8_lossy(&stderr).into_owned(),
        })
    }

    /// Starts a command and hands back its stdout as it arrives, line by
    /// line, for commands that keep writing until told to stop (a luna
    /// subscription). Dropping or closing the stream ends the command.
    pub async fn stream(&self, command: &str) -> Result<CommandStream> {
        let channel = self.handle.channel_open_session().await.map_err(io_error)?;
        channel.exec(true, command).await.map_err(io_error)?;
        Ok(CommandStream {
            channel,
            buffer: Vec::new(),
            finished: false,
        })
    }

    /// Opens the SFTP subsystem on this connection, for uploading a package.
    pub async fn sftp(&self) -> Result<russh_sftp::client::SftpSession> {
        let channel = self.handle.channel_open_session().await.map_err(io_error)?;
        channel
            .request_subsystem(true, "sftp")
            .await
            .map_err(io_error)?;
        russh_sftp::client::SftpSession::new(channel.into_stream())
            .await
            .map_err(|e| Error::message(format!("Couldn't open a file transfer to the TV: {e}")))
    }

    /// Ends the connection. Errors are ignored: there is nothing left to
    /// do with a connection that failed to close politely.
    pub async fn close(self) {
        let _ = self
            .handle
            .disconnect(Disconnect::ByApplication, "", "en")
            .await;
    }
}

/// A running command's stdout, read one line at a time.
pub struct CommandStream {
    channel: russh::Channel<client::Msg>,
    buffer: Vec<u8>,
    finished: bool,
}

impl CommandStream {
    /// The next complete line, without its newline, or None once the
    /// command has ended and the buffer is drained. Waits at most
    /// `timeout` for the TV to write something.
    pub async fn next_line(&mut self, timeout: Duration) -> Result<Option<String>> {
        loop {
            if let Some(at) = self.buffer.iter().position(|b| *b == b'\n') {
                let line: Vec<u8> = self.buffer.drain(..=at).collect();
                let text = String::from_utf8_lossy(&line[..line.len() - 1]).into_owned();
                return Ok(Some(text));
            }
            if self.finished {
                if self.buffer.is_empty() {
                    return Ok(None);
                }
                let rest = String::from_utf8_lossy(&self.buffer).into_owned();
                self.buffer.clear();
                return Ok(Some(rest));
            }
            let msg = tokio::time::timeout(timeout, self.channel.wait())
                .await
                .map_err(|_| Error::message("The TV stopped reporting progress."))?;
            match msg {
                Some(ChannelMsg::Data { data }) => self.buffer.extend_from_slice(&data),
                Some(ChannelMsg::Failure) => {
                    return Err(Error::message("The TV refused to run that command."))
                }
                Some(ChannelMsg::Eof) | Some(ChannelMsg::Close) | None => self.finished = true,
                Some(_) => {}
            }
        }
    }

    /// Stops the command. Errors are ignored: the caller has what it needs.
    pub async fn close(self) {
        let _ = self.channel.close().await;
    }
}

/// Tries the RSA hash the server says it supports, then classic SHA-1
/// `ssh-rsa` if that was refused or the server said nothing. A webOS TV
/// sends no `server-sig-algs`, so it goes straight to the fallback.
async fn authenticate(
    handle: &mut Handle<AcceptAnyHostKey>,
    username: &str,
    key: Arc<keys::PrivateKey>,
) -> Result<()> {
    let mut candidates = Vec::new();
    if let Ok(Some(hash)) = handle.best_supported_rsa_hash().await {
        candidates.push(hash);
    }
    if !candidates.contains(&None) {
        candidates.push(None);
    }

    let mut last_failure = None;
    for hash in candidates {
        let attempt = PrivateKeyWithHashAlg::new(Arc::clone(&key), hash);
        match handle.authenticate_publickey(username, attempt).await {
            Ok(AuthResult::Success) => return Ok(()),
            Ok(AuthResult::Failure { .. }) => last_failure = None,
            Err(e) => last_failure = Some(e),
        }
    }

    // Shown in full rather than as a generic message: with no crash
    // reporting, this is the only way such a failure is ever diagnosable.
    Err(match last_failure {
        Some(e) => Error::message(format!(
            "Couldn't authenticate with the TV. It may need pairing again: {e}"
        )),
        None => Error::message("Couldn't authenticate with the TV. It may need pairing again."),
    })
}

/// russh's modern defaults, then the legacy algorithms the TV needs, with
/// two changes to the key exchange list.
///
/// ECDH over the NIST curves goes in right after curve25519: the TV has
/// no curve25519, and ECDH is the modern exchange it does have. Group
/// exchange (`diffie-hellman-group-exchange-*`) is left out altogether:
/// with it, the server picks the group, and the TV picks an 8192-bit one
/// whose exponentiation took russh 27 seconds in a debug build, well past
/// [`CONNECT_TIMEOUT`]. Every fixed group left in the list is one the
/// client sized itself.
fn preferred_for_tv() -> Preferred {
    let defaults = Preferred::default();
    let mut kex_list: Vec<kex::Name> = Vec::new();
    for name in defaults.kex.iter().copied() {
        if name == kex::DH_GEX_SHA256 || name == kex::DH_GEX_SHA1 {
            continue;
        }
        kex_list.push(name);
        if name == kex::CURVE25519_PRE_RFC_8731 {
            kex_list.extend([
                kex::ECDH_SHA2_NISTP256,
                kex::ECDH_SHA2_NISTP384,
                kex::ECDH_SHA2_NISTP521,
            ]);
        }
    }
    for name in [kex::DH_G14_SHA1, kex::DH_G1_SHA1] {
        if !kex_list.contains(&name) {
            kex_list.push(name);
        }
    }
    let mut mac_list = defaults.mac.to_vec();
    for name in [mac::HMAC_SHA1_ETM, mac::HMAC_SHA1] {
        if !mac_list.contains(&name) {
            mac_list.push(name);
        }
    }
    Preferred {
        kex: Cow::Owned(kex_list),
        mac: Cow::Owned(mac_list),
        ..defaults
    }
}

fn io_error(e: russh::Error) -> Error {
    Error::message(format!("The connection to the TV failed: {e}"))
}

/// Accepts whichever host key the TV presents. See the module docs.
struct AcceptAnyHostKey;

impl client::Handler for AcceptAnyHostKey {
    type Error = russh::Error;

    async fn check_server_key(
        &mut self,
        _server_public_key: &keys::PublicKeyOrCertificate,
    ) -> std::result::Result<bool, Self::Error> {
        Ok(true)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn the_legacy_algorithms_are_offered_after_the_modern_ones() {
        let preferred = preferred_for_tv();
        let kex_list = preferred.kex.as_ref();
        let first_legacy = kex_list
            .iter()
            .position(|k| *k == kex::DH_G1_SHA1)
            .expect("group1-sha1 is offered");
        let curve = kex_list
            .iter()
            .position(|k| *k == kex::CURVE25519)
            .expect("curve25519 is offered");
        let ecdh = kex_list
            .iter()
            .position(|k| *k == kex::ECDH_SHA2_NISTP256)
            .expect("ecdh nistp256 is offered");
        assert!(curve < ecdh);
        assert!(ecdh < first_legacy);
        assert!(!kex_list.contains(&kex::DH_GEX_SHA256));
        assert!(!kex_list.contains(&kex::DH_GEX_SHA1));
        assert!(preferred.mac.contains(&mac::HMAC_SHA1));
        assert!(preferred.mac.contains(&mac::HMAC_SHA256));
    }
}
