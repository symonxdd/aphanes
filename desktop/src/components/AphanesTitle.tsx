import { useId, useRef, type CSSProperties } from "react";
import { EyeOff } from "lucide-react";
import { placePopover } from "./InfoPopover";
import popoverStyles from "./InfoPopover.module.css";

const WORD = "Aphanes";
const FLIP_MS = 2600;
const HOLD_MS = 500;

/**
 * The word "Aphanes", the project's codename, with the mobile app's two
 * quiet easter eggs: a click slides the letters into reverse order and
 * back (each glyph passing through the others, pausing at the mirrored
 * extreme), and holding the mouse button on it explains the name.
 *
 * Takes its text style from wherever it is placed, like plain text.
 */
export function AphanesTitle({ className, style }: { className?: string; style?: CSSProperties }) {
  const id = useId();
  const container = useRef<HTMLSpanElement>(null);
  const popover = useRef<HTMLDivElement>(null);
  const animating = useRef(false);
  const holdTimer = useRef<number | null>(null);
  const held = useRef(false);

  const flip = () => {
    const root = container.current;
    if (!root || animating.current) {
      return;
    }
    const letters = Array.from(root.querySelectorAll<HTMLElement>("[data-letter]"));
    const n = letters.length;
    const widths = letters.map((el) => el.offsetWidth);
    // Left edge of each glyph in normal order, and of each slot in
    // reversed order. Glyph i lands in reversed slot (n-1-i), which is
    // exactly where it belongs once the word is flipped.
    const originX = prefixSums(widths);
    const reversedSlotX = prefixSums([...widths].reverse());
    animating.current = true;
    const animations = letters.map((el, i) => {
      const dx = reversedSlotX[n - 1 - i] - originX[i];
      return el.animate(
        [
          { transform: "translateX(0)", easing: "ease-in-out" },
          { transform: `translateX(${dx}px)`, offset: 0.34 },
          { transform: `translateX(${dx}px)`, offset: 0.66, easing: "ease-in-out" },
          { transform: "translateX(0)" },
        ],
        { duration: FLIP_MS, fill: "none" },
      );
    });
    void Promise.all(animations.map((a) => a.finished)).finally(() => {
      animating.current = false;
    });
  };

  const explain = () => {
    const anchor = container.current;
    const card = popover.current;
    if (!anchor || !card) {
      return;
    }
    card.showPopover();
    placePopover(anchor, card);
  };

  const startHold = () => {
    held.current = false;
    holdTimer.current = window.setTimeout(() => {
      held.current = true;
      explain();
    }, HOLD_MS);
  };

  const cancelHold = () => {
    if (holdTimer.current !== null) {
      window.clearTimeout(holdTimer.current);
      holdTimer.current = null;
    }
  };

  return (
    <>
      <span
        ref={container}
        className={className}
        style={{ display: "inline-flex", whiteSpace: "pre", ...style }}
        role="button"
        tabIndex={0}
        aria-label="Aphanes"
        onPointerDown={startHold}
        onPointerUp={cancelHold}
        onPointerLeave={cancelHold}
        onPointerCancel={cancelHold}
        onClick={() => {
          // A hold that already opened the explainer is not also a click.
          if (held.current) {
            held.current = false;
            return;
          }
          flip();
        }}
        onKeyDown={(event) => {
          if (event.key === "Enter" || event.key === " ") {
            event.preventDefault();
            flip();
          }
        }}
      >
        {WORD.split("").map((letter, i) => (
          <span key={i} data-letter="" style={{ display: "inline-block" }}>
            {letter}
          </span>
        ))}
      </span>
      <div
        ref={popover}
        id={id}
        popover="auto"
        className={popoverStyles.popover}
        role="dialog"
        aria-labelledby={`${id}-title`}
      >
        <div className={popoverStyles.header}>
          <span className={popoverStyles.icon}>
            <EyeOff size={22} />
          </span>
          <span id={`${id}-title`} className={popoverStyles.title}>
            Aphanes
          </span>
        </div>
        <p className={popoverStyles.body}>
          {"Aphanes comes from the Ancient Greek word ἀφανής (aphanēs), meaning unseen, invisible, not manifest.\n\n" +
            'It\'s built from a negative prefix, a-, plus phainesthai, "to appear". Literally: the thing that does not ' +
            "appear.\n\n" +
            "The same root is commonly linked to Aphaia, a minor Greek goddess worshipped on Aegina, known in myth for " +
            "vanishing into a sacred grove."}
        </p>
      </div>
    </>
  );
}

function prefixSums(values: number[]): number[] {
  const sums: number[] = [];
  let acc = 0;
  for (const v of values) {
    sums.push(acc);
    acc += v;
  }
  return sums;
}
