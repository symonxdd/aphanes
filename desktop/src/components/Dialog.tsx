import { useEffect, useRef, type ReactNode } from "react";
import { X } from "lucide-react";
import { IconButton } from "./IconButton";
import styles from "./Dialog.module.css";

interface DialogProps {
  open: boolean;
  onClose: () => void;
  title: string;
  /** Extra header controls, placed before the close button. */
  headerActions?: ReactNode;
  className?: string;
  children: ReactNode;
}

/**
 * A modal on the native <dialog> element: the platform handles focus
 * trapping, the Escape key and the backdrop, so nothing is reimplemented.
 */
export function Dialog({ open, onClose, title, headerActions, className, children }: DialogProps) {
  const ref = useRef<HTMLDialogElement>(null);

  useEffect(() => {
    const element = ref.current;
    if (!element) {
      return;
    }
    if (open && !element.open) {
      element.showModal();
    } else if (!open && element.open) {
      element.close();
    }
  }, [open]);

  return (
    <dialog
      ref={ref}
      className={[styles.dialog, className].filter(Boolean).join(" ")}
      onClose={onClose}
      onClick={(event) => {
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
        <h2 className={styles.title}>{title}</h2>
        {headerActions}
        <IconButton label="Close" onClick={onClose}>
          <X size={22} />
        </IconButton>
      </div>
      <div className={styles.body}>{children}</div>
    </dialog>
  );
}
