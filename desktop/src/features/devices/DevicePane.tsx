import { useState } from "react";
import { Info, LayoutGrid, Plus, Search, Tv, Upload } from "lucide-react";
import { Button } from "../../components/Button";
import { Tabs, type TabItem } from "../../components/Tabs";
import type { Device, DeviceInfo, DevModeStatus, InstalledApp } from "../../data/models";
import { InstalledApps } from "../apps/InstalledApps";
import { DeviceDetails } from "./DeviceDetails";
import { reachabilityLabel } from "./Sidebar";
import styles from "./DevicePane.module.css";

type TabId = "apps" | "details";

const tabs: readonly TabItem<TabId>[] = [
  { id: "apps", label: "Installed apps", icon: <LayoutGrid size={18} /> },
  { id: "details", label: "Device details", icon: <Info size={18} /> },
];

interface DevicePaneProps {
  /** False until the device list has loaded, so no empty state flashes. */
  ready: boolean;
  device: Device | null;
  reachable: boolean | undefined;
  info: DeviceInfo;
  devMode: DevModeStatus;
  apps: InstalledApp[];
  onPair: () => void;
  onBrowseCatalog: () => void;
  onInstallIpk: () => void;
  onUninstall: (app: InstalledApp) => void;
  onRemoveDevice: (device: Device) => void;
}

/** The main area: the selected TV's name and state, then its two tabs. */
export function DevicePane({
  ready,
  device,
  reachable,
  info,
  devMode,
  apps,
  onPair,
  onBrowseCatalog,
  onInstallIpk,
  onUninstall,
  onRemoveDevice,
}: DevicePaneProps) {
  const [tab, setTab] = useState<TabId>("apps");

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

  return (
    <main className={styles.pane}>
      <div className={styles.header}>
        <div className={styles.heading}>
          <h1 className={styles.name}>{device.name}</h1>
          <div className={[styles.status, reachable === true && styles.statusReachable].filter(Boolean).join(" ")}>
            <span className={styles.dot} />
            <span>{reachabilityLabel(reachable)}</span>
            <span className={styles.host}>&middot; {device.host}</span>
          </div>
        </div>
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
          {tab === "apps" ? (
            <InstalledApps apps={apps} onUninstall={onUninstall} />
          ) : (
            <DeviceDetails device={device} info={info} devMode={devMode} onRemove={() => onRemoveDevice(device)} />
          )}
        </div>
      </div>
    </main>
  );
}
