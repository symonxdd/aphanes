import { Channel, invoke } from "@tauri-apps/api/core";
import { open as openFileDialog } from "@tauri-apps/plugin-dialog";
import { openUrl } from "@tauri-apps/plugin-opener";
import type { CatalogPackage, Device, DeviceDetail, InstalledApp, OperationProgress } from "../data/models";

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

/** Saves a new address for a paired TV; the pairing key stays as it is. */
export function updateDeviceHost(id: string, host: string): Promise<Device> {
  return invoke<Device>("update_device_host", { id, host });
}

/** The pairing key, only ever asked for by the reveal on the details page. */
export function devicePrivateKey(id: string): Promise<string> {
  return invoke<string>("device_private_key", { id });
}

/** The passphrase that unlocked the key at pairing time, for the same reveal. */
export function devicePassphrase(id: string): Promise<string> {
  return invoke<string>("device_passphrase", { id });
}

/**
 * What the TV reports about itself and its Developer Mode session, over
 * one SSH connection opened for this call. The one command that also
 * reaches developer.lge.com, for the session's remaining time.
 */
export function fetchDeviceDetail(id: string): Promise<DeviceDetail> {
  return invoke<DeviceDetail>("fetch_device_detail", { id });
}

/** The visible apps installed on the TV, over a connection of its own. */
export function listInstalledApps(id: string): Promise<InstalledApp[]> {
  return invoke<InstalledApp[]>("list_installed_apps", { id });
}

/** Opens the TV's Developer Mode app to extend the session. Only from the Renew button. */
export function renewDevMode(id: string): Promise<void> {
  return invoke<void>("renew_dev_mode", { id });
}

/** The public Homebrew catalog listing, fetched when the catalog opens. */
export function fetchCatalog(): Promise<CatalogPackage[]> {
  return invoke<CatalogPackage[]>("fetch_catalog");
}

/** One app's README fragment from the catalog, when its page opens. */
export function fetchAppDescription(url: string): Promise<string> {
  return invoke<string>("fetch_app_description", { url });
}

/** The ids of the apps running on the TV, read when an app's page opens. */
export function listRunningApps(id: string): Promise<string[]> {
  return invoke<string[]>("list_running_apps", { id });
}

/** Opens an app on the TV's screen. Only from the Launch button. */
export function launchApp(id: string, appId: string): Promise<void> {
  return invoke<void>("launch_app", { id, appId });
}

/** Called once per step while an install or uninstall runs. */
export type ProgressListener = (progress: OperationProgress) => void;

function progressChannel(onProgress: ProgressListener): Channel<OperationProgress> {
  const channel = new Channel<OperationProgress>();
  channel.onmessage = onProgress;
  return channel;
}

/** Uninstalls an app. Only ever called after the confirmation dialog. */
export function removeApp(id: string, packageId: string, onProgress: ProgressListener): Promise<void> {
  return invoke<void>("remove_app", { id, packageId, onProgress: progressChannel(onProgress) });
}

/** Downloads, verifies and installs a catalog package. Only from its Install button. */
export function installFromCatalog(
  id: string,
  ipkUrl: string,
  ipkSha256: string | null,
  onProgress: ProgressListener,
): Promise<void> {
  return invoke<void>("install_from_catalog", { id, ipkUrl, ipkSha256, onProgress: progressChannel(onProgress) });
}

/** Installs a .ipk from this computer's disk, chosen through [pickIpkFile]. */
export function installFromFile(id: string, path: string, onProgress: ProgressListener): Promise<void> {
  return invoke<void>("install_from_file", { id, path, onProgress: progressChannel(onProgress) });
}

/** The native file picker, limited to .ipk files. Null when dismissed. */
export async function pickIpkFile(): Promise<string | null> {
  const picked = await openFileDialog({
    multiple: false,
    directory: false,
    title: "Choose a webOS package",
    filters: [{ name: "webOS package", extensions: ["ipk"] }],
  });
  return typeof picked === "string" ? picked : null;
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
