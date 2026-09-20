use std::fmt;

/// A protocol-layer failure, with a message specific enough to show inline
/// in the UI. The Tauri shell forwards the `Display` text as-is, so every
/// variant's message is written for a person, never a raw wrapped error.
#[derive(Debug, thiserror::Error)]
pub enum Error {
    /// The TV could not be reached on the local network.
    #[error("Couldn't reach that TV. Check it's on the same network.")]
    Unreachable,

    /// The TV was reached but did not answer in time.
    #[error("Connection to the TV timed out.")]
    Timeout,

    /// A failure with its own explanation, already phrased for display.
    #[error("{0}")]
    Message(String),
}

impl Error {
    /// Builds a [`Error::Message`] from anything that displays.
    pub fn message(text: impl fmt::Display) -> Self {
        Self::Message(text.to_string())
    }
}
