import { useEffect, useRef } from "react";
import { AppMark } from "../../components/AppMark";
import styles from "./SplashCard.module.css";

/**
 * The app icon's easter egg, ported from the mobile AppSplashOverlay: the
 * window fades to pure black, then the icon, the name and the codename's
 * meaning settle in one at a time. A click anywhere (or Escape) plays it
 * back out and returns to exactly where it was.
 *
 * One progress value drives every element, written straight to the DOM
 * each frame rather than through React state, so a whole card costs one
 * requestAnimationFrame loop and no re-renders. Arriving is slower than
 * leaving: the entrance is meant to be watched, the exit to get out of
 * the way.
 */
const ENTER_MS = 2200;
const EXIT_MS = 560;

// Where each element starts and finishes, as a fraction of the whole.
// Overlapping rather than sequential, so the card assembles as one
// continuous movement instead of a queue of separate ones.
const STEPS = {
  backdrop: [0, 0.26],
  icon: [0.2, 0.5],
  name: [0.38, 0.62],
  shippedName: [0.46, 0.68],
  rule: [0.58, 0.76],
  greek: [0.66, 0.84],
  meaning: [0.72, 0.9],
  hint: [0.9, 1],
} as const;

type StepName = keyof typeof STEPS;

function stepOf(name: StepName, t: number): number {
  const [begin, end] = STEPS[name];
  const raw = Math.min(1, Math.max(0, (t - begin) / (end - begin)));
  // Ease-out cubic, as on mobile.
  return 1 - Math.pow(1 - raw, 3);
}

/** Lift and fade together: settles in from slightly low. */
function rise(element: HTMLElement | null, progress: number, distance = 14, scaleFrom?: number) {
  if (!element) {
    return;
  }
  const lift = distance * (1 - progress);
  const scale = scaleFrom === undefined ? "" : ` scale(${scaleFrom + (1 - scaleFrom) * progress})`;
  element.style.transform = `translateY(${lift}px)${scale}`;
  element.style.opacity = String(progress);
}

interface SplashCardProps {
  onDone: () => void;
}

export function SplashCard({ onDone }: SplashCardProps) {
  const card = useRef<HTMLDivElement>(null);
  const icon = useRef<HTMLDivElement>(null);
  const name = useRef<HTMLDivElement>(null);
  const shippedName = useRef<HTMLDivElement>(null);
  const rule = useRef<HTMLDivElement>(null);
  const greek = useRef<HTMLDivElement>(null);
  const meaning = useRef<HTMLDivElement>(null);
  const hint = useRef<HTMLDivElement>(null);

  const progress = useRef(0);
  const leaving = useRef(false);
  const frame = useRef<number | null>(null);
  const onDoneRef = useRef(onDone);
  onDoneRef.current = onDone;

  useEffect(() => {
    const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;

    const paint = () => {
      const t = progress.current;
      if (card.current) {
        card.current.style.background = `rgb(0 0 0 / ${stepOf("backdrop", t)})`;
      }
      rise(icon.current, stepOf("icon", t), 10, 0.86);
      rise(name.current, stepOf("name", t));
      rise(shippedName.current, stepOf("shippedName", t));
      if (rule.current) {
        rule.current.style.transform = `scaleX(${stepOf("rule", t)})`;
      }
      rise(greek.current, stepOf("greek", t));
      rise(meaning.current, stepOf("meaning", t));
      if (hint.current) {
        hint.current.style.opacity = String(stepOf("hint", t));
      }
    };

    // Runs the progress from its current value to `target` over `ms`,
    // then calls `then`. Cancelled by whoever starts the next run.
    const run = (target: number, ms: number, then?: () => void) => {
      if (frame.current !== null) {
        cancelAnimationFrame(frame.current);
      }
      const from = progress.current;
      const start = performance.now();
      const tick = (now: number) => {
        const fraction = ms === 0 ? 1 : Math.min(1, (now - start) / ms);
        progress.current = from + (target - from) * fraction;
        paint();
        if (fraction < 1) {
          frame.current = requestAnimationFrame(tick);
        } else {
          frame.current = null;
          then?.();
        }
      };
      frame.current = requestAnimationFrame(tick);
    };

    const dismiss = () => {
      if (leaving.current) {
        return;
      }
      leaving.current = true;
      // Honours the system's reduced-motion setting by cutting rather
      // than playing a faster version of the same motion.
      run(0, reduceMotion ? 0 : EXIT_MS * progress.current, () => onDoneRef.current());
    };

    run(1, reduceMotion ? 0 : ENTER_MS);

    const element = card.current;
    const onKey = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault();
        dismiss();
      }
    };
    element?.addEventListener("click", dismiss);
    window.addEventListener("keydown", onKey, true);
    return () => {
      if (frame.current !== null) {
        cancelAnimationFrame(frame.current);
      }
      element?.removeEventListener("click", dismiss);
      window.removeEventListener("keydown", onKey, true);
    };
  }, []);

  return (
    <div ref={card} className={styles.card} role="button" aria-label="Return to the app">
      <div className={styles.stack}>
        <div ref={icon} style={{ opacity: 0 }}>
          <AppMark width={144} />
        </div>
        <div ref={name} className={styles.name} style={{ opacity: 0 }}>
          Aphanes
        </div>
        <div ref={shippedName} className={styles.shippedName} style={{ opacity: 0 }}>
          a webOS Dev Mode Manager
        </div>
        <div ref={rule} className={styles.rule} style={{ transform: "scaleX(0)" }} />
        <div ref={greek} className={styles.greek} style={{ opacity: 0 }}>
          ἀφανής
        </div>
        <div ref={meaning} className={styles.meaning} style={{ opacity: 0 }}>
          unseen &middot; not manifest
        </div>
      </div>
      <div ref={hint} className={styles.hint} style={{ opacity: 0 }}>
        Click anywhere to return
      </div>
    </div>
  );
}
