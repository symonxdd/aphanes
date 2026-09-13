/**
 * Frontend-side shapes, named after the mobile app's models so the two
 * codebases read alike. They will be filled from aphanes-protocol through
 * Tauri commands; for now the shell renders placeholder values.
 */
export interface Device {
  id: string;
  name: string;
  host: string;
  username: string;
  pairedAt: string;
  reachable: boolean;
}

export interface DeviceInfo {
  modelName: string;
  firmwareVersion: string;
  webosVersion: string;
  socName: string;
  otaId: string;
}

export interface DevModeStatus {
  /** As the TV reports it, e.g. "999:52:55". */
  remaining: string;
}

export interface InstalledApp {
  id: string;
  title: string;
  version: string;
  vendor: string | null;
}

export interface CatalogPackage {
  id: string;
  title: string;
  shortDescription: string;
  favorite: boolean;
  installed: boolean;
}
