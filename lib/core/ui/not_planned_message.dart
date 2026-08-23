import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../project_links.dart';

/// The shared placeholder for a tab that is deliberately not built yet
/// (Files, Terminal). One wording and one styling for that state, plus
/// the one thing that actually moves it forward: a link straight to the
/// project's issue tracker.
///
/// "Open an issue" is the linked phrase rather than the whole sentence -
/// it is the part that names an action, so it is the part a reader
/// reaches for. It carries a color change, an underline, and a trailing
/// external-link glyph, so the affordance never rests on color alone.
class NotPlannedMessage extends StatefulWidget {
  const NotPlannedMessage({super.key});

  @override
  State<NotPlannedMessage> createState() => _NotPlannedMessageState();
}

class _NotPlannedMessageState extends State<NotPlannedMessage> {
  late final TapGestureRecognizer _openIssues = TapGestureRecognizer()
    ..onTap = _handleTap;

  @override
  void dispose() {
    _openIssues.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    bool opened;
    try {
      opened = await launchUrl(
        Uri.parse(ProjectLinks.issues),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    // A tap that silently does nothing (no browser installed, or the
    // platform refusing the intent) reads as a broken link. Falling back
    // to showing the address at least leaves something to act on.
    if (opened || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Couldn't open a browser. ${ProjectLinks.issues}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? bodyStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Not currently planned, but don't hesitate to ask!",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                style: bodyStyle,
                children: [
                  TextSpan(
                    text: 'Open an issue',
                    style: bodyStyle?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: theme.colorScheme.primary.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    recognizer: _openIssues,
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      // Wider on the right than the left: the glyph
                      // follows the link text it belongs to and then has
                      // to clear the word starting the rest of the
                      // sentence, which a symmetric gap left it hugging.
                      padding: const EdgeInsets.only(left: 4, right: 6),
                      child: Icon(
                        LucideIcons.externalLink,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const TextSpan(
                    text: "in the project's GitHub repository, and I'd be "
                        'happy to consider adding it.',
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
