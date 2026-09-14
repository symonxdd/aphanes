import { useState } from "react";
import { Info, LayoutGrid, Search, Tv, Upload } from "lucide-react";
import { Button } from "../../components/Button";
import { Tabs, type TabItem } from "../../components/Tabs";
import type { Device, DeviceInfo, DevModeStatus, InstalledApp } from "../../data/models";
import { InstalledApps } from "../apps/InstalledApps";
import { DeviceDetails } from "./DeviceDetails";
import styles from "./DevicePane.module.css";

type TabId = "apps" | "details";

const tabs: readonly TabItem<TabId>[] = [
  { id: "apps", label: "Installed apps", icon: <LayoutGrid size={18} /> },
  { id: "details", label: "Device details", icon: <Info size={18} /> },
];

interface DevicePaneProps {
  device: Device | null;
  info: DeviceInfo;
  devMode: DevModeStatus;
  apps: InstalledApp[];
  onBrowseCatalog: () => void;
  onInstallIpk: () => void;
  onUninstall: (app: InstalledApp) => void;
  onRemoveDevice: (device: Device) => void;
}

/** The main area: the selected TV's name and state, then its two tabs. */
export function DevicePane({
  device,
  info,
  devMode,
  apps,
  onBrowseCatalog,
  onInstallIpk,
  onUninstall,
  onRemoveDevice,
}: DevicePaneProps) {
  const [tab, setTab] = useState<TabId>("apps");

  if (!device) {
    return (
      <main className={styles.pane}>
        <div className={styles.empty}>
          <Tv size={48} />
          <div className={styles.emptyTitle}>No TV selected</div>
          <p>Pick a paired TV in the sidebar, or pair one.</p>
        </div>
      </main>
    );
  }

  return (
    <main className={styles.pane}>
      <div className={styles.header}>
        <div className={styles.heading}>
          <h1 className={styles.name}>{device.name}</h1>
          <div className={[styles.status, device.reachable && styles.statusReachable].filter(Boolean).join(" ")}>
            <span className={styles.dot} />
            <span>{device.reachable ? "TV is reachable" : "TV is off or unreachable"}</span>
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
