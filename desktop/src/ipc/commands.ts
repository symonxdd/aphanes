import { invoke } from "@tauri-apps/api/core";

/**
 * Typed wrappers around the Tauri commands in src-tauri/src/commands.rs.
 * The only place `invoke` is called, so every command's name and shape
 * lives in one file on each side of the bridge.
 */
export function appVersion(): Promise<string> {
  return invoke<string>("app_version");
}
