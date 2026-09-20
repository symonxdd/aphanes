import { ExternalLink } from "lucide-react";
import { projectLinks } from "../data/projectLinks";
import { openInBrowser } from "../ipc/commands";
import styles from "./NotPlannedMessage.module.css";

/**
 * The shared placeholder for a tab that is deliberately not built yet
 * (Files, Terminal), with the mobile app's wording. One thing moves it
 * forward, a link straight to the project's issue tracker, so "Open an
 * issue" is the linked phrase: it names the action, so it is the part a
 * reader reaches for. It carries a color, an underline and a trailing
 * external-link glyph, so the affordance never rests on color alone.
 */
export function NotPlannedMessage() {
  return (
    <div className={styles.message}>
      <div className={styles.title}>Not currently planned, but don't hesitate to ask!</div>
      <p className={styles.body}>
        <button type="button" className={styles.link} onClick={() => void openInBrowser(projectLinks.issues)}>
          Open an issue
          <ExternalLink size={12} />
        </button>{" "}
        in the project's GitHub repository, and I'd be happy to consider adding it.
      </p>
    </div>
  );
}
