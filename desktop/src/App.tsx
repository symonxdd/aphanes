import { useEffect, useState } from "react";
import { ConfirmDialog, type ConfirmRequest } from "./components/ConfirmDialog";
import { FullscreenLayer } from "./components/FullscreenLayer";
import type { CatalogPackage, Device, InstalledApp } from "./data/models";
import { placeholderApps, placeholderCatalog, placeholderDevMode, placeholderInfo } from "./data/placeholder";
import { CatalogDialog } from "./features/apps/CatalogDialog";
import { CatalogExplainerDialog } from "./features/apps/CatalogExplainerDialog";
import { DevicePane } from "./features/devices/DevicePane";
import { DevmodeSetupDialog } from "./features/devices/DevmodeSetupDialog";
import { PairDialog } from "./features/devices/PairDialog";
import { PairingWalkthroughDialog } from "./features/devices/PairingWalkthroughDialog";
import { Sidebar } from "./features/devices/Sidebar";
import { useDevices } from "./features/devices/useDevices";
import { Onboarding } from "./features/onboarding/Onboarding";
import { readOnboardingDone, writeOnboardingDone } from "./features/onboarding/onboardingState";
import { AboutDialog } from "./features/settings/AboutDialog";
import { SettingsDialog } from "./features/settings/SettingsDialog";
import { VersionExplainerDialog } from "./features/settings/VersionExplainerDialog";
import styles from "./App.module.css";

type Overlay = "pair" | "pairHelp" | "catalog" | "catalogExplainer" | "settings" | "about" | "version" | null;

/**
 * Root of the desktop UI: the intro on first run, then the sidebar, the
 * selected TV's pane, and the dialogs that open over them. Devices are
 * real; apps and device info are placeholder until the protocol crate
 * grows. Every destructive action goes through the confirmation dialog.
 */
export default function App() {
  const [introOpen, setIntroOpen] = useState(() => !readOnboardingDone());
  // A replay from settings shows the intro above the still-open settings
  // dialog, as mobile pushes it over the sheet, and lands back on it.
  const [introReplay, setIntroReplay] = useState(false);
  const { devices, loaded, reachability, refresh, check, remove } = useDevices();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [overlay, setOverlay] = useState<Overlay>(null);
  // Its own flag, not an Overlay value: it stacks on top of the pairing
  // dialog, which must stay open so nothing typed there is lost.
  const [setupStepsOpen, setSetupStepsOpen] = useState(false);
  const [confirm, setConfirm] = useState<ConfirmRequest | null>(null);
  const [version, setVersion] = useState<string | null>(null);

  // Keep a valid selection: the first TV once loaded, or whatever is left
  // after one is removed.
  const selected = devices.find((device) => device.id === selectedId) ?? devices[0] ?? null;
  useEffect(() => {
    if (selected && selected.id !== selectedId) {
      setSelectedId(selected.id);
    }
  }, [selected, selectedId]);

  // Reachability is checked when a TV comes into view, never on a timer.
  useEffect(() => {
    if (selected && reachability[selected.id] === undefined) {
      void check(selected);
    }
  }, [selected, reachability, check]);

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
      onConfirm: () => void remove(device.id),
    });

  const install = (_pkg: CatalogPackage) => {
    // Wired to the protocol crate later; installing is always a direct result of this click.
  };

  return (
    <div className={styles.app}>
      <Sidebar
        devices={devices}
        reachability={reachability}
        selectedId={selected?.id ?? null}
        onSelect={setSelectedId}
        onPair={() => setOverlay("pair")}
        onSettings={() => setOverlay("settings")}
      />
      <DevicePane
        ready={loaded}
        device={selected}
        reachable={selected ? reachability[selected.id] : undefined}
        info={placeholderInfo}
        devMode={placeholderDevMode}
        apps={placeholderApps}
        onPair={() => setOverlay("pair")}
        onBrowseCatalog={() => setOverlay("catalog")}
        onInstallIpk={() => {}}
        onUninstall={askUninstall}
        onRemoveDevice={askRemoveDevice}
      />

      <PairDialog
        open={overlay === "pair"}
        pairedHosts={devices.map((device) => device.host)}
        onClose={() => setOverlay(null)}
        onPaired={(device) => {
          void refresh();
          setSelectedId(device.id);
        }}
        onHowItWorks={() => setOverlay("pairHelp")}
        onSetupSteps={() => setSetupStepsOpen(true)}
      />
      <DevmodeSetupDialog open={setupStepsOpen} onClose={() => setSetupStepsOpen(false)} />
      <PairingWalkthroughDialog open={overlay === "pairHelp"} onClose={() => setOverlay("pair")} />
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
        onShowIntro={() => setIntroReplay(true)}
      />
      <FullscreenLayer open={introReplay} onCancel={() => setIntroReplay(false)}>
        <Onboarding onDone={() => setIntroReplay(false)} />
      </FullscreenLayer>
      <AboutDialog
        open={overlay === "about"}
        onClose={() => setOverlay("settings")}
        onExplainVersion={(v) => {
          setVersion(v);
          setOverlay("version");
        }}
      />
      <VersionExplainerDialog open={overlay === "version"} version={version} onClose={() => setOverlay("about")} />
      <ConfirmDialog request={confirm} onClose={() => setConfirm(null)} />
    </div>
  );
}
