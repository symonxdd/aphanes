import {
  Calendar,
  Contrast,
  Cpu,
  Fingerprint,
  Hash,
  IdCard,
  KeyRound,
  LockKeyhole,
  Microchip,
  Network,
  ShieldCheck,
  Tv,
} from "lucide-react";
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
    "Sessions are deliberately temporary. LG gives no reason, but Developer Mode exists for testing apps rather " +
    "than keeping them installed for good, and the timer is what enforces that. Once a session expires the TV " +
    "stops accepting developer connections until it is renewed, and apps installed through Developer Mode are " +
    "removed with it. Only Developer Mode itself has to be switched on again on the TV; the account, the app " +
    "and this app's pairing all survive. Renewing does not mean " +
    "pairing again: it asks the TV to open its own Developer Mode app with an extend flag, which is the same " +
    "thing as reopening that app on the TV by hand. Expect that app to appear on the TV screen when the " +
    "button is used.\n\n" +
    "The webOS Homebrew project documents an overall limit of 1000 hours on Developer Mode, with the timer " +
    "resettable from the Developer Mode app on the TV.\n\n" +
    "How much time is left cannot be worked out locally. The figure shown on this page is whatever LG's own " +
    "session endpoint reports; this app does not calculate or count it down itself.",
};

/** Desktop only for now: the (i) beside the pairing key row. */
export const pairingKey: Explainer = {
  icon: <KeyRound size={22} />,
  title: "Pairing key",
  body:
    "The credential this app presents to the TV every time it connects. Pairing fetched it once from the TV's " +
    "key server, unlocked it locally with the passphrase shown on the TV screen, and saved the unlocked key " +
    "in this computer's own credential store. The passphrase itself is not kept: it was only needed to unlock " +
    "the key, and has no use afterwards.\n\n" +
    "From then on, every action on this TV (listing apps, installing, uninstalling, reading device details) " +
    'starts by logging in to the TV\'s SSH server on port 9922 as the built-in "prisoner" account, using this ' +
    "key as proof of identity. It plays the role a password would, which is also the reason to treat it like " +
    "one.\n\n" +
    "Revealing it here reads it from the credential store at that moment and shows it on screen for a short " +
    "while. Nothing about it is written to a file or sent anywhere.",
  details:
    "What someone with a copy could do: log in to this TV the same way this app does, from any device on the " +
    "same network, and do everything this app can, plus anything else that account is allowed to run on the " +
    'TV. "prisoner" is a sandboxed account rather than full control of the TV, so that means installing and ' +
    "removing homebrew apps and running commands with that account's permissions, not the TV's own settings " +
    "or any LG account.\n\n" +
    "What they would need besides the key: a network path to the TV, so a device on the same home network " +
    "(or a router deliberately set up to forward port 9922, which no router does by default), and Developer " +
    "Mode still enabled on the TV with its session not lapsed. No physical access to the TV is needed once " +
    "someone has the key. Without the key, they would need to read the passphrase off the TV screen and " +
    "have the key server on, which does take being in front of it.\n\n" +
    "Revoking it: the TV has no button for that. It generates the key once, the first time Developer Mode " +
    "is enabled, and derives the passphrase from its own device ID, so both stay the same across reboots " +
    "and across turning Developer Mode off and on again. Only a factory reset produces a new key. Turning " +
    "Developer Mode off does stop the TV's SSH server, which makes any copy of the key useless until it is " +
    "on again. Removing the device here deletes the copy on this computer but changes nothing on the TV.\n\n" +
    "In practice: a copy is fine to keep as a backup or to use with a regular SSH client " +
    "(ssh -i <file> -p 9922 prisoner@<ip>), as long as it is kept the way a password would be. The clipboard " +
    "can be read by other apps, so paste it where it is going and move on.",
};

/** Desktop only for now: the (i) beside the passphrase row. */
export const passphrase: Explainer = {
  icon: <LockKeyhole size={22} />,
  title: "Passphrase",
  body:
    "The six characters the Developer Mode app shows in its bottom-left corner, typed in once at pairing time. " +
    "It unlocked the encrypted key the TV's key server handed over; the app then kept the unlocked key and has " +
    "had no use for the passphrase since. It is kept in this computer's credential store only so it can be shown " +
    "here.\n\n" +
    "It is not a fresh code each time. The Developer Mode app builds it from the TV's own device ID (the first " +
    "six characters of the NDUID, in capitals), so it reads the same every time that app is opened, survives " +
    "reboots and turning Developer Mode off and on, and only changes with a factory reset.",
  details:
    "On its own it is nearly harmless: it only unlocks the encrypted key, and getting that key means being on " +
    "the same network as the TV with the key server switched on in the Developer Mode app. Anyone in that " +
    "position can read the passphrase off the TV screen anyway. Where it does matter is next to a copy of the " +
    "encrypted key, or with the command-line tools (ares-setup-device asks for both), and because it doubles as " +
    "the start of the TV's device ID.\n\n" +
    "Where this comes from: LG's webOS Open Source Edition publishes the Developer Mode service, and its " +
    "getPassphrase call returns the first six characters of the NDUID. The script the TV's own Developer Mode " +
    "app runs at startup does the same when it creates the key.",
};

/**
 * Ready for the NDUID row, which arrives with the SSH module: the details
 * page cannot ask the TV for anything until that exists.
 */
export const nduid: Explainer = {
  icon: <Fingerprint size={22} />,
  title: "NDUID",
  body:
    "The TV's device identifier at the operating system level: 40 hexadecimal characters, fixed for the life " +
    "of the TV. The name is short for Nyx Device Unique ID, after Nyx, the layer of webOS that answers " +
    "questions about the hardware it runs on.\n\n" +
    "Its first six characters, in capitals, are the Developer Mode passphrase.",
  details:
    "It is one of the identifiers a webOS TV carries, next to the serial number and the network addresses, " +
    "and like those it is worth keeping out of public posts and screenshots: it names this exact TV, and " +
    "the passphrase can be read straight off it.\n\n" +
    "It is not the same thing as the LGUDID that apps from the LG Content Store are given, which is derived " +
    "from a network address and a random number and is the identifier LG documents publicly.",
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
