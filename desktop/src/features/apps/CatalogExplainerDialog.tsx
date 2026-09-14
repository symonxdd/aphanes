import { Dialog } from "../../components/Dialog";
import styles from "./CatalogExplainerDialog.module.css";

interface CatalogExplainerDialogProps {
  open: boolean;
  onClose: () => void;
}

/** The mobile catalog explainer sheet, word for word. */
export function CatalogExplainerDialog({ open, onClose }: CatalogExplainerDialogProps) {
  return (
    <Dialog open={open} onClose={onClose} title="The Homebrew catalog" className={styles.dialog}>
      <h3 className={styles.sectionTitle}>What "homebrew" means</h3>
      <p className={styles.paragraph}>
        A plain-language synonym: unofficial, community-made software. "Homebrew" is the general term for software built
        by hobbyists for a device that was never designed to run it, and that its manufacturer doesn't officially
        support. It's used the same way across game consoles, routers, and plenty of other hardware, not just webOS TVs.
      </p>
      <p className={styles.paragraph}>
        <strong>Trivia.</strong> The term traces back to the Homebrew Computer Club, a hobbyist group that met in Menlo
        Park, California starting in 1975 - Steve Wozniak first showed off an early Apple computer there.
      </p>

      <h3 className={styles.sectionTitle}>What this "catalog" is</h3>
      <p className={styles.paragraph}>
        Another word for it: a directory, or a listing - a single place that indexes homebrew apps other developers have
        published for webOS TVs. This one is run by the webOS Homebrew community (webosbrew); this screen reads it
        directly from repo.webosbrew.org/api/apps.json, the raw listing behind repo.webosbrew.org. Like this app itself,
        that project is unaffiliated with LG Electronics: developers submit their own apps to it publicly on GitHub,
        nobody at LG reviews or approves what ends up listed.
      </p>

      <h3 className={styles.sectionTitle}>Is everything here open source?</h3>
      <p className={styles.paragraph}>
        Not guaranteed to be, but in practice, yes so far: every app currently listed publishes a public source link.
        The catalog's own submission format does allow a developer to mark their app closed-source, so that could change
        for a future entry - this app shows a package's source link (when the developer provided one) on that package's
        own details, so it's easy to check per app rather than assumed for the whole catalog.
      </p>
    </Dialog>
  );
}
