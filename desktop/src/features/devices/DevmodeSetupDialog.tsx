import { ExternalLink, Info } from "lucide-react";
import { Dialog } from "../../components/Dialog";
import { openInBrowser } from "../../ipc/commands";
import styles from "./DevmodeSetupDialog.module.css";

/** The community's guide, the same page the mobile checklist links to. */
const guideUrl = "https://www.webosbrew.org/devmode/";

const steps = [
  { title: "Create an LG developer account", detail: "If you don't already have one." },
  {
    title: "Install the Developer Mode app",
    detail: 'On the TV: open the LG Content Store, search for "Developer Mode", and install it.',
  },
  {
    title: "Turn on Developer Mode",
    detail:
      "Open the Developer Mode app, sign in with the developer account, and enable Developer Mode. The TV will restart.",
  },
  {
    title: "Turn on the Key Server",
    detail: "Open the Developer Mode app again, confirm Dev Mode Status is on, and enable Key Server.",
  },
];

interface DevmodeSetupDialogProps {
  open: boolean;
  onClose: () => void;
}

/**
 * The mobile "Before pairing" sheet, word for word. Opens on top of the
 * pairing dialog rather than in place of it, so whatever was typed there
 * is still there on the way back.
 */
export function DevmodeSetupDialog({ open, onClose }: DevmodeSetupDialogProps) {
  return (
    <Dialog open={open} onClose={onClose} title="Before pairing" className={styles.dialog}>
      <ol className={styles.steps}>
        {steps.map((step, index) => (
          <li key={step.title} className={styles.step}>
            <span className={styles.number}>{index + 1}.</span>
            <div>
              <div className={styles.stepTitle}>{step.title}</div>
              <div className={styles.stepDetail}>{step.detail}</div>
            </div>
          </li>
        ))}
      </ol>
      <div className={styles.note}>
        <Info size={16} />
        <span>One-time setup. If the session ever expires, after about 1000 hours, only step 3 is needed again.</span>
      </div>
      <button type="button" className={styles.guide} onClick={() => void openInBrowser(guideUrl)}>
        <ExternalLink size={16} />
        <span>Read the full guide</span>
      </button>
    </Dialog>
  );
}
