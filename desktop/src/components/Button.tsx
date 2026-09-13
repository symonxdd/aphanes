import type { ButtonHTMLAttributes, ReactNode } from "react";
import styles from "./Button.module.css";

type Variant = "filled" | "tonal" | "outlined" | "danger" | "filledError";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  /** An 18px icon, rendered before the label. */
  icon?: ReactNode;
  children: ReactNode;
}

export function Button({ variant = "outlined", icon, children, className, ...rest }: ButtonProps) {
  const classes = [styles.button, styles[variant], className].filter(Boolean).join(" ");
  return (
    <button type="button" className={classes} {...rest}>
      {icon}
      <span>{children}</span>
    </button>
  );
}
