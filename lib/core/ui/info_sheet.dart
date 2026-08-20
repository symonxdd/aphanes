import 'package:flutter/material.dart';

/// A small "what does this mean" explainer, opened from an (i) icon next
/// to a field or concept. Same shell every screen uses for these:
/// icon + title row, then a plain-language body.
class InfoSheet extends StatelessWidget {
  const InfoSheet({
    required this.icon,
    required this.title,
    required this.body,
    this.trailingLinkLabel,
    this.onTrailingLinkTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  // An optional "read more" link below the body, for cases where a fuller
  // page covers the same topic in much greater depth than a bottom sheet
  // comfortably can.
  final String? trailingLinkLabel;
  final VoidCallback? onTrailingLinkTap;

  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    String? trailingLinkLabel,
    VoidCallback? onTrailingLinkTap,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext _) => InfoSheet(
        icon: icon,
        title: title,
        body: body,
        trailingLinkLabel: trailingLinkLabel,
        onTrailingLinkTap: onTrailingLinkTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // A couple pixels up: centering the icon's own box against
                // titleLarge's taller line-height box isn't the same as
                // centering against the title text's actual glyph ink,
                // which sits a bit higher in its box - box-centering alone
                // reads as the icon sitting slightly low next to the title.
                Transform.translate(
                  offset: const Offset(0, -2),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: theme.textTheme.bodyMedium),
            if (trailingLinkLabel != null && onTrailingLinkTap != null) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: onTrailingLinkTap,
                  child: Text(trailingLinkLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
