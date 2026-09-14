import { useRef } from "react";
import { Button } from "./Button";
import { Dialog } from "./Dialog";
import styles from "./ConfirmDialog.module.css";

export interface ConfirmRequest {
  title: string;
  message: string;
  /** The destructive verb on the confirming button, e.g. "Uninstall". */
  confirmLabel: string;
  onConfirm: () => void;
}

interface ConfirmDialogProps {
  request: ConfirmRequest | null;
  onClose: () => void;
}

/**
 * The visible, easy-to-reach confirmation every destructive action gets.
 * As on mobile: a plain Cancel, then the destructive verb on a filled
 * error-coloured button, last, so it is never the one focus lands on.
 */
export function ConfirmDialog({ request, onClose }: ConfirmDialogProps) {
  // The request goes null the instant the dialog closes, but the dialog
  // is still fading out. Keep showing the last one so the content, and
  // with it the dialog's size and position, hold still until it is gone.
  const last = useRef<ConfirmRequest | null>(null);
  if (request) {
    last.current = request;
  }
  const shown = request ?? last.current;

  return (
    <Dialog open={request !== null} onClose={onClose} title={shown?.title ?? ""} className={styles.dialog}>
      <p className={styles.message}>{shown?.message}</p>
      <div className={styles.actions}>
        <Button variant="outlined" onClick={onClose} autoFocus>
          Cancel
        </Button>
        <Button
          variant="filledError"
          onClick={() => {
            request?.onConfirm();
            onClose();
          }}
        >
          {shown?.confirmLabel}
        </Button>
      </div>
    </Dialog>
  );
}
