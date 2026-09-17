import { useMemo, useState } from "react";
import { ArrowDownAZ, CircleCheck, Info, RefreshCw, Search, Star } from "lucide-react";
import { Button } from "../../components/Button";
import { Dialog } from "../../components/Dialog";
import { IconButton } from "../../components/IconButton";
import { curatedFavoriteAppIds } from "../../data/curatedFavorites";
import type { CatalogPackage } from "../../data/models";
import type { Remote } from "../devices/useDeviceData";
import { PackageIcon } from "./PackageIcon";
import styles from "./CatalogDialog.module.css";

type Filter = "favorites" | "all";

interface CatalogDialogProps {
  open: boolean;
  catalog: Remote<CatalogPackage[]>;
  /** Ids of the apps installed on the selected TV, to mark rows. */
  installedIds: ReadonlySet<string>;
  onClose: () => void;
  onRefresh: () => void;
  onInstall: (pkg: CatalogPackage) => void;
  /** Opens a package's page. */
  onOpen: (pkg: CatalogPackage) => void;
  onExplain: () => void;
}

/**
 * The Homebrew catalog as a dialog over the main window rather than a
 * pushed page. Same controls as mobile: search, Favorites (in the curated
 * list's own order) or everything A to Z, one Install button per row.
 */
export function CatalogDialog({
  open,
  catalog,
  installedIds,
  onClose,
  onRefresh,
  onInstall,
  onOpen,
  onExplain,
}: CatalogDialogProps) {
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState<Filter>("favorites");
  const packages = catalog.data ?? [];

  const shown = useMemo(() => {
    const needle = query.trim().toLowerCase();
    const matching = packages.filter(
      (pkg) => needle === "" || pkg.title.toLowerCase().includes(needle) || pkg.id.toLowerCase().includes(needle),
    );
    if (filter === "favorites") {
      return matching
        .filter((pkg) => curatedFavoriteAppIds.includes(pkg.id))
        .sort((a, b) => curatedFavoriteAppIds.indexOf(a.id) - curatedFavoriteAppIds.indexOf(b.id));
    }
    return matching.sort((a, b) => a.title.localeCompare(b.title));
  }, [packages, query, filter]);

  return (
    <Dialog
      open={open}
      onClose={onClose}
      title="Browse catalog"
      scrollsInside
      className={styles.dialog}
      headerActions={
        <>
          <IconButton
            label="Reload the catalog"
            className={catalog.loading ? styles.refreshing : undefined}
            disabled={catalog.loading}
            onClick={onRefresh}
          >
            <RefreshCw size={20} />
          </IconButton>
          <IconButton label="About the catalog" onClick={onExplain}>
            <Info size={22} />
          </IconButton>
        </>
      }
    >
      <div className={styles.toolbar}>
        <label className={styles.search}>
          <Search size={20} />
          <input
            type="search"
            placeholder={packages.length === 0 ? "Search" : `Search ${packages.length} packages`}
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </label>
        <div className={styles.segments} role="group" aria-label="Filter">
          <button
            type="button"
            className={styles.segment}
            aria-pressed={filter === "favorites"}
            onClick={() => setFilter("favorites")}
          >
            <Star size={18} />
            <span>Favorites</span>
          </button>
          <button
            type="button"
            className={styles.segment}
            aria-pressed={filter === "all"}
            onClick={() => setFilter("all")}
          >
            <ArrowDownAZ size={18} />
            <span>A to Z</span>
          </button>
        </div>
      </div>

      <CatalogBody
        catalog={catalog}
        shown={shown}
        installedIds={installedIds}
        onInstall={onInstall}
        onOpen={onOpen}
        onRetry={onRefresh}
      />

      <div className={styles.footer}>
        Packages come from repo.webosbrew.org. Each install is checked against its published SHA-256.
      </div>
    </Dialog>
  );
}

interface CatalogBodyProps {
  catalog: Remote<CatalogPackage[]>;
  shown: CatalogPackage[];
  installedIds: ReadonlySet<string>;
  onInstall: (pkg: CatalogPackage) => void;
  onOpen: (pkg: CatalogPackage) => void;
  onRetry: () => void;
}

function CatalogBody({ catalog, shown, installedIds, onInstall, onOpen, onRetry }: CatalogBodyProps) {
  if (catalog.data === null) {
    if (catalog.error) {
      return (
        <div className={styles.empty}>
          <div className={styles.errorText}>{catalog.error}</div>
          <Button variant="outlined" onClick={onRetry}>
            Try again
          </Button>
        </div>
      );
    }
    return (
      <div className={styles.empty}>
        <span className={styles.spinner} />
      </div>
    );
  }
  if (shown.length === 0) {
    return <div className={styles.empty}>Nothing in the catalog matches.</div>;
  }
  return (
    <ul className={styles.list}>
      {shown.map((pkg) => (
        <CatalogRow key={pkg.id} pkg={pkg} installed={installedIds.has(pkg.id)} onInstall={onInstall} onOpen={onOpen} />
      ))}
    </ul>
  );
}

interface CatalogRowProps {
  pkg: CatalogPackage;
  installed: boolean;
  onInstall: (pkg: CatalogPackage) => void;
  onOpen: (pkg: CatalogPackage) => void;
}

function CatalogRow({ pkg, installed, onInstall, onOpen }: CatalogRowProps) {
  return (
    <li className={styles.row}>
      <button type="button" className={styles.open} onClick={() => onOpen(pkg)}>
        <PackageIcon uri={pkg.iconUri} />
        <div className={styles.text}>
          <div className={styles.title}>{pkg.title}</div>
          <div className={styles.description}>{pkg.shortDescription || pkg.id}</div>
        </div>
      </button>
      <span className={styles.version}>{pkg.manifest.version}</span>
      {installed ? (
        <span className={styles.installed}>
          <CircleCheck size={20} />
          <span>Installed</span>
        </span>
      ) : (
        <Button variant="outlined" onClick={() => onInstall(pkg)}>
          Install
        </Button>
      )}
    </li>
  );
}
