import { useEffect, useState, type ButtonHTMLAttributes, type ReactNode } from "react";
import styles from "./Button.module.css";

type Variant = "filled" | "tonal" | "outlined" | "danger" | "filledError";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  /** An 18px icon, rendered before the label. */
  icon?: ReactNode;
  /**
   * The action is in flight. Clicks are ignored, but the button keeps its
   * normal look rather than the dimmed disabled one, so a quick action
   * finishes without the button flashing. If the wait grows long enough
   * to notice, a spinner takes the label's place, over the space the
   * label keeps holding, so the button never changes size, and it then
   * stays long enough to read.
   */
  busy?: boolean;
  children: ReactNode;
}

/** How long an action may take before it earns a spinner. */
const SPINNER_DELAY_MS = 200;
/** Once shown, how long the spinner stays, so it never blinks. */
const SPINNER_HOLD_MS = 400;

/**
 * `busy`, smoothed for display: true only after `busy` has held for the
 * delay, and then for at least the hold, whatever `busy` does meanwhile.
 */
function useSpinnerShown(busy: boolean): boolean {
  const [shown, setShown] = useState(false);
  const [shownAt, setShownAt] = useState(0);

  useEffect(() => {
    if (busy && !shown) {
      const timer = setTimeout(() => {
        setShown(true);
        setShownAt(Date.now());
      }, SPINNER_DELAY_MS);
      return () => clearTimeout(timer);
    }
    if (!busy && shown) {
      const remaining = Math.max(0, shownAt + SPINNER_HOLD_MS - Date.now());
      const timer = setTimeout(() => setShown(false), remaining);
      return () => clearTimeout(timer);
    }
    return undefined;
  }, [busy, shown, shownAt]);

  return shown;
}

export function Button({
  variant = "outlined",
  icon,
  busy = false,
  disabled,
  onClick,
  children,
  className,
  ...rest
}: ButtonProps) {
  const spinning = useSpinnerShown(busy);
  const classes = [styles.button, styles[variant], icon && styles.withIcon, spinning && styles.spinning, className]
    .filter(Boolean)
    .join(" ");
  return (
    <button
      type="button"
      className={classes}
      disabled={disabled && !busy}
      onClick={busy ? undefined : onClick}
      aria-busy={busy || undefined}
      {...rest}
    >
      {icon}
      <span>{children}</span>
      {spinning && (
        <span className={styles.spinnerSlot} aria-hidden="true">
          <span className={styles.spinner} />
        </span>
      )}
    </button>
  );
}
