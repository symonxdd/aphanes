import type { ReactNode } from "react";
import { Calendar, Cpu, Hash, IdCard, Microchip, Network, RefreshCw, ShieldCheck, Trash2, Tv } from "lucide-react";
import { Button } from "../../components/Button";
import { IconButton } from "../../components/IconButton";
import { InfoPopover, type Explainer } from "../../components/InfoPopover";
import type { Device, DeviceInfo, DevModeStatus } from "../../data/models";
import * as explain from "./explainers";
import styles from "./DeviceDetails.module.css";

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
  return (
    <div className={styles.details}>
      <div className={styles.group}>
        <div className={styles.sectionTitle}>Pairing</div>
        <div className={styles.rows}>
          <Row icon={<Network size={20} />} label="IP address" value={device.host} explainer={explain.ipAddress} />
          <Row icon={<Calendar size={20} />} label="Paired at" value={device.pairedAt} explainer={explain.pairedAt} />
          <Row
            icon={<IdCard size={20} />}
            label="Connected as"
            value={device.username}
            explainer={explain.connectedAs(device.username)}
            explainerLabel={`Why "${device.username}"?`}
          />
        </div>
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
  explainer: Explainer;
  explainerLabel?: string;
  action?: ReactNode;
}

function Row({ icon, label, value, explainer, explainerLabel, action }: RowProps) {
  return (
    <div className={styles.row}>
      <span className={styles.rowIcon}>{icon}</span>
      <div className={styles.label}>
        <span>{label}</span>
        <InfoPopover explainer={explainer} label={explainerLabel} />
        {action}
      </div>
      <span className={styles.value}>{value}</span>
    </div>
  );
}
