import styles from "./Switch.module.css";

interface SwitchProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  /** Accessible name; the visible label sits in the row around it. */
  label: string;
}

export function Switch({ checked, onChange, label }: SwitchProps) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      className={styles.switch}
      onClick={() => onChange(!checked)}
    />
  );
}
