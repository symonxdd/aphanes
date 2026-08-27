'use client';

import { useEffect, useId, useRef, useState } from 'react';
import { Info } from 'lucide-react';

/// A word in running text that can explain itself.
///
/// Deliberately not hover-only. This is a site about a phone app, read
/// mostly on phones, where there is no hover at all: the word is a real
/// button, so a tap works, and so does a keyboard.
///
/// Hovering opens it and leaving closes it again. Clicking pins it open
/// until the next click, Escape, or a press somewhere else, which is what
/// makes it usable by touch without a separate code path.
export function Glossary({ word, children }) {
  const [hovered, setHovered] = useState(false);
  const [pinned, setPinned] = useState(false);
  const [focused, setFocused] = useState(false);
  const wrapper = useRef(null);
  const id = useId();

  const open = hovered || pinned || focused;

  useEffect(() => {
    if (!pinned) {
      return;
    }
    const onKeyDown = (event) => {
      if (event.key === 'Escape') {
        setPinned(false);
      }
    };
    const onPointerDown = (event) => {
      if (!wrapper.current?.contains(event.target)) {
        setPinned(false);
      }
    };
    document.addEventListener('keydown', onKeyDown);
    document.addEventListener('pointerdown', onPointerDown);
    return () => {
      document.removeEventListener('keydown', onKeyDown);
      document.removeEventListener('pointerdown', onPointerDown);
    };
  }, [pinned]);

  // Mouse only. A touch also fires enter events, and letting those open
  // it would leave the panel stuck open after the finger has gone.
  const onPointerEnter = (event) => {
    if (event.pointerType === 'mouse') {
      setHovered(true);
    }
  };
  const onPointerLeave = (event) => {
    if (event.pointerType === 'mouse') {
      setHovered(false);
    }
  };

  return (
    <span ref={wrapper} className="relative inline-block">
      <button
        type="button"
        aria-expanded={open}
        aria-describedby={open ? id : undefined}
        onPointerEnter={onPointerEnter}
        onPointerLeave={onPointerLeave}
        onFocus={() => setFocused(true)}
        onBlur={() => setFocused(false)}
        onClick={() => setPinned((was) => !was)}
        className="inline-flex items-baseline gap-1 rounded-sm border-b border-dotted border-muted-foreground/60 text-foreground/80 transition-colors hover:border-muted-foreground hover:text-foreground focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-accent"
      >
        {word}
        <Info className="h-3 w-3 shrink-0 self-center opacity-60" aria-hidden />
      </button>

      {/* Left aligned rather than centred: the panel is wider than the
          word, and every card it sits in has room to the right but not
          always to the left. */}
      <span
        id={id}
        role="tooltip"
        hidden={!open}
        className="absolute left-0 top-full z-20 mt-2 w-[min(18rem,72vw)] rounded-xl border border-foreground/10 bg-background p-3 text-xs leading-relaxed font-normal text-muted-foreground shadow-lg"
      >
        {children}
      </span>
    </span>
  );
}
