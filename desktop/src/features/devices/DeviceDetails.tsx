import { useEffect, useState, type ReactNode } from "react";
import {
  Calendar,
  Check,
  Copy,
  Cpu,
  Eye,
  EyeOff,
  Hash,
  IdCard,
  KeyRound,
  LockKeyhole,
  Microchip,
  Network,
  RefreshCw,
  ShieldCheck,
  Trash2,
  Tv,
} from "lucide-react";
import { Button } from "../../components/Button";
import { IconButton } from "../../components/IconButton";
import { InfoPopover, type Explainer } from "../../components/InfoPopover";
import type { Device, DeviceInfo, DevModeStatus } from "../../data/models";
import { devicePassphrase, devicePrivateKey } from "../../ipc/commands";
import * as explain from "./explainers";
import styles from "./DeviceDetails.module.css";

/** How long a revealed key stays on screen before it is hidden again. */
const REVEAL_SECONDS = 30;

interface DeviceDetailsProps {
  device: Device;
  info: DeviceInfo;
  devMode: DevModeStatus;
  onRemove: () => void;
}

/**
 * The same two groups as the mobile device detail page, one above the
 * other: what the app stored at pairing time, then what the TV reports
 * about itself, each laid out in two columns. Every label carries the
 * same explainer as on mobile.
 */
export function DeviceDetails({ device, info, devMode, onRemove }: DeviceDetailsProps) {
  const key = useRevealedSecret(device.id, devicePrivateKey);
  const passphrase = useRevealedSecret(device.id, devicePassphrase);

  return (
    <div className={styles.details}>
      <div className={styles.group}>
        <div className={styles.sectionTitle}>Pairing</div>
        <div className={styles.rows}>
          <Row icon={<Network size={20} />} label="IP address" value={device.host} explainer={explain.ipAddress} />
          <Row
            icon={<Calendar size={20} />}
            label="Paired at"
            value={formatPairedAt(device.pairedAt)}
            explainer={explain.pairedAt}
          />
          <Row
            icon={<IdCard size={20} />}
            label="Connected as"
            value={device.username}
            explainer={explain.connectedAs(device.username)}
            explainerLabel={`Why "${device.username}"?`}
          />
          <Row
            icon={<LockKeyhole size={20} />}
            label="Passphrase"
            value={passphrase.value ?? "Hidden"}
            mono={passphrase.value !== null}
            explainer={explain.passphrase}
            action={<RevealButton what="passphrase" secret={passphrase} />}
          />
          <Row
            icon={<KeyRound size={20} />}
            label="Pairing key"
            value={key.value ? `Shown, hides in ${key.secondsLeft} s` : "Hidden"}
            explainer={explain.pairingKey}
            action={<RevealButton what="pairing key" secret={key} />}
          />
        </div>
        {(passphrase.error ?? key.error) && <div className={styles.keyError}>{passphrase.error ?? key.error}</div>}
        {key.value && <RevealedKey pem={key.value} />}
      </div>

      <div className={styles.group}>
        <div className={styles.sectionTitle}>From the TV</div>
        <div className={styles.rows}>
          <Row icon={<Tv size={20} />} label="Model" value={info.modelName} explainer={explain.model} />
          <Row icon={<Cpu size={20} />} label="Firmware" value={info.firmwareVersion} explainer={explain.firmware} />
          <Row
            icon={<Tv size={20} />}
            label="webOS version"
            value={info.webosVersion}
            explainer={explain.webosVersion}
          />
          <Row icon={<Microchip size={20} />} label="SoC" value={info.socName} explainer={explain.soc} />
          <Row icon={<Hash size={20} />} label="OTA ID" value={info.otaId} explainer={explain.otaId} />
          <Row
            icon={<ShieldCheck size={20} />}
            label="Developer Mode"
            value={devMode.remaining}
            explainer={explain.developerMode}
            action={
              <IconButton size="small" label="Renew Developer Mode session">
                <RefreshCw size={16} />
              </IconButton>
            }
          />
        </div>
      </div>

      <div className={styles.actions}>
        <Button variant="danger" icon={<Trash2 size={18} />} onClick={onRemove}>
          Remove device
        </Button>
      </div>
    </div>
  );
}

interface RowProps {
  icon: ReactNode;
  label: string;
  value: string;
  /** Monospace and selectable, for a revealed secret. */
  mono?: boolean;
  explainer: Explainer;
  explainerLabel?: string;
  action?: ReactNode;
}

function Row({ icon, label, value, mono, explainer, explainerLabel, action }: RowProps) {
  return (
    <div className={styles.row}>
      <span className={styles.rowIcon}>{icon}</span>
      <div className={styles.label}>
        <span>{label}</span>
        <InfoPopover explainer={explainer} label={explainerLabel} />
        {action}
      </div>
      <span className={[styles.value, mono && styles.valueMono].filter(Boolean).join(" ")}>{value}</span>
    </div>
  );
}

function RevealButton({ what, secret }: { what: string; secret: RevealedSecret }) {
  return (
    <IconButton size="small" label={secret.value ? `Hide ${what}` : `Show ${what}`} onClick={secret.toggle}>
      {secret.value ? <EyeOff size={16} /> : <Eye size={16} />}
    </IconButton>
  );
}

interface RevealedSecret {
  value: string | null;
  secondsLeft: number;
  error: string | null;
  toggle: () => void;
}

/**
 * A secret while it is on screen. Read from the keychain at the moment of
 * the click, dropped again after [REVEAL_SECONDS], on hide, and whenever
 * the page shows a different device; never kept longer.
 */
function useRevealedSecret(deviceId: string, read: (id: string) => Promise<string>): RevealedSecret {
  const [value, setValue] = useState<string | null>(null);
  const [secondsLeft, setSecondsLeft] = useState(REVEAL_SECONDS);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setValue(null);
    setError(null);
  }, [deviceId]);

  useEffect(() => {
    if (!value) {
      return;
    }
    setSecondsLeft(REVEAL_SECONDS);
    const started = Date.now();
    const tick = setInterval(() => {
      const left = REVEAL_SECONDS - Math.floor((Date.now() - started) / 1000);
      if (left <= 0) {
        setValue(null);
      } else {
        setSecondsLeft(left);
      }
    }, 250);
    return () => clearInterval(tick);
  }, [value]);

  const toggle = async () => {
    if (value) {
      setValue(null);
      return;
    }
    setError(null);
    try {
      setValue(await read(deviceId));
    } catch (e) {
      setError(String(e));
    }
  };

  return { value, secondsLeft, error, toggle: () => void toggle() };
}

/** The key itself, monospace, with a copy button. */
function RevealedKey({ pem }: { pem: string }) {
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (!copied) {
      return;
    }
    const timer = setTimeout(() => setCopied(false), 1500);
    return () => clearTimeout(timer);
  }, [copied]);

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(pem);
      setCopied(true);
    } catch {
      // The clipboard can be unavailable; the key is still on screen to select.
    }
  };

  return (
    <div className={styles.key}>
      <pre className={styles.keyText}>{pem.trim()}</pre>
      <IconButton size="small" label={copied ? "Copied" : "Copy pairing key"} onClick={() => void copy()}>
        {copied ? <Check size={16} /> : <Copy size={16} />}
      </IconButton>
    </div>
  );
}

/** "Aug 23, 2026 13:37", as the mobile page shows it. */
function formatPairedAt(millis: number): string {
  const date = new Date(millis);
  const day = date.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
  const time = date.toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit", hour12: false });
  return `${day} ${time}`;
}
