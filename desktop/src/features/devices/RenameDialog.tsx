import { useEffect, useState } from "react";
import { Button } from "../../components/Button";
import { Dialog } from "../../components/Dialog";
import type { Device } from "../../data/models";
import styles from "./EditHostDialog.module.css";

interface RenameDialogProps {
  open: boolean;
  /** The TV being renamed; null only while closed. */
  device: Device | null;
  onClose: () => void;
  onSave: (name: string) => Promise<void>;
}

/**
 * The mobile _RenameDeviceSheet as a dialog: a new display name for an
 * already paired TV. Purely cosmetic, so unlike the address there is no
 * check against the other paired TVs. Shares the address dialog's
 * stylesheet, being the same one-field form.
 */
export function RenameDialog({ open, device, onClose, onSave }: RenameDialogProps) {
  const [name, setName] = useState("");
  const [attempted, setAttempted] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Starts from the current name each time it opens, as on mobile.
  useEffect(() => {
    if (open) {
      setName(device?.name ?? "");
      setAttempted(false);
      setSaving(false);
      setError(null);
    }
  }, [open, device]);

  const trimmed = name.trim();
  const problem = trimmed === "" ? "Name is required" : null;
  // Validation only speaks up once Save has been tried, so the field is
  // not red while the name is being cleared to type a new one.
  const shownProblem = attempted ? problem : null;

  const save = async () => {
    setAttempted(true);
    if (problem || saving) {
      return;
    }
    setSaving(true);
    setError(null);
    try {
      await onSave(trimmed);
      onClose();
    } catch (e) {
      setError(String(e));
    } finally {
      setSaving(false);
    }
  };

  return (
    <Dialog open={open} onClose={onClose} title="Rename device" className={styles.dialog}>
      <label className={styles.field}>
        <span className={styles.label}>Device name</span>
        <input
          className={[styles.input, shownProblem && styles.inputError].filter(Boolean).join(" ")}
          value={name}
          onChange={(event) => setName(event.target.value)}
          onKeyDown={(event) => event.key === "Enter" && void save()}
          disabled={saving}
          autoFocus
        />
        <div className={styles.status}>
          {shownProblem ? (
            <span className={styles.statusBad}>{shownProblem}</span>
          ) : (
            <span className={styles.hint}>Any name works, emojis included.</span>
          )}
        </div>
      </label>

      {error && <div className={styles.error}>{error}</div>}

      <div className={styles.actions}>
        <Button variant="outlined" onClick={onClose}>
          Cancel
        </Button>
        <Button variant="filled" onClick={() => void save()} disabled={saving} busy={saving}>
          Save
        </Button>
      </div>
    </Dialog>
  );
}
