import { Calendar, Contrast, Cpu, Hash, IdCard, Microchip, Network, ShieldCheck, Tv } from "lucide-react";
import type { Explainer } from "../../components/InfoPopover";

/**
 * The device field explainers, copied from the mobile app's
 * device_field_explainers.dart and devmode_explainers.dart. The prose is
 * the same word for word, except that the one line naming the device the
 * app runs on says computer instead of phone.
 */
export const ipAddress: Explainer = {
  icon: <Network size={22} />,
  title: "IP address",
  body:
    "The address used to find the TV on the local network.\n\n" +
    "Most home routers hand these out automatically over DHCP, on a lease that renews from time to time. " +
    "When a lease renews, a TV can come back on a different address than before, which is the usual reason " +
    "a TV that worked yesterday stops answering today.\n\n" +
    "The saved pairing key does not depend on the address at all. If it changes, correcting it here is enough. " +
    "There is no need to pair again from the TV's Developer Mode app.",
  details:
    "A router can also be told to hand the same address to the same device every time, which is what a static " +
    "or reserved IP does.\n\n" +
    "That setting lives in the router's own admin page rather than on the TV, and hides under a different name " +
    "on almost every model: DHCP reservation, address reservation, static lease, or binding an IP to a MAC " +
    "address. Doing it there is safer than typing a fixed address into the TV's own network settings, which " +
    "can collide with an address the router later hands out to something else.\n\n" +
    "For exact steps, an AI assistant such as Claude or ChatGPT is a good shortcut: give it the exact router " +
    "model and ask how to reserve an IP address for a device on it.",
};

export const pairedAt: Explainer = {
  icon: <Calendar size={22} />,
  title: "Paired at",
  body: "When the TV's pairing key was retrieved and saved on this computer.",
};

export function connectedAs(username: string): Explainer {
  return {
    icon: <IdCard size={22} />,
    title: `Why "${username}"?`,
    body:
      "An SSH connection is a login, not a one-off request, so it always has to say which account it's " +
      "logging into. That account decides what is allowed once connected.\n\n" +
      '"prisoner" is a built-in account present on every webOS TV\'s Developer Mode, not something created ' +
      "during pairing - it's the same fixed username on any paired TV. It's a special, sandboxed account with " +
      "only the access Developer Mode is meant to have, rather than full control of the TV.",
  };
}

export const model: Explainer = {
  icon: <Tv size={22} />,
  title: "Model",
  body:
    "The TV's model name.\n\n" +
    "Usually matches the model printed on the box or shown in the TV's own settings, though it can carry " +
    "extra suffixes for the panel type, the region it was sold in, or the production run.",
};

export const firmware: Explainer = {
  icon: <Cpu size={22} />,
  title: "Firmware",
  body:
    "The version of the TV's own system software.\n\n" +
    "LG numbers firmware per model, so two TVs running the same webOS release can still show different " +
    "versions here. The number on its own is only meaningful next to others for the same model.\n\n" +
    "Firmware is updated by the TV itself, from its own settings. This app never installs or changes it.",
};

export const webosVersion: Explainer = {
  icon: <Tv size={22} />,
  title: "webOS version",
  body:
    "The release of webOS, LG's smart TV platform, that the firmware is built on.\n\n" +
    "This is the number that decides what a TV can actually run. Homebrew apps are often written against a " +
    "minimum webOS release. A TV usually keeps the release it shipped with, so this rarely moves, though LG " +
    "has offered version upgrades to some newer sets.",
};

export const soc: Explainer = {
  icon: <Microchip size={22} />,
  title: "SoC",
  body:
    "SoC is short for system on a chip: one piece of silicon carrying the processor, graphics, memory " +
    "controller, video decoders and I/O that would otherwise be spread across several separate chips on a " +
    "board.\n\n" +
    "Every webOS TV is built around one, and it is the main thing deciding how quickly the TV's interface and " +
    "apps run. It is also why an older TV can feel slow while still receiving firmware updates: the software " +
    "moves on, the chip does not.",
};

export const otaId: Explainer = {
  icon: <Hash size={22} />,
  title: "OTA ID",
  body:
    "OTA stands for over the air: firmware delivered to the TV over the internet rather than from a USB " +
    "stick. The OTA ID appears to be how LG tells one firmware target from another, though LG does not " +
    "document what it is used for.\n\n" +
    "It is more specific than the model name, and TVs sold in different regions can carry different OTA IDs, " +
    "so it is a useful string to search for when looking up firmware or checking whether something built by " +
    "the homebrew community targets this exact variant.",
};

export const developerMode: Explainer = {
  icon: <ShieldCheck size={22} />,
  title: "Developer Mode",
  body:
    "Developer Mode is LG's own switch for letting a TV run software that did not come from the LG Content " +
    "Store. It is what makes everything else in this app possible.\n\n" +
    "Sessions are deliberately temporary. Once one lapses the TV stops accepting developer connections until " +
    "it is renewed, and apps installed through Developer Mode are removed with it. Renewing does not mean " +
    "pairing again: it asks the TV to open its own Developer Mode app with an extend flag, which is the same " +
    "thing as reopening that app on the TV by hand. Expect that app to appear on the TV screen when the " +
    "button is used.\n\n" +
    "The webOS Homebrew project documents an overall limit of 1000 hours on Developer Mode, with the timer " +
    "resettable from the Developer Mode app on the TV.\n\n" +
    "How much time is left cannot be worked out locally. The figure shown on this page is whatever LG's own " +
    "session endpoint reports; this app does not calculate or count it down itself.",
};

/** From settings_sheet.dart, the (i) beside the OLED toggle. */
export const oledTheme: Explainer = {
  icon: <Contrast size={22} />,
  title: "OLED theme",
  body:
    "Replaces dark mode's usual dark grey with pure black across every surface. On OLED and AMOLED screens, " +
    "black pixels are turned off entirely, so this can noticeably extend battery life alongside a cleaner, " +
    "higher-contrast look.\n\n" +
    "Has no effect while the app is in light mode.",
};
