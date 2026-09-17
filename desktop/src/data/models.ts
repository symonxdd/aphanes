/**
 * Frontend-side shapes, named after the mobile app's models so the two
 * codebases read alike. All of them come from aphanes-protocol through
 * Tauri commands.
 */
/** Mirrors DeviceRecord in src-tauri/src/store.rs; the key stays in Rust. */
export interface Device {
  id: string;
  name: string;
  host: string;
  port: number;
  username: string;
  /** Milliseconds since the Unix epoch. */
  pairedAt: number;
  /** What the TV reported last time, kept so the details tab renders at once. */
  info?: DeviceInfo | null;
}

/**
 * Mirrors DeviceInfo in the protocol crate's devmode.rs. A null field is
 * one the TV did not report; its row is left out rather than shown blank.
 */
export interface DeviceInfo {
  modelName: string | null;
  firmwareVersion: string | null;
  webosVersion: string | null;
  socName: string | null;
  otaId: string | null;
}

/** Mirrors DevModeStatus in devmode.rs. The token itself never gets here. */
export interface DevModeStatus {
  hasSession: boolean;
  /** Exactly as LG's endpoint reports it, e.g. "999:52:55", or null when unknown. */
  remaining: string | null;
}

export interface DeviceDetail {
  info: DeviceInfo;
  devMode: DevModeStatus;
}

export interface InstalledApp {
  id: string;
  title: string;
  version: string;
  vendor: string | null;
}

/** Mirrors CatalogPackage in the protocol crate's catalog.rs. */
export interface CatalogPackage {
  id: string;
  title: string;
  iconUri: string | null;
  shortDescription: string;
  featured: boolean;
  openSource: boolean;
  minWebosRelease: string | null;
  /** The package's README as an HTML fragment, absolute; fetched only when its page opens. */
  fullDescriptionUrl: string | null;
  manifest: CatalogManifest;
}

export interface CatalogManifest {
  version: string;
  appDescription: string;
  sourceUrl: string | null;
  ipkUrl: string;
  /** Null for the few entries that publish no hash; those install unchecked, after a heads-up. */
  ipkSha256: string | null;
  ipkSize: number;
  installedSize: number | null;
  rootRequired: boolean;
}

/** Mirrors OperationProgress in apps.rs: one step of an install or uninstall. */
export type OperationProgress =
  | { kind: "uploading"; sent: number; total: number }
  | { kind: "verifying" }
  | { kind: "working"; message: string }
  | { kind: "succeeded"; packageId: string };
