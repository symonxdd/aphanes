import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import {
  applyMode,
  readOledEnabled,
  readStoredMode,
  systemMode,
  watchSystemMode,
  writeOledEnabled,
  writeStoredMode,
  type ThemeMode,
} from "./theme";

interface ThemeContextValue {
  /** The mode actually in effect: the stored choice, else the system's. */
  mode: ThemeMode;
  /** Flips between light and dark and keeps the result. */
  toggle: () => void;
  /** The OLED preference, applied only while dark. */
  oled: boolean;
  setOled: (enabled: boolean) => void;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [chosen, setChosen] = useState<ThemeMode | null>(readStoredMode);
  const [system, setSystem] = useState<ThemeMode>(systemMode);
  const [oled, setOledState] = useState<boolean>(readOledEnabled);

  useEffect(() => watchSystemMode(setSystem), []);

  const mode = chosen ?? system;
  useEffect(() => applyMode(mode, oled), [mode, oled]);

  const toggle = useCallback(() => {
    const next: ThemeMode = mode === "dark" ? "light" : "dark";
    setChosen(next);
    writeStoredMode(next);
  }, [mode]);

  const setOled = useCallback((enabled: boolean) => {
    setOledState(enabled);
    writeOledEnabled(enabled);
  }, []);

  const value = useMemo(() => ({ mode, toggle, oled, setOled }), [mode, toggle, oled, setOled]);
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const value = useContext(ThemeContext);
  if (!value) {
    throw new Error("useTheme needs a ThemeProvider above it");
  }
  return value;
}
