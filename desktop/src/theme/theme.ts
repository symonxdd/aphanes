/**
 * Theme mode, mirroring the mobile app's ThemeModeController: the stored
 * choice is light, dark, or nothing at all. Nothing means "follow the
 * system", and it stays that way until the person picks one, after which
 * the choice is kept.
 *
 * A theme preference is not a credential, so plain localStorage is the
 * right store for it; secure storage is reserved for device secrets.
 */
export type ThemeMode = "light" | "dark";

const STORAGE_KEY = "theme_mode";
const DARK_QUERY = "(prefers-color-scheme: dark)";

export function readStoredMode(): ThemeMode | null {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    return stored === "light" || stored === "dark" ? stored : null;
  } catch {
    return null;
  }
}

export function writeStoredMode(mode: ThemeMode): void {
  try {
    localStorage.setItem(STORAGE_KEY, mode);
  } catch {
    // A blocked store only loses persistence, not the current session.
  }
}

export function systemMode(): ThemeMode {
  return window.matchMedia(DARK_QUERY).matches ? "dark" : "light";
}

/** Calls `onChange` whenever the system theme flips; returns the unsubscribe. */
export function watchSystemMode(onChange: (mode: ThemeMode) => void): () => void {
  const query = window.matchMedia(DARK_QUERY);
  const handler = (event: MediaQueryListEvent) => onChange(event.matches ? "dark" : "light");
  query.addEventListener("change", handler);
  return () => query.removeEventListener("change", handler);
}

export function applyMode(mode: ThemeMode): void {
  document.documentElement.dataset.theme = mode;
}
