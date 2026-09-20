import type { ReactNode } from "react";
import styles from "./ReadMore.module.css";

interface ReadMoreProps {
  open: boolean;
  onToggle: () => void;
  /** Extra classes for the toggle, for where it sits in its parent. */
  buttonClassName?: string;
  /** Extra classes for the panel, for the spacing it opens into. */
  panelClassName?: string;
  children: ReactNode;
}

/**
 * The "Read more" toggle every explainer uses, with the panel it unfolds.
 * The state lives with the parent, which resets it whenever its surface
 * reopens. The unfold runs at the mobile sheets' 220 ms, on the same
 * grid-row trick the settings dialog's OLED section uses, so a panel's
 * height animates without being known.
 */
export function ReadMore({ open, onToggle, buttonClassName, panelClassName, children }: ReadMoreProps) {
  return (
    <>
      <button
        type="button"
        className={[styles.toggle, buttonClassName].filter(Boolean).join(" ")}
        aria-expanded={open}
        onClick={onToggle}
      >
        {open ? "Collapse" : "Read more"}
      </button>
      <div className={[styles.panel, open && styles.panelOpen, panelClassName].filter(Boolean).join(" ")}>
        <div className={styles.panelInner} aria-hidden={!open}>
          {children}
        </div>
      </div>
    </>
  );
}
