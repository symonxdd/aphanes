import { useEffect, useState } from "react";
import { ExternalLink } from "lucide-react";
import { AppMark } from "../../components/AppMark";
import { Dialog } from "../../components/Dialog";
import { projectLinks } from "../../data/projectLinks";
import { appVersion, openInBrowser } from "../../ipc/commands";
import styles from "./AboutDialog.module.css";

interface AboutDialogProps {
  open: boolean;
  onClose: () => void;
}

/**
 * The mobile About sheet, word for word. The version line is where this
 * build says it is the desktop one; nothing else about the app's identity
 * differs between the two.
 */
export function AboutDialog({ open, onClose }: AboutDialogProps) {
  const [version, setVersion] = useState<string | null>(null);

  useEffect(() => {
    if (open && version === null) {
      appVersion().then(setVersion).catch(() => setVersion(null));
    }
  }, [open, version]);

  return (
    <Dialog open={open} onClose={onClose} title="About" className={styles.dialog}>
      <div className={styles.mark}>
        <AppMark width={56} />
      </div>
      <p className={styles.paragraph}>
        Aphanes - a webOS Dev Mode Manager, is not affiliated with LG Electronics Inc. or the webOS Open Source
        Edition project.
      </p>
      <p className={styles.paragraph}>
        Free of charge, with no advertising, no paid features and no tracking, and that will not change. Official
        releases come only from the project's GitHub page.
      </p>
      <button type="button" className={styles.link} onClick={() => openInBrowser(projectLinks.privacyPolicy)}>
        <span>Privacy policy</span>
        <ExternalLink size={14} />
      </button>
      {version && (
        <div className={styles.version}>
          {version} &middot; desktop &middot; {import.meta.env.DEV ? "dev" : "release"}
        </div>
      )}
    </Dialog>
  );
}
