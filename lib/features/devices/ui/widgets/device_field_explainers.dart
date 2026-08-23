import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/ui/info_sheet.dart';

/// Plain-language explainers for every field on the device detail page,
/// opened from the small (i) next to each label.
///
/// A field is worth an explainer here when its name alone does not say
/// what it is ("SoC", "OTA ID"), or when knowing what it is changes what
/// someone would do about it (an IP address that can change on its own, a
/// Developer Mode session that expires). Each one says what the value
/// means and whether it matters, and stops there.
///
/// Specifically not where the value came from. These rows sit under a
/// heading that already reads "From the TV", so "read from the TV's
/// system properties" tells a reader nothing they cannot see, and which
/// luna call produced it is not their problem.
///
/// Each sheet reuses the icon of the row it was opened from, so the sheet
/// visibly belongs to the row that produced it.
abstract final class DeviceFieldExplainers {
  static Future<void> ipAddress(BuildContext context) {
    return InfoSheet.show(
      context,
      icon: LucideIcons.network,
      title: 'IP address',
      body:
          'The address used to find the TV on the local '
          'network.\n\n'
          'Most home routers hand these out automatically over DHCP, on '
          'a lease that renews from time to time. When a lease renews, a '
          'TV can come back on a different address than before, which is '
          'the usual reason a TV that worked yesterday stops answering '
          'today.\n\n'
          'The saved pairing key does not depend on the address at all. '
          'If it changes, correcting it here is enough. There is no need '
          "to pair again from the TV's Developer Mode app.",
      // Behind "Read more": this answers how to stop the address moving
      // in the first place, which is a step past what the field itself
      // is, and not everyone opening this wants to go and reconfigure a
      // router about it.
      details:
          'A router can also be told to hand the same address to the same '
          'device every time, which is what a static or reserved IP '
          'does.\n\n'
          "That setting lives in the router's own admin page rather than "
          'on the TV, and hides under a different name on almost every '
          'model: DHCP reservation, address reservation, static lease, or '
          'binding an IP to a MAC address. Doing it there is safer than '
          "typing a fixed address into the TV's own network settings, "
          'which can collide with an address the router later hands out '
          'to something else.\n\n'
          'For exact steps, an AI assistant such as Claude or ChatGPT is '
          'a good shortcut: give it the exact router model and ask how to '
          'reserve an IP address for a device on it.',
    );
  }

  static Future<void> pairedAt(BuildContext context) {
    return InfoSheet.show(context, icon: LucideIcons.calendar, title: 'Paired at', body: "When the TV's pairing key was retrieved and saved on this phone.");
  }

  static Future<void> model(BuildContext context) {
    return InfoSheet.show(
      context,
      icon: LucideIcons.tv,
      title: 'Model',
      body:
          "The TV's model name.\n\n"
          'Usually matches the model printed on the box or shown in the '
          "TV's own settings, though it can carry extra suffixes for the "
          'panel type, the region it was sold in, or the production run.',
    );
  }

  static Future<void> firmware(BuildContext context) {
    return InfoSheet.show(
      context,
      icon: LucideIcons.cpu,
      title: 'Firmware',
      body:
          "The version of the TV's own system software.\n\n"
          'LG numbers firmware per model, so two TVs running the same '
          'webOS release can still show different versions here. The '
          'number on its own is only meaningful next to others for the '
          'same model.\n\n'
          'Firmware is updated by the TV itself, from its own settings. '
          'This app never installs or changes it.',
    );
  }

  static Future<void> webosVersion(BuildContext context) {
    return InfoSheet.show(
      context,
      icon: LucideIcons.tv,
      title: 'webOS version',
      body:
          "The release of webOS, LG's smart TV platform, that the "
          'firmware is built on.\n\n'
          'This is the number that decides what a TV can actually run. '
          'Homebrew apps are often written against a minimum webOS '
          'release. A TV usually keeps the release it shipped with, so '
          'this rarely moves, though LG has offered version upgrades to '
          'some newer sets.',
    );
  }

  static Future<void> soc(BuildContext context) {
    return InfoSheet.show(
      context,
      icon: LucideIcons.microchip,
      title: 'SoC',
      body:
          'SoC is short for system on a chip: one piece of silicon '
          'carrying the processor, graphics, memory controller, video '
          'decoders and I/O that would otherwise be spread across '
          'several separate chips on a board.\n\n'
          'Every webOS TV is built around one, and it is the main thing '
          "deciding how quickly the TV's interface and apps run. It is "
          'also why an older TV can feel slow while still receiving '
          'firmware updates: the software moves on, the chip does not.',
    );
  }

  static Future<void> otaId(BuildContext context) {
    return InfoSheet.show(
      context,
      icon: LucideIcons.hash,
      title: 'OTA ID',
      body:
          'OTA stands for over the air: firmware delivered to the TV '
          'over the internet rather than from a USB stick. The OTA ID '
          'appears to be how LG tells one firmware target from another, '
          'though LG does not document what it is used for.\n\n'
          'It is more specific than the model name, and TVs sold in '
          'different regions can carry different OTA IDs, so it is a '
          'useful string to search for when looking up firmware or '
          'checking whether something built by the homebrew community '
          'targets this exact variant.',
    );
  }

  static Future<void> developerMode(BuildContext context) {
    return InfoSheet.show(
      context,
      icon: LucideIcons.shieldCheck,
      title: 'Developer Mode',
      body:
          "Developer Mode is LG's own switch for letting a TV run "
          'software that did not come from the LG Content Store. It is '
          'what makes everything else in this app possible.\n\n'
          'Sessions are deliberately temporary. Once one lapses the TV '
          'stops accepting developer connections until it is renewed, and '
          'apps installed through Developer Mode are removed with it. '
          'Renewing does not mean pairing again: it asks the TV to open '
          'its own Developer Mode app with an extend flag, which is the '
          'same thing as reopening that app on the TV by hand. Expect '
          'that app to appear on the TV screen when the button is '
          'used.\n\n'
          'The webOS Homebrew project documents an overall limit of 1000 '
          'hours on Developer Mode, with the timer resettable from the '
          'Developer Mode app on the TV.\n\n'
          'How much time is left cannot be worked out locally. The figure '
          "shown on this page is whatever LG's own session endpoint "
          'reports; this app does not calculate or count it down itself.',
    );
  }
}
