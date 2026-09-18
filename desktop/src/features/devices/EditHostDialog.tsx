import { useEffect, useState } from "react";
import { Button } from "../../components/Button";
import { Dialog } from "../../components/Dialog";
import { ReadMore } from "../../components/ReadMore";
import { isValidIpv4 } from "../../data/ipv4";
import type { Device } from "../../data/models";
import styles from "./EditHostDialog.module.css";

/** Behind "Read more", the same three paragraphs as the mobile sheet. */
const detailParagraphs = [
  "Most home networks hand out IP addresses through DHCP, on a lease that renews periodically. When that lease " +
    "renews, a device can be handed a different address than before - this is the most common reason a " +
    "previously paired TV's address changes.",
  "If this TV's address was instead set manually to always stay the same (a static IP, usually configured by " +
    "whoever manages the home network), it will never change on its own, and this screen shouldn't need touching.",
  "Either way, the saved pairing key stays valid: updating the address here reconnects to the same TV without " +
    "pairing again from its Developer Mode app.",
];

interface EditHostDialogProps {
  open: boolean;
  /** The TV whose address is being edited; null only while closed. */
  device: Device | null;
  /** Every other paired TV, so two records never share an address. */
  otherDevices: Device[];
  onClose: () => void;
  onSave: (host: string) => Promise<void>;
}

/**
 * The mobile _EditHostSheet as a dialog: a new address for an already
 * paired TV. The saved pairing key stays valid whatever the address, so
 * this is the recovery path for a TV whose DHCP lease renewed to a
 * different one, without pairing again from its Developer Mode app.
 */
export function EditHostDialog({ open, device, otherDevices, onClose, onSave }: EditHostDialogProps) {
  const [host, setHost] = useState("");
  const [showDetails, setShowDetails] = useState(false);
  const [attempted, setAttempted] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Starts from the current address each time it opens, as on mobile.
  useEffect(() => {
    if (open) {
      setHost(device?.host ?? "");
      setShowDetails(false);
      setAttempted(false);
      setSaving(false);
      setError(null);
    }
  }, [open, device]);

  const trimmed = host.trim();
  const problem = validate(trimmed, otherDevices);
  // Validation only speaks up once Save has been tried, so the field is
  // not red while a new address is still being typed.
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
    <Dialog open={open} onClose={onClose} title="Edit IP address" className={styles.dialog}>
      <p className={styles.lead}>
        A TV's address can change over time. Updating it here reconnects without pairing again.
      </p>
      <ReadMore
        open={showDetails}
        onToggle={() => setShowDetails((value) => !value)}
        buttonClassName={styles.more}
        panelClassName={[styles.details, showDetails && styles.detailsOpen].filter(Boolean).join(" ")}
      >
        <div className={styles.paragraphs}>
          {detailParagraphs.map((paragraph) => (
            <p key={paragraph}>{paragraph}</p>
          ))}
        </div>
      </ReadMore>

      <label className={styles.field}>
        <span className={styles.label}>TV's IP address</span>
        <input
          className={[styles.input, shownProblem && styles.inputError].filter(Boolean).join(" ")}
          value={host}
          onChange={(event) => setHost(event.target.value)}
          onKeyDown={(event) => event.key === "Enter" && void save()}
          disabled={saving}
          inputMode="numeric"
        />
        <div className={styles.status}>{shownProblem && <span className={styles.statusBad}>{shownProblem}</span>}</div>
      </label>

      {error && <div className={styles.error}>{error}</div>}

      <div className={styles.actions}>
        <Button variant="outlined" onClick={onClose} disabled={saving}>
          Cancel
        </Button>
        <Button variant="filled" onClick={() => void save()} disabled={saving}>
          {saving ? "Saving..." : "Save"}
        </Button>
      </div>
    </Dialog>
  );
}

/** The mobile sheet's three checks, in its order and wording. */
function validate(host: string, otherDevices: Device[]): string | null {
  if (host === "") {
    return "IP address is required";
  }
  if (!isValidIpv4(host)) {
    return "Enter a valid IP address";
  }
  if (otherDevices.some((device) => device.host === host)) {
    return "Another paired TV already uses this address";
  }
  return null;
}
