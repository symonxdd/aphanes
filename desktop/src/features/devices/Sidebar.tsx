import { Moon, Plus, Settings, Sun, Tv } from "lucide-react";
import { AppMark } from "../../components/AppMark";
import { IconButton } from "../../components/IconButton";
import type { Device } from "../../data/models";
import { useTheme } from "../../theme/ThemeProvider";
import styles from "./Sidebar.module.css";

interface SidebarProps {
  devices: Device[];
  selectedId: string | null;
  onSelect: (id: string) => void;
  onPair: () => void;
  onSettings: () => void;
}

/**
 * The left rail: brand, every paired TV by name with its reachability,
 * and the two things that are not a TV (pairing one, settings). Every
 * entry carries a label; nothing here is icon-only.
 */
export function Sidebar({ devices, selectedId, onSelect, onPair, onSettings }: SidebarProps) {
  const { mode, toggle } = useTheme();
  const isDark = mode === "dark";

  return (
    <nav className={styles.sidebar} aria-label="Devices">
      <div className={styles.brand}>
        <AppMark />
        <div className={styles.brandText}>
          <div className={styles.brandName}>Aphanes</div>
          <div className={styles.brandSub}>A webOS Dev Mode Manager</div>
        </div>
      </div>

      <div className={styles.section}>
        <div className={styles.sectionTitle}>Paired devices</div>
        {devices.map((device) => (
          <button
            key={device.id}
            type="button"
            className={styles.item}
            aria-current={device.id === selectedId}
            onClick={() => onSelect(device.id)}
          >
            <Tv size={22} />
            <span className={styles.itemLabel}>{device.name}</span>
            <span
              className={[styles.dot, device.reachable && styles.dotReachable].filter(Boolean).join(" ")}
              title={device.reachable ? "TV is reachable" : "TV is off or unreachable"}
            />
          </button>
        ))}
        <button type="button" className={styles.item} onClick={onPair}>
          <Plus size={22} />
          <span className={styles.itemLabel}>Pair a TV</span>
        </button>
      </div>

      <div className={styles.spacer} />

      <div className={styles.footer}>
        <button type="button" className={styles.item} onClick={onSettings}>
          <Settings size={22} />
          <span className={styles.itemLabel}>Settings</span>
        </button>
        <IconButton size="large" label={isDark ? "Switch to light mode" : "Switch to dark mode"} onClick={toggle}>
          {isDark ? <Moon size={22} /> : <Sun size={22} />}
        </IconButton>
      </div>
    </nav>
  );
}
