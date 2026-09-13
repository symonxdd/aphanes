import { useEffect, useState } from "react";
import { Info, Moon, Sun } from "lucide-react";
import { AppMark } from "../../components/AppMark";
import { Dialog } from "../../components/Dialog";
import { IconButton } from "../../components/IconButton";
import { appVersion } from "../../ipc/commands";
import { useTheme } from "../../theme/ThemeProvider";
import styles from "./SettingsDialog.module.css";

interface SettingsDialogProps {
  open: boolean;
  onClose: () => void;
}

/**
 * The settings sheet's desktop form. As on mobile, this is one of the two
 * places the Aphanes codename appears as a signature; the shipped name
 * stays visible in the footer line beneath it.
 */
export function SettingsDialog({ open, onClose }: SettingsDialogProps) {
  const { mode, toggle } = useTheme();
  const isDark = mode === "dark";
  const [version, setVersion] = useState<string | null>(null);

  useEffect(() => {
    if (open && version === null) {
      appVersion().then(setVersion).catch(() => setVersion(null));
    }
  }, [open, version]);

  return (
    <Dialog open={open} onClose={onClose} title="Settings" className={styles.dialog}>
      <div className={styles.brand}>
        <div className={styles.brandRow}>
          <AppMark width={40} />
          <span>Aphanes</span>
          <IconButton label={isDark ? "Switch to light mode" : "Switch to dark mode"} onClick={toggle}>
            {isDark ? <Moon size={22} /> : <Sun size={22} />}
          </IconButton>
        </div>
        <div className={styles.tagline}>A Symon Software Experience</div>
      </div>

      <div className={styles.sectionTitle}>Appearance</div>
      <div className={styles.row}>
        <span className={styles.rowIcon}>{isDark ? <Moon size={22} /> : <Sun size={22} />}</span>
        <span className={styles.rowLabel}>Theme</span>
        <span className={styles.rowValue}>{isDark ? "Dark" : "Light"}</span>
      </div>

      <div className={styles.sectionTitle}>About</div>
      <div className={styles.row}>
        <span className={styles.rowIcon}>
          <Info size={22} />
        </span>
        <p className={styles.disclaimer}>
          Unaffiliated with LG Electronics Inc. or the webOS Open Source Edition project. Free of charge, with no
          advertising, permanently.
        </p>
      </div>

      <div className={styles.footer}>
        Aphanes &middot; a webOS Dev Mode Manager{version ? ` · ${version}` : ""}
      </div>
    </Dialog>
  );
}
