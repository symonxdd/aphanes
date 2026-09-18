import { useEffect, useMemo, useRef, useState, type MouseEvent, type ReactNode } from "react";
import {
  BookOpen,
  Building2,
  CirclePlay,
  Expand,
  ExternalLink,
  Fingerprint,
  HardDrive,
  Package,
  Play,
  RefreshCw,
  ShieldAlert,
  ShieldQuestion,
  Tag,
  Trash2,
} from "lucide-react";
import { Button } from "../../components/Button";
import { Dialog } from "../../components/Dialog";
import { ImageLightbox } from "../../components/ImageLightbox";
import { InfoPopover, type Explainer } from "../../components/InfoPopover";
import type { CatalogPackage, InstalledApp } from "../../data/models";
import { fetchAppDescription, launchApp, listRunningApps, openInBrowser } from "../../ipc/commands";
import type { Remote } from "../devices/useDeviceData";
import { sanitizeDescription } from "./description";
import * as explain from "./explainers";
import { PackageIcon } from "./PackageIcon";
import styles from "./AppDialog.module.css";

/** What the page is about: an installed app, a catalog entry, or both. */
export interface AppSubject {
  app: InstalledApp | null;
  pkg: CatalogPackage | null;
}

interface AppDialogProps {
  open: boolean;
  deviceId: string | null;
  /** Null only while closed. */
  subject: AppSubject | null;
  /** The catalog's own state, for while an installed app's entry is still being looked up. */
  catalog: Remote<CatalogPackage[]>;
  onClose: () => void;
  onUninstall: (app: InstalledApp) => void;
  onInstall: (pkg: CatalogPackage) => void;
  /** Called with every running list the TV reports here, for the app list. */
  onRunning: (ids: string[]) => void;
}

/**
 * One app's page, opened from the installed list or from the catalog:
 * what the TV knows about it, what the catalog adds when it is listed
 * there (icon, latest version, the listing's description), and the
 * things to do with it. Launch, Install and Uninstall each reach the TV
 * only from their button; the description is fetched when the page
 * opens and kept for the session.
 */
export function AppDialog({
  open,
  deviceId,
  subject,
  catalog,
  onClose,
  onUninstall,
  onInstall,
  onRunning,
}: AppDialogProps) {
  // Held through the close animation so the page does not empty out
  // while it fades, as the confirmation dialog does.
  const last = useRef<AppSubject | null>(null);
  if (subject) {
    last.current = subject;
  }
  const shown = subject ?? last.current;
  const app = shown?.app ?? null;
  const pkg = shown?.pkg ?? null;
  const id = app?.id ?? pkg?.id ?? null;
  const title = app?.title ?? pkg?.title ?? "";

  const description = useDescription(pkg?.fullDescriptionUrl ?? null);
  const launch = useLaunch(deviceId, app?.id ?? null, app?.running ?? false, open, onRunning);
  const [lightbox, setLightbox] = useState<number | null>(null);
  const [iconOpen, setIconOpen] = useState(false);
  useEffect(() => {
    setLightbox(null);
    setIconOpen(false);
  }, [id]);

  if (!shown || !id) {
    return null;
  }

  const catalogPage = `https://repo.webosbrew.org/apps/${id}/`;
  // An update is the catalog's install run over the same app ID, which
  // replaces what is there; only offered when the catalog is ahead.
  const updateAvailable = app !== null && pkg !== null && compareVersions(app.version, pkg.manifest.version) < 0;

  return (
    <>
      <Dialog open={open} onClose={onClose} title={title} className={styles.dialog}>
        <div className={styles.head}>
          {pkg?.iconUri ? (
            <button type="button" className={styles.iconButton} onClick={() => setIconOpen(true)}>
              <PackageIcon uri={pkg.iconUri} size={64} />
              <span className={styles.iconOverlay} aria-hidden="true">
                <Expand size={24} />
              </span>
              <span className={styles.srOnly}>Show the icon large</span>
            </button>
          ) : (
            <PackageIcon uri={null} size={64} />
          )}
          <dl className={styles.facts}>
            {app ? (
              <Fact icon={<Tag size={16} />} label="Installed version">
                {app.version}
                {pkg && <VersionNote installed={app.version} latest={pkg.manifest.version} catalogPage={catalogPage} />}
              </Fact>
            ) : (
              pkg && (
                <Fact icon={<Package size={16} />} label="Latest version">
                  {pkg.manifest.version}
                </Fact>
              )
            )}
            {app?.vendor && (
              <Fact icon={<Building2 size={16} />} label="Developer">
                {app.vendor}
              </Fact>
            )}
            {pkg && (
              <Fact icon={<HardDrive size={16} />} label="Size">
                {formatSize(pkg.manifest.ipkSize)}
              </Fact>
            )}
            <Fact icon={<Fingerprint size={16} />} label="App ID" explainer={explain.appId} mono>
              {id}
            </Fact>
          </dl>
        </div>

        {pkg?.manifest.rootRequired && (
          <div className={styles.warning}>
            <ShieldAlert size={18} />
            <span>Needs root access on the TV to work.</span>
          </div>
        )}
        {pkg && pkg.manifest.ipkSha256 === null && (
          <div className={styles.note}>
            <ShieldQuestion size={18} />
            <span>The catalog publishes no checksum for this package, so its download can't be checked.</span>
          </div>
        )}

        <div className={styles.actions}>
          {app && (
            <Button variant="danger" icon={<Trash2 size={18} />} onClick={() => onUninstall(app)}>
              Uninstall
            </Button>
          )}
          <span className={styles.status}>{launch.message}</span>
          {pkg?.manifest.sourceUrl && (
            <Button
              variant="outlined"
              icon={<ExternalLink size={18} />}
              onClick={() => void openInBrowser(pkg.manifest.sourceUrl ?? "")}
            >
              Source
            </Button>
          )}
          {updateAvailable && pkg && (
            <Button variant="tonal" icon={<RefreshCw size={18} />} onClick={() => onInstall(pkg)}>
              Update to {pkg.manifest.version}
            </Button>
          )}
          {app ? (
            launch.running ? (
              <span className={styles.running}>
                <CirclePlay size={18} />
                <span>Running on the TV</span>
                <InfoPopover explainer={explain.running} label="About running" />
              </span>
            ) : (
              <Button variant="filled" icon={<Play size={18} />} disabled={launch.busy} onClick={launch.start}>
                {launch.busy ? "Opening..." : "Launch"}
              </Button>
            )
          ) : (
            pkg && (
              <Button variant="filled" onClick={() => onInstall(pkg)}>
                Install
              </Button>
            )
          )}
        </div>

        {description.html && (
          <div className={styles.origin}>
            <BookOpen size={16} />
            <span>The content below is the developer's own description of this app.</span>
          </div>
        )}

        <DescriptionBody
          pkg={pkg}
          catalog={catalog}
          description={description}
          onImage={(index) => setLightbox(index)}
        />
      </Dialog>
      <ImageLightbox
        images={description.images}
        index={lightbox}
        onSelect={setLightbox}
        onClose={() => setLightbox(null)}
      />
      {pkg?.iconUri && (
        <ImageLightbox
          images={[pkg.iconUri]}
          index={iconOpen ? 0 : null}
          onSelect={() => undefined}
          onClose={() => setIconOpen(false)}
          showcase={title}
        />
      )}
    </>
  );
}

interface FactProps {
  icon: ReactNode;
  label: string;
  explainer?: Explainer;
  mono?: boolean;
  children: ReactNode;
}

/** One label and value pair, the label led by its icon. */
function Fact({ icon, label, explainer, mono, children }: FactProps) {
  return (
    <>
      <dt>
        <span className={styles.factIcon}>{icon}</span>
        <span>{label}</span>
        {explainer && <InfoPopover explainer={explainer} />}
      </dt>
      <dd className={mono ? styles.factMono : undefined}>{children}</dd>
    </>
  );
}

interface VersionNoteProps {
  installed: string;
  latest: string;
  catalogPage: string;
}

/** After the installed version: whether it is the latest, in parentheses. */
function VersionNote({ installed, latest, catalogPage }: VersionNoteProps) {
  const order = compareVersions(installed, latest);
  if (order === 0) {
    return <span className={styles.factNote}> (latest)</span>;
  }
  if (order > 0) {
    return <span className={styles.factNote}> (newer than the catalog's {latest})</span>;
  }
  return (
    <span className={styles.factNote}>
      {" "}
      (newer version available:{" "}
      <button
        type="button"
        className={styles.factLink}
        title={`Open ${catalogPage}`}
        onClick={() => void openInBrowser(catalogPage)}
      >
        {latest}
      </button>
      )
    </span>
  );
}

/** Dotted numeric versions compared part by part; anything else compares as text. */
function compareVersions(a: string, b: string): number {
  const pa = a.split(".").map(Number);
  const pb = b.split(".").map(Number);
  if (pa.some(Number.isNaN) || pb.some(Number.isNaN)) {
    return a.localeCompare(b);
  }
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d !== 0) {
      return d;
    }
  }
  return 0;
}

function formatSize(bytes: number): string {
  if (bytes >= 1024 * 1024) {
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }
  return `${Math.max(1, Math.round(bytes / 1024))} KB`;
}

interface DescriptionBodyProps {
  pkg: CatalogPackage | null;
  catalog: Remote<CatalogPackage[]>;
  description: Description;
  onImage: (index: number) => void;
}

/** The listing's description, or the reason there is not one. */
function DescriptionBody({ pkg, catalog, description, onImage }: DescriptionBodyProps) {
  // Every link goes to the system browser, never the webview; every
  // image opens large.
  const onClick = (event: MouseEvent<HTMLDivElement>) => {
    const target = event.target as HTMLElement;
    const anchor = target.closest("a");
    if (anchor?.href) {
      event.preventDefault();
      void openInBrowser(anchor.href);
      return;
    }
    if (target instanceof HTMLImageElement) {
      const index = description.images.indexOf(target.src);
      if (index >= 0) {
        onImage(index);
      }
    }
  };

  if (description.html) {
    return <div className={styles.readme} onClick={onClick} dangerouslySetInnerHTML={{ __html: description.html }} />;
  }
  if (catalog.loading || description.loading) {
    return (
      <div className={styles.notice}>
        <span className={styles.spinner} />
      </div>
    );
  }
  if (catalog.error) {
    return <div className={`${styles.notice} ${styles.noticeError}`}>{catalog.error}</div>;
  }
  if (!pkg) {
    return (
      <div className={styles.notice}>
        This app isn't in the Homebrew catalog, so there is no description to show. Apps installed from a .ipk file
        usually aren't.
      </div>
    );
  }
  if (description.error) {
    return <div className={`${styles.notice} ${styles.noticeError}`}>{description.error}</div>;
  }
  return <div className={styles.notice}>The catalog has no description for this app.</div>;
}

interface Description {
  html: string | null;
  /** The images in it, in document order, for the lightbox. */
  images: string[];
  loading: boolean;
  error: string | null;
}

const cache = new Map<string, string>();

/**
 * A listing's description, fetched once per URL for the session and
 * sanitized. What was last shown stays while the URL goes null, so a
 * closing page keeps its content through the fade.
 */
function useDescription(url: string | null): Description {
  const [state, setState] = useState<Remote<string>>({ data: null, loading: false, error: null });

  useEffect(() => {
    if (!url) {
      return;
    }
    const cached = cache.get(url);
    if (cached !== undefined) {
      setState({ data: cached, loading: false, error: null });
      return;
    }
    let stale = false;
    setState({ data: null, loading: true, error: null });
    fetchAppDescription(url).then(
      (data) => {
        cache.set(url, data);
        if (!stale) {
          setState({ data, loading: false, error: null });
        }
      },
      (e: unknown) => {
        if (!stale) {
          setState({ data: null, loading: false, error: String(e) });
        }
      },
    );
    return () => {
      stale = true;
    };
  }, [url]);

  return useMemo(() => {
    if (!state.data) {
      return { html: null, images: [], loading: state.loading, error: state.error };
    }
    const html = sanitizeDescription(state.data);
    const images = Array.from(new DOMParser().parseFromString(html, "text/html").images, (img) => img.src);
    return { html, images, loading: false, error: null };
  }, [state]);
}

interface LaunchState {
  running: boolean;
  busy: boolean;
  message: string | null;
  start: () => void;
}

/**
 * The Launch button and the running state it shows. The state is the
 * app list's own flag: the page opens with what the list already knew,
 * asks the TV again at every open, and both that answer and a launch's
 * report go back to the list through `onRunning`, so the row and the
 * page always agree and neither needs a connection of its own.
 */
function useLaunch(
  deviceId: string | null,
  appId: string | null,
  running: boolean,
  open: boolean,
  onRunning: (ids: string[]) => void,
): LaunchState {
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);

  // Reset for another app, never for closing: the page keeps its state
  // through the close fade.
  useEffect(() => setMessage(null), [deviceId, appId]);

  // The callback is read through a ref so the check runs once per open,
  // not once per render of the parent.
  const report = useRef(onRunning);
  report.current = onRunning;

  useEffect(() => {
    if (!open || !deviceId || !appId) {
      return;
    }
    let stale = false;
    listRunningApps(deviceId).then(
      (ids) => {
        if (!stale) {
          report.current(ids);
        }
      },
      () => {
        // The TV did not say; what was known stands.
      },
    );
    return () => {
      stale = true;
    };
  }, [open, deviceId, appId]);

  const start = async () => {
    if (!deviceId || !appId) {
      return;
    }
    setBusy(true);
    setMessage(null);
    try {
      report.current(await launchApp(deviceId, appId));
      setMessage("Opened on the TV.");
    } catch (e) {
      setMessage(`Couldn't open it: ${String(e)}`);
    } finally {
      setBusy(false);
    }
  };

  return { running, busy, message, start: () => void start() };
}
