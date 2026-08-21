import 'package:flutter/material.dart';

/// Explains the Homebrew catalog itself, opened from the (i) action on
/// the catalog browser's app bar: what "homebrew" and "catalog" mean here,
/// where the listing comes from, and whether what's in it is open source.
class CatalogExplainerSheet extends StatelessWidget {
  const CatalogExplainerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext _) => const CatalogExplainerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle sectionTitleStyle = theme.textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w600,
    );
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
                Icon(
                  Icons.storefront_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The Homebrew catalog',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('What "homebrew" means', style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(
              'A plain-language synonym: unofficial, community-made '
              'software. "Homebrew" is the general term for software '
              'built by hobbyists for a device that was never designed '
              "to run it, and that its manufacturer doesn't officially "
              "support. It's used the same way across game consoles, "
              'routers, and plenty of other hardware, not just webOS TVs.',
              style: bodyStyle,
            ),
            const SizedBox(height: 10),
            _Trivia(
              'The term traces back to the Homebrew Computer Club, a '
              'hobbyist group that met in Menlo Park, California '
              'starting in 1975 - Steve Wozniak first showed off an '
              'early Apple computer there.',
              style: triviaStyle,
            ),
            const SizedBox(height: 20),
            Text('What this "catalog" is', style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(
              'Another word for it: a directory, or a listing - a single '
              'place that indexes homebrew apps other developers have '
              'published for webOS TVs. This one is run by the webOS '
              'Homebrew community (webosbrew); this screen reads it '
              'directly from repo.webosbrew.org/api/apps.json, the raw '
              'listing behind repo.webosbrew.org. Like this app itself, '
              'that project is unaffiliated with LG Electronics: '
              'developers submit their own apps to it publicly on '
              'GitHub, nobody at LG reviews or approves what ends up '
              'listed.',
              style: bodyStyle,
            ),
            const SizedBox(height: 20),
            Text('Is everything here open source?', style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(
              'Not guaranteed to be, but in practice, yes so far: every '
              'app currently listed publishes a public source link. The '
              "catalog's own submission format does allow a developer to "
              'mark their app closed-source, so that could change for a '
              "future entry - this app shows a package's source link "
              "(when the developer provided one) on that package's own "
              "details, so it's easy to check per app rather than "
              'assumed for the whole catalog.',
              style: bodyStyle,
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
