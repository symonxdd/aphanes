import type { ReactNode } from "react";
import { useSplash } from "./SplashProvider";

/**
 * Wraps an app mark so clicking it opens the title card. Unstyled on
 * purpose: this is not a control anyone is meant to hunt for.
 */
export function SplashTapTarget({ children }: { children: ReactNode }) {
  const show = useSplash();
  return (
    <button type="button" aria-label="About webOS Dev Mode Manager" onClick={show} style={{ display: "flex" }}>
      {children}
    </button>
  );
}
