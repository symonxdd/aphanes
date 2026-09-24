import { Download, ExternalLink, RefreshCw, RotateCw } from "lucide-react";
import { Button } from "../../components/Button";
import { projectLinks } from "../../data/projectLinks";
import { openInBrowser } from "../../ipc/commands";
import type { Updater } from "./useUpdater";
import settings from "./SettingsDialog.module.css";
import styles from "./UpdateRow.module.css";

interface UpdateRowProps {
  updater: Updater;
}

/** The GitHub release page for a desktop version, where its notes live. */
function releasePage(version: string): string {
  return `${projectLinks.repository}/releases/tag/desktop-v${version}`;
}

/**
 * The Settings row for updates. While nothing is pending, the whole row
 * is the check button, like the rows around it. Once an update is found
 * the row holds the next step as its own button instead, so downloading
 * and installing each take a deliberate click, and the line under the
 * label says what that click does before it is made.
 */
export function UpdateRow({ updater }: UpdateRowProps) {
  const { status, version, progress, error } = updater;
  const checkable = status === "idle" || status === "checking" || status === "current";

  const content = (
    <>
      <span className={settings.rowIcon}>
        <RefreshCw size={22} className={status === "checking" ? styles.spinning : undefined} />
      </span>
      <span className={`${settings.rowLabel} ${styles.text}`}>
        <span>{label(updater)}</span>
        {detail(updater) && <span className={styles.detail}>{detail(updater)}</span>}
        {error && <span className={styles.error}>{error}</span>}
        {status === "downloading" && (
          <span
            className={styles.track}
            role="progressbar"
            aria-valuenow={progress === null ? undefined : progress * 100}
          >
            <span
              className={`${styles.fill} ${progress === null ? styles.indeterminate : ""}`}
              style={progress === null ? undefined : { width: `${Math.round(progress * 100)}%` }}
            />
          </span>
        )}
      </span>
    </>
  );

  if (checkable) {
    return (
      <button
        type="button"
        className={settings.row}
        onClick={status === "checking" ? undefined : updater.check}
        aria-busy={status === "checking" || undefined}
      >
        {content}
      </button>
    );
  }

  return (
    <div className={`${settings.row} ${styles.pending}`}>
      {content}
      <span className={`${settings.trailing} ${styles.actions}`}>
        {version && status !== "downloading" && (
          <button type="button" className={styles.link} onClick={() => openInBrowser(releasePage(version))}>
            <span>What's new</span>
            <ExternalLink size={14} />
          </button>
        )}
        {status === "available" && (
          <Button variant="tonal" icon={<Download size={18} />} onClick={updater.download}>
            Download
          </Button>
        )}
        {(status === "downloaded" || status === "installing") && (
          <Button
            variant="filled"
            icon={<RotateCw size={18} />}
            busy={status === "installing"}
            onClick={updater.install}
          >
            Install and restart
          </Button>
        )}
      </span>
    </div>
  );
}

function label({ status }: Updater): string {
  switch (status) {
    case "available":
      return "Update available";
    case "downloading":
      return "Downloading update";
    case "downloaded":
    case "installing":
      return "Update ready";
    default:
      return "Check for updates";
  }
}

function detail({ status, version, progress }: Updater): string | null {
  switch (status) {
    case "checking":
      return "Checking...";
    case "current":
      return "This is the latest version.";
    case "available":
      return `Version ${version} is available.`;
    case "downloading":
      return progress === null ? `Version ${version}` : `Version ${version}, ${Math.round(progress * 100)}%`;
    case "downloaded":
    case "installing":
      return `Version ${version}. The app closes while it installs, then opens again on its own.`;
    default:
      return null;
  }
}
