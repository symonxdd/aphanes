import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { applyMode, readStoredMode, systemMode, watchSystemMode, writeStoredMode, type ThemeMode } from "./theme";

interface ThemeContextValue {
  /** The mode actually in effect: the stored choice, else the system's. */
  mode: ThemeMode;
  /** Flips between light and dark and keeps the result. */
  toggle: () => void;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [chosen, setChosen] = useState<ThemeMode | null>(readStoredMode);
  const [system, setSystem] = useState<ThemeMode>(systemMode);

  useEffect(() => watchSystemMode(setSystem), []);

  const mode = chosen ?? system;
  useEffect(() => applyMode(mode), [mode]);

  const toggle = useCallback(() => {
    const next: ThemeMode = mode === "dark" ? "light" : "dark";
    setChosen(next);
    writeStoredMode(next);
  }, [mode]);

  const value = useMemo(() => ({ mode, toggle }), [mode, toggle]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const value = useContext(ThemeContext);
  if (!value) {
    throw new Error("useTheme needs a ThemeProvider above it");
  }
  return value;
}
