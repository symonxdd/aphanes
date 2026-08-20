import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'info_sheet.dart';

/// The word "Aphanes", the project's internal codename, with a quiet easter
/// egg: a tap smoothly flips the letters into reverse order and back (each
/// glyph sliding through the others, pausing briefly at the mirrored
/// extreme). Ported from Rivus's `RivusTitle`.
///
/// Takes its text style from the ambient [DefaultTextStyle], the same way a
/// plain [Text] would, so it drops into any context - wrap it in a
/// [DefaultTextStyle] first if the surrounding one isn't already the style
/// wanted.
class AphanesTitle extends StatefulWidget {
  const AphanesTitle({super.key});

  @override
  State<AphanesTitle> createState() => _AphanesTitleState();
}

class _AphanesTitleState extends State<AphanesTitle>
    with SingleTickerProviderStateMixin {
  static const String _word = 'Aphanes';

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  // Drives the letters from their normal order (0) to fully reversed (1) and
  // back, holding at the reversed extreme so the flip registers as a state
  // the eye can read rather than an instant bounce.
  late final Animation<double> _t =
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 0,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 34,
        ),
        TweenSequenceItem<double>(tween: ConstantTween<double>(1), weight: 32),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1,
            end: 0,
          ).chain(CurveTween(curve: Curves.easeInOut)),
          weight: 34,
        ),
      ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!_controller.isAnimating) {
      _controller.forward(from: 0);
    }
  }

  void _onLongPress(BuildContext context) {
    InfoSheet.show(
      context,
      icon: Icons.visibility_off_outlined,
      title: 'Aphanes',
      body:
          'Aphanes comes from the Ancient Greek word ἀφανής '
          '(aphanēs), meaning unseen, invisible, not manifest.\n\n'
          'It\'s built from a negative prefix, a-, plus phainesthai, '
          '"to appear". Literally: the thing that does not appear.\n\n'
          'The same root is commonly linked to Aphaia, a minor Greek '
          'goddess worshipped on Aegina, known in myth for vanishing '
          'into a sacred grove.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle style = DefaultTextStyle.of(context).style;
    final List<String> chars = _word.split('');
    final int n = chars.length;

    // Per-glyph widths, so each letter can slide between the exact x it holds
    // in "Aphanes" and the x it holds in the reversed word, passing through
    // the others on the way rather than snapping.
    final List<double> widths = <double>[
      for (final String c in chars) _glyphWidth(c, style),
    ];

    // Left edge of each glyph in normal order, and of each slot in reversed
    // order. Glyph i lands in reversed slot (n-1-i), which is exactly where
    // it belongs once the word is flipped.
    final List<double> originX = _prefixSums(widths);
    final List<double> reversedSlotX = _prefixSums(<double>[
      for (int i = n - 1; i >= 0; i--) widths[i],
    ]);
    final List<double> targetX = <double>[
      for (int i = 0; i < n; i++) reversedSlotX[n - 1 - i],
    ];

    return GestureDetector(
      onTap: _onTap,
      onLongPress: () => _onLongPress(context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _t,
        builder: (BuildContext context, Widget? _) {
          final double t = _t.value;
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // Invisible full word, laid out normally, purely to give the
              // Stack a real width and height for the positioned glyphs
              // (which on their own would collapse it to nothing).
              Opacity(opacity: 0, child: Text(_word, style: style)),
              for (int i = 0; i < n; i++)
                Positioned(
                  top: 0,
                  left: lerpDouble(originX[i], targetX[i], t),
                  child: Text(chars[i], style: style),
                ),
            ],
          );
        },
      ),
    );
  }

  static List<double> _prefixSums(List<double> values) {
    final List<double> sums = <double>[];
    double acc = 0;
    for (final double v in values) {
      sums.add(acc);
      acc += v;
    }
    return sums;
  }

  static double _glyphWidth(String glyph, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: glyph, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }
}
