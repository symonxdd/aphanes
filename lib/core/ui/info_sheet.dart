import 'package:flutter/material.dart';

/// A small "what does this mean" explainer, opened from an (i) icon next
/// to a field or concept. Same shell every screen uses for these:
/// icon + title row, then a plain-language body.
class InfoSheet extends StatefulWidget {
  const InfoSheet({
    required this.icon,
    required this.title,
    required this.body,
    this.details,
    this.trailingLinkLabel,
    this.onTrailingLinkTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  /// A second, longer half of the explanation, hidden behind a "Read
  /// more" toggle so the sheet opens at the length someone actually
  /// wanted rather than at the length it is capable of.
  ///
  /// For the part that answers "and what should be done about it" once
  /// [body] has already answered "what is this". Someone who only wanted
  /// the definition is done before this ever unfolds.
  final String? details;

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
    String? details,
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
        details: details,
        trailingLinkLabel: trailingLinkLabel,
        onTrailingLinkTap: onTrailingLinkTap,
      ),
    );
  }

  @override
  State<InfoSheet> createState() => _InfoSheetState();
}

class _InfoSheetState extends State<InfoSheet>
    with SingleTickerProviderStateMixin {
  // Same mechanism, timing and curve as _EditHostSheet's own "Read more",
  // so the two behave identically wherever a reader meets them.
  //
  // Built in initState rather than as a `late final` field initializer,
  // which would be lazy. Most sheets have no `details` at all, so their
  // build never touches this, and dispose would then be the first thing
  // to read it - constructing an AnimationController while the element is
  // already deactivated, which throws when createTicker goes looking for
  // a TickerMode ancestor. _EditHostSheet gets away with the lazy form
  // only because its own build always references its controller.
  late final AnimationController _detailsController;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _detailsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _toggleDetails() {
    setState(() => _showDetails = !_showDetails);
    if (_showDetails) {
      _detailsController.forward();
    } else {
      _detailsController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? details = widget.details;
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
                  child: Icon(widget.icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(widget.body, style: theme.textTheme.bodyMedium),
            if (details != null) ...[
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _toggleDetails,
                  child: Text(_showDetails ? 'Collapse' : 'Read more'),
                ),
              ),
              const SizedBox(height: 4),
              SizeTransition(
                sizeFactor: CurvedAnimation(
                  parent: _detailsController,
                  curve: Curves.easeInOut,
                ),
                alignment: Alignment.topLeft,
                child: FadeTransition(
                  opacity: _detailsController,
                  child: Text(details, style: theme.textTheme.bodyMedium),
                ),
              ),
            ],
            if (widget.trailingLinkLabel != null &&
                widget.onTrailingLinkTap != null) ...[
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: widget.onTrailingLinkTap,
                  child: Text(widget.trailingLinkLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
