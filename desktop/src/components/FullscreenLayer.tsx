import { useEffect, useRef, type ReactNode } from "react";
import styles from "./FullscreenLayer.module.css";

interface FullscreenLayerProps {
  open: boolean;
  /** Called when the platform closes it (Escape); the child handles its own exit otherwise. */
  onCancel: () => void;
  children: ReactNode;
}

export function FullscreenLayer({ open, onCancel, children }: FullscreenLayerProps) {
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
      className={styles.layer}
      onCancel={(event) => {
        event.preventDefault();
        onCancel();
      }}
    >
      {open && children}
    </dialog>
  );
}
