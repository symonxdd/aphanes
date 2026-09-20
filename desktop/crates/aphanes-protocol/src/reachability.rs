//! Whether a paired TV currently answers on its SSH port: not a handshake,
//! just a TCP connect with a short timeout, as the mobile app's
//! `device_reachability_controller.dart` does. Enough to tell "TV off or
//! wrong network" apart from "TV is there but something else is wrong",
//! without the cost of a real connection. Checked when a screen asks,
//! never on a timer.

use std::time::Duration;

use tokio::net::TcpStream;

pub async fn is_reachable(host: &str, port: u16) -> bool {
    matches!(
        tokio::time::timeout(Duration::from_secs(3), TcpStream::connect((host, port))).await,
        Ok(Ok(_))
    )
}
