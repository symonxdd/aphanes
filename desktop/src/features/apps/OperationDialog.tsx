import { useRef } from "react";
import { CircleAlert, CircleCheck } from "lucide-react";
import { Button } from "../../components/Button";
import { Dialog } from "../../components/Dialog";
import type { OperationProgress } from "../../data/models";
import type { AppOperationState } from "./useAppOperation";
import styles from "./OperationDialog.module.css";

interface OperationDialogProps {
  state: AppOperationState;
  onClose: () => void;
}

/**
 * Shared progress UI for install and uninstall, as on mobile: not
 * dismissible while the operation runs (the TV is mid-write, and closing
 * this should not feel like it cancelled anything), a Close button once
 * it reaches a terminal state.
 */
export function OperationDialog({ state, onClose }: OperationDialogProps) {
  // Keep the last real state through the closing fade, as ConfirmDialog does.
  const last = useRef<AppOperationState>(state);
  if (state.phase !== "idle") {
    last.current = state;
  }
  const shown = state.phase === "idle" ? last.current : state;
  const running = state.phase === "running";

  return (
    <Dialog
      open={state.phase !== "idle"}
      onClose={onClose}
      dismissible={!running}
      title={shown.phase === "idle" ? "" : shown.title}
      className={styles.dialog}
    >
      <div className={styles.status}>
        <StatusRow state={shown} />
      </div>
      {!running && (
        <div className={styles.actions}>
          <Button variant="filled" onClick={onClose} autoFocus>
            Close
          </Button>
        </div>
      )}
    </Dialog>
  );
}

function StatusRow({ state }: { state: AppOperationState }) {
  switch (state.phase) {
    case "idle":
      return null;
    case "running":
      return (
        <>
          <span className={styles.spinner} />
          <span>{progressLabel(state.progress)}</span>
        </>
      );
    case "succeeded":
      return (
        <>
          <CircleCheck size={22} className={styles.ok} />
          <span>Done</span>
        </>
      );
    case "failed":
      return (
        <>
          <CircleAlert size={22} className={styles.error} />
          <span className={styles.error}>{state.message}</span>
        </>
      );
  }
}

/** The mobile progress dialog's wording for each step. */
function progressLabel(progress: OperationProgress | null): string {
  if (!progress) {
    return "Starting...";
  }
  switch (progress.kind) {
    case "uploading": {
      const percent = progress.total === 0 ? 0 : Math.min(100, Math.round((progress.sent / progress.total) * 100));
      return `Uploading... ${percent}%`;
    }
    case "verifying":
      return "Verifying upload...";
    case "working":
      return progress.message;
    case "succeeded":
      return "Finishing...";
  }
}
