import { useEffect, useState } from "react";
import { ChevronRight, Contrast, Info, Moon, Palette, RotateCcw, Sun } from "lucide-react";
import { AphanesTitle } from "../../components/AphanesTitle";
import { AppMark } from "../../components/AppMark";
import { Dialog } from "../../components/Dialog";
import { SplashTapTarget } from "../splash/SplashTapTarget";
import { IconButton } from "../../components/IconButton";
import { InfoPopover } from "../../components/InfoPopover";
import { Switch } from "../../components/Switch";
import { appVersion } from "../../ipc/commands";
import { useTheme } from "../../theme/ThemeProvider";
import { oledTheme } from "../devices/explainers";
import styles from "./SettingsDialog.module.css";

interface SettingsDialogProps {
  open: boolean;
  onClose: () => void;
  onAccentColor: () => void;
  onAbout: () => void;
  onShowIntro: () => void;
}

/**
 * The mobile settings sheet, as a dialog. Same header (the codename as a
 * signature, with the shipped name in the footer line), same sections in
 * the same order. The hidden tab switches and the ambient backdrop are
 * not here yet.
 */
export function SettingsDialog({ open, onClose, onAccentColor, onAbout, onShowIntro }: SettingsDialogProps) {
  const { mode, toggle, oled, setOled, seed } = useTheme();
  const isDark = mode === "dark";
  const [version, setVersion] = useState<string | null>(null);

  useEffect(() => {
    if (open && version === null) {
      appVersion()
        .then(setVersion)
        .catch(() => setVersion(null));
    }
  }, [open, version]);

  return (
    <Dialog open={open} onClose={onClose} title="Settings" className={styles.dialog}>
      <div className={styles.brand}>
        <div className={styles.brandRow}>
          <SplashTapTarget>
            <AppMark width={34} />
          </SplashTapTarget>
          <AphanesTitle className={styles.brandTitle} />
          <IconButton
            label={isDark ? "Switch to light mode" : "Switch to dark mode"}
            className={styles.brandTheme}
            onClick={toggle}
          >
            {isDark ? <Moon size={22} /> : <Sun size={22} />}
          </IconButton>
        </div>
        <div className={styles.tagline}>A Symon Software Experience</div>
      </div>

      <div className={styles.section}>
        <div className={styles.sectionTitle}>Appearance</div>
        <button type="button" className={styles.row} onClick={onAccentColor}>
          <span className={styles.rowIcon}>
            <Palette size={22} />
          </span>
          <span className={styles.rowLabel}>Accent color</span>
          <span className={styles.trailing}>
            <span className={styles.seedDot} style={{ background: seed }} aria-hidden="true" />
            <ChevronRight size={22} />
          </span>
        </button>
        {/* Only dark mode has an OLED ladder, so its row unfolds with it. */}
        <div
          className={[styles.reveal, styles.revealTight, isDark && styles.revealOpen].filter(Boolean).join(" ")}
          inert={!isDark}
        >
          <div className={styles.revealInner}>
            <div className={styles.row}>
              <span className={styles.rowIcon}>
                <Contrast size={22} />
              </span>
              <span className={styles.rowLabel}>Enable OLED theme</span>
              <span className={styles.trailing}>
                <InfoPopover explainer={oledTheme} label="About OLED theme" />
                <Switch checked={oled} onChange={setOled} label="Enable OLED theme" />
              </span>
            </div>
          </div>
        </div>
      </div>

      <div className={styles.section}>
        <div className={styles.sectionTitle}>General</div>
        <button type="button" className={styles.row} onClick={onAbout}>
          <span className={styles.rowIcon}>
            <Info size={22} />
          </span>
          <span className={styles.rowLabel}>About</span>
          <span className={styles.trailing}>
            <ChevronRight size={22} />
          </span>
        </button>
        <button type="button" className={styles.row} onClick={onShowIntro}>
          <span className={styles.rowIcon}>
            <RotateCcw size={22} />
          </span>
          <span className={styles.rowLabel}>Show intro again</span>
          <span className={styles.trailing}>
            <ChevronRight size={22} />
          </span>
        </button>
      </div>

      {version && (
        <div className={styles.footer}>
          Aphanes &middot; a webOS Dev Mode Manager &middot; {version} ({import.meta.env.DEV ? "dev" : "release"})
        </div>
      )}
    </Dialog>
  );
}
