import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from "react";
import { FullscreenLayer } from "../../components/FullscreenLayer";
import { SplashCard } from "./SplashCard";

const SplashContext = createContext<(() => void) | null>(null);

/**
 * Owns the title card and offers `show()` to any app mark on screen. The
 * card opens in the top layer, so it covers whatever dialog it was opened
 * from and returns to it afterwards.
 */
export function SplashProvider({ children }: { children: ReactNode }) {
  const [open, setOpen] = useState(false);
  const show = useCallback(() => setOpen(true), []);
  const value = useMemo(() => show, [show]);

  return (
    <SplashContext.Provider value={value}>
      {children}
      {/* Escape is handled by the card itself, so it can play the exit. */}
      <FullscreenLayer open={open} onCancel={() => {}}>
        <SplashCard onDone={() => setOpen(false)} />
      </FullscreenLayer>
    </SplashContext.Provider>
  );
}

export function useSplash(): () => void {
  const show = useContext(SplashContext);
  if (!show) {
    throw new Error("useSplash needs a SplashProvider above it");
  }
  return show;
}
