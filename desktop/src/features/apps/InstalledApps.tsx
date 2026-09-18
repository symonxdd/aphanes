import { LayoutGrid, Trash2 } from "lucide-react";
import { IconButton } from "../../components/IconButton";
import type { Device, InstalledApp } from "../../data/models";
import { UnreachableMessage } from "../devices/UnreachableMessage";
import type { Remote } from "../devices/useDeviceData";
import styles from "./InstalledApps.module.css";

interface InstalledAppsProps {
  device: Device;
  apps: Remote<InstalledApp[]>;
  reachable: boolean | undefined;
  onOpen: (app: InstalledApp) => void;
  onUninstall: (app: InstalledApp) => void;
}

/**
 * The apps installed through the developer or homebrew route, as the TV
 * lists them. A list fetched earlier stays on screen through a refetch or
 * a failed one; the notices below only ever replace nothing.
 */
export function InstalledApps({ device, apps, reachable, onOpen, onUninstall }: InstalledAppsProps) {
  if (!apps.data) {
    if (reachable === false) {
      return <UnreachableMessage deviceName={device.name} />;
    }
    if (apps.error) {
      return <div className={`${styles.empty} ${styles.error}`}>{apps.error}</div>;
    }
    if (reachable === undefined && !apps.loading) {
      return null;
    }
    return (
      <div className={styles.empty}>
        <span className={styles.spinner} />
      </div>
    );
  }

  if (apps.data.length === 0) {
    return <div className={styles.empty}>No apps installed through the developer or homebrew route yet.</div>;
  }

  return (
    <>
      <ul className={styles.list} style={{ listStyle: "none", margin: 0, padding: 0 }}>
        {apps.data.map((app) => (
          <li key={app.id} className={styles.row}>
            <button type="button" className={styles.open} onClick={() => onOpen(app)}>
              <LayoutGrid size={24} />
              <div className={styles.text}>
                <div className={styles.title}>{app.title}</div>
                <div className={styles.meta}>
                  {app.version}
                  {app.vendor ? ` · ${app.vendor}` : ""}
                  {app.running && <span className={styles.running}> · Running</span>}
                </div>
              </div>
            </button>
            <IconButton label={`Uninstall ${app.title}`} onClick={() => onUninstall(app)}>
              <Trash2 size={22} />
            </IconButton>
          </li>
        ))}
      </ul>
      {apps.error && <div className={`${styles.empty} ${styles.error}`}>{apps.error}</div>}
    </>
  );
}
