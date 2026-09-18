//! One held SSH connection per paired TV, reused across commands.
//!
//! Opening a connection to the TV's old sshd is the slow part of any
//! action (a second of key exchange and login); the calls over it take
//! milliseconds. So a connection is kept after the action that opened it
//! and handed to the next one, instead of a fresh login every time. The
//! protocol [`Session`] stays a dumb single connection that knows nothing
//! of this; the reuse and the reconnect live here.
//!
//! A held connection sends keepalives (see the protocol crate), so a TV
//! that goes away is noticed within about a minute: the session reports
//! [`Session::is_closed`], and the next request reconnects. The frontend
//! never waits on a dead one hanging.

use std::collections::HashMap;
use std::sync::Arc;

use aphanes_protocol::ssh::Session;
use tokio::sync::Mutex;

use crate::store::{Connection, DeviceStore};

/// The live connections, one per device id, opened on demand and kept.
#[derive(Default)]
pub struct SessionPool {
    sessions: Mutex<HashMap<String, Arc<Session>>>,
}

impl SessionPool {
    /// The connection for a device, reused if one is held and still open,
    /// or freshly connected otherwise. The returned handle is shared: two
    /// commands on the same TV run over the one connection, each on its
    /// own channel.
    pub async fn get(&self, store: &DeviceStore, id: &str) -> Result<Arc<Session>, String> {
        {
            let held = self.sessions.lock().await;
            if let Some(session) = held.get(id) {
                if !session.is_closed() {
                    return Ok(Arc::clone(session));
                }
            }
        }
        // Connect without the lock held, so a slow login to one TV does
        // not stall commands to another. A concurrent request may connect
        // too; the later insert wins and the other connection closes when
        // its last user drops it.
        let Connection {
            host,
            port,
            username,
            private_key_pem,
        } = store.connection(id).map_err(|e| e.to_string())?;
        let session = Arc::new(
            Session::connect(&host, port, &username, &private_key_pem)
                .await
                .map_err(|e| e.to_string())?,
        );
        self.sessions
            .lock()
            .await
            .insert(id.to_string(), Arc::clone(&session));
        Ok(session)
    }

    /// Drops the held connection for a device, if any. Called when the
    /// device is removed or its address changed, so the next request
    /// connects afresh rather than reusing a connection to the old
    /// address. The connection closes once its last in-flight user drops
    /// it; a dropped [`Session`] disconnects itself.
    pub async fn invalidate(&self, id: &str) {
        self.sessions.lock().await.remove(id);
    }
}
