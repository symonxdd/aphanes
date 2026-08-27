'use client';

import { useCallback, useRef } from 'react';

// Past this many pixels a press counts as a drag rather than a click.
const DRAG_THRESHOLD = 5;

/// Lets a horizontally scrolling element be dragged with the mouse.
///
/// Mouse only, deliberately. Touch already scrolls these natively, with
/// momentum and rubber-banding that no hand-written version matches, so
/// hijacking it would make the phone experience worse to fix a desktop
/// one. The wheel and trackpad are untouched for the same reason.
export function useDragScroll() {
  const ref = useRef(null);
  const drag = useRef({ active: false, startX: 0, startLeft: 0, moved: 0 });

  const onPointerDown = useCallback((event) => {
    const element = ref.current;
    if (event.pointerType !== 'mouse' || !element) {
      return;
    }
    drag.current = {
      active: true,
      startX: event.clientX,
      startLeft: element.scrollLeft,
      moved: 0,
    };
    // Capture, so a pointer that leaves the strip mid-drag keeps
    // delivering moves here instead of stopping dead at the edge.
    element.setPointerCapture(event.pointerId);
  }, []);

  const onPointerMove = useCallback((event) => {
    const element = ref.current;
    if (!drag.current.active || !element) {
      return;
    }
    const dx = event.clientX - drag.current.startX;
    drag.current.moved = Math.max(drag.current.moved, Math.abs(dx));
    element.scrollLeft = drag.current.startLeft - dx;
  }, []);

  const onPointerEnd = useCallback((event) => {
    const element = ref.current;
    if (element?.hasPointerCapture?.(event.pointerId)) {
      element.releasePointerCapture(event.pointerId);
    }
    drag.current.active = false;
  }, []);

  // A drag ends in a click event, which would otherwise follow whatever
  // link happened to be under the cursor when the mouse came up.
  const onClickCapture = useCallback((event) => {
    if (drag.current.moved > DRAG_THRESHOLD) {
      event.preventDefault();
      event.stopPropagation();
    }
  }, []);

  return {
    ref,
    handlers: {
      onPointerDown,
      onPointerMove,
      onPointerUp: onPointerEnd,
      onPointerCancel: onPointerEnd,
      onClickCapture,
    },
  };
}
