import { useState } from "react";
import { Info, LayoutGrid, Pencil, Plus, RefreshCw, Search, Tv, Upload } from "lucide-react";
import { Button } from "../../components/Button";
import { IconButton } from "../../components/IconButton";
import { Tabs, type TabItem } from "../../components/Tabs";
import type { Device, DeviceDetail, InstalledApp } from "../../data/models";
import { InstalledApps } from "../apps/InstalledApps";
import { DeviceDetails } from "./DeviceDetails";
import { reachabilityLabel } from "./Sidebar";
import type { Remote } from "./useDeviceData";
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
  detail: Remote<DeviceDetail>;
  apps: Remote<InstalledApp[]>;
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

/** The main area: the selected TV's name and state, then its two tabs. */
export function DevicePane({
  ready,
  device,
  reachable,
  detail,
  apps,
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
          {tab === "apps" ? (
            <InstalledApps
              device={device}
              apps={apps}
              reachable={reachable}
              onOpen={onOpenApp}
              onUninstall={onUninstall}
            />
          ) : (
            <DeviceDetails
              device={device}
              detail={detail}
              reachable={reachable}
              onEditHost={() => onEditHost(device)}
              onRemove={() => onRemoveDevice(device)}
            />
          )}
        </div>
      </div>
    </main>
  );
}
