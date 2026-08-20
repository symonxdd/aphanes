import 'package:flutter/material.dart';

import '../../../../core/ui/info_sheet.dart';
import '../pairing_deep_dive_page.dart';

Future<void> showConnectionInfoSheet(BuildContext context) async {
  await InfoSheet.show(
    context,
    icon: Icons.lock_outline,
    title: 'How it works',
    body:
        'SSH is a secure, encrypted way to control another device\'s '
        'command line directly, not just fetch or send data the way HTTP '
        'does. It\'s what lets this app install apps, browse files, and '
        'open a terminal on the TV.\n\n'
        'Pairing trades the TV\'s on-screen passphrase (fixed per TV) for '
        'a permanent secure key.\n\n'
        'Once paired, installing apps, browsing files, and opening a '
        'terminal all use the saved key directly, with no need to open '
        'the Developer Mode app or turn on Key Server again.',
    trailingLinkLabel: 'Read the full walkthrough',
    onTrailingLinkTap: () {
      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext _) => const PairingDeepDivePage(),
          ),
        );
      }
    },
  );
}

Future<void> showUsernameInfoSheet(BuildContext context, String username) {
  return InfoSheet.show(
    context,
    icon: Icons.badge_outlined,
    title: 'Why "$username"?',
    body:
        'An SSH connection is a login, not a one-off request, so it '
        'always has to say which account it\'s logging into. That '
        'account decides what is allowed once connected.\n\n'
        '"prisoner" is a built-in account present on every webOS TV\'s '
        'Developer Mode, not something created during pairing - it\'s '
        'the same fixed username on any paired TV. It\'s a special, '
        'sandboxed account with only the access Developer Mode is meant '
        'to have, rather than full control of the TV.',
  );
}
