import { useState } from "react";
import { AppMark } from "../../components/AppMark";
import { Button } from "../../components/Button";
import styles from "./Onboarding.module.css";

interface OnboardingProps {
  onDone: () => void;
}

/**
 * The first-run screen, with the mobile onboarding page's prose word for
 * word: the mark and name at the top, the tagline centred on the full
 * height, and the two footnotes above the one button at the bottom. The
 * disclaimer and the free-forever line are the two things this screen
 * exists to show, so they stay however the layout changes.
 */
export function Onboarding({ onDone }: OnboardingProps) {
  const [leaving, setLeaving] = useState(false);

  return (
    <div
      className={[styles.screen, leaving && styles.leaving].filter(Boolean).join(" ")}
      onAnimationEnd={(event) => {
        if (leaving && event.target === event.currentTarget) {
          onDone();
        }
      }}
    >
      <div className={styles.top}>
        <AppMark width={96} />
        <div className={styles.title}>Aphanes</div>
      </div>
      <div className={styles.middle}>
        <div className={styles.tagline}>Manage your webOS TV's Developer Mode.</div>
        <div className={styles.subline}>
          Install apps, check the TV's details, and renew the Developer Mode session.
        </div>
      </div>
      <div className={styles.bottom}>
        <div className={styles.footnote}>No ads. No tracking. Free, forever.</div>
        <div className={styles.footnote}>
          Unaffiliated with LG Electronics Inc. or the webOS Open Source Edition project.
        </div>
        <Button variant="filled" className={styles.cta} onClick={() => setLeaving(true)} autoFocus>
          Got it, boss
        </Button>
      </div>
    </div>
  );
}
