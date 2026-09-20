import { CirclePlay, Fingerprint } from "lucide-react";
import type { Explainer } from "../../components/InfoPopover";

/** Beside "Running on the TV": what the TV does and does not say. */
export const running: Explainer = {
  icon: <CirclePlay size={22} />,
  title: "Running on the TV",
  body:
    "The TV shows this app as currently active, but it doesn't specify whether it's running in the background " +
    "or displayed on the screen.",
};

/** What the ID beside it is. */
export const appId: Explainer = {
  icon: <Fingerprint size={22} />,
  title: "App ID",
  body:
    "The name webOS knows the app by.\n\n" +
    "Launching, listing and removing an app all happen by this ID, and it is what matches an app on the TV to " +
    "its entry in the Homebrew catalog.",
};
