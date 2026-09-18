import {
  Hct,
  MaterialDynamicColors,
  SchemeTonalSpot,
  argbFromHex,
  hexFromArgb,
} from "@material/material-color-utilities";
import type { ThemeMode } from "./theme";

/**
 * The accent seed, mirroring the mobile app's SeedColorController: one
 * color the palette is generated from, kept in localStorage like the
 * theme mode (a preference, not a credential). The generation itself is
 * Google's material-color-utilities, the same code Flutter's
 * ColorScheme.fromSeed runs, so any seed yields the same colors on both
 * apps.
 */

/** AppTheme.seed on mobile: the brand purple. */
export const DEFAULT_SEED = "#9333ea";

/**
 * The mobile accent sheet's presets, the brand default first: a curated
 * spread across the hue wheel. Each is only a seed; the scheme turns it
 * into correctly toned light and dark colors whatever its saturation.
 */
export const PRESET_SEEDS: readonly string[] = [
  DEFAULT_SEED,
  "#ea580c",
  "#f59e0b",
  "#16a34a",
  "#0d9488",
  "#2563eb",
  "#4f46e5",
  "#db2777",
  "#475569",
];

const STORAGE_KEY = "seed_color";
const HEX = /^#[0-9a-f]{6}$/;

/** The stored seed, or the default when none is stored or it is malformed. */
export function readStoredSeed(): string {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)?.toLowerCase();
    return stored && HEX.test(stored) ? stored : DEFAULT_SEED;
  } catch {
    return DEFAULT_SEED;
  }
}

export function writeStoredSeed(seed: string): void {
  try {
    localStorage.setItem(STORAGE_KEY, seed);
  } catch {
    // A blocked store only loses persistence, not the current session.
  }
}

/**
 * The tokens the seed decides, as tokens.css names them, for one mode.
 * The surface ladder is not among them: as on mobile, surfaces stay
 * plain neutral grays whatever the seed, and only the accent roles and
 * the text and outline neutrals (which Material tints faintly toward the
 * seed) follow it.
 */
export function seedTokens(seed: string, mode: ThemeMode): Record<string, string> {
  const scheme = new SchemeTonalSpot(Hct.fromInt(argbFromHex(seed)), mode === "dark", 0);
  const hex = (role: (typeof MaterialDynamicColors)["primary"]) => hexFromArgb(role.getArgb(scheme));
  return {
    "--primary": hex(MaterialDynamicColors.primary),
    "--on-primary": hex(MaterialDynamicColors.onPrimary),
    "--primary-container": hex(MaterialDynamicColors.primaryContainer),
    "--on-primary-container": hex(MaterialDynamicColors.onPrimaryContainer),
    "--on-surface": hex(MaterialDynamicColors.onSurface),
    "--on-surface-variant": hex(MaterialDynamicColors.onSurfaceVariant),
    "--outline": hex(MaterialDynamicColors.outline),
    "--outline-variant": hex(MaterialDynamicColors.outlineVariant),
  };
}

/**
 * Writes the seed's tokens onto the root element, where an inline value
 * outranks every rule in tokens.css. The stylesheet keeps the default
 * seed's values so the first paint already looks right.
 */
export function applySeed(seed: string, mode: ThemeMode): void {
  const root = document.documentElement;
  for (const [name, value] of Object.entries(seedTokens(seed, mode))) {
    root.style.setProperty(name, value);
  }
}

/** Whether text on a swatch of this color reads better in white than black. */
export function isDarkColor(seed: string): boolean {
  return Hct.fromInt(argbFromHex(seed)).tone < 60;
}
