import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/shared_preferences_provider.dart';

const String _ambientBackdropPrefsKey = 'ambient_backdrop_enabled';

/// Whether the drifting ambient backdrop shows behind every screen.
/// Defaults to off pending a rework of the effect itself; a continuous
/// animation has a real (if modest) battery cost while visible, so it
/// stays a deliberate, opt-in choice for now rather than on by default.
class AmbientBackdropController extends Notifier<bool> {
  @override
  bool build() {
    return ref
            .watch(sharedPreferencesProvider)
            .getBool(_ambientBackdropPrefsKey) ??
        false;
  }

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref
        .read(sharedPreferencesProvider)
        .setBool(_ambientBackdropPrefsKey, enabled);
  }
}

final NotifierProvider<AmbientBackdropController, bool>
ambientBackdropControllerProvider =
    NotifierProvider<AmbientBackdropController, bool>(
      AmbientBackdropController.new,
    );

/// Two large, soft, low-opacity circles drifting slowly behind whatever
/// else is in the same [Stack] - ambient light rather than an obvious
/// animation. Meant to be the first child of a [Stack]; positions and
/// sizes itself to fill it. Reads its own on/off state, so a screen just
/// drops `const AmbientBackdrop()` in without wiring anything.
class AmbientBackdrop extends ConsumerStatefulWidget {
  const AmbientBackdrop({super.key});

  @override
  ConsumerState<AmbientBackdrop> createState() => _AmbientBackdropState();
}

class _AmbientBackdropState extends ConsumerState<AmbientBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _driftController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 25),
  );

  @override
  void dispose() {
    _driftController.dispose();
    super.dispose();
  }

  // Actually stops ticking when disabled, rather than just not painting -
  // no point spending frames animating something invisible.
  void _syncRunning(bool enabled) {
    if (enabled && !_driftController.isAnimating) {
      _driftController.repeat();
    } else if (!enabled && _driftController.isAnimating) {
      _driftController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = ref.watch(ambientBackdropControllerProvider);
    _syncRunning(enabled);
    if (!enabled) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: _AmbientBlobs(
            animation: _driftController,
            primary: theme.colorScheme.primary,
            secondary: theme.colorScheme.tertiary,
          ),
        ),
      ),
    );
  }
}

class _AmbientBlobs extends StatelessWidget {
  const _AmbientBlobs({
    required this.animation,
    required this.primary,
    required this.secondary,
  });

  final Animation<double> animation;
  final Color primary;
  final Color secondary;

  static BoxDecoration _blobDecoration(Color color) {
    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final BoxDecoration primaryDecoration = _blobDecoration(primary);
    final BoxDecoration secondaryDecoration = _blobDecoration(secondary);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? _) {
            final double t = animation.value * 2 * math.pi;
            return Stack(
              children: [
                _Blob(
                  decoration: primaryDecoration,
                  diameter: width * 0.95,
                  center: Offset(
                    width * 0.22 + math.sin(t) * width * 0.08,
                    height * 0.2 + math.cos(t * 2) * height * 0.05,
                  ),
                ),
                _Blob(
                  decoration: secondaryDecoration,
                  diameter: width * 0.85,
                  center: Offset(
                    width * 0.8 + math.cos(t) * width * 0.07,
                    height * 0.62 + math.sin(t * 2) * height * 0.06,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.decoration,
    required this.diameter,
    required this.center,
  });

  final BoxDecoration decoration;
  final double diameter;
  final Offset center;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - diameter / 2,
      top: center.dy - diameter / 2,
      child: DecoratedBox(
        decoration: decoration,
        child: SizedBox(width: diameter, height: diameter),
      ),
    );
  }
}
