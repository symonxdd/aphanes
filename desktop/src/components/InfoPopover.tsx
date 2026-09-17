import { useId, useRef, useState, type ReactNode } from "react";
import { Info } from "lucide-react";
import { IconButton } from "./IconButton";
import { ReadMore } from "./ReadMore";
import styles from "./InfoPopover.module.css";

export interface Explainer {
  icon: ReactNode;
  title: string;
  body: string;
  /** Shown behind a Read more button, as on mobile. */
  details?: string;
}

interface InfoPopoverProps {
  explainer: Explainer;
  /** Accessible name for the (i) button; defaults to mobile's wording. */
  label?: string;
}

const GAP = 8;
const MARGIN = 12;

/**
 * The desktop form of the mobile InfoSheet: an (i) button that opens an
 * anchored card next to itself rather than a sheet from the bottom.
 * Built on the native popover attribute, so the platform provides the
 * top layer, the Escape key and light dismiss on an outside click.
 */
export function InfoPopover({ explainer, label }: InfoPopoverProps) {
  const id = useId();
  const buttonRef = useRef<HTMLButtonElement>(null);
  const popoverRef = useRef<HTMLDivElement>(null);
  const [showDetails, setShowDetails] = useState(false);

  const open = () => {
    const button = buttonRef.current;
    const popover = popoverRef.current;
    if (!button || !popover) {
      return;
    }
    setShowDetails(false);
    popover.showPopover();
    placePopover(button, popover);
  };

  return (
    <>
      <IconButton ref={buttonRef} size="small" label={label ?? `What is "${explainer.title}"?`} onClick={open}>
        <Info size={18} />
      </IconButton>
      <div
        ref={popoverRef}
        id={id}
        popover="auto"
        className={styles.popover}
        role="dialog"
        aria-labelledby={`${id}-title`}
      >
        <div className={styles.header}>
          <span className={styles.icon}>{explainer.icon}</span>
          <span id={`${id}-title`} className={styles.title}>
            {explainer.title}
          </span>
        </div>
        <p className={styles.body}>{explainer.body}</p>
        {explainer.details && (
          <ReadMore
            open={showDetails}
            onToggle={() => setShowDetails((value) => !value)}
            buttonClassName={styles.more}
            panelClassName={[styles.details, showDetails && styles.detailsOpen].filter(Boolean).join(" ")}
          >
            <p className={styles.body}>{explainer.details}</p>
          </ReadMore>
        )}
      </div>
    </>
  );
}

/** Puts the card below its anchor, left-aligned to it, kept inside the window. */
export function placePopover(button: HTMLElement, popover: HTMLElement): void {
  const anchor = button.getBoundingClientRect();
  const size = popover.getBoundingClientRect();
  const viewportWidth = document.documentElement.clientWidth;
  const viewportHeight = document.documentElement.clientHeight;

  let left = anchor.left;
  if (left + size.width > viewportWidth - MARGIN) {
    left = Math.max(MARGIN, viewportWidth - MARGIN - size.width);
  }

  let top = anchor.bottom + GAP;
  if (top + size.height > viewportHeight - MARGIN) {
    const above = anchor.top - GAP - size.height;
    top = above >= MARGIN ? above : Math.max(MARGIN, viewportHeight - MARGIN - size.height);
  }

  popover.style.left = `${Math.round(left)}px`;
  popover.style.top = `${Math.round(top)}px`;
}
