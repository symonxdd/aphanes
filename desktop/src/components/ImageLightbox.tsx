import { useEffect, useRef, useState } from "react";
import { ChevronLeft, ChevronRight, X } from "lucide-react";
import { IconButton } from "./IconButton";
import styles from "./ImageLightbox.module.css";

interface ImageLightboxProps {
  /** The images in the set, in order. */
  images: string[];
  /** Which one is open, or null while closed. */
  index: number | null;
  onSelect: (index: number) => void;
  onClose: () => void;
  /**
   * Shows the one image as a piece on display: larger, drifting slowly,
   * with this title centered under it. For an app's icon.
   */
  showcase?: string;
}

/**
 * One image of a set at the window's size, with the set as a strip of
 * thumbnails along the bottom to switch between. A modal of its own on
 * the native <dialog>, so it sits above whatever dialog opened it and
 * fades in and out like one. Left and right arrows and the arrow keys
 * move through the set; Escape, the close button or a click on the
 * backdrop leave it.
 */
export function ImageLightbox({ images, index, onSelect, onClose, showcase }: ImageLightboxProps) {
  const ref = useRef<HTMLDialogElement>(null);
  const open = index !== null && images.length > 0;
  // Held through the exit fade so the image does not vanish before it.
  const [shown, setShown] = useState(0);
  const [showcaseWidth, setShowcaseWidth] = useState<number | null>(null);
  useEffect(() => {
    if (index !== null) {
      setShown(index);
    }
  }, [index]);

  useEffect(() => {
    const element = ref.current;
    if (!element) {
      return;
    }
    if (open && !element.open) {
      element.showModal();
    } else if (!open && element.open) {
      element.close();
    }
  }, [open]);

  const count = images.length;
  const previous = () => onSelect((shown - 1 + count) % count);
  const next = () => onSelect((shown + 1) % count);
  const many = count > 1;

  return (
    <dialog
      ref={ref}
      className={styles.lightbox}
      onCancel={(event) => {
        event.preventDefault();
        onClose();
      }}
      onKeyDown={(event) => {
        if (!many) {
          return;
        }
        if (event.key === "ArrowLeft") {
          previous();
        } else if (event.key === "ArrowRight") {
          next();
        }
      }}
      onClick={(event) => {
        // Only the backdrop closes; the image, the strip and the buttons
        // are targets of their own.
        if (event.target === event.currentTarget) {
          onClose();
        }
      }}
    >
      <div className={styles.top}>
        {many && (
          <span className={styles.counter}>
            {shown + 1} of {count}
          </span>
        )}
        <IconButton label="Close" className={styles.control} onClick={onClose}>
          <X size={22} />
        </IconButton>
      </div>
      {many && (
        <IconButton
          label="Previous image"
          className={[styles.control, styles.arrow, styles.arrowLeft].join(" ")}
          onClick={previous}
        >
          <ChevronLeft size={28} />
        </IconButton>
      )}
      {images[shown] &&
        (showcase === undefined ? (
          <img className={styles.image} src={images[shown]} alt="" />
        ) : (
          <div className={styles.showcase}>
            <img
              className={styles.showcaseImage}
              style={showcaseWidth === null ? undefined : { width: showcaseWidth }}
              src={images[shown]}
              alt=""
              onLoad={(event) => setShowcaseWidth(Math.min(360, event.currentTarget.naturalWidth * 2.5))}
            />
            <div className={styles.showcaseTitle}>{showcase}</div>
          </div>
        ))}
      {many && (
        <IconButton
          label="Next image"
          className={[styles.control, styles.arrow, styles.arrowRight].join(" ")}
          onClick={next}
        >
          <ChevronRight size={28} />
        </IconButton>
      )}
      {many && (
        <div className={styles.strip} role="tablist" aria-label="Images">
          {images.map((src, i) => (
            <button
              key={src}
              type="button"
              role="tab"
              aria-selected={i === shown}
              className={[styles.thumb, i === shown && styles.thumbCurrent].filter(Boolean).join(" ")}
              onClick={() => onSelect(i)}
            >
              <img src={src} alt="" loading="lazy" />
            </button>
          ))}
        </div>
      )}
    </dialog>
  );
}
