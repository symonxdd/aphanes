import { useRef } from "react";
import { Check, Pipette, RotateCcw } from "lucide-react";
import { Button } from "../../components/Button";
import { Dialog } from "../../components/Dialog";
import { DEFAULT_SEED, PRESET_SEEDS, isDarkColor } from "../../theme/seed";
import { useTheme } from "../../theme/ThemeProvider";
import styles from "./AccentColorDialog.module.css";

interface AccentColorDialogProps {
  open: boolean;
  onClose: () => void;
}

/**
 * The mobile accent color sheet as a dialog: the same nine presets, then
 * a custom color. The custom picker is the platform's own color dialog
 * (an <input type="color">), which needs no library and already knows
 * the platform's conventions; the mobile app needs a picker widget for
 * lack of a native one. A chosen color applies at once, as on mobile,
 * so the dialog itself shows the result.
 */
export function AccentColorDialog({ open, onClose }: AccentColorDialogProps) {
  const { seed, setSeed, resetSeed } = useTheme();
  const pickerRef = useRef<HTMLInputElement>(null);

  return (
    <Dialog open={open} onClose={onClose} title="Accent color" className={styles.dialog}>
      <p className={styles.lead}>
        Regenerates the whole app's palette from a single color, so every screen stays consistent.
      </p>

      <div className={styles.swatches} role="group" aria-label="Preset colors">
        {PRESET_SEEDS.map((preset) => {
          const selected = preset === seed;
          return (
            <button
              key={preset}
              type="button"
              className={[styles.swatch, selected && styles.swatchSelected].filter(Boolean).join(" ")}
              style={{ background: preset }}
              aria-label={preset === DEFAULT_SEED ? "Default accent" : `Accent ${preset}`}
              aria-pressed={selected}
              onClick={() => setSeed(preset)}
            >
              {selected && <Check size={22} className={isDarkColor(preset) ? styles.checkLight : styles.checkDark} />}
            </button>
          );
        })}
      </div>

      <div className={styles.actions}>
        <Button variant="outlined" icon={<Pipette size={18} />} onClick={() => pickerRef.current?.click()}>
          Custom color
        </Button>
        {/* The native picker, opened by the button above; the input itself
            stays out of sight so the dialog keeps its own controls. */}
        <input
          ref={pickerRef}
          type="color"
          className={styles.picker}
          value={seed}
          onChange={(event) => setSeed(event.target.value)}
          aria-hidden="true"
          tabIndex={-1}
        />
        {seed !== DEFAULT_SEED && (
          <Button variant="tonal" icon={<RotateCcw size={18} />} onClick={resetSeed}>
            Reset to default
          </Button>
        )}
      </div>
    </Dialog>
  );
}
