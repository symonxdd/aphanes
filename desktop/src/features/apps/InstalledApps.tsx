import { LayoutGrid, Trash2 } from "lucide-react";
import { IconButton } from "../../components/IconButton";
import type { InstalledApp } from "../../data/models";
import styles from "./InstalledApps.module.css";

interface InstalledAppsProps {
  apps: InstalledApp[];
  onUninstall: (app: InstalledApp) => void;
}

export function InstalledApps({ apps, onUninstall }: InstalledAppsProps) {
  if (apps.length === 0) {
    return <div className={styles.empty}>No apps installed through the developer or homebrew route yet.</div>;
  }

  return (
    <ul className={styles.list} style={{ listStyle: "none", margin: 0, padding: 0 }}>
      {apps.map((app) => (
        <li key={app.id} className={styles.row}>
          <LayoutGrid size={24} />
          <div className={styles.text}>
            <div className={styles.title}>{app.title}</div>
            <div className={styles.meta}>
              {app.version}
              {app.vendor ? ` · ${app.vendor}` : ""}
            </div>
          </div>
          <IconButton label={`Uninstall ${app.title}`} onClick={() => onUninstall(app)}>
            <Trash2 size={22} />
          </IconButton>
        </li>
      ))}
    </ul>
  );
}
