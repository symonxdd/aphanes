import { useEffect, useState } from "react";
import { ExternalLink, Hand, Hash, MousePointerClick } from "lucide-react";
import { AppMark } from "../../components/AppMark";
import { Dialog } from "../../components/Dialog";
import { SplashTapTarget } from "../splash/SplashTapTarget";
import { projectLinks } from "../../data/projectLinks";
import { appVersion, openInBrowser } from "../../ipc/commands";
import styles from "./AboutDialog.module.css";

interface AboutDialogProps {
  open: boolean;
  onClose: () => void;
  /** The version line opens the explainer; App owns that dialog. */
  onExplainVersion: (version: string | null) => void;
}

/**
 * The mobile About sheet, word for word. The version line is where this
 * build says it is the desktop one; nothing else about the app's identity
 * differs between the two.
 */
export function AboutDialog({ open, onClose, onExplainVersion }: AboutDialogProps) {
  const [version, setVersion] = useState<string | null>(null);

  useEffect(() => {
    if (open && version === null) {
      appVersion()
        .then(setVersion)
        .catch(() => setVersion(null));
    }
  }, [open, version]);

  return (
    <Dialog open={open} onClose={onClose} title="About" className={styles.dialog}>
      <div className={styles.mark}>
        <SplashTapTarget>
          <AppMark width={56} />
        </SplashTapTarget>
      </div>
      <p className={styles.paragraph}>
        Aphanes - a webOS Dev Mode Manager, is not affiliated with LG Electronics Inc. or the webOS Open Source Edition
        project.
      </p>
      <p className={styles.paragraph}>
        This app will always be free, and free from every kind of ad and tracking. Official releases come only from the{" "}
        <button type="button" className={styles.inlineLink} onClick={() => openInBrowser(projectLinks.repository)}>
          project's GitHub page
        </button>
        .
      </p>
      <button type="button" className={styles.link} onClick={() => openInBrowser(projectLinks.privacyPolicy)}>
        <span>Privacy policy</span>
        <ExternalLink size={14} />
      </button>
      <div className={styles.divider} />
      <div className={styles.tryTitle}>Things to try</div>
      <ul className={styles.tryList}>
        <li className={styles.tryRow}>
          <span className={styles.tryIcon}>
            <SplashTapTarget>
              <AppMark width={18} />
            </SplashTapTarget>
          </span>
          <span>Click the app icon</span>
        </li>
        <li className={styles.tryRow}>
          <span className={styles.tryIcon}>
            <MousePointerClick size={18} />
          </span>
          <span>Click the Aphanes name</span>
        </li>
        <li className={styles.tryRow}>
          <span className={styles.tryIcon}>
            <Hand size={18} />
          </span>
          <span>Hold the Aphanes name</span>
        </li>
        <li className={styles.tryRow}>
          <span className={styles.tryIcon}>
            <Hash size={18} />
          </span>
          <span>Click the version below</span>
        </li>
      </ul>

      {version && (
        <button type="button" className={styles.version} onClick={() => onExplainVersion(version)}>
          {version} &middot; desktop &middot; {import.meta.env.DEV ? "dev" : "release"}
        </button>
      )}
    </Dialog>
  );
}
