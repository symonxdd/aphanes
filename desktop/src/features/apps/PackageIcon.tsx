import { useEffect, useState } from "react";
import { LayoutGrid } from "lucide-react";
import styles from "./PackageIcon.module.css";

interface PackageIconProps {
  uri: string | null;
  /** Side length in pixels; the catalog rows use 48, the app page 64. */
  size?: number;
}

/**
 * A package's icon from the catalog host, with a generic mark in its
 * place until it loads, or if there is none or it fails.
 */
export function PackageIcon({ uri, size = 48 }: PackageIconProps) {
  const [failed, setFailed] = useState(false);
  useEffect(() => setFailed(false), [uri]);
  const style = { width: size, height: size, borderRadius: size / 4 };
  if (!uri || failed) {
    return (
      <div className={styles.icon} style={style} aria-hidden="true">
        <LayoutGrid size={Math.round(size * 0.46)} />
      </div>
    );
  }
  return <img className={styles.icon} style={style} src={uri} alt="" loading="lazy" onError={() => setFailed(true)} />;
}
