//! Everything the desktop app says to a webOS TV, and nothing about how it
//! is shown.
//!
//! This crate is pure Rust: no Tauri types, no window handles, no frontend
//! events. The Tauri shell in `src-tauri` calls into it and returns; that
//! boundary is what would let the same code be bound into the mobile app
//! later, if a shared core is ever wanted. It is not wanted now.
//!
//! The network side mirrors the mobile app's `lib/core/ssh/` layer file for
//! file, and the protocol details are read from webosbrew's ares-cli-rs
//! (Apache-2.0, `common/connection/src/setup.rs` for the devmode key
//! exchange, `common/connection/src/luna/luna.rs` for the luna bus calls).
//! ares-cli-rs is a reference to read, never a dependency to link.
//!
//! Modules, built and planned:
//!
//! - [`pairing`]: the devmode key exchange against the TV's key server on
//!   port 9991, and the SSH key it yields. Built.
//! - [`reachability`]: a TCP connect to the SSH port, to show whether a
//!   TV is there at all. Built.
//! - [`ssh`]: one authenticated connection per user-triggered action to
//!   the TV's sshd on port 9922, offering the legacy `ssh-rsa` (SHA-1)
//!   signature the TV needs alongside the modern one. Built.
//! - [`luna`]: `luna-send-pub` calls over an open connection, one-shot
//!   and subscribed. Built.
//! - [`apps`]: list, install and remove homebrew apps and IPKs. Built.
//! - [`catalog`]: the public Homebrew catalog listing and verified
//!   package downloads. Built.
//! - [`devmode`]: device info and the Developer Mode session's remaining
//!   time. Built.
//!
//! What this crate must never do, in the words of the project's own
//! constraints: modify a TV except as the direct result of a user action,
//! store or log a credential, or send anything anywhere but the paired TV
//! and the few named hosts the app is allowed to reach.

pub mod apps;
pub mod catalog;
pub mod devmode;
mod error;
mod http;
pub mod luna;
pub mod pairing;
pub mod reachability;
pub mod ssh;

pub use error::Error;

/// Alias used throughout the crate for fallible protocol operations.
pub type Result<T> = std::result::Result<T, Error>;
