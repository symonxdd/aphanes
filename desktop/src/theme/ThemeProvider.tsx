import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { DEFAULT_SEED, applySeed, readStoredSeed, writeStoredSeed } from "./seed";
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
  /** The accent seed, as a lowercase #rrggbb, and how to change it. */
  seed: string;
  setSeed: (seed: string) => void;
  resetSeed: () => void;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [chosen, setChosen] = useState<ThemeMode | null>(readStoredMode);
  const [system, setSystem] = useState<ThemeMode>(systemMode);
  const [oled, setOledState] = useState<boolean>(readOledEnabled);
  const [seed, setSeedState] = useState<string>(readStoredSeed);

  useEffect(() => watchSystemMode(setSystem), []);

  const mode = chosen ?? system;
  useEffect(() => applyMode(mode, oled), [mode, oled]);
  // The seed's colors depend on the mode, so both changes reapply them.
  useEffect(() => applySeed(seed, mode), [seed, mode]);

  const toggle = useCallback(() => {
    const next: ThemeMode = mode === "dark" ? "light" : "dark";
    setChosen(next);
    writeStoredMode(next);
  }, [mode]);

  const setOled = useCallback((enabled: boolean) => {
    setOledState(enabled);
    writeOledEnabled(enabled);
  }, []);

  const setSeed = useCallback((next: string) => {
    const normalized = next.toLowerCase();
    setSeedState(normalized);
    writeStoredSeed(normalized);
  }, []);

  const resetSeed = useCallback(() => setSeed(DEFAULT_SEED), [setSeed]);

  const value = useMemo(
    () => ({ mode, toggle, oled, setOled, seed, setSeed, resetSeed }),
    [mode, toggle, oled, setOled, seed, setSeed, resetSeed],
  );
  return <ThemeContext.Provider value={value}>{children}</ThemeContext.Provider>;
}

export function useTheme(): ThemeContextValue {
  const value = useContext(ThemeContext);
  if (!value) {
    throw new Error("useTheme needs a ThemeProvider above it");
  }
  return value;
}
