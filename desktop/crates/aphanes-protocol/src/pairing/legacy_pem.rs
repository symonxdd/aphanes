//! Decrypts the "traditional" OpenSSL encrypted PEM format webOS's devmode
//! key server actually returns: a `RSA PRIVATE KEY` block carrying
//! `Proc-Type: 4,ENCRYPTED` and `DEK-Info: <cipher>,<hex iv>` header lines,
//! confirmed by querying a real TV's key server directly (`GET /webos_rsa`
//! on port 9991). This predates PKCS#8 and PBES2 entirely: the key is
//! derived from the passphrase with OpenSSL's classic EVP_BytesToKey
//! (iterated MD5), salted with the first 8 bytes of the IV given in
//! DEK-Info, rather than PBKDF2 with its own salt and iteration count.
//!
//! Neither webosbrew/ares-cli-rs nor dev-manager-desktop implement this
//! decryption themselves; they hand the raw response to libssh, which
//! supports the legacy format natively. russh's own reader covers only the
//! AES-128 case, so this reimplements OpenSSL's documented algorithm
//! directly, as the mobile app's `legacy_pem_decryptor.dart` does, and
//! hands russh a plain PKCS#1 key afterwards.

use aes::cipher::{block_padding::Pkcs7, BlockModeDecrypt, KeyIvInit};
use data_encoding::{BASE64, BASE64_MIME, HEXUPPER_PERMISSIVE};

use crate::{Error, Result};

const BEGIN: &str = "-----BEGIN RSA PRIVATE KEY-----";
const END: &str = "-----END RSA PRIVATE KEY-----";

const NOT_A_KEY: &str = "That didn't look like a pairing key. Make sure Developer Mode \
    and Key Server are both currently on, then try again.";
const WRONG_PASSPHRASE: &str = "Passphrase is incorrect, or the key is corrupted.";

/// Decrypts an encrypted traditional PEM into an unencrypted PKCS#1 PEM.
pub fn decrypt_to_pkcs1_pem(encrypted_pem: &str, passphrase: &str) -> Result<String> {
    let block = split_headers_and_body(encrypted_pem)?;
    let dek_info = block.dek_info.ok_or_else(|| Error::message(NOT_A_KEY))?;
    let (cipher_name, iv_hex) = dek_info
        .split_once(',')
        .ok_or_else(|| Error::message(NOT_A_KEY))?;
    let cipher = Cipher::by_name(cipher_name.trim())?;
    let iv = HEXUPPER_PERMISSIVE
        .decode(iv_hex.trim().as_bytes())
        .map_err(|_| Error::message(NOT_A_KEY))?;
    if iv.len() != cipher.iv_len() {
        return Err(Error::message(NOT_A_KEY));
    }

    // OpenSSL's classic PEM encryption always salts EVP_BytesToKey with
    // just the first 8 bytes of the IV, no separate salt field, regardless
    // of how long the IV itself is for the chosen cipher.
    let key = evp_bytes_to_key(passphrase.as_bytes(), &iv[..8], cipher.key_len());

    let ciphertext = BASE64_MIME
        .decode(block.body.as_bytes())
        .map_err(|_| Error::message(NOT_A_KEY))?;

    let der = cipher
        .decrypt(&key, &iv, ciphertext)
        .map_err(|_| Error::message(WRONG_PASSPHRASE))?;

    // A wrong passphrase can still produce bytes that happen to satisfy
    // PKCS#7 padding; parsing as an RSA key catches that case too rather
    // than handing back garbage as a "valid" key.
    let pem = der_to_pem(&der);
    russh::keys::decode_secret_key(&pem, None).map_err(|_| Error::message(WRONG_PASSPHRASE))?;
    Ok(pem)
}

/// OpenSSL's EVP_BytesToKey with MD5, one iteration: D_i = MD5(D_{i-1} ||
/// passphrase || salt), concatenated until `key_len` bytes are available.
fn evp_bytes_to_key(passphrase: &[u8], salt: &[u8], key_len: usize) -> Vec<u8> {
    let mut derived = Vec::with_capacity(key_len + 16);
    let mut previous: Vec<u8> = Vec::new();
    while derived.len() < key_len {
        let mut context = md5::Context::new();
        context.consume(&previous);
        context.consume(passphrase);
        context.consume(salt);
        let digest = context.finalize();
        derived.extend_from_slice(&digest.0);
        previous = digest.0.to_vec();
    }
    derived.truncate(key_len);
    derived
}

#[derive(Clone, Copy)]
/// The DEK-Info ciphers OpenSSL uses for this format, all in CBC mode.
enum Cipher {
    Aes128,
    Aes192,
    Aes256,
    DesEde3,
}

impl Cipher {
    fn by_name(name: &str) -> Result<Self> {
        match name.to_ascii_uppercase().as_str() {
            "AES-128-CBC" => Ok(Self::Aes128),
            "AES-192-CBC" => Ok(Self::Aes192),
            "AES-256-CBC" => Ok(Self::Aes256),
            "DES-EDE3-CBC" => Ok(Self::DesEde3),
            _ => Err(Error::message("Unsupported private key encryption cipher.")),
        }
    }

    fn key_len(self) -> usize {
        match self {
            Self::Aes128 => 16,
            Self::Aes192 | Self::DesEde3 => 24,
            Self::Aes256 => 32,
        }
    }

    fn iv_len(self) -> usize {
        match self {
            Self::DesEde3 => 8,
            _ => 16,
        }
    }

    /// CBC with PKCS#7 padding. Any failure (bad key length, bad padding)
    /// is reported the same way: the passphrase did not fit.
    fn decrypt(self, key: &[u8], iv: &[u8], mut data: Vec<u8>) -> std::result::Result<Vec<u8>, ()> {
        let plain_len = match self {
            Self::Aes128 => cbc::Decryptor::<aes::Aes128>::new_from_slices(key, iv)
                .map_err(|_| ())?
                .decrypt_padded::<Pkcs7>(&mut data)
                .map_err(|_| ())?
                .len(),
            Self::Aes192 => cbc::Decryptor::<aes::Aes192>::new_from_slices(key, iv)
                .map_err(|_| ())?
                .decrypt_padded::<Pkcs7>(&mut data)
                .map_err(|_| ())?
                .len(),
            Self::Aes256 => cbc::Decryptor::<aes::Aes256>::new_from_slices(key, iv)
                .map_err(|_| ())?
                .decrypt_padded::<Pkcs7>(&mut data)
                .map_err(|_| ())?
                .len(),
            Self::DesEde3 => cbc::Decryptor::<des::TdesEde3>::new_from_slices(key, iv)
                .map_err(|_| ())?
                .decrypt_padded::<Pkcs7>(&mut data)
                .map_err(|_| ())?
                .len(),
        };
        data.truncate(plain_len);
        Ok(data)
    }
}

struct PemBlock {
    dek_info: Option<String>,
    body: String,
}

/// Splits the text between the BEGIN and END lines into the `Name: value`
/// header lines and the base64 body that follows them.
fn split_headers_and_body(pem: &str) -> Result<PemBlock> {
    let start = pem.find(BEGIN).ok_or_else(|| Error::message(NOT_A_KEY))?;
    let stop = pem.find(END).ok_or_else(|| Error::message(NOT_A_KEY))?;
    if stop < start {
        return Err(Error::message(NOT_A_KEY));
    }
    let inner = &pem[start + BEGIN.len()..stop];

    let mut dek_info = None;
    let mut body = String::new();
    let mut in_headers = true;
    for line in inner.lines().map(str::trim).filter(|line| !line.is_empty()) {
        if in_headers {
            if let Some((name, value)) = line.split_once(':') {
                if name.trim() == "DEK-Info" {
                    dek_info = Some(value.trim().to_string());
                }
                continue;
            }
            in_headers = false;
        }
        body.push_str(line);
    }
    Ok(PemBlock { dek_info, body })
}

fn der_to_pem(der: &[u8]) -> String {
    // Plain BASE64, not the MIME variant: that one inserts its own line
    // breaks, and the 64-column wrapping below is the PEM convention.
    let body = BASE64.encode(der);
    let mut pem = String::with_capacity(body.len() + 64);
    pem.push_str(BEGIN);
    pem.push('\n');
    for chunk in body.as_bytes().chunks(64) {
        pem.push_str(&String::from_utf8_lossy(chunk));
        pem.push('\n');
    }
    pem.push_str(END);
    pem.push('\n');
    pem
}
