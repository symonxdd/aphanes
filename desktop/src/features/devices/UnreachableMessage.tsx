import { TvMinimal } from "lucide-react";
import styles from "./UnreachableMessage.module.css";

/**
 * Why a tab has nothing to show: the TV did not answer on its SSH port.
 * The mobile app's UnreachableMessage, worded for a computer.
 */
export function UnreachableMessage({ deviceName }: { deviceName: string }) {
  return (
    <div className={styles.message}>
      <TvMinimal size={36} />
      <div className={styles.title}>"{deviceName}" not reachable. Is it turned on?</div>
      <p>Also, make sure this computer is on the same network as the TV.</p>
    </div>
  );
}
