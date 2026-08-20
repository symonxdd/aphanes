import 'package:flutter/material.dart';

/// Explains the two numbers shown next to the app version in the About
/// sheet: the semver string (0.1.0) and the build number (1). Opened by
/// tapping that version line.
class VersionExplainerSheet extends StatelessWidget {
  const VersionExplainerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext _) => const VersionExplainerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle sectionTitleStyle =
        theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.w600);
    final TextStyle bodyStyle = theme.textTheme.bodyMedium!;
    final TextStyle triviaStyle = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.outline,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.numbers, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Version numbers, explained',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This app shows two numbers together as its version: '
              '0.1.0 (1). What each one means, and why there are two, '
              'below.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),
            Text('Semantic versioning, the 0.1.0 part', style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(
              'The three numbers separated by dots follow a convention '
              'called semantic versioning, semver for short: '
              'MAJOR.MINOR.PATCH.',
              style: bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'MAJOR increases when something changes in a way that '
              'breaks how the app worked before. MINOR increases when a '
              'new feature arrives without breaking anything existing. '
              'PATCH increases for a small fix that does not change how '
              'the app is used.',
              style: bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'A leading zero, as in this app\'s current 0.1.0, carries a '
              'specific meaning under the semver spec: everything is '
              'still considered unstable, and any part of it may change '
              'at any point, even between small updates. Version 1.0.0 '
              'is meant to mark the first release treated as a stable, '
              'public commitment.',
              style: bodyStyle,
            ),
            const SizedBox(height: 10),
            _Trivia(
              'Semver was written by Tom Preston-Werner, a co-founder of '
              'GitHub, first published a little over a decade ago and '
              'formalized as version 2.0.0 of the spec in 2013. It is '
              'only a convention, not something any tool enforces '
              'automatically; nothing stops a developer from breaking '
              'things in a patch release. npm, the Node.js package '
              'manager, is largely responsible for making semver '
              'mainstream, by baking ranges like ^1.2.3 directly into '
              'how it resolves package dependencies.',
              style: triviaStyle,
            ),
            const SizedBox(height: 20),
            Text('Build number, the (1) part', style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(
              'Right after the version number sits a second, separate '
              'integer: the build number. It exists for a different '
              'reason than the version above it. App stores need a '
              'strict, unambiguous way to tell whether one uploaded '
              'binary is newer than another, even when the human '
              'readable version has not changed at all.',
              style: bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Google Play, for Android, calls this versionCode. '
              'Apple\'s App Store and Mac App Store, for iOS and macOS, '
              'call it CFBundleVersion. Both require it to strictly '
              'increase on every single upload accepted for that app; '
              'an upload gets rejected otherwise. It does not need to '
              'climb by exactly one each time either, any higher '
              'integer works, so jumping from 1 straight to 50 is '
              'perfectly valid.',
              style: bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              'Desktop builds distributed outside of an app store, and '
              'ordinary web apps, are not gated by this at all; nothing '
              'checks the number the way a store does. It only becomes '
              'enforced again for a desktop build distributed through '
              'something like the Microsoft Store or Mac App Store.',
              style: bodyStyle,
            ),
            const SizedBox(height: 10),
            _Trivia(
              'Android\'s versionCode has a hard ceiling of '
              '2,100,000,000, a real limit a handful of very old, '
              'frequently updated apps have run into over the years. '
              'This app is presently on build 1, meaning it has not yet '
              'needed a second upload under its current version name.',
              style: triviaStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _Trivia extends StatelessWidget {
  const _Trivia(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(
            text: 'Trivia. ',
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: text),
        ],
      ),
    );
  }
}
