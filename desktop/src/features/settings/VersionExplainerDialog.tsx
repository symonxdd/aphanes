import { Dialog } from "../../components/Dialog";
import styles from "../apps/CatalogExplainerDialog.module.css";

interface VersionExplainerDialogProps {
  open: boolean;
  version: string | null;
  onClose: () => void;
}

/**
 * The mobile version explainer, opened from the version line in About.
 * The semver section is word for word; the build number section is
 * reworked, because a desktop build carries no build number, which is
 * itself the point the mobile text makes about desktop builds.
 */
export function VersionExplainerDialog({ open, version, onClose }: VersionExplainerDialogProps) {
  const shown = version ?? "0.1.0";
  const preOne = shown.startsWith("0.");
  return (
    <Dialog open={open} onClose={onClose} title="Version numbers, explained" className={styles.dialog}>
      <p className={styles.paragraph}>
        This app shows its version as a single number: {shown}. What it means, and why the mobile app shows a second
        number next to it, below.
      </p>

      <h3 className={styles.sectionTitle}>Semantic versioning, the {shown} part</h3>
      <p className={styles.paragraph}>
        The three numbers separated by dots follow a convention called semantic versioning, semver for short:
        MAJOR.MINOR.PATCH.
      </p>
      <p className={styles.paragraph}>
        MAJOR increases when something changes in a way that breaks how the app worked before. MINOR increases when a
        new feature arrives without breaking anything existing. PATCH increases for a small fix that does not change how
        the app is used.
      </p>
      <p className={styles.paragraph}>
        {preOne
          ? `A leading zero, as in this app's current ${shown}, carries a specific meaning under the semver spec: everything is still considered unstable, and any part of it may change at any point, even between small updates. Version 1.0.0 is meant to mark the first release treated as a stable, public commitment.`
          : `A leading zero carries a specific meaning under the semver spec: everything is still considered unstable, and any part of it may change at any point, even between small updates. Version 1.0.0 marks the first release treated as a stable, public commitment, which this app, at ${shown}, has passed.`}
      </p>
      <p className={styles.trivia}>
        <strong>Trivia.</strong> Semver was written by Tom Preston-Werner, a co-founder of GitHub, first published a
        little over a decade ago and formalized as version 2.0.0 of the spec in 2013. It is only a convention, not
        something any tool enforces automatically; nothing stops a developer from breaking things in a patch release.
        npm, the Node.js package manager, is largely responsible for making semver mainstream, by baking ranges like
        ^1.2.3 directly into how it resolves package dependencies.
      </p>

      <h3 className={styles.sectionTitle}>The build number, and why there is none here</h3>
      <p className={styles.paragraph}>
        On the phone, right after the version number sits a second, separate integer: the build number. It exists for a
        different reason than the version above it. App stores need a strict, unambiguous way to tell whether one
        uploaded binary is newer than another, even when the human readable version has not changed at all.
      </p>
      <p className={styles.paragraph}>
        Google Play, for Android, calls this versionCode. Apple's App Store and Mac App Store, for iOS and macOS, call
        it CFBundleVersion. Both require it to strictly increase on every single upload accepted for that app; an upload
        gets rejected otherwise. It does not need to climb by exactly one each time either, any higher integer works, so
        jumping from 1 straight to 50 is perfectly valid.
      </p>
      <p className={styles.paragraph}>
        Desktop builds distributed outside of an app store, and ordinary web apps, are not gated by this at all; nothing
        checks the number the way a store does. It only becomes enforced again for a desktop build distributed through
        something like the Microsoft Store or Mac App Store. This build comes from the project's GitHub page, so it
        carries the version alone.
      </p>
      <p className={styles.trivia}>
        <strong>Trivia.</strong> Android's versionCode has a hard ceiling of 2,100,000,000, a real limit a handful of
        very old, frequently updated apps have run into over the years.
      </p>
    </Dialog>
  );
}
