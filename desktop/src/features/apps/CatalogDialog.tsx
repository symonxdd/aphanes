import { useMemo, useState } from "react";
import { ArrowDownAZ, CircleCheck, Info, Search, Star } from "lucide-react";
import { Button } from "../../components/Button";
import { Dialog } from "../../components/Dialog";
import { IconButton } from "../../components/IconButton";
import type { CatalogPackage } from "../../data/models";
import styles from "./CatalogDialog.module.css";

type Filter = "favorites" | "all";

interface CatalogDialogProps {
  open: boolean;
  packages: CatalogPackage[];
  onClose: () => void;
  onInstall: (pkg: CatalogPackage) => void;
}

/**
 * The Homebrew catalog as a dialog over the main window rather than a
 * pushed page. Same controls as mobile: search, Favorites or everything
 * A to Z, one Install button per row.
 */
export function CatalogDialog({ open, packages, onClose, onInstall }: CatalogDialogProps) {
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState<Filter>("favorites");

  const shown = useMemo(() => {
    const needle = query.trim().toLowerCase();
    return packages
      .filter((pkg) => filter === "all" || pkg.favorite)
      .filter((pkg) => needle === "" || pkg.title.toLowerCase().includes(needle) || pkg.id.toLowerCase().includes(needle))
      .sort((a, b) => a.title.localeCompare(b.title));
  }, [packages, query, filter]);

  return (
    <Dialog
      open={open}
      onClose={onClose}
      title="Browse catalog"
      className={styles.dialog}
      headerActions={
        <IconButton label="About the catalog">
          <Info size={22} />
        </IconButton>
      }
    >
      <div className={styles.toolbar}>
        <label className={styles.search}>
          <Search size={20} />
          <input
            type="search"
            placeholder={`Search ${packages.length} packages`}
            value={query}
            onChange={(event) => setQuery(event.target.value)}
          />
        </label>
        <div className={styles.segments} role="group" aria-label="Filter">
          <button type="button" className={styles.segment} aria-pressed={filter === "favorites"} onClick={() => setFilter("favorites")}>
            <Star size={18} />
            <span>Favorites</span>
          </button>
          <button type="button" className={styles.segment} aria-pressed={filter === "all"} onClick={() => setFilter("all")}>
            <ArrowDownAZ size={18} />
            <span>A to Z</span>
          </button>
        </div>
      </div>

      {shown.length === 0 ? (
        <div className={styles.empty}>Nothing in the catalog matches.</div>
      ) : (
        <ul className={styles.list}>
          {shown.map((pkg) => (
            <li key={pkg.id} className={styles.row}>
              <div className={styles.icon} aria-hidden="true" />
              <div className={styles.text}>
                <div className={styles.title}>{pkg.title}</div>
                <div className={styles.description}>{pkg.shortDescription}</div>
              </div>
              {pkg.installed ? (
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
          ))}
        </ul>
      )}

      <div className={styles.footer}>
        Packages come from repo.webosbrew.org. Each install is checked against its published SHA-256.
      </div>
    </Dialog>
  );
}
