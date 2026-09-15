import { invoke } from "@tauri-apps/api/core";
import { openUrl } from "@tauri-apps/plugin-opener";
import type { Device } from "../data/models";

/**
 * Typed wrappers around the Tauri commands in src-tauri/src/commands.rs,
 * plus the one plugin call the frontend makes. The only place `invoke` is
 * called, so every command's name and shape lives in one file on each
 * side of the bridge. Errors arrive as display-ready strings.
 */
export function appVersion(): Promise<string> {
  return invoke<string>("app_version");
}

export function listDevices(): Promise<Device[]> {
  return invoke<Device[]>("list_devices");
}

/** Whether the TV answers on its SSH port right now. */
export function checkReachable(host: string, port: number): Promise<boolean> {
  return invoke<boolean>("check_reachable", { host, port });
}

/** Whether a key server answers at the address. Advisory only. */
export function probeKeyServer(host: string): Promise<boolean> {
  return invoke<boolean>("probe_key_server", { host });
}

export function fetchEncryptedKey(host: string): Promise<string> {
  return invoke<string>("fetch_encrypted_key", { host });
}

/** Local only: the passphrase never leaves this computer. */
export function validatePassphrase(encryptedPem: string, passphrase: string): Promise<boolean> {
  return invoke<boolean>("validate_passphrase", { encryptedPem, passphrase });
}

export function pairDevice(
  host: string,
  passphrase: string,
  cachedEncryptedPem: string | null,
  name: string,
): Promise<Device> {
  return invoke<Device>("pair_device", { host, passphrase, cachedEncryptedPem, name });
}

export function renameDevice(id: string, name: string): Promise<Device> {
  return invoke<Device>("rename_device", { id, name });
}

/** The pairing key, only ever asked for by the reveal on the details page. */
export function devicePrivateKey(id: string): Promise<string> {
  return invoke<string>("device_private_key", { id });
}

/** The passphrase that unlocked the key at pairing time, for the same reveal. */
export function devicePassphrase(id: string): Promise<string> {
  return invoke<string>("device_passphrase", { id });
}

export function removeDevice(id: string): Promise<void> {
  return invoke<void>("remove_device", { id });
}

/**
 * Hands a link to the system browser. Not a request by the app itself,
 * but outward-facing all the same: only ever called for a link whose
 * destination is visible or obvious before the click.
 */
export function openInBrowser(url: string): Promise<void> {
  return openUrl(url);
}
