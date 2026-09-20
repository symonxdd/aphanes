//! The TV's devmode key server: a tiny HTTP/1.0 server on port 9991 that
//! answers `GET /webos_rsa` with the encrypted private key, and nothing
//! else. Spoken to over a raw TCP socket, as ares-cli-rs's
//! `common/connection/src/setup.rs` and the mobile app both do; an HTTP
//! client library would be more than this server understands.

use std::time::Duration;

use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;

use crate::{Error, Result};

/// The port the key server listens on while enabled in the Developer Mode app.
pub const KEY_SERVER_PORT: u16 = 9991;

const REQUEST: &[u8] = b"GET /webos_rsa HTTP/1.0\r\nConnection: close\r\n\r\n";

/// Whether something answering like the key server is listening at `host`.
/// Short timeouts on purpose: this runs as a person types an address, so
/// it is only ever advisory and must never hold anything up.
pub async fn probe(host: &str, port: u16) -> bool {
    match request(host, port, Duration::from_secs(1), Duration::from_secs(1)).await {
        Ok(response) => status_code_of(&response) == Some(200),
        Err(_) => false,
    }
}

/// Fetches the encrypted PEM the key server serves.
pub async fn fetch_encrypted_key(host: &str, port: u16) -> Result<String> {
    let response = request(host, port, Duration::from_secs(10), Duration::from_secs(10)).await?;
    parse_response(&response)
}

async fn request(
    host: &str,
    port: u16,
    connect_timeout: Duration,
    response_timeout: Duration,
) -> Result<Vec<u8>> {
    let connect = TcpStream::connect((host, port));
    let mut stream = match tokio::time::timeout(connect_timeout, connect).await {
        Ok(Ok(stream)) => stream,
        Ok(Err(_)) => {
            return Err(Error::message(
                "Couldn't reach that IP address. Check it's correct and that this computer and the TV are on the \
                 same network.",
            ))
        }
        Err(_) => {
            return Err(Error::message(
                "Connection timed out. Check the IP address and that this computer and the TV are on the same \
                 network.",
            ))
        }
    };

    let exchange = async {
        stream.write_all(REQUEST).await?;
        let mut response = Vec::new();
        stream.read_to_end(&mut response).await?;
        Ok::<Vec<u8>, std::io::Error>(response)
    };
    match tokio::time::timeout(response_timeout, exchange).await {
        Ok(Ok(response)) => Ok(response),
        Ok(Err(_)) | Err(_) => Err(Error::message(
            "The TV stopped responding while fetching the pairing key.",
        )),
    }
}

fn status_code_of(response: &[u8]) -> Option<u16> {
    let raw = String::from_utf8_lossy(response);
    let first_line = raw.split("\r\n").next()?;
    let mut parts = first_line.split(' ');
    let version = parts.next()?;
    if !version.starts_with("HTTP/") {
        return None;
    }
    parts.next()?.parse().ok()
}

fn parse_response(response: &[u8]) -> Result<String> {
    let raw = String::from_utf8_lossy(response);
    let header_end = raw.find("\r\n\r\n").ok_or_else(|| {
        Error::message(
            "The TV sent an unexpected response. Make sure Developer Mode and its key server are turned on.",
        )
    })?;
    if status_code_of(response) != Some(200) {
        return Err(Error::message(
            "No pairing key is available. Make sure Developer Mode is on and the key server is enabled in the \
             Developer Mode app.",
        ));
    }
    Ok(raw[header_end + 4..].to_string())
}

#[cfg(test)]
#[allow(clippy::unwrap_used)]
mod tests {
    use super::*;

    #[test]
    fn reads_the_status_code() {
        assert_eq!(status_code_of(b"HTTP/1.0 200 OK\r\n\r\nbody"), Some(200));
        assert_eq!(status_code_of(b"HTTP/1.1 404 Not Found\r\n"), Some(404));
        assert_eq!(status_code_of(b"garbage"), None);
    }

    #[test]
    fn returns_the_body_after_the_headers() {
        let body = parse_response(b"HTTP/1.0 200 OK\r\nContent-Type: text/plain\r\n\r\n-----BEGIN")
            .unwrap();
        assert_eq!(body, "-----BEGIN");
    }

    #[test]
    fn refuses_a_non_200_response() {
        assert!(parse_response(b"HTTP/1.0 404 Not Found\r\n\r\n").is_err());
        assert!(parse_response(b"no headers here").is_err());
    }
}
