import { useState } from "react";
import { ConfirmDialog, type ConfirmRequest } from "./components/ConfirmDialog";
import type { CatalogPackage, Device, InstalledApp } from "./data/models";
import {
  placeholderApps,
  placeholderCatalog,
  placeholderDevices,
  placeholderDevMode,
  placeholderInfo,
} from "./data/placeholder";
import { CatalogDialog } from "./features/apps/CatalogDialog";
import { CatalogExplainerDialog } from "./features/apps/CatalogExplainerDialog";
import { DevicePane } from "./features/devices/DevicePane";
import { Sidebar } from "./features/devices/Sidebar";
import { Onboarding } from "./features/onboarding/Onboarding";
import { readOnboardingDone, writeOnboardingDone } from "./features/onboarding/onboardingState";
import { AboutDialog } from "./features/settings/AboutDialog";
import { SettingsDialog } from "./features/settings/SettingsDialog";
import styles from "./App.module.css";

type Overlay = "catalog" | "catalogExplainer" | "settings" | "about" | null;

/**
 * Root of the desktop UI: the intro on first run, then the sidebar, the
 * selected TV's pane, and the dialogs that open over them. Data is
 * placeholder until the protocol crate is wired in; the destructive
 * actions already go through the confirmation every one of them must have.
 */
export default function App() {
  const [introOpen, setIntroOpen] = useState(() => !readOnboardingDone());
  const devices = placeholderDevices;
  const [selectedId, setSelectedId] = useState<string | null>(devices[0]?.id ?? null);
  const [overlay, setOverlay] = useState<Overlay>(null);
  const [confirm, setConfirm] = useState<ConfirmRequest | null>(null);

  const selected = devices.find((device) => device.id === selectedId) ?? null;

  if (introOpen) {
    return (
      <Onboarding
        onDone={() => {
          writeOnboardingDone();
          setIntroOpen(false);
        }}
      />
    );
  }

  const askUninstall = (app: InstalledApp) =>
    setConfirm({
      title: `Uninstall "${app.title}"?`,
      message: "This removes the app and its data from the TV. This can't be undone.",
      confirmLabel: "Uninstall",
      onConfirm: () => {},
    });

  const askRemoveDevice = (device: Device) =>
    setConfirm({
      title: `Remove "${device.name}"?`,
      message: "Reconnecting later will need pairing again from the TV's Developer Mode app.",
      confirmLabel: "Remove device",
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

      <CatalogDialog
        open={overlay === "catalog"}
        packages={placeholderCatalog}
        onClose={() => setOverlay(null)}
        onInstall={install}
        onExplain={() => setOverlay("catalogExplainer")}
      />
      <CatalogExplainerDialog open={overlay === "catalogExplainer"} onClose={() => setOverlay("catalog")} />
      <SettingsDialog
        open={overlay === "settings"}
        onClose={() => setOverlay(null)}
        onAbout={() => setOverlay("about")}
        onShowIntro={() => {
          setOverlay(null);
          setIntroOpen(true);
        }}
      />
      <AboutDialog open={overlay === "about"} onClose={() => setOverlay("settings")} />
      <ConfirmDialog request={confirm} onClose={() => setConfirm(null)} />
    </div>
  );
}
