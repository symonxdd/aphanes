import type { ComponentProps, ReactNode } from "react";
import styles from "./IconButton.module.css";

interface IconButtonProps extends ComponentProps<"button"> {
  /** Accessible name, also shown as the tooltip. */
  label: string;
  size?: "small" | "regular" | "large";
  /**
   * Shows the label in the app's own tooltip the moment the pointer
   * arrives, instead of the platform's delayed one. For a button whose
   * glyph alone does not say what it does.
   */
  tooltip?: boolean;
  children: ReactNode;
}

export function IconButton({
  label,
  size = "regular",
  tooltip = false,
  children,
  className,
  ...rest
}: IconButtonProps) {
  const classes = [styles.button, size === "large" && styles.large, size === "small" && styles.small, className]
    .filter(Boolean)
    .join(" ");
  return (
    <button type="button" className={classes} aria-label={label} title={tooltip ? undefined : label} {...rest}>
      {children}
      {tooltip && (
        <span className={styles.tooltip} aria-hidden="true">
          {label}
        </span>
      )}
    </button>
  );
}
