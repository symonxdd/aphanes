import { useState } from "react";
import { Folder, Info, LayoutGrid, Pencil, Plus, RefreshCw, Search, SquareTerminal, Tv, Upload } from "lucide-react";
import { Button } from "../../components/Button";
import { IconButton } from "../../components/IconButton";
import { NotPlannedMessage } from "../../components/NotPlannedMessage";
import { Tabs, type TabItem } from "../../components/Tabs";
import type { Device, DeviceDetail, InstalledApp } from "../../data/models";
import { InstalledApps } from "../apps/InstalledApps";
import type { TabVisibility } from "../settings/tabVisibility";
import { DeviceDetails } from "./DeviceDetails";
import { reachabilityLabel } from "./Sidebar";
import type { Remote } from "./useDeviceData";
import styles from "./DevicePane.module.css";

type TabId = "apps" | "details" | "files" | "terminal";

const appsTab: TabItem<TabId> = { id: "apps", label: "Installed apps", icon: <LayoutGrid size={18} /> };
const detailsTab: TabItem<TabId> = { id: "details", label: "Device details", icon: <Info size={18} /> };
/* The two optional tabs, shown only when switched on in settings. Like
   the mobile app's, each holds a placeholder for now. */
const filesTab: TabItem<TabId> = { id: "files", label: "Files", icon: <Folder size={18} /> };
const terminalTab: TabItem<TabId> = { id: "terminal", label: "Terminal", icon: <SquareTerminal size={18} /> };

interface DevicePaneProps {
  /** False until the device list has loaded, so no empty state flashes. */
  ready: boolean;
  device: Device | null;
  reachable: boolean | undefined;
  detail: Remote<DeviceDetail>;
  apps: Remote<InstalledApp[]>;
  /** Which optional tabs are switched on. */
  tabs: TabVisibility;
  onPair: () => void;
  /** Probes the TV again and, if it answers, fetches everything afresh. */
  onRefresh: () => void;
  onBrowseCatalog: () => void;
  onInstallIpk: () => void;
  onOpenApp: (app: InstalledApp) => void;
  onUninstall: (app: InstalledApp) => void;
  onRename: (device: Device) => void;
  onEditHost: (device: Device) => void;
  onRemoveDevice: (device: Device) => void;
}

/** The main area: the selected TV's name and state, then its tabs. */
export function DevicePane({
  ready,
  device,
  reachable,
  detail,
  apps,
  tabs: visibleTabs,
  onPair,
  onRefresh,
  onBrowseCatalog,
  onInstallIpk,
  onOpenApp,
  onUninstall,
  onRename,
  onEditHost,
  onRemoveDevice,
}: DevicePaneProps) {
  const [chosenTab, setTab] = useState<TabId>("apps");
  const tabs: TabItem<TabId>[] = [
    appsTab,
    detailsTab,
    ...(visibleTabs.files ? [filesTab] : []),
    ...(visibleTabs.terminal ? [terminalTab] : []),
  ];
  // An optional tab switched off while open falls back to the first.
  const tab: TabId = tabs.some((item) => item.id === chosenTab) ? chosenTab : "apps";

  if (!ready) {
    return <main className={styles.pane} />;
  }

  if (!device) {
    return (
      <main className={styles.pane}>
        <div className={styles.empty}>
          <Tv size={48} />
          <div className={styles.emptyTitle}>No device paired yet</div>
          <p>Pair a TV on the local network to get started.</p>
          <Button variant="filled" icon={<Plus size={18} />} className={styles.emptyAction} onClick={onPair}>
            Pair a device
          </Button>
        </div>
      </main>
    );
  }

  const refreshing = reachable === undefined || detail.loading || apps.loading;

  return (
    <main className={styles.pane}>
      <div className={styles.header}>
        <div className={styles.heading}>
          <div className={styles.nameRow}>
            <h1 className={styles.name}>{device.name}</h1>
            <IconButton size="small" label="Rename device" tooltip onClick={() => onRename(device)}>
              <Pencil size={16} />
            </IconButton>
          </div>
          <div className={[styles.status, reachable === true && styles.statusReachable].filter(Boolean).join(" ")}>
            <span className={styles.dot} />
            <span>{reachabilityLabel(reachable)}</span>
            <span className={styles.host}>&middot; {device.host}</span>
          </div>
        </div>
        <IconButton
          label="Refresh"
          tooltip
          className={refreshing ? styles.refreshing : undefined}
          disabled={refreshing}
          onClick={onRefresh}
        >
          <RefreshCw size={20} />
        </IconButton>
        <Button variant="outlined" icon={<Upload size={18} />} onClick={onInstallIpk}>
          Install .ipk
        </Button>
        <Button variant="tonal" icon={<Search size={18} />} onClick={onBrowseCatalog}>
          Browse catalog
        </Button>
      </div>

      <Tabs items={tabs} selected={tab} onSelect={setTab} />

      <div className={styles.content}>
        <div key={tab} className={styles.tabContent}>
          {tab === "apps" && (
            <InstalledApps
              device={device}
              apps={apps}
              reachable={reachable}
              onOpen={onOpenApp}
              onUninstall={onUninstall}
            />
          )}
          {tab === "details" && (
            <DeviceDetails
              device={device}
              detail={detail}
              reachable={reachable}
              onEditHost={() => onEditHost(device)}
              onRemove={() => onRemoveDevice(device)}
            />
          )}
          {(tab === "files" || tab === "terminal") && <NotPlannedMessage />}
        </div>
      </div>
    </main>
  );
}
