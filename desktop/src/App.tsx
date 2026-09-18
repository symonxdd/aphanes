import { useEffect, useState } from "react";
import { ConfirmDialog, type ConfirmRequest } from "./components/ConfirmDialog";
import { FullscreenLayer } from "./components/FullscreenLayer";
import type { CatalogPackage, Device, InstalledApp } from "./data/models";
import { AppDialog, type AppSubject } from "./features/apps/AppDialog";
import { PackageIcon } from "./features/apps/PackageIcon";
import { CatalogDialog } from "./features/apps/CatalogDialog";
import { CatalogExplainerDialog } from "./features/apps/CatalogExplainerDialog";
import { OperationDialog } from "./features/apps/OperationDialog";
import { useAppOperation } from "./features/apps/useAppOperation";
import { useCatalog } from "./features/apps/useCatalog";
import { DevicePane } from "./features/devices/DevicePane";
import { DevmodeSetupDialog } from "./features/devices/DevmodeSetupDialog";
import { EditHostDialog } from "./features/devices/EditHostDialog";
import { PairDialog } from "./features/devices/PairDialog";
import { PairingWalkthroughDialog } from "./features/devices/PairingWalkthroughDialog";
import { Sidebar } from "./features/devices/Sidebar";
import { useDeviceData } from "./features/devices/useDeviceData";
import { useDevices } from "./features/devices/useDevices";
import { useFocusRecheck } from "./features/devices/useFocusRecheck";
import { Onboarding } from "./features/onboarding/Onboarding";
import { readOnboardingDone, writeOnboardingDone } from "./features/onboarding/onboardingState";
import { installFromCatalog, installFromFile, pickIpkFile, removeApp } from "./ipc/commands";
import { AboutDialog } from "./features/settings/AboutDialog";
import { SettingsDialog } from "./features/settings/SettingsDialog";
import { VersionExplainerDialog } from "./features/settings/VersionExplainerDialog";
import styles from "./App.module.css";

type Overlay =
  "pair" | "pairHelp" | "editHost" | "app" | "catalog" | "catalogExplainer" | "settings" | "about" | "version" | null;

/**
 * Root of the desktop UI: the intro on first run, then the sidebar, the
 * selected TV's pane, and the dialogs that open over them. Every
 * destructive action goes through the confirmation dialog, and every
 * change to a TV starts from a click here.
 */
/** The host a package downloads from, for saying so before an unchecked download. */
function downloadHost(url: string): string {
  try {
    return new URL(url).host;
  } catch {
    return url;
  }
}

export default function App() {
  const [introOpen, setIntroOpen] = useState(() => !readOnboardingDone());
  // A replay from settings shows the intro above the still-open settings
  // dialog, as mobile pushes it over the sheet, and lands back on it.
  const [introReplay, setIntroReplay] = useState(false);
  const { devices, loaded, reachability, refresh, check, remove, updateHost } = useDevices();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [overlay, setOverlay] = useState<Overlay>(null);
  // Its own flag, not an Overlay value: it stacks on top of the pairing
  // dialog, which must stay open so nothing typed there is lost.
  const [setupStepsOpen, setSetupStepsOpen] = useState(false);
  const [confirm, setConfirm] = useState<ConfirmRequest | null>(null);
  // The app page's subject and where it was opened from, which is where
  // closing it returns to.
  const [page, setPage] = useState<{ subject: AppSubject; from: "installed" | "catalog" } | null>(null);
  const [version, setVersion] = useState<string | null>(null);

  // Keep a valid selection: the first TV once loaded, or whatever is left
  // after one is removed.
  const selected = devices.find((device) => device.id === selectedId) ?? devices[0] ?? null;
  const selectedReachable = selected ? reachability[selected.id] : undefined;
  useEffect(() => {
    if (selected && selected.id !== selectedId) {
      setSelectedId(selected.id);
    }
  }, [selected, selectedId]);

  // What the TV reports, fetched once it is known to answer.
  const data = useDeviceData(selected, selectedReachable);
  // Coming back to the window after a while asks the TV again: the
  // reachability probe for the dot, then the app list with its running
  // flags if the TV answers. The TV only; the details, whose session
  // check goes out to developer.lge.com, wait for a Refresh.
  // Coming back to the window asks the TV again over the held connection:
  // the reachability probe for the dot, then the app list with its
  // running flags if the TV answers. The details, whose session check
  // reaches developer.lge.com, wait for a Refresh.
  useFocusRecheck(() => {
    if (!selected) {
      return;
    }
    void check(selected).then((reachable) => {
      if (reachable) {
        data.refreshApps();
      }
    });
  });

  const refreshSelected = async () => {
    if (selected && (await check(selected))) {
      data.refresh();
    }
  };

  // Reachability is checked when a TV comes into view, never on a timer.
  useEffect(() => {
    if (selected && selectedReachable === undefined) {
      void check(selected);
    }
  }, [selected, selectedReachable, check]);

  // One install or uninstall at a time, shown in its own dialog over
  // whatever is open; the app list is refetched once it succeeds.
  const operation = useAppOperation(data.refreshApps);
  // The catalog also serves an app's page, for the entry matching the app.
  const catalog = useCatalog(overlay === "catalog" || overlay === "app");
  const installedIds = new Set((data.apps.data ?? []).map((app) => app.id));

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

  const openInstalledApp = (app: InstalledApp) => {
    // The catalog entry is looked up when the page renders, since the
    // catalog may still be loading at this point.
    setPage({ subject: { app, pkg: null }, from: "installed" });
    setOverlay("app");
  };

  const openCatalogApp = (pkg: CatalogPackage) => {
    const app = (data.apps.data ?? []).find((candidate) => candidate.id === pkg.id) ?? null;
    setPage({ subject: { app, pkg }, from: "catalog" });
    setOverlay("app");
  };

  // The page's two halves follow what is known now: the installed half
  // is the list's current entry, so a running flag the list learns
  // reaches the page, and it is dropped once the list no longer has the
  // app (after an uninstall from the page itself), which turns the page
  // into its catalog view; the catalog entry is filled in once the
  // catalog has loaded.
  const openedApp = page?.subject.app ?? null;
  const pageApp = openedApp
    ? data.apps.data
      ? (data.apps.data.find((app) => app.id === openedApp.id) ?? null)
      : openedApp
    : null;
  const pageSubject: AppSubject | null = page && {
    app: pageApp,
    pkg: page.subject.pkg ?? catalog.data?.find((entry) => entry.id === page.subject.app?.id) ?? null,
  };

  // The confirmation stacks over whatever asked, so an app's page stays
  // open behind it. It stays open through the uninstall too, becoming the
  // catalog's view of the app, unless the app is not in the catalog, in
  // which case there is nothing left for a page to show.
  const askUninstall = (app: InstalledApp) => {
    if (!selected) {
      return;
    }
    const device = selected;
    const pageHasCatalogHalf = pageSubject?.pkg !== null;
    const iconUri = catalog.data?.find((entry) => entry.id === app.id)?.iconUri ?? null;
    setConfirm({
      icon: iconUri ? <PackageIcon uri={iconUri} size={28} /> : undefined,
      title: `Uninstall "${app.title}"?`,
      message: "This removes the app and its data from the TV. This can't be undone.",
      confirmLabel: "Uninstall",
      onConfirm: () => {
        if (!pageHasCatalogHalf) {
          setOverlay((current) => (current === "app" ? null : current));
        }
        operation.run(`Uninstalling ${app.title}`, (onProgress) => removeApp(device.id, app.id, onProgress));
      },
    });
  };

  const askRemoveDevice = (device: Device) =>
    setConfirm({
      title: `Remove "${device.name}"?`,
      message: "Reconnecting later will need pairing again from the TV's Developer Mode app.",
      confirmLabel: "Remove device",
      onConfirm: () => void remove(device.id),
    });

  // A package the catalog publishes no checksum for downloads unchecked,
  // so it starts only after saying so, once, in plain terms.
  const install = (pkg: CatalogPackage) => {
    if (!selected) {
      return;
    }
    const device = selected;
    const run = () =>
      operation.run(`Installing ${pkg.title}`, (onProgress) =>
        installFromCatalog(device.id, pkg.manifest.ipkUrl, pkg.manifest.ipkSha256, onProgress),
      );
    if (pkg.manifest.ipkSha256 !== null) {
      run();
      return;
    }
    setConfirm({
      icon: pkg.iconUri ? <PackageIcon uri={pkg.iconUri} size={28} /> : undefined,
      title: `Install "${pkg.title}"?`,
      message:
        "The catalog publishes no checksum for this package, so the download can't be checked before it goes to " +
        `the TV. It comes from ${downloadHost(pkg.manifest.ipkUrl)}.`,
      confirmLabel: "Install",
      tone: "plain",
      onConfirm: run,
    });
  };

  const installIpk = async () => {
    if (!selected) {
      return;
    }
    const device = selected;
    const path = await pickIpkFile();
    if (path) {
      const name = path.split(/[\\/]/).pop() ?? path;
      operation.run(`Installing ${name}`, (onProgress) => installFromFile(device.id, path, onProgress));
    }
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
        reachable={selectedReachable}
        detail={data.detail}
        apps={data.apps}
        onPair={() => setOverlay("pair")}
        onRefresh={() => void refreshSelected()}
        onBrowseCatalog={() => setOverlay("catalog")}
        onInstallIpk={() => void installIpk()}
        onOpenApp={openInstalledApp}
        onUninstall={askUninstall}
        onEditHost={() => setOverlay("editHost")}
        onRemoveDevice={askRemoveDevice}
      />

      <AppDialog
        open={overlay === "app"}
        deviceId={selected?.id ?? null}
        subject={pageSubject}
        catalog={catalog}
        onClose={() => setOverlay(page?.from === "catalog" ? "catalog" : null)}
        onUninstall={askUninstall}
        onInstall={install}
        onRunning={data.setRunning}
      />
      <EditHostDialog
        open={overlay === "editHost"}
        device={selected}
        otherDevices={devices.filter((device) => device.id !== selected?.id)}
        onClose={() => setOverlay(null)}
        onSave={(host) => (selected ? updateHost(selected.id, host) : Promise.resolve())}
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
        catalog={catalog}
        installedIds={installedIds}
        onClose={() => setOverlay(null)}
        onRefresh={catalog.refresh}
        onInstall={install}
        onOpen={openCatalogApp}
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
      <OperationDialog state={operation.state} onClose={operation.reset} />
    </div>
  );
}
