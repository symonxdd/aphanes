import { useEffect, useId, useRef, useState, type ReactNode, type ToggleEvent } from "react";
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
  Pencil,
  RefreshCw,
  ShieldCheck,
  Trash2,
  Tv,
} from "lucide-react";
import { Button } from "../../components/Button";
import type { ConfirmRequest } from "../../components/ConfirmDialog";
import { IconButton } from "../../components/IconButton";
import { InfoPopover, placePopover, type Explainer } from "../../components/InfoPopover";
import popoverStyles from "../../components/InfoPopover.module.css";
import type { Device, DeviceDetail, DeviceInfo, DevModeStatus } from "../../data/models";
import { devicePassphrase, devicePrivateKey, renewDevMode } from "../../ipc/commands";
import { formatCountdown, remainingSeconds } from "./devModeTime";
import * as explain from "./explainers";
import { UnreachableMessage } from "./UnreachableMessage";
import type { Remote } from "./useDeviceData";
import styles from "./DeviceDetails.module.css";

/** How long a revealed key stays on screen before it is hidden again. */
const REVEAL_SECONDS = 30;

interface DeviceDetailsProps {
  device: Device;
  detail: Remote<DeviceDetail>;
  reachable: boolean | undefined;
  onEditHost: () => void;
  onRemove: () => void;
  /** Puts a question to the person before something happens on the TV. */
  onConfirm: (request: ConfirmRequest) => void;
}

/**
 * The same two groups as the mobile device detail page, one above the
 * other: what the app stored at pairing time, then what the TV reports
 * about itself, each laid out in two columns. Every label carries the
 * same explainer as on mobile.
 *
 * The TV's facts are shown from the stored copy the moment the tab opens
 * and a fresh fetch runs behind them, so a TV opened before shows its
 * details at once. The Developer Mode session is pointedly not served
 * that way: it is a countdown, so a stored copy would be wrong rather
 * than stale, and the row says what the check is doing instead.
 */
export function DeviceDetails({ device, detail, reachable, onEditHost, onRemove, onConfirm }: DeviceDetailsProps) {
  const key = useRevealedSecret(device.id, devicePrivateKey);
  const passphrase = useRevealedSecret(device.id, devicePassphrase);
  const info = detail.data?.info ?? device.info ?? null;

  return (
    <div className={styles.details}>
      <div className={styles.group}>
        <div className={styles.sectionTitle}>Pairing</div>
        <div className={styles.rows}>
          <Row
            icon={<Network size={20} />}
            label="IP address"
            value={device.host}
            explainer={explain.ipAddress}
            action={
              <IconButton size="small" label="Edit IP address" onClick={onEditHost}>
                <Pencil size={16} />
              </IconButton>
            }
          />
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
            value={key.value ? "Shown" : "Hidden"}
            explainer={explain.pairingKey}
            action={<KeyPopover secret={key} />}
          />
        </div>
        {(passphrase.error ?? key.error) && <div className={styles.keyError}>{passphrase.error ?? key.error}</div>}
      </div>

      <div className={styles.group}>
        <div className={styles.sectionTitle}>From the TV</div>
        <FromTheTv device={device} info={info} detail={detail} reachable={reachable} onConfirm={onConfirm} />
      </div>

      <div className={styles.actions}>
        <Button variant="danger" icon={<Trash2 size={18} />} onClick={onRemove}>
          Remove device
        </Button>
      </div>
    </div>
  );
}

interface FromTheTvProps {
  device: Device;
  info: DeviceInfo | null;
  detail: Remote<DeviceDetail>;
  reachable: boolean | undefined;
  onConfirm: (request: ConfirmRequest) => void;
}

/**
 * The TV's facts and, below them, the Developer Mode row or the reason
 * there is not one. Follows the mobile page's _LiveDeviceInfo case by
 * case, with stored facts always taking precedence over a notice.
 */
function FromTheTv({ device, info, detail, reachable, onConfirm }: FromTheTvProps) {
  const hasRows = info !== null && !isEmptyInfo(info);

  if (!hasRows) {
    if (reachable === false) {
      return <UnreachableMessage deviceName={device.name} />;
    }
    if (detail.error) {
      return <div className={`${styles.notice} ${styles.noticeError}`}>{detail.error}</div>;
    }
    if (reachable === undefined) {
      // Reachability is still being probed; a spinner here would flash
      // for a TV whose stored facts are about to make it pointless.
      return null;
    }
    return (
      <div className={styles.notice}>
        <span className={styles.spinner} />
      </div>
    );
  }

  return (
    <>
      <div className={styles.rows}>
        <InfoRows info={info} />
        <DevModeRow device={device} detail={detail} reachable={reachable} onConfirm={onConfirm} />
      </div>
      {detail.error && <div className={`${styles.notice} ${styles.noticeError}`}>{detail.error}</div>}
    </>
  );
}

function isEmptyInfo(info: DeviceInfo): boolean {
  return !info.modelName && !info.firmwareVersion && !info.webosVersion && !info.socName && !info.otaId;
}

/** One row per fact the TV reported; the ones it did not are left out. */
function InfoRows({ info }: { info: DeviceInfo }) {
  return (
    <>
      {info.modelName && <Row icon={<Tv size={20} />} label="Model" value={info.modelName} explainer={explain.model} />}
      {info.firmwareVersion && (
        <Row icon={<Cpu size={20} />} label="Firmware" value={info.firmwareVersion} explainer={explain.firmware} />
      )}
      {info.webosVersion && (
        <Row icon={<Tv size={20} />} label="webOS version" value={info.webosVersion} explainer={explain.webosVersion} />
      )}
      {info.socName && <Row icon={<Microchip size={20} />} label="SoC" value={info.socName} explainer={explain.soc} />}
      {info.otaId && <Row icon={<Hash size={20} />} label="OTA ID" value={info.otaId} explainer={explain.otaId} />}
    </>
  );
}

interface DevModeRowProps {
  device: Device;
  detail: Remote<DeviceDetail>;
  reachable: boolean | undefined;
  onConfirm: (request: ConfirmRequest) => void;
}

/**
 * The one row never served from the stored copy. Short values only, so
 * it stays on one line beside the others; what each one means is the
 * explainer's job. Renewing sits in the same small action slot the
 * secrets keep their reveal buttons in.
 */
function DevModeRow({ device, detail, reachable, onConfirm }: DevModeRowProps) {
  const renew = useRenew(device.id);
  const status: DevModeStatus | null = reachable === false ? null : (detail.data?.devMode ?? null);
  const seconds = status ? remainingSeconds(status.remaining) : null;

  let value: string;
  if (reachable === false) {
    value = "Unreachable";
  } else if (!status) {
    value = detail.error ? "Unavailable" : "Checking...";
  } else if (seconds !== null) {
    value = formatCountdown(seconds);
  } else if (status.remaining) {
    value = status.remaining;
  } else if (status.hasSession) {
    value = "Time unknown";
  } else {
    value = "No session";
  }

  return (
    <>
      <Row
        icon={<ShieldCheck size={20} />}
        label="Developer Mode"
        value={value}
        valueOverride={seconds === null ? undefined : <SessionCountdown key={status?.remaining} from={seconds} />}
        explainer={explain.developerMode}
        action={
          renew.busy ? (
            <span className={styles.actionSpinner}>
              <span className={styles.spinner} />
            </span>
          ) : (
            <IconButton
              size="small"
              label="Renew Developer Mode session"
              // Nothing to renew until the current session is known.
              disabled={status === null}
              onClick={() =>
                onConfirm({
                  title: "Renew Developer Mode session?",
                  message:
                    "This opens the Developer Mode app on the TV screen, which extends the session's remaining " +
                    "time. Nothing is installed or removed.",
                  confirmLabel: "Renew",
                  tone: "plain",
                  onConfirm: renew.start,
                })
              }
            >
              <RefreshCw size={16} />
            </IconButton>
          )
        }
      />
      {renew.message && (
        <div
          className={[styles.notice, styles.noticeWide, renew.failed && styles.noticeError].filter(Boolean).join(" ")}
        >
          {renew.message}
        </div>
      )}
    </>
  );
}

/**
 * Ticks a session's remaining time down once a second from what LG
 * reported, rather than asking again: the endpoint is consulted once per
 * fetch, and this only stops a live session from looking frozen.
 */
function SessionCountdown({ from }: { from: number }) {
  const [left, setLeft] = useState(from);

  useEffect(() => {
    setLeft(from);
    const started = Date.now();
    const tick = setInterval(() => setLeft(Math.max(0, from - Math.floor((Date.now() - started) / 1000))), 1000);
    return () => clearInterval(tick);
  }, [from]);

  return <>{left === 0 ? "Expired" : formatCountdown(left)}</>;
}

interface RenewState {
  busy: boolean;
  message: string | null;
  failed: boolean;
  start: () => void;
}

/**
 * Drives the Renew button: one short-lived SSH connection per click,
 * like every other user-triggered TV action. The outcome is shown under
 * the row and dropped when the page shows a different device.
 */
function useRenew(deviceId: string): RenewState {
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [failed, setFailed] = useState(false);

  useEffect(() => {
    setMessage(null);
    setFailed(false);
  }, [deviceId]);

  const start = async () => {
    setBusy(true);
    setMessage(null);
    try {
      await renewDevMode(deviceId);
      setFailed(false);
      setMessage("Renewal requested. The remaining time updates once the TV processes it.");
    } catch (e) {
      setFailed(true);
      setMessage(`Something went wrong: ${String(e)}`);
    } finally {
      setBusy(false);
    }
  };

  return { busy, message, failed, start: () => void start() };
}

interface RowProps {
  icon: ReactNode;
  label: string;
  value: string;
  /** Rendered in place of `value` when given; `value` still names the row for assistive tech. */
  valueOverride?: ReactNode;
  /** Monospace and selectable, for a revealed secret. */
  mono?: boolean;
  explainer: Explainer;
  explainerLabel?: string;
  action?: ReactNode;
}

function Row({ icon, label, value, valueOverride, mono, explainer, explainerLabel, action }: RowProps) {
  return (
    <div className={styles.row}>
      <span className={styles.rowIcon}>{icon}</span>
      <div className={styles.label}>
        <span>{label}</span>
        <InfoPopover explainer={explainer} label={explainerLabel} />
        {action && <span className={styles.rowAction}>{action}</span>}
      </div>
      <span className={[styles.value, mono && styles.valueMono].filter(Boolean).join(" ")} aria-label={value}>
        {valueOverride ?? value}
      </span>
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
  reveal: () => void;
  hide: () => void;
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

  const reveal = async () => {
    setError(null);
    try {
      setValue(await read(deviceId));
    } catch (e) {
      setError(String(e));
    }
  };
  const hide = () => setValue(null);

  return {
    value,
    secondsLeft,
    error,
    reveal: () => void reveal(),
    hide,
    toggle: () => (value ? hide() : void reveal()),
  };
}

/**
 * The pairing key in a card anchored to its eye button, the same card
 * the (i) buttons open. The button is the card's native invoker, so the
 * platform handles closing, Escape and clicks outside, and a click on
 * the button while the card is open closes it rather than reopening.
 * Opening is held back: the first open request is refused while the key
 * is read, and the card opens itself the moment the key lands, so it
 * never shows empty and then jumps. The key is dropped when the card
 * closes, however that happens; the timer closes it too.
 */
function KeyPopover({ secret }: { secret: RevealedSecret }) {
  const id = useId();
  const buttonRef = useRef<HTMLButtonElement>(null);
  const popoverRef = useRef<HTMLDivElement>(null);
  const [copied, setCopied] = useState(false);

  // A key arriving opens the card; the key going (the timer, a device
  // change) closes it.
  useEffect(() => {
    const button = buttonRef.current;
    const popover = popoverRef.current;
    if (!button || !popover) {
      return;
    }
    const isOpen = popover.matches(":popover-open");
    if (secret.value && !isOpen) {
      popover.showPopover();
      placePopover(button, popover);
    } else if (!secret.value && isOpen) {
      popover.hidePopover();
    }
  }, [secret.value]);

  useEffect(() => {
    if (!copied) {
      return;
    }
    const timer = setTimeout(() => setCopied(false), 1500);
    return () => clearTimeout(timer);
  }, [copied]);

  const handleBeforeToggle = (event: ToggleEvent<HTMLDivElement>) => {
    if (event.newState === "open" && !secret.value) {
      event.preventDefault();
      secret.reveal();
    }
  };

  const handleToggle = (event: ToggleEvent<HTMLDivElement>) => {
    if (event.newState === "open") {
      setCopied(false);
    } else {
      secret.hide();
    }
  };

  const copy = async () => {
    if (!secret.value) {
      return;
    }
    try {
      await navigator.clipboard.writeText(secret.value);
      setCopied(true);
    } catch {
      // The clipboard can be unavailable; the key is still on screen to select.
    }
  };

  const open = secret.value !== null;
  return (
    <>
      <IconButton
        ref={buttonRef}
        size="small"
        label={open ? "Hide pairing key" : "Show pairing key"}
        popoverTarget={id}
        popoverTargetAction="toggle"
      >
        {open ? <EyeOff size={16} /> : <Eye size={16} />}
      </IconButton>
      <div
        ref={popoverRef}
        id={id}
        popover="auto"
        className={[popoverStyles.popover, styles.keyPopover].join(" ")}
        role="dialog"
        aria-labelledby={`${id}-title`}
        onBeforeToggle={handleBeforeToggle}
        onToggle={handleToggle}
      >
        <div className={popoverStyles.header}>
          <span className={popoverStyles.icon}>
            <KeyRound size={22} />
          </span>
          <span id={`${id}-title`} className={[popoverStyles.title, styles.keyTitle].join(" ")}>
            Pairing key
          </span>
          <span className={styles.keyCountdown}>Hides in {secret.secondsLeft} s</span>
          <IconButton size="small" label={copied ? "Copied" : "Copy pairing key"} onClick={() => void copy()}>
            {copied ? <Check size={16} /> : <Copy size={16} />}
          </IconButton>
        </div>
        <pre className={styles.keyText}>{secret.value?.trim()}</pre>
      </div>
    </>
  );
}

/** "Aug 23, 2026 13:37", as the mobile page shows it. */
function formatPairedAt(millis: number): string {
  const date = new Date(millis);
  const day = date.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
  const time = date.toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit", hour12: false });
  return `${day} ${time}`;
}
