import { useEffect, useRef, type ReactNode, type SyntheticEvent } from "react";
import { X } from "lucide-react";
import { IconButton } from "./IconButton";
import styles from "./Dialog.module.css";

interface DialogProps {
  open: boolean;
  onClose: () => void;
  title: string;
  /** A small icon before the title, e.g. the app a confirmation is about. */
  titleIcon?: ReactNode;
  /** Extra header controls, placed before the close button. */
  headerActions?: ReactNode;
  /**
   * False while closing would be misleading, e.g. mid-install: no close
   * button, and Escape and the backdrop are ignored. Defaults to true.
   */
  dismissible?: boolean;
  /**
   * True for a body that scrolls inside itself (a list under fixed
   * controls): the body then shrinks to the dialog's height instead of
   * growing with its content and scrolling under the header.
   */
  scrollsInside?: boolean;
  className?: string;
  children: ReactNode;
}

/**
 * A modal on the native <dialog> element: the platform handles focus
 * trapping, the Escape key and the backdrop, so nothing is reimplemented.
 */
export function Dialog({
  open,
  onClose,
  title,
  titleIcon,
  headerActions,
  dismissible = true,
  scrollsInside = false,
  className,
  children,
}: DialogProps) {
  const ref = useRef<HTMLDialogElement>(null);
  // The native close event fires for a programmatic close too. Only a
  // close the person initiated (Escape, the X, the backdrop) may report
  // back, or closing one dialog to open another would cancel the second.
  const closingFromProps = useRef(false);

  useEffect(() => {
    const element = ref.current;
    if (!element) {
      return;
    }
    if (open && !element.open) {
      element.showModal();
      // React's autoFocus never reaches the DOM as an attribute, and this
      // element stays mounted while closed, so the native focusing steps
      // land on the header's first button. A dialog that opens with a
      // text field opens on that field instead.
      element.querySelector<HTMLElement>("input:not([disabled]), textarea:not([disabled])")?.focus();
    } else if (!open && element.open) {
      closingFromProps.current = true;
      element.close();
    }
  }, [open]);

  const handleClose = () => {
    if (closingFromProps.current) {
      closingFromProps.current = false;
      return;
    }
    onClose();
  };

  // Escape arrives as a cancel event first; refusing it keeps the dialog
  // open. The browser may still force a close on a repeated press, in
  // which case the close event reports it like any other.
  const handleCancel = (event: SyntheticEvent<HTMLDialogElement>) => {
    if (!dismissible) {
      event.preventDefault();
    }
  };

  return (
    <dialog
      ref={ref}
      className={[styles.dialog, className].filter(Boolean).join(" ")}
      onClose={handleClose}
      onCancel={handleCancel}
      onClick={(event) => {
        if (!dismissible) {
          return;
        }
        // A backdrop click reports the dialog itself as its target, but so
        // does a click on the dialog's own padding, so check the bounds.
        const element = ref.current;
        if (!element || event.target !== element) {
          return;
        }
        const box = element.getBoundingClientRect();
        const inside =
          event.clientX >= box.left &&
          event.clientX <= box.right &&
          event.clientY >= box.top &&
          event.clientY <= box.bottom;
        if (!inside) {
          onClose();
        }
      }}
    >
      <div className={styles.header}>
        {titleIcon && <span className={styles.titleIcon}>{titleIcon}</span>}
        <h2 className={styles.title}>{title}</h2>
        {headerActions}
        {dismissible && (
          <IconButton label="Close" onClick={onClose}>
            <X size={22} />
          </IconButton>
        )}
      </div>
      <div className={[styles.body, scrollsInside && styles.bodyScrollsInside].filter(Boolean).join(" ")}>
        {children}
      </div>
    </dialog>
  );
}
