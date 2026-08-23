import 'package:flutter/material.dart';

class AppIconGlyph extends StatelessWidget {
  const AppIconGlyph({this.size = 24, this.opacity = 1, super.key});

  final double size;

  /// Applied by the painter to its own composite layer rather than by
  /// wrapping this in an [Opacity] widget. The painter already needs a
  /// `saveLayer` for its transparent cutout, so folding the fade into
  /// that same layer costs nothing, where an [Opacity] above it would
  /// add a second full-size layer per frame of an animated fade.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AppIconPainter(opacity)),
    );
  }
}

class _AppIconPainter extends CustomPainter {
  const _AppIconPainter(this.opacity);

  final double opacity;

  static const Color _gradientStart = Color(0xFFFB7185);
  static const Color _gradientEnd = Color(0xFFEC4899);

  // Recentered now that the stand is gone: the screen alone, not a
  // screen+stand group, is what's centered in this box.
  static const double _screenX = 140;
  static const double _screenY = 174;
  static const double _screenWidth = 232;
  static const double _screenHeight = 164;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = (size.width * 0.82) / _screenWidth;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(scale);
    canvas.translate(
      -(_screenX + _screenWidth / 2),
      -(_screenY + _screenHeight / 2),
    );

    final RRect screenRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(_screenX, _screenY, _screenWidth, _screenHeight),
      const Radius.circular(20),
    );
    final Paint screen = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_gradientStart, _gradientEnd],
      ).createShader(screenRRect.outerRect);

    // The "veiled" half is a real transparent cutout (BlendMode.clear on
    // a separate layer), not a translucent dark fill - it needs to read
    // as see-through against whatever surface the glyph sits on (varies
    // by theme and screen), not a hardcoded shadow color.
    canvas.saveLayer(
      screenRRect.outerRect,
      Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
    );
    canvas.clipRRect(screenRRect);
    canvas.drawRRect(screenRRect, screen);
    final Path veilPath = Path()
      ..moveTo(_screenX, _screenY + _screenHeight)
      ..lineTo(_screenX, _screenY + 48)
      ..lineTo(_screenX + _screenWidth, _screenY + _screenHeight)
      ..close();
    canvas.drawPath(veilPath, Paint()..blendMode = BlendMode.clear);
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AppIconPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}
