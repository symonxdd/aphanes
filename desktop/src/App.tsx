import { useState } from "react";
import { ConfirmDialog, type ConfirmRequest } from "./components/ConfirmDialog";
import type { CatalogPackage, Device, InstalledApp } from "./data/models";
import { placeholderApps, placeholderCatalog, placeholderDevices, placeholderDevMode, placeholderInfo } from "./data/placeholder";
import { CatalogDialog } from "./features/apps/CatalogDialog";
import { DevicePane } from "./features/devices/DevicePane";
import { Sidebar } from "./features/devices/Sidebar";
import { SettingsDialog } from "./features/settings/SettingsDialog";
import styles from "./App.module.css";

type Overlay = "catalog" | "settings" | null;

/**
 * Root of the desktop UI: the sidebar, the selected TV's pane, and the
 * dialogs that open over them. Data is placeholder until the protocol
 * crate is wired in; the destructive actions already go through the
 * confirmation every one of them must have.
 */
export default function App() {
  const devices = placeholderDevices;
  const [selectedId, setSelectedId] = useState<string | null>(devices[0]?.id ?? null);
  const [overlay, setOverlay] = useState<Overlay>(null);
  const [confirm, setConfirm] = useState<ConfirmRequest | null>(null);

  const selected = devices.find((device) => device.id === selectedId) ?? null;

  const askUninstall = (app: InstalledApp) =>
    setConfirm({
      title: `Uninstall ${app.title}?`,
      message: `${app.title} ${app.version} will be removed from ${selected?.name ?? "the TV"}.`,
      confirmLabel: "Uninstall",
      onConfirm: () => {},
    });

  const askRemoveDevice = (device: Device) =>
    setConfirm({
      title: `Remove ${device.name}?`,
      message: "The pairing and its key are deleted from this computer. The TV itself is not changed.",
      confirmLabel: "Remove",
      onConfirm: () => {},
    });

  const install = (_pkg: CatalogPackage) => {
    // Wired to the protocol crate later; installing is always a direct result of this click.
  };

  return (
    <div className={styles.app}>
      <Sidebar
        devices={devices}
        selectedId={selectedId}
        onSelect={setSelectedId}
        onPair={() => {}}
        onSettings={() => setOverlay("settings")}
      />
      <DevicePane
        device={selected}
        info={placeholderInfo}
        devMode={placeholderDevMode}
        apps={placeholderApps}
        onBrowseCatalog={() => setOverlay("catalog")}
        onInstallIpk={() => {}}
        onUninstall={askUninstall}
        onRemoveDevice={askRemoveDevice}
      />

      <CatalogDialog open={overlay === "catalog"} packages={placeholderCatalog} onClose={() => setOverlay(null)} onInstall={install} />
      <SettingsDialog open={overlay === "settings"} onClose={() => setOverlay(null)} />
      <ConfirmDialog request={confirm} onClose={() => setConfirm(null)} />
    </div>
  );
}
