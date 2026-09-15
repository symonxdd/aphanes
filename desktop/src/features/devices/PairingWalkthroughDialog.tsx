import type { ReactNode } from "react";
import { Dialog } from "../../components/Dialog";
import styles from "./PairingWalkthroughDialog.module.css";

interface PairingWalkthroughDialogProps {
  open: boolean;
  onClose: () => void;
}

/**
 * The mobile pairing deep-dive page, word for word except that the two
 * mentions of the device the app runs on say computer instead of phone.
 * Opened from the (i) on the pairing dialog, in the same frame as the
 * catalog explainer.
 */
export function PairingWalkthroughDialog({ open, onClose }: PairingWalkthroughDialogProps) {
  return (
    <Dialog open={open} onClose={onClose} title="How pairing works" className={styles.dialog}>
      <p className={styles.paragraph}>
        Developer Mode is a special account-locked state built into webOS TVs, meant for installing and testing
        unofficial ("homebrew") apps. Turning it on exposes two small local services on the TV: a Key Server, and an SSH
        (Secure Shell) server. Pairing is the process of using those two together, once, to get a permanent, secure way
        to control the TV from this app.
      </p>

      <Step number="1" title="Finding the Key Server">
        <p className={styles.paragraph}>
          Tapping Pair first sends a small request to the IP address entered, on a fixed network port (9991) that the
          TV's Key Server listens on. A port is just a numbered channel a device can be reached on; a TV can run several
          independent services at once, each on its own port, the way an apartment building routes mail by unit number
          rather than address alone.
        </p>
        <p className={styles.paragraph}>
          This request uses plain HTTP, the same protocol a web browser uses to load a page, and is not authenticated:
          anything on the same network could ask the Key Server for this, which is why it is only meant to be left on
          briefly, during pairing.
        </p>
        <p className={styles.paragraph}>
          Developer Mode's own screen on the TV shows two address fields, one for a wired (Ethernet) connection and one
          for wireless (Wi-Fi); a TV connected both ways at once can show both filled in. Either works exactly the same,
          since both are just different network paths to the same TV - whichever one is actually reachable, matching
          however the TV is connected, is the one to use.
        </p>
      </Step>

      <Step number="2" title="Fetching the encrypted key">
        <p className={styles.paragraph}>
          The Key Server responds with a private key: the credential that will eventually let this app log into the TV
          directly, without a password prompt every time. It is sent in PEM format, a common plain-text encoding for
          cryptographic keys, and it arrives encrypted, meaning it is scrambled into unusable data unless unlocked with
          the right passphrase.
        </p>
      </Step>

      <Step number="3" title="Unlocking the key, on this computer only">
        <p className={styles.paragraph}>
          The passphrase shown in the Developer Mode app on the TV is typed in, and used to decrypt that key, but
          entirely on this computer: the passphrase itself is never sent anywhere over the network. It is only ever used
          locally, as the input to a decryption calculation that either produces a usable key or fails.
        </p>
        <p className={styles.paragraph}>
          Unlike a one-time code, this passphrase is fixed for a given TV: it is derived from the TV's own unique
          hardware identifier, so it will read the same every time Developer Mode's Key Server screen is opened, on that
          same TV. That is also why the passphrase field can be checked instantly while typing, without waiting on the
          network: the app already has the encrypted key cached locally by this point, so trying a passphrase against it
          is a calculation done entirely on this computer.
        </p>
      </Step>

      <Step number="4" title="Connecting over SSH">
        <p className={styles.paragraph}>
          With the key decrypted, the app opens a second connection to the TV, this time over SSH, on a different fixed
          port (9922). SSH (Secure Shell) is an encrypted, authenticated way to control another device's command line
          directly, rather than just fetching or sending data the way HTTP does; it is the same technology system
          administrators use to manage remote servers.
        </p>
        <p className={styles.paragraph}>
          This connection logs in as a dedicated account named "prisoner": a sandboxed account Developer Mode creates
          for exactly this purpose, with only the access installing apps, browsing files, and running commands actually
          needs, rather than full control of the TV's own operating system.
        </p>
      </Step>

      <Step number="5" title="Saving the result">
        <p className={styles.paragraph}>
          Once the SSH connection succeeds, the decrypted private key is what actually gets saved, in this computer's
          secure platform storage, alongside the TV's address and the device name given at the end of pairing. Every
          later action against that TV, installing an app, browsing a file, opening a terminal, reuses this saved key to
          open a fresh SSH connection directly. Developer Mode and the Key Server do not need to be turned on again for
          any of that.
        </p>
      </Step>

      <p className={styles.closing}>
        That saved key is what SFTP (SSH File Transfer Protocol) and the terminal both build on: SFTP is a file-browsing
        and transfer protocol layered on top of the same SSH connection used for pairing, and the in-app terminal is
        that same connection used to run commands directly instead.
      </p>
    </Dialog>
  );
}

function Step({ number, title, children }: { number: string; title: string; children: ReactNode }) {
  return (
    <section className={styles.step}>
      <div className={styles.stepHeader}>
        <span className={styles.stepNumber}>{number}</span>
        <h3 className={styles.stepTitle}>{title}</h3>
      </div>
      <div className={styles.stepBody}>{children}</div>
    </section>
  );
}
