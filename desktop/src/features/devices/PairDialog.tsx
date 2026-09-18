import { useEffect, useRef, useState } from "react";
import { CircleCheck, Eye, EyeOff, Info } from "lucide-react";
import { Button } from "../../components/Button";
import { Dialog } from "../../components/Dialog";
import { IconButton } from "../../components/IconButton";
import { isValidIpv4 } from "../../data/ipv4";
import type { Device } from "../../data/models";
import { fetchEncryptedKey, pairDevice, probeKeyServer, renameDevice, validatePassphrase } from "../../ipc/commands";
import styles from "./PairDialog.module.css";

type ProbeStatus = "idle" | "checking" | "found" | "notFound";
type PassphraseStatus = "idle" | "checking" | "correct" | "incorrect";

interface PairDialogProps {
  open: boolean;
  pairedHosts: string[];
  onClose: () => void;
  /** Called once a device is saved, and again if it is renamed before Continue. */
  onPaired: (device: Device) => void;
  /** Opens the walkthrough of what pairing does. */
  onHowItWorks: () => void;
  /** Opens the "Before pairing" checklist, on top of this dialog. */
  onSetupSteps: () => void;
}

/**
 * The mobile pairing page as a dialog, with the same two live checks: the
 * address is probed as it is typed (advisory only, never blocks Pair),
 * and once the encrypted key is cached the passphrase is checked locally
 * with every keystroke. The passphrase never goes over the network.
 *
 * The device is saved the moment pairing succeeds, not on Continue, so
 * closing the dialog any other way never loses a pairing that worked.
 */
export function PairDialog({ open, pairedHosts, onClose, onPaired, onHowItWorks, onSetupSteps }: PairDialogProps) {
  const [host, setHost] = useState("");
  const [passphrase, setPassphrase] = useState("");
  const [showPassphrase, setShowPassphrase] = useState(false);
  const [probe, setProbe] = useState<ProbeStatus>("idle");
  const [passStatus, setPassStatus] = useState<PassphraseStatus>("idle");
  const [pairing, setPairing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [paired, setPaired] = useState<Device | null>(null);
  const [name, setName] = useState("");

  // Cached once the host is found, so passphrase attempts are checked
  // locally instead of fetching the key again each time. State, not a
  // ref, so the passphrase check re-runs the moment the key arrives.
  const [cachedPem, setCachedPem] = useState<string | null>(null);
  const probeToken = useRef(0);
  const passToken = useRef(0);

  useEffect(() => {
    if (!open) {
      setHost("");
      setPassphrase("");
      setShowPassphrase(false);
      setProbe("idle");
      setPassStatus("idle");
      setPairing(false);
      setError(null);
      setPaired(null);
      setName("");
      setCachedPem(null);
    }
  }, [open]);

  const trimmedHost = host.trim();
  const validHost = isValidIpv4(trimmedHost);
  const alreadyPaired = validHost && pairedHosts.includes(trimmedHost);

  useEffect(() => {
    setCachedPem(null);
    const token = ++probeToken.current;
    if (!validHost) {
      setProbe("idle");
      return;
    }
    setProbe("checking");
    const timer = setTimeout(async () => {
      const found = await probeKeyServer(trimmedHost);
      if (token !== probeToken.current) {
        return;
      }
      setProbe(found ? "found" : "notFound");
      if (found) {
        try {
          const pem = await fetchEncryptedKey(trimmedHost);
          if (token === probeToken.current) {
            setCachedPem(pem);
          }
        } catch {
          // Advisory only; the real attempt reports its own error.
        }
      }
    }, 100);
    return () => clearTimeout(timer);
  }, [trimmedHost, validHost]);

  useEffect(() => {
    const token = ++passToken.current;
    const pem = cachedPem;
    if (!pem || passphrase === "") {
      setPassStatus("idle");
      return;
    }
    setPassStatus("checking");
    const timer = setTimeout(async () => {
      const ok = await validatePassphrase(pem, passphrase);
      if (token === passToken.current) {
        setPassStatus(ok ? "correct" : "incorrect");
      }
    }, 150);
    return () => clearTimeout(timer);
  }, [passphrase, cachedPem]);

  const canPair = validHost && !alreadyPaired && passphrase !== "" && !pairing;

  const pair = async () => {
    if (!canPair) {
      return;
    }
    setPairing(true);
    setError(null);
    try {
      const device = await pairDevice(trimmedHost, passphrase, cachedPem, "webOS TV");
      setPaired(device);
      setName(device.name);
      onPaired(device);
    } catch (e) {
      setError(String(e));
    } finally {
      setPairing(false);
    }
  };

  const finish = async () => {
    if (paired && name.trim() !== "" && name.trim() !== paired.name) {
      try {
        onPaired(await renameDevice(paired.id, name.trim()));
      } catch (e) {
        setError(String(e));
        return;
      }
    }
    onClose();
  };

  return (
    <Dialog
      open={open}
      onClose={onClose}
      title={paired ? "Paired" : "Pair a device"}
      className={styles.dialog}
      headerActions={
        paired ? null : (
          <IconButton label="How it works" onClick={onHowItWorks}>
            <Info size={22} />
          </IconButton>
        )
      }
    >
      {paired ? (
        <>
          <div className={styles.success}>
            <CircleCheck size={22} />
            <span>Paired successfully</span>
          </div>
          <label className={styles.field}>
            <span className={styles.label}>Name this device</span>
            <input
              className={styles.input}
              value={name}
              onChange={(event) => setName(event.target.value)}
              onKeyDown={(event) => event.key === "Enter" && void finish()}
              autoFocus
            />
          </label>
          {error && <div className={styles.error}>{error}</div>}
          <div className={styles.actions}>
            <Button variant="filled" onClick={() => void finish()}>
              Continue
            </Button>
          </div>
        </>
      ) : (
        <>
          <p className={styles.lead}>
            Both the IP address and passphrase are shown in the Developer Mode app on the TV
          </p>

          <div className={styles.fields}>
            <label className={styles.field}>
              <span className={styles.label}>TV's IP address</span>
              <input
                className={[styles.input, alreadyPaired && styles.inputError].filter(Boolean).join(" ")}
                value={host}
                onChange={(event) => setHost(event.target.value)}
                disabled={pairing}
                inputMode="numeric"
                placeholder="e.g. 192.168.1.67"
              />
              <div className={styles.status}>
                {alreadyPaired ? (
                  <span className={styles.statusBad}>This TV is already paired</span>
                ) : (
                  <ProbeIndicator status={probe} />
                )}
              </div>
            </label>

            <label className={styles.field}>
              <span className={styles.label}>Passphrase</span>
              {/* Our own show/hide, not the browser's: Edge's built-in
                  reveal button hides on blur and only returns after more
                  typing, and WebKit has none at all. */}
              <div className={styles.secret}>
                <input
                  className={[styles.input, styles.inputSecret].join(" ")}
                  type={showPassphrase ? "text" : "password"}
                  value={passphrase}
                  onChange={(event) => setPassphrase(event.target.value)}
                  onKeyDown={(event) => event.key === "Enter" && void pair()}
                  disabled={pairing}
                  autoComplete="off"
                />
                <IconButton
                  size="small"
                  className={styles.reveal}
                  label={showPassphrase ? "Hide passphrase" : "Show passphrase"}
                  onClick={() => setShowPassphrase((value) => !value)}
                  disabled={pairing}
                >
                  {showPassphrase ? <EyeOff size={18} /> : <Eye size={18} />}
                </IconButton>
              </div>
              <div className={styles.status}>
                <PassphraseIndicator status={passStatus} />
              </div>
            </label>
          </div>

          {error && <div className={styles.error}>{error}</div>}

          <div className={styles.actions}>
            <Button variant="outlined" onClick={onClose} disabled={pairing}>
              Cancel
            </Button>
            <Button variant="filled" onClick={() => void pair()} disabled={!canPair}>
              {pairing ? "Pairing..." : "Pair"}
            </Button>
          </div>

          {/* Highlighted after a failed attempt, the moment someone is
              most likely to need it, without opening unasked. */}
          <button
            type="button"
            className={[styles.setupLink, error !== null && styles.setupLinkHighlighted].filter(Boolean).join(" ")}
            onClick={onSetupSteps}
          >
            New here? See setup steps.
          </button>
        </>
      )}
    </Dialog>
  );
}

function ProbeIndicator({ status }: { status: ProbeStatus }) {
  switch (status) {
    case "idle":
      return null;
    case "checking":
      return (
        <>
          <span className={styles.spinner} />
          <span>Checking...</span>
        </>
      );
    case "found":
      return (
        <span className={[styles.status, styles.statusGood].join(" ")}>
          <CircleCheck size={14} />
          <span>Developer Mode and Key Server are on</span>
        </span>
      );
    case "notFound":
      return (
        <>
          <Info size={14} />
          <span>No response. Check Developer Mode and Key Server are on.</span>
        </>
      );
  }
}

function PassphraseIndicator({ status }: { status: PassphraseStatus }) {
  switch (status) {
    case "idle":
      return null;
    case "checking":
      return (
        <>
          <span className={styles.spinner} />
          <span>Checking...</span>
        </>
      );
    case "correct":
      return (
        <span className={[styles.status, styles.statusGood].join(" ")}>
          <CircleCheck size={14} />
          <span>Passphrase looks correct</span>
        </span>
      );
    case "incorrect":
      return (
        <span className={[styles.status, styles.statusBad].join(" ")}>
          <Info size={14} />
          <span>Incorrect passphrase</span>
        </span>
      );
  }
}
