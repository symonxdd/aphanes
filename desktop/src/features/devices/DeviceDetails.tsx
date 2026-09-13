import type { ReactNode } from "react";
import { Calendar, Cpu, Hash, Network, RefreshCw, ShieldCheck, Trash2, Tv, User } from "lucide-react";
import { Button } from "../../components/Button";
import { IconButton } from "../../components/IconButton";
import type { Device, DeviceInfo, DevModeStatus } from "../../data/models";
import styles from "./DeviceDetails.module.css";

interface DeviceDetailsProps {
  device: Device;
  info: DeviceInfo;
  devMode: DevModeStatus;
  onRemove: () => void;
}

/**
 * The same two groups as the mobile device detail page: what the app
 * stored at pairing time, then what the TV reports about itself.
 */
export function DeviceDetails({ device, info, devMode, onRemove }: DeviceDetailsProps) {
  return (
    <div className={styles.details}>
      <Row icon={<Network size={22} />} label="IP address" value={device.host} />
      <Row icon={<Calendar size={22} />} label="Paired at" value={device.pairedAt} />
      <Row icon={<User size={22} />} label="Connected as" value={device.username} />

      <div className={styles.sectionTitle}>From the TV</div>
      <Row icon={<Tv size={22} />} label="Model" value={info.modelName} />
      <Row icon={<Cpu size={22} />} label="Firmware" value={info.firmwareVersion} />
      <Row icon={<Tv size={22} />} label="webOS version" value={info.webosVersion} />
      <Row icon={<Cpu size={22} />} label="SoC" value={info.socName} />
      <Row icon={<Hash size={22} />} label="OTA ID" value={info.otaId} />
      <Row
        icon={<ShieldCheck size={22} />}
        label="Developer Mode"
        value={devMode.remaining}
        action={
          <IconButton label="Renew the Developer Mode session">
            <RefreshCw size={18} />
          </IconButton>
        }
      />

      <div className={styles.remove}>
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
  action?: ReactNode;
}

function Row({ icon, label, value, action }: RowProps) {
  return (
    <div className={styles.row}>
      <span className={styles.rowIcon}>{icon}</span>
      <div className={styles.label}>
        <span>{label}</span>
        {action}
      </div>
      <span className={styles.value}>{value}</span>
    </div>
  );
}
