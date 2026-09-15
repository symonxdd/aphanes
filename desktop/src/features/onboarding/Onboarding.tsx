import { useState, type ReactNode } from "react";
import { LayoutGrid, RefreshCw, Tv } from "lucide-react";
import { AppMark } from "../../components/AppMark";
import { Button } from "../../components/Button";
import styles from "./Onboarding.module.css";

interface OnboardingProps {
  onDone: () => void;
}

/**
 * The first-run screen, laid out as the mobile onboarding page is: the
 * mark and name at the top, the pitch (tagline, three feature rows, and
 * the price promise) centered a little above the middle, and the one
 * button at the bottom with the disclaimer beneath it. The disclaimer and
 * the free-forever line are the two things this screen exists to show, so
 * they stay however the layout changes.
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
        {/* Three rows instead of one sentence: scanned rather than parsed,
            and the YouTube line gets to be its own item. Left-aligned in a
            narrow centered column, since a list wants a left edge and the
            tagline above has none. The icons are the ones those screens
            already use. */}
        <ul className={styles.features}>
          <FeatureRow icon={<LayoutGrid size={18} />}>
            Install apps, including the one that makes YouTube ad free
          </FeatureRow>
          <FeatureRow icon={<Tv size={18} />}>Check the TV's details</FeatureRow>
          <FeatureRow icon={<RefreshCw size={18} />}>Renew the Developer Mode session</FeatureRow>
        </ul>
        {/* The price line is a public commitment the README and project
            site also make, and this is the one place every user reads it.
            It closes the pitch, so it sits with the pitch. */}
        <div className={styles.promise}>No ads, no tracking, and free forever.</div>
      </div>
      <div className={styles.bottom}>
        <Button variant="filled" className={styles.cta} onClick={() => setLeaving(true)} autoFocus>
          Got it, boss
        </Button>
        {/* Legal text goes where legal text goes: under the button, as the
            quietest thing on the screen. */}
        <div className={styles.disclaimer}>
          Unaffiliated with LG Electronics Inc. or the webOS Open Source Edition project.
        </div>
      </div>
    </div>
  );
}

function FeatureRow({ icon, children }: { icon: ReactNode; children: ReactNode }) {
  return (
    <li className={styles.feature}>
      <span className={styles.featureIcon}>{icon}</span>
      <span>{children}</span>
    </li>
  );
}
