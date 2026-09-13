import { invoke } from "@tauri-apps/api/core";
import { openUrl } from "@tauri-apps/plugin-opener";

/**
 * Typed wrappers around the Tauri commands in src-tauri/src/commands.rs,
 * plus the one plugin call the frontend makes. The only place `invoke` is
 * called, so every command's name and shape lives in one file on each
 * side of the bridge.
 */
export function appVersion(): Promise<string> {
  return invoke<string>("app_version");
}

/**
 * Hands a link to the system browser. Not a request by the app itself,
 * but outward-facing all the same: only ever called for a link whose
 * destination is visible or obvious before the click.
 */
export function openInBrowser(url: string): Promise<void> {
  return openUrl(url);
}
