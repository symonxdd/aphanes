import type { ButtonHTMLAttributes, ReactNode } from "react";
import styles from "./IconButton.module.css";

interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  /** Accessible name, also shown as the tooltip. */
  label: string;
  size?: "regular" | "large";
  children: ReactNode;
}

export function IconButton({ label, size = "regular", children, className, ...rest }: IconButtonProps) {
  const classes = [styles.button, size === "large" && styles.large, className].filter(Boolean).join(" ");
  return (
    <button type="button" className={classes} aria-label={label} title={label} {...rest}>
      {children}
    </button>
  );
}
