import type { ComponentProps, ReactNode } from "react";
import styles from "./IconButton.module.css";

interface IconButtonProps extends ComponentProps<"button"> {
  /** Accessible name, also shown as the tooltip. */
  label: string;
  size?: "small" | "regular" | "large";
  children: ReactNode;
}

export function IconButton({ label, size = "regular", children, className, ...rest }: IconButtonProps) {
  const classes = [styles.button, size === "large" && styles.large, size === "small" && styles.small, className]
    .filter(Boolean)
    .join(" ");
  return (
    <button type="button" className={classes} aria-label={label} title={label} {...rest}>
      {children}
    </button>
  );
}
